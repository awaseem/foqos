import FamilyControls
import Foundation

enum SharedData {
  private static let suite = UserDefaults(
    suiteName: "group.dev.ambitionsoftware.foqos"
  )!

  // MARK: – Keys
  private enum Key: String {
    case profileSnapshots
    case activeScheduleSession
    case completedScheduleSessions
  }

  // MARK: – Serializable snapshot of a profile (no sessions)
  struct ProfileSnapshot: Codable, Equatable {
    var id: UUID
    var name: String
    var selectedActivity: FamilyActivitySelection
    var createdAt: Date
    var updatedAt: Date
    var blockingStrategyId: String?
    var order: Int

    var enableLiveActivity: Bool
    var reminderTimeInSeconds: UInt32?
    var enableBreaks: Bool
    var enableStrictMode: Bool
    var enableAllowMode: Bool
    var enableAllowModeDomains: Bool

    var domains: [String]?
    var physicalUnblockNFCTagId: String?
    var physicalUnblockQRCodeId: String?

    var schedule: BlockedProfileSchedule?
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
  static var completedScheduleSessions: [SessionSnapshot] {
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
  static var activeScheduleSession: SessionSnapshot? {
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

  static func createActiveScheduledSession(for profileID: UUID) {
    activeScheduleSession = SessionSnapshot(
      id: UUID().uuidString,
      tag: profileID.uuidString,
      blockedProfileId: profileID,
      startTime: Date(),
      forceStarted: true)
  }

  static func getActiveScheduledSession() -> SessionSnapshot? {
    activeScheduleSession
  }

  static func endActiveScheduledSession() {
    guard var existingScheduledSession = activeScheduleSession else { return }

    existingScheduledSession.endTime = Date()
    completedScheduleSessions.append(existingScheduledSession)

    activeScheduleSession = nil
  }

  static func getCompletedScheduleSessions() -> [SessionSnapshot] {
    completedScheduleSessions
  }

  static func flushCompletedScheduleSessions() {
    completedScheduleSessions = []
  }
}
