import Darwin
import Foundation
import NetworkExtension
import OSLog

final class FilterDataProvider: NEFilterDataProvider {
  private let logger = Logger(
    subsystem: "dev.ambitionsoftware.foqos.mac.filter",
    category: "filter"
  )
  private let stateLock = NSLock()
  private var activeWebFlows: [UUID: NEFilterSocketFlow] = [:]
  private var configurationObservation: NSKeyValueObservation?
  private var outboundBuffers: [UUID: Data] = [:]
  private var rules = FilterRules.disabled

  override func startFilter(completionHandler: @escaping (Error?) -> Void) {
    configurationObservation = observe(\.filterConfiguration, options: [.new]) {
      [weak self] _, _ in
      self?.reloadRules()
    }
    reloadRules()

    apply(NEFilterSettings(rules: [], defaultAction: .filterData)) {
      [logger] error in
      if let error {
        logger.error("Unable to apply filter settings: \(error.localizedDescription)")
      }
      completionHandler(error)
    }
  }

  override func stopFilter(
    with reason: NEProviderStopReason,
    completionHandler: @escaping () -> Void
  ) {
    configurationObservation?.invalidate()
    configurationObservation = nil

    stateLock.lock()
    activeWebFlows.removeAll()
    outboundBuffers.removeAll()
    stateLock.unlock()

    logger.notice("Filter stopped: \(reason.rawValue)")
    completionHandler()
  }

  override func handleNewFlow(_ flow: NEFilterFlow) -> NEFilterNewFlowVerdict {
    let verdict = newFlowVerdict(for: flow, rules: currentRules)

    if let socketFlow = flow as? NEFilterSocketFlow, isWebFlow(socketFlow) {
      stateLock.lock()
      activeWebFlows[flow.identifier] = socketFlow
      stateLock.unlock()
      verdict.shouldReport = true
    }

    return verdict
  }

  override func handle(_ report: NEFilterReport) {
    guard report.event == .flowClosed, let identifier = report.flow?.identifier else {
      return
    }

    stateLock.lock()
    activeWebFlows.removeValue(forKey: identifier)
    outboundBuffers.removeValue(forKey: identifier)
    stateLock.unlock()
  }

  override func handleOutboundData(
    from flow: NEFilterFlow,
    readBytesStartOffset offset: Int,
    readBytes: Data
  ) -> NEFilterDataVerdict {
    let rules = currentRules
    guard rules.isEnabled else {
      return .allow()
    }

    guard let data = append(readBytes, at: offset, for: flow) else {
      return .allow()
    }

    switch TLSClientHelloParser.parse(data) {
    case .hostname(let hostname):
      removeBuffer(for: flow)
      return dataVerdict(for: hostname, rules: rules)

    case .needMoreData(let byteCount):
      guard byteCount > data.count else {
        removeBuffer(for: flow)
        return .allow()
      }
      return .init(passBytes: 0, peekBytes: byteCount)

    case .notClientHello:
      removeBuffer(for: flow)
      return .allow()
    }
  }

  override func handleOutboundDataComplete(for flow: NEFilterFlow) -> NEFilterDataVerdict {
    removeBuffer(for: flow)
    return .allow()
  }

  private func reloadRules() {
    let updatedRules = configuredRules

    stateLock.lock()
    let shouldResetFlows = updatedRules.isEnabled && updatedRules != rules
    rules = updatedRules
    let flowsToReset = shouldResetFlows ? Array(activeWebFlows.values) : []
    stateLock.unlock()

    logger.notice(
      "Rules updated: enabled=\(updatedRules.isEnabled) domains=\(updatedRules.domains.count) reset_flows=\(flowsToReset.count)"
    )

    for flow in flowsToReset {
      update(flow, using: .drop(), for: .any)
    }
  }

  private var currentRules: FilterRules {
    stateLock.lock()
    defer {
      stateLock.unlock()
    }
    return rules
  }

