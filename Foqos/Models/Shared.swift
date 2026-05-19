import FamilyControls
import Foundation
import ManagedSettings
import os

enum SharedData {
  private static let suite = UserDefaults(
    suiteName: "group.dev.ambitionsoftware.foqos"
  )!

  static func debugLog(_ message: String) {
    let formatted = "[PauseMode] \(message)"
    print(formatted)
    NSLog("%@", formatted)
    os_log("%{public}@", log: .default, type: .default, formatted)
  }

  // MARK: – Keys
  private enum Key: String {
    case profileSnapshots
    case activeScheduleSession
    case completedScheduleSessions
    case pauseModeActiveProfileId
    case pauseUnlockedApplicationTokens
    case pauseUnlockedCategoryTokens
  }

  // MARK: – Serializable snapshot of a profile (no sessions)
  struct ProfileSnapshot: Codable, Equatable {
    var id: UUID
    var name: String
    var selectedActivity: FamilyActivitySelection
    var createdAt: Date
    var updatedAt: Date
    var blockingStrategyId: String?
    var strategyData: Data?
    var order: Int

    var enableLiveActivity: Bool
    var reminderTimeInSeconds: UInt32?
    var customReminderMessage: String?
    var enableBreaks: Bool
    var breakTimeInMinutes: Int = 15
    var enableStrictMode: Bool
    var enableBlockAppInstallation: Bool = false
    var enableAllowMode: Bool
    var enableAllowModeDomains: Bool
    var enableSafariBlocking: Bool
    var enableAdultContentBlocking: Bool? = nil

    var domains: [String]?

    @available(*, deprecated, message: "Use physicalUnblockItems instead")
    var physicalUnblockNFCTagId: String? = nil

    @available(*, deprecated, message: "Use physicalUnblockItems instead")
    var physicalUnblockQRCodeId: String? = nil

    var physicalUnblockItems: [PhysicalUnblockItem]? = nil

    var schedule: BlockedProfileSchedule?

    var disableBackgroundStops: Bool?
    var enableEmergencyUnblock: Bool?
  }

  // MARK: – Serializable snapshot of a session (no profile object)
  struct SessionSnapshot: Codable, Equatable {
    var id: String
    var tag: String
    var blockedProfileId: UUID

    var startTime: Date
    var endTime: Date?

    var breakStartTime: Date?
    var breakEndTime: Date?

    var pauseStartTime: Date?
    var pauseEndTime: Date?

    var forceStarted: Bool
  }

  // MARK: – Persisted snapshots keyed by profile ID (UUID string)
  static var profileSnapshots: [String: ProfileSnapshot] {
    get {
      guard let data = suite.data(forKey: Key.profileSnapshots.rawValue) else { return [:] }
      return (try? JSONDecoder().decode([String: ProfileSnapshot].self, from: data)) ?? [:]
    }
    set {
      if let data = try? JSONEncoder().encode(newValue) {
        suite.set(data, forKey: Key.profileSnapshots.rawValue)
      } else {
        suite.removeObject(forKey: Key.profileSnapshots.rawValue)
      }
    }
  }

  static func snapshot(for profileID: String) -> ProfileSnapshot? {
    profileSnapshots[profileID]
  }

  static func setSnapshot(_ snapshot: ProfileSnapshot, for profileID: String) {
    var all = profileSnapshots
    all[profileID] = snapshot
    profileSnapshots = all
  }

  static func removeSnapshot(for profileID: String) {
    var all = profileSnapshots
    all.removeValue(forKey: profileID)
    profileSnapshots = all
  }

  // MARK: – Persisted array of scheduled sessions
  static var completedSessionsInSchedular: [SessionSnapshot] {
    get {
      guard let data = suite.data(forKey: Key.completedScheduleSessions.rawValue) else { return [] }
      return (try? JSONDecoder().decode([SessionSnapshot].self, from: data)) ?? []
    }
    set {
      if let data = try? JSONEncoder().encode(newValue) {
        suite.set(data, forKey: Key.completedScheduleSessions.rawValue)
      } else {
        suite.removeObject(forKey: Key.completedScheduleSessions.rawValue)
      }
    }
  }

