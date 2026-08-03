import AppKit
import Foundation

@MainActor
final class FoqosMacController: ObservableObject {
  @Published private(set) var syncedRecord: ActiveProfileSyncRecord?
  @Published var enableMacBlocking: Bool {
    didSet {
      defaults.set(enableMacBlocking, forKey: enableMacBlockingKey)
      applyCurrentRules()
    }
  }
  @Published var enableLocalTest: Bool = false {
    didSet {
      applyCurrentRules()
    }
  }
  @Published var localTestDomain: String {
    didSet {
      defaults.set(localTestDomain, forKey: localTestDomainKey)
      scheduleLocalTestRuleUpdate()
    }
  }

  private let enableMacBlockingKey = "enableMacBlocking"
  private let localTestDomainKey = "localTestDomain"
  private let cloudStore = NSUbiquitousKeyValueStore.default
  private let defaults = UserDefaults.standard
  private let filterManager: FoqosFilterManager
  private var cloudObserver: NSObjectProtocol?
  private var localTestRuleUpdateWorkItem: DispatchWorkItem?

  var isBlocking: Bool {
    guard enableMacBlocking, enableLocalTest || syncedRecord?.state == .active else {
      return false
    }

    return activeMode == .allowOnly || !activeDomains.isEmpty
  }

  var activeDomains: [String] {
    if enableLocalTest {
      return FilterRules.normalize([localTestDomain])
    }

    guard syncedRecord?.state == .active else {
      return []
    }

    return FilterRules.normalize(syncedRecord?.domains ?? [])
  }

  var activeMode: FilterRules.Mode {
    guard !enableLocalTest, syncedRecord?.domainMode == .allowOnly else {
      return .block
    }

    return .allowOnly
  }

  var isICloudAvailable: Bool {
    FileManager.default.ubiquityIdentityToken != nil
  }

  init(filterManager: FoqosFilterManager = FoqosFilterManager()) {
    self.filterManager = filterManager

    if defaults.object(forKey: enableMacBlockingKey) == nil {
      enableMacBlocking = true
    } else {
      enableMacBlocking = defaults.bool(forKey: enableMacBlockingKey)
    }

    localTestDomain = defaults.string(forKey: localTestDomainKey) ?? "youtube.com"

    startObserving()
    refreshFromCloud()
  }

  deinit {
    if let cloudObserver {
      NotificationCenter.default.removeObserver(cloudObserver)
    }
  }

  func refreshFromCloud() {
    cloudStore.synchronize()

    guard let data = cloudStore.data(forKey: ActiveProfileSyncRecord.storeKey) else {
      syncedRecord = nil
      applyCurrentRules()
      return
    }

    syncedRecord = try? JSONDecoder().decode(ActiveProfileSyncRecord.self, from: data)
    applyCurrentRules()
  }

  func quit() {
    filterManager.setRules(.disabled)
    NSApplication.shared.terminate(nil)
  }

  private func startObserving() {
    cloudObserver = NotificationCenter.default.addObserver(
      forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
      object: cloudStore,
      queue: .main
    ) { [weak self] _ in
      Task { @MainActor in
        self?.refreshFromCloud()
      }
    }
  }

  private func applyCurrentRules() {
    filterManager.setRules(
      FilterRules(
        isEnabled: isBlocking,
        domains: activeDomains,
        mode: activeMode
      )
    )
  }

  private func scheduleLocalTestRuleUpdate() {
    localTestRuleUpdateWorkItem?.cancel()

    let workItem = DispatchWorkItem { [weak self] in
      self?.applyCurrentRules()
    }
    localTestRuleUpdateWorkItem = workItem
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: workItem)
  }
}