  private var configuredRules: FilterRules {
    guard
      let data = filterConfiguration.vendorConfiguration?[
        FilterRules.vendorConfigurationKey
      ] as? Data,
      let rules = try? JSONDecoder().decode(FilterRules.self, from: data)
    else {
      return .disabled
    }

    return rules
  }

  private func newFlowVerdict(
    for flow: NEFilterFlow,
    rules: FilterRules
  ) -> NEFilterNewFlowVerdict {
    guard rules.isEnabled else {
      return .allow()
    }

    guard
      let socketFlow = flow as? NEFilterSocketFlow,
      let endpoint = socketFlow.remoteEndpoint as? NWHostEndpoint
    else {
      guard let hostname = flow.url?.host else {
        return .allow()
      }
      return rules.shouldBlock(hostname) ? loggedDrop(hostname) : .allow()
    }

    guard endpoint.port == "80" || endpoint.port == "443" else {
      return .allow()
    }

    if let hostname = hostname(for: flow) {
      return rules.shouldBlock(hostname) ? loggedDrop(hostname) : .allow()
    }

    if socketFlow.socketProtocol == IPPROTO_UDP, endpoint.port == "443" {
      return .drop()
    }

    guard socketFlow.socketProtocol == IPPROTO_TCP, endpoint.port == "443" else {
      return .allow()
    }

    return .filterDataVerdict(
      withFilterInbound: false,
      peekInboundBytes: 0,
      filterOutbound: true,
      peekOutboundBytes: TLSClientHelloParser.initialByteCount
    )
  }

  private func dataVerdict(
    for hostname: String,
    rules: FilterRules
  ) -> NEFilterDataVerdict {
    guard rules.shouldBlock(hostname) else {
      return .allow()
    }

    logger.debug("Blocked TLS hostname: \(hostname, privacy: .public)")
    return .drop()
  }

  private func loggedDrop(_ hostname: String) -> NEFilterNewFlowVerdict {
    logger.debug("Blocked hostname: \(hostname, privacy: .public)")
    return .drop()
  }

  private func append(
    _ data: Data,
    at offset: Int,
    for flow: NEFilterFlow
  ) -> Data? {
    stateLock.lock()
    defer {
      stateLock.unlock()
    }

    let identifier = flow.identifier
    var buffer = outboundBuffers[identifier] ?? Data()
    guard
      offset == buffer.count,
      buffer.count + data.count <= TLSClientHelloParser.maximumByteCount
    else {
      outboundBuffers.removeValue(forKey: identifier)
      return nil
    }

    buffer.append(data)
    outboundBuffers[identifier] = buffer
    return buffer
  }

  private func removeBuffer(for flow: NEFilterFlow) {
    stateLock.lock()
    outboundBuffers.removeValue(forKey: flow.identifier)
    stateLock.unlock()
  }

  private func isWebFlow(_ flow: NEFilterSocketFlow) -> Bool {
    guard let endpoint = flow.remoteEndpoint as? NWHostEndpoint else {
      return false
    }
    return endpoint.port == "80" || endpoint.port == "443"
  }

  private func hostname(for flow: NEFilterFlow) -> String? {
    if let hostname = flow.url?.host {
      return hostname
    }

    guard let socketFlow = flow as? NEFilterSocketFlow else {
      return nil
    }

    if let hostname = socketFlow.remoteHostname {
      return hostname
    }

    guard
      let endpoint = socketFlow.remoteEndpoint as? NWHostEndpoint,
      !isIPAddress(endpoint.hostname)
    else {
      return nil
    }
    return endpoint.hostname
  }

  private func isIPAddress(_ value: String) -> Bool {
    let address =
      value
      .trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
      .split(separator: "%", maxSplits: 1)
      .first
      .map(String.init) ?? value
    var ipv4 = in_addr()
    var ipv6 = in6_addr()

    return address.withCString { inet_pton(AF_INET, $0, &ipv4) == 1 }
      || address.withCString { inet_pton(AF_INET6, $0, &ipv6) == 1 }
  }
}