  // MARK: – Persisted array of scheduled sessions
  static var activeSharedSession: SessionSnapshot? {
    get {
      guard let data = suite.data(forKey: Key.activeScheduleSession.rawValue) else { return nil }
      return (try? JSONDecoder().decode(SessionSnapshot.self, from: data)) ?? nil
    }
    set {
      if let data = try? JSONEncoder().encode(newValue) {
        suite.set(data, forKey: Key.activeScheduleSession.rawValue)
      } else {
        suite.removeObject(forKey: Key.activeScheduleSession.rawValue)
      }
    }
  }

  static func createSessionForSchedular(for profileID: UUID) {
    activeSharedSession = SessionSnapshot(
      id: UUID().uuidString,
      tag: profileID.uuidString,
      blockedProfileId: profileID,
      startTime: Date(),
      forceStarted: true)
  }

  static func createActiveSharedSession(for session: SessionSnapshot) {
    activeSharedSession = session
  }

  static func getActiveSharedSession() -> SessionSnapshot? {
    activeSharedSession
  }

  static func endActiveSharedSession() {
    guard var existingScheduledSession = activeSharedSession else { return }

    existingScheduledSession.endTime = Date()
    completedSessionsInSchedular.append(existingScheduledSession)

    activeSharedSession = nil
  }

  static func flushActiveSession() {
    activeSharedSession = nil
  }

  // MARK: - Pause mode state

  static var pauseModeActiveProfileId: String? {
    get {
      suite.string(forKey: Key.pauseModeActiveProfileId.rawValue)
    }
    set {
      if let newValue {
        suite.set(newValue, forKey: Key.pauseModeActiveProfileId.rawValue)
      } else {
        suite.removeObject(forKey: Key.pauseModeActiveProfileId.rawValue)
      }
    }
  }

  static var pauseUnlockedApplicationTokens: Set<ApplicationToken> {
    get {
      decodeApplicationTokens(forKey: Key.pauseUnlockedApplicationTokens.rawValue)
    }
    set {
      encodeApplicationTokens(newValue, forKey: Key.pauseUnlockedApplicationTokens.rawValue)
    }
  }

  static var pauseUnlockedCategoryTokens: Set<ActivityCategoryToken> {
    get {
      decodeCategoryTokens(forKey: Key.pauseUnlockedCategoryTokens.rawValue)
    }
    set {
      encodeCategoryTokens(newValue, forKey: Key.pauseUnlockedCategoryTokens.rawValue)
    }
  }

  static func startPauseMode(for profileId: String) {
    pauseModeActiveProfileId = profileId
    clearAllPauseTimers()
    pauseUnlockedApplicationTokens = []
    pauseUnlockedCategoryTokens = []
  }

  static func clearPauseModeState() {
    pauseModeActiveProfileId = nil
    pauseUnlockedApplicationTokens = []
    pauseUnlockedCategoryTokens = []
    clearAllPauseTimers()
  }

  static func addPauseUnlockedApplicationToken(_ token: ApplicationToken) {
    var tokens = pauseUnlockedApplicationTokens
    tokens.insert(token)
    pauseUnlockedApplicationTokens = tokens
  }

  static func addPauseUnlockedCategoryToken(_ token: ActivityCategoryToken) {
    var tokens = pauseUnlockedCategoryTokens
    tokens.insert(token)
    pauseUnlockedCategoryTokens = tokens
  }

  static var activePauseModeProfileId: String? {
    if let pauseModeActiveProfileId {
      return pauseModeActiveProfileId
    }

    guard
      let activeSharedSession,
      activeSharedSession.tag == "PauseBlockingStrategy",
      activeSharedSession.endTime == nil
    else {
      return nil
    }

    return activeSharedSession.blockedProfileId.uuidString
  }

