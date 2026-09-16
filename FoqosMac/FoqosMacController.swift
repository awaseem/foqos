import AppKit
import Foundation

@MainActor
final class FoqosMacController: ObservableObject {
  @Published private(set) var syncedRecord: ActiveProfileSyncRecord?

  private let cloudStore = NSUbiquitousKeyValueStore.default
  private let filterManager: FoqosFilterManager
  private var cloudObserver: NSObjectProtocol?
  private var identityObserver: NSObjectProtocol?
  private let diagnostics = MacDiagnostics.shared

  var isBlocking: Bool {
    guard syncedRecord?.state == .active, !isAllowModeActive else {
      return false
    }

    return !activeDomains.isEmpty
  }

  var activeDomains: [String] {
    guard syncedRecord?.state == .active, !isAllowModeActive else {
      return []
    }

    return FilterRules.normalize(syncedRecord?.domains ?? [])
  }

  var isAllowModeActive: Bool {
    syncedRecord?.state == .active && syncedRecord?.domainMode == .allowOnly
  }

  var isICloudAvailable: Bool {
    FileManager.default.ubiquityIdentityToken != nil
  }

  init(filterManager: FoqosFilterManager = FoqosFilterManager()) {
    self.filterManager = filterManager

    startObserving()
    refreshFromCloud(trigger: "app_launch")
  }

  deinit {
    if let cloudObserver {
      NotificationCenter.default.removeObserver(cloudObserver)
    }
    if let identityObserver {
      NotificationCenter.default.removeObserver(identityObserver)
    }
  }

  func refreshFromCloud(trigger: String = "manual_refresh") {
    let attemptID = UUID().uuidString
    let accepted = cloudStore.synchronize()
    let fields = [
      "attemptID": attemptID, "trigger": trigger,
      "iCloudIdentityAvailable": String(isICloudAvailable),
      "synchronizeAccepted": String(accepted),
    ]
    diagnostics.record(
      "sync.refresh_requested",
      "Reading the local iCloud cache; synchronize acceptance does not confirm server delivery.",
      level: accepted && isICloudAvailable ? .info : .warning, fields: fields
    )

    guard let data = cloudStore.data(forKey: ActiveProfileSyncRecord.storeKey) else {
      syncedRecord = nil
      diagnostics.record(
        "sync.record_missing",
        "No profile record is available in the local iCloud cache. Waiting for an iPhone update.",
        level: .warning, fields: fields
      )
      diagnostics.updateState(
        "sync", fields: fields.merging(["result": "record_missing"]) { _, new in new })
      applyCurrentRules(attemptID: attemptID)
      return
    }

    do {
      let record = try JSONDecoder().decode(ActiveProfileSyncRecord.self, from: data)
      let changed = record != syncedRecord
      syncedRecord = record
      let details = fields.merging(ProfileSyncDiagnostics.fields(for: record)) { _, new in new }
        .merging([
          "changed": String(changed), "payloadBytes": String(data.count), "result": "decoded",
        ]) { _, new in new }
      diagnostics.record(
        "sync.record_decoded", "Read a profile record from the local iCloud cache.", fields: details
      )
      diagnostics.updateState("sync", fields: details)
    } catch {
      syncedRecord = nil
      let details = fields.merging(ProfileSyncDiagnostics.fields(for: error)) { _, new in new }
        .merging(["payloadBytes": String(data.count), "result": "decode_failed"]) { _, new in new }
      diagnostics.record(
        "sync.decode_failed",
        "The cached profile could not be decoded. Blocking rules will be disabled.",
        level: .error, fields: details
      )
      diagnostics.updateState("sync", fields: details)
    }
    applyCurrentRules(attemptID: attemptID)
  }

  func quit() {
    diagnostics.record(
      "app.quit_requested", "Submitting disabled rules before quitting; completion is not awaited.")
    filterManager.setRules(.disabled)
    NSApplication.shared.terminate(nil)
  }

  private func startObserving() {
    cloudObserver = NotificationCenter.default.addObserver(
      forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
      object: cloudStore,
      queue: .main
    ) { [weak self] notification in
      let reason = ProfileSyncDiagnostics.changeReason(
        notification.userInfo?[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int
      )
      let keys = notification.userInfo?[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String] ?? []
      Task { @MainActor in
        self?.diagnostics.record(
          "sync.external_change", "iCloud reported a change to the Mac key-value store.",
          level: reason == "quota_violation" ? .error : .info,
          fields: [
            "reason": reason, "changedKeyCount": String(keys.count),
            "includesProfileKey": String(keys.contains(ActiveProfileSyncRecord.storeKey)),
          ]
        )
        self?.refreshFromCloud(trigger: reason)
      }
    }
    identityObserver = NotificationCenter.default.addObserver(
      forName: NSNotification.Name.NSUbiquityIdentityDidChange, object: nil, queue: .main
    ) { [weak self] _ in
      Task { @MainActor in
        self?.diagnostics.record(
          "sync.identity_changed",
          "The Mac's iCloud identity changed. Rechecking the profile cache.")
        self?.refreshFromCloud(trigger: "identity_changed")
      }
    }
  }

  private func applyCurrentRules(attemptID: String) {
    let reason: String
    if syncedRecord == nil {
      reason = "no_readable_record"
    } else if syncedRecord?.state != .active {
      reason = "profile_not_active"
    } else if isAllowModeActive {
      reason = "allow_mode_unsupported_on_mac"
    } else if activeDomains.isEmpty {
      reason = "no_explicit_domains"
    } else {
      reason = "active_block_profile"
    }
    let fields = [
      "attemptID": attemptID, "reason": reason, "blockingRequested": String(isBlocking),
      "domainCount": String(activeDomains.count),
    ]
    diagnostics.record(
      "sync.rules_selected",
      "Selected website rules from the cached profile; submitting them to the filter manager.",
      level: isAllowModeActive ? .warning : .info, fields: fields
    )
    diagnostics.updateState("rules", fields: fields)
    filterManager.setRules(
      FilterRules(
        isEnabled: isBlocking,
        domains: activeDomains
      ), attemptID: attemptID
    )
  }
}
