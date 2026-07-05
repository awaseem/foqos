import Foundation

enum SoftUnblockGrantStore {
  struct DebugSnapshot: Equatable {
    let activeSession: SoftUnblockSessionState?
    let hasStoredActiveSession: Bool
    let grants: [SoftUnblockGrant]
    let storedGrantEntryCount: Int
    let undecodableGrantKeys: [String]
  }

  private static let suite = UserDefaults(
    suiteName: "group.dev.ambitionsoftware.foqos"
  )!

  private static let activeSessionKey = "softUnblock.activeSession"
  private static let grantKeyPrefix = "softUnblock.grant."

  static var activeSession: SoftUnblockSessionState? {
    guard let data = suite.data(forKey: activeSessionKey) else { return nil }
    return try? JSONDecoder().decode(SoftUnblockSessionState.self, from: data)
  }

  static func beginSession(sessionId: String, profileId: UUID) {
    clearAll()

    let state = SoftUnblockSessionState(sessionId: sessionId, profileId: profileId)
    guard let data = try? JSONEncoder().encode(state) else { return }
    suite.set(data, forKey: activeSessionKey)
  }

  static func add(_ grant: SoftUnblockGrant) -> Bool {
    guard isActive(sessionId: grant.sessionId, profileId: grant.profileId),
      let data = try? JSONEncoder().encode(grant)
    else {
      return false
    }

    suite.set(data, forKey: grantKey(sessionId: grant.sessionId, grantId: grant.id))
    return true
  }

  static func grant(id: UUID, sessionId: String) -> SoftUnblockGrant? {
    let key = grantKey(sessionId: sessionId, grantId: id)
    guard let data = suite.data(forKey: key) else { return nil }
    return try? JSONDecoder().decode(SoftUnblockGrant.self, from: data)
  }

  static func activeGrants(
    for profileId: UUID,
    at date: Date = Date()
  ) -> [SoftUnblockGrant] {
    guard let activeSession, activeSession.profileId == profileId else { return [] }

    return grants(for: activeSession.sessionId).filter { !$0.isExpired(at: date) }
  }

  static func hasActiveGrant(
    for resource: SoftUnblockResource,
    profileId: UUID,
    at date: Date = Date()
  ) -> Bool {
    activeGrants(for: profileId, at: date).contains { $0.resource == resource }
  }

  static func removeGrant(id: UUID, sessionId: String) {
    suite.removeObject(forKey: grantKey(sessionId: sessionId, grantId: id))
  }

  static func endSession(sessionId: String) {
    removeGrants(for: sessionId)

    guard activeSession?.sessionId == sessionId else { return }
    suite.removeObject(forKey: activeSessionKey)
  }

  static func clearAll() {
    for key in suite.dictionaryRepresentation().keys where key.hasPrefix(grantKeyPrefix) {
      suite.removeObject(forKey: key)
    }
    suite.removeObject(forKey: activeSessionKey)
  }

  static func isActive(sessionId: String, profileId: UUID) -> Bool {
    activeSession == SoftUnblockSessionState(sessionId: sessionId, profileId: profileId)
  }

  static func debugSnapshot() -> DebugSnapshot {
    let storedValues = suite.dictionaryRepresentation()
    let grantEntries = storedValues.filter { key, _ in
      key.hasPrefix(grantKeyPrefix)
    }
    var grants: [SoftUnblockGrant] = []
    var undecodableGrantKeys: [String] = []

    for (key, value) in grantEntries {
      guard let data = value as? Data,
        let grant = try? JSONDecoder().decode(SoftUnblockGrant.self, from: data)
      else {
        undecodableGrantKeys.append(key)
        continue
      }

      grants.append(grant)
    }

    return DebugSnapshot(
      activeSession: activeSession,
      hasStoredActiveSession: storedValues[activeSessionKey] != nil,
      grants: grants.sorted { $0.createdAt < $1.createdAt },
      storedGrantEntryCount: grantEntries.count,
      undecodableGrantKeys: undecodableGrantKeys.sorted()
    )
  }

  private static func grants(for sessionId: String) -> [SoftUnblockGrant] {
    let prefix = grantSessionKeyPrefix(sessionId: sessionId)

    return suite.dictionaryRepresentation().compactMap { key, value in
      guard key.hasPrefix(prefix), let data = value as? Data else { return nil }
      return try? JSONDecoder().decode(SoftUnblockGrant.self, from: data)
    }
  }

  private static func removeGrants(for sessionId: String) {
    let prefix = grantSessionKeyPrefix(sessionId: sessionId)
    for key in suite.dictionaryRepresentation().keys where key.hasPrefix(prefix) {
      suite.removeObject(forKey: key)
    }
  }

  private static func grantSessionKeyPrefix(sessionId: String) -> String {
    "\(grantKeyPrefix)\(sessionId)."
  }

  private static func grantKey(sessionId: String, grantId: UUID) -> String {
    "\(grantSessionKeyPrefix(sessionId: sessionId))\(grantId.uuidString)"
  }
}