  static func removePauseUnlockedApplicationToken(matching tokenKeyToRemove: String) {
    let tokens = pauseUnlockedApplicationTokens.filter { tokenKey($0) != tokenKeyToRemove }
    pauseUnlockedApplicationTokens = Set(tokens)
  }

  static func removePauseUnlockedCategoryToken(matching tokenKeyToRemove: String) {
    let tokens = pauseUnlockedCategoryTokens.filter { tokenKey($0) != tokenKeyToRemove }
    pauseUnlockedCategoryTokens = Set(tokens)
  }

  static func pauseTimer(for token: ApplicationToken) -> Date? {
    guard let value = suite.object(forKey: pauseTimerKey(for: token)) as? Double else {
      return nil
    }
    return Date(timeIntervalSince1970: value)
  }

  static func startPauseTimer(for token: ApplicationToken) {
    suite.set(Date().timeIntervalSince1970, forKey: pauseTimerKey(for: token))
  }

  static func clearPauseTimer(for token: ApplicationToken) {
    suite.removeObject(forKey: pauseTimerKey(for: token))
  }

  static func elapsedPauseTime(for token: ApplicationToken) -> TimeInterval {
    guard let startTime = suite.object(forKey: pauseTimerKey(for: token)) as? Double else {
      return 0
    }
    return Date().timeIntervalSince1970 - startTime
  }

  private static func clearAllPauseTimers() {
    for key in suite.dictionaryRepresentation().keys where key.hasPrefix("pauseTimer_") {
      suite.removeObject(forKey: key)
    }
  }

  private static func pauseTimerKey(for token: ApplicationToken) -> String {
    return "pauseTimer_\(tokenKey(token))"
  }

  static func tokenKey(_ token: ApplicationToken) -> String {
    guard let data = try? JSONEncoder().encode(token) else {
      return String(token.hashValue)
    }
    return data.base64EncodedString()
  }

  static func tokenKey(_ token: ActivityCategoryToken) -> String {
    guard let data = try? JSONEncoder().encode(token) else {
      return String(token.hashValue)
    }
    return data.base64EncodedString()
  }

  private static func decodeApplicationTokens(forKey key: String) -> Set<ApplicationToken> {
    guard let data = suite.data(forKey: key) else { return [] }
    return (try? JSONDecoder().decode(Set<ApplicationToken>.self, from: data)) ?? []
  }

  private static func decodeCategoryTokens(forKey key: String) -> Set<ActivityCategoryToken> {
    guard let data = suite.data(forKey: key) else { return [] }
    return (try? JSONDecoder().decode(Set<ActivityCategoryToken>.self, from: data)) ?? []
  }

  private static func encodeApplicationTokens(_ tokens: Set<ApplicationToken>, forKey key: String) {
    if let data = try? JSONEncoder().encode(tokens) {
      suite.set(data, forKey: key)
    } else {
      suite.removeObject(forKey: key)
    }
  }

  private static func encodeCategoryTokens(
    _ tokens: Set<ActivityCategoryToken>,
    forKey key: String
  ) {
    if let data = try? JSONEncoder().encode(tokens) {
      suite.set(data, forKey: key)
    } else {
      suite.removeObject(forKey: key)
    }
  }

  static func getCompletedSessionsForSchedular() -> [SessionSnapshot] {
    completedSessionsInSchedular
  }

  static func flushCompletedSessionsForSchedular() {
    completedSessionsInSchedular = []
  }

  static func setBreakStartTime(date: Date) {
    activeSharedSession?.breakStartTime = date
  }

  static func setBreakEndTime(date: Date) {
    activeSharedSession?.breakEndTime = date
  }

  static func setEndTime(date: Date) {
    activeSharedSession?.endTime = date
  }

  static func resetPause() {
    activeSharedSession?.pauseStartTime = nil
    activeSharedSession?.pauseEndTime = nil
  }

  static func setPauseStartTime(date: Date) {
    activeSharedSession?.pauseStartTime = date
  }

  static func setPauseEndTime(date: Date) {
    activeSharedSession?.pauseEndTime = date
  }
}
