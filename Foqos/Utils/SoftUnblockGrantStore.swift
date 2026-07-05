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

  static func beginSession(
    sessionId: String,
    profileId: UUID,
    maximumUnblockCount: Int
  ) {
    clearAll()

    let state = SoftUnblockSessionState(
      sessionId: sessionId,
      profileId: profileId,
      maximumUnblockCount: min(max(maximumUnblockCount, 1), 10),
      usedUnblockCount: 0
    )
    saveActiveSession(state)
  }

  static func issue(_ grant: SoftUnblockGrant) -> Bool {
    guard var session = activeSession,
      session.sessionId == grant.sessionId,
      session.profileId == grant.profileId,
      session.remainingUnblockCount > 0,
      let grantData = try? JSONEncoder().encode(grant)
    else {
      return false
    }

    session.usedUnblockCount += 1
    guard let sessionData = try? JSONEncoder().encode(session) else { return false }

    suite.set(grantData, forKey: grantKey(sessionId: grant.sessionId, grantId: grant.id))
    suite.set(sessionData, forKey: activeSessionKey)
    return true
  }

  static func rollbackIssuedGrant(id: UUID, sessionId: String) {
    guard grant(id: id, sessionId: sessionId) != nil else { return }
    removeGrant(id: id, sessionId: sessionId)

    guard var session = activeSession,
      session.sessionId == sessionId,
      session.usedUnblockCount > 0
    else {
      return
    }

    session.usedUnblockCount -= 1
    saveActiveSession(session)
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
    guard let activeSession else { return false }
    return activeSession.sessionId == sessionId && activeSession.profileId == profileId
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

  private static func saveActiveSession(_ session: SoftUnblockSessionState) {
    guard let data = try? JSONEncoder().encode(session) else { return }
    suite.set(data, forKey: activeSessionKey)
  }
}
