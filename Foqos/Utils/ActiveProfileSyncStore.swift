import Foundation

enum ActiveProfileSyncStore {
  private static let store = NSUbiquitousKeyValueStore.default

  static func publish(session: BlockedProfileSession?) {
    let record: ActiveProfileSyncRecord

    if let session, session.isActive, session.blockedProfile.enableMacSync {
      record = ActiveProfileSyncRecord(
        profileId: session.blockedProfile.id,
        profileName: session.blockedProfile.name,
        sessionId: session.id,
        domains: domains(for: session.blockedProfile),
        domainMode: session.blockedProfile.enableAllowModeDomains ? .allowOnly : .block,
        state: state(for: session),
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

    guard let data = try? JSONEncoder().encode(record) else {
      return
    }

    store.set(data, forKey: ActiveProfileSyncRecord.storeKey)
    store.synchronize()
  }

  private static func state(for session: BlockedProfileSession) -> ActiveProfileSyncRecord.State {
    if session.isPauseActive {
      return .paused
    }

    if session.isBreakActive {
      return .breakActive
    }

    return .active
  }

  private static func domains(for profile: BlockedProfiles) -> [String] {
    FilterRules.normalize(profile.domains ?? [])
  }
}
