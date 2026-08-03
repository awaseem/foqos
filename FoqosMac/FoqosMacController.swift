import AppKit
import Foundation

@MainActor
final class FoqosMacController: ObservableObject {
  @Published private(set) var syncedRecord: ActiveProfileSyncRecord?

  private let cloudStore = NSUbiquitousKeyValueStore.default
  private let filterManager: FoqosFilterManager
  private var cloudObserver: NSObjectProtocol?

  var isBlocking: Bool {
    guard syncedRecord?.state == .active else {
      return false
    }

    return activeMode == .allowOnly || !activeDomains.isEmpty
  }

  var activeDomains: [String] {
    guard syncedRecord?.state == .active else {
      return []
    }

    return FilterRules.normalize(syncedRecord?.domains ?? [])
  }

  var activeMode: FilterRules.Mode {
    guard syncedRecord?.domainMode == .allowOnly else {
      return .block
    }

    return .allowOnly
  }

  var isICloudAvailable: Bool {
    FileManager.default.ubiquityIdentityToken != nil
  }

  init(filterManager: FoqosFilterManager = FoqosFilterManager()) {
    self.filterManager = filterManager

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
}
