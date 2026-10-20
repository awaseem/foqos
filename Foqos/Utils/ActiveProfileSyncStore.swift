import Foundation
import OSLog

enum ActiveProfileSyncStore {
  private static let log = Logger(
    subsystem: "dev.ambitionsoftware.foqos", category: "ActiveProfileSync")

  static func publish(
    session: SharedData.SessionSnapshot?,
    profile: SharedData.ProfileSnapshot?
  ) {
    let record: ActiveProfileSyncRecord

    if let session, session.endTime == nil,
      let profile, profile.id == session.blockedProfileId, profile.enableMacSync == true
    {
      record = ActiveProfileSyncRecord(
        profileId: profile.id,
        profileName: profile.name,
        sessionId: session.id,
        domains: FilterRules.normalize(profile.domains ?? []),
        domainMode: profile.enableAllowModeDomains ? .allowOnly : .block,
        state: state(for: session, profile: profile),
        updatedAt: Date()
      )
    } else {
      record = ActiveProfileSyncRecord(
        profileId: nil,
        profileName: nil,
        sessionId: nil,
        domains: [],
        domainMode: .block,
        state: .inactive,
        updatedAt: Date()
      )
    }
    do {
      let data = try JSONEncoder().encode(record)
      let store = NSUbiquitousKeyValueStore.default
      store.set(data, forKey: ActiveProfileSyncRecord.storeKey)
      // Hand off the local update before the monitor callback returns. This is not a delivery acknowledgement.
      let accepted = store.synchronize()
      log.info(
        "Profile sync update: state=\(record.state.rawValue, privacy: .public) bytes=\(data.count) synchronizeAccepted=\(accepted)"
      )
      if !accepted {
        log.error(
          "iCloud did not accept profile synchronization; check availability and entitlements")
      }
    } catch {
      log.error("Could not encode the profile sync record")
    }
  }

  private static func state(
    for session: SharedData.SessionSnapshot,
    profile: SharedData.ProfileSnapshot
  ) -> ActiveProfileSyncRecord.State {
    if session.pauseStartTime != nil && session.pauseEndTime == nil {
      return .paused
    }

    if profile.enableBreaks,
      profile.blockingStrategyId != SoftUnblockSessionLifecycleHandler.nfcStrategyId,
      profile.blockingStrategyId != SoftUnblockSessionLifecycleHandler.qrStrategyId,
      session.breakStartTime != nil && session.breakEndTime == nil
    {
      return .breakActive
    }

    return .active
  }
}
