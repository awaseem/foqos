import Foundation
import NetworkExtension
import OSLog
import SystemExtensions

final class FoqosFilterManager: NSObject, ObservableObject {
  enum Status: Equatable {
    case approvalRequired
    case disabled
    case enabled
    case failed(String)
    case installing
    case requiresRestart
    case unknown
  }

  static let extensionIdentifier = "dev.ambitionsoftware.foqos.mac.filter"

  @Published private(set) var status: Status = .unknown

  private let logger = Logger(
    subsystem: "dev.ambitionsoftware.foqos.mac",
    category: "filter-manager"
  )
  private var inspectionRequest: OSSystemExtensionRequest?
  private var latestRules: FilterRules?
  private var isSavingRules = false

  var statusText: String {
    switch status {
    case .approvalRequired:
      return "Approve the Foqos filter in System Settings."
    case .disabled:
      return "The website filter is installed but disabled."
    case .enabled:
      return "Website filter enabled"
    case .failed(let message):
      return message
    case .installing:
      return "Installing website filter…"
    case .requiresRestart:
      return "Restart your Mac to finish installing the filter."
    case .unknown:
      return "Website filter not configured"
    }
  }

  override init() {
    super.init()
    refreshStatus()
    installBundledExtensionIfNeeded()
  }

  func installAndEnable() {
    status = .installing

    let request = OSSystemExtensionRequest.activationRequest(
      forExtensionWithIdentifier: Self.extensionIdentifier,
      queue: .main
    )
    request.delegate = self
    OSSystemExtensionManager.shared.submitRequest(request)
  }

  private func installBundledExtensionIfNeeded() {
    let request = OSSystemExtensionRequest.propertiesRequest(
      forExtensionWithIdentifier: Self.extensionIdentifier,
      queue: .main
    )
    request.delegate = self
    inspectionRequest = request
    OSSystemExtensionManager.shared.submitRequest(request)
  }

  private var bundledExtensionVersion: String? {
    guard
      let bundleURL = Bundle.main.url(
        forResource: Self.extensionIdentifier,
        withExtension: "systemextension",
        subdirectory: "Contents/Library/SystemExtensions"
      )
    else {
      return nil
    }

    return Bundle(url: bundleURL)?.object(forInfoDictionaryKey: "CFBundleVersion") as? String
  }

  func refreshStatus() {
    NEFilterManager.shared().loadFromPreferences { [weak self] error in
      DispatchQueue.main.async {
        guard let self else {
          return
        }

        if let error {
          self.status = .failed(error.localizedDescription)
          return
        }

        self.status = NEFilterManager.shared().isEnabled ? .enabled : .disabled
      }
    }
  }

  func setRules(_ rules: FilterRules) {
    guard latestRules != rules else {
      return
    }

    latestRules = rules
    saveLatestRulesIfNeeded()
  }

  private func configureFilter() {
    let manager = NEFilterManager.shared()
    manager.loadFromPreferences { [weak self] error in
      guard let self, error == nil else {
        DispatchQueue.main.async {
          self?.status = .failed(error?.localizedDescription ?? "Unable to load filter settings.")
        }
        return
      }

      let configuration = NEFilterProviderConfiguration()
      configuration.filterDataProviderBundleIdentifier = Self.extensionIdentifier
      configuration.filterPackets = false
      configuration.filterSockets = true
      configuration.organization = "Foqos"
      configuration.vendorConfiguration = self.vendorConfiguration(
        for: self.latestRules ?? .disabled)

      manager.localizedDescription = "Foqos Website Filter"
      manager.providerConfiguration = configuration
      manager.isEnabled = true
      manager.saveToPreferences { error in
        DispatchQueue.main.async {
          if let error {
            self.status = .failed(error.localizedDescription)
          } else {
            self.status = .enabled
          }
        }
      }
    }
  }

  private func saveLatestRulesIfNeeded() {
    guard !isSavingRules else {
      return
    }

    guard let rules = latestRules else {
      return
    }

    isSavingRules = true

    let manager = NEFilterManager.shared()
    manager.loadFromPreferences { [weak self] error in
      DispatchQueue.main.async {
        guard
          let self,
          error == nil,
          let configuration = manager.providerConfiguration
        else {
          self?.finishSavingRules(rules, error: error)
          return
        }

        configuration.vendorConfiguration = self.vendorConfiguration(for: rules)
        manager.providerConfiguration = configuration
        manager.saveToPreferences { error in
          DispatchQueue.main.async {
            self.finishSavingRules(rules, error: error)
          }
        }
      }
    }
  }

  private func finishSavingRules(_ savedRules: FilterRules, error: Error?) {
    if let error {
      status = .failed(error.localizedDescription)
    }

    isSavingRules = false

    if latestRules != savedRules {
      saveLatestRulesIfNeeded()
    }
  }

  private func vendorConfiguration(for rules: FilterRules) -> [String: Any]? {
    guard let data = try? JSONEncoder().encode(rules) else {
      return nil
    }

    return [FilterRules.vendorConfigurationKey: data]
  }
}

extension FoqosFilterManager: OSSystemExtensionRequestDelegate {
  func request(
    _ request: OSSystemExtensionRequest,
    actionForReplacingExtension existing: OSSystemExtensionProperties,
    withExtension extension: OSSystemExtensionProperties
  ) -> OSSystemExtensionRequest.ReplacementAction {
    .replace
  }

  func request(
    _ request: OSSystemExtensionRequest,
    didFailWithError error: Error
  ) {
    if request === inspectionRequest {
      inspectionRequest = nil
      logger.error("Unable to inspect installed filter version: \(error.localizedDescription)")
      return
    }

    status = .failed(error.localizedDescription)
  }

  func request(
    _ request: OSSystemExtensionRequest,
    didFinishWithResult result: OSSystemExtensionRequest.Result
  ) {
    if request === inspectionRequest {
      inspectionRequest = nil
      return
    }

    switch result {
    case .completed:
      configureFilter()
    case .willCompleteAfterReboot:
      status = .requiresRestart
    @unknown default:
      status = .failed("The system returned an unknown filter installation result.")
    }
  }

  func requestNeedsUserApproval(_ request: OSSystemExtensionRequest) {
    status = .approvalRequired
  }

  func request(
    _ request: OSSystemExtensionRequest,
    foundProperties properties: [OSSystemExtensionProperties]
  ) {
    guard request === inspectionRequest else {
      return
    }

    let hasCurrentVersion = properties.contains { properties in
      properties.isEnabled && properties.bundleVersion == bundledExtensionVersion
    }

    if !hasCurrentVersion {
      installAndEnable()
    }
  }
}
