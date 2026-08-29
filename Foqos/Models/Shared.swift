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
    var strategyData: Data?
    var order: Int

    var enableLiveActivity: Bool
    var reminderTimeInSeconds: UInt32?
    var customReminderMessage: String?
    var enableBreaks: Bool
    var breakTimeInMinutes: Int = 15
    var allowMultipleBreaks: Bool? = nil
    var enableStrictMode: Bool
    var enableBlockAppInstallation: Bool = false
    var enableAllowMode: Bool
    var enableAllowModeDomains: Bool
    var enableSafariBlocking: Bool
    var enableAdultContentBlocking: Bool? = nil
    var enableMacSync: Bool? = nil

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

  private struct FailableDecodable<Value: Decodable>: Decodable {
    let value: Value?

    init(from decoder: Decoder) throws {
      value = try? Value(from: decoder)
    }
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
    var usedBreakDurationInSeconds: TimeInterval? = nil

    var pauseStartTime: Date?
    var pauseEndTime: Date?

    var forceStarted: Bool
  }

  // MARK: – Persisted snapshots keyed by profile ID (UUID string)
  static var profileSnapshots: [String: ProfileSnapshot] {
    get {
      guard let data = suite.data(forKey: Key.profileSnapshots.rawValue) else { return [:] }
      return decodeProfileSnapshots(from: data)
    }
    set {
      if let data = try? JSONEncoder().encode(newValue) {
        suite.set(data, forKey: Key.profileSnapshots.rawValue)
      } else {
        suite.removeObject(forKey: Key.profileSnapshots.rawValue)
      }
    }
  }

  static func decodeProfileSnapshots(from data: Data) -> [String: ProfileSnapshot] {
    let decoded = try? JSONDecoder().decode(
      [String: FailableDecodable<ProfileSnapshot>].self,
      from: data
    )
    return decoded?.compactMapValues(\.value) ?? [:]
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

  @discardableResult
  static func createSessionForSchedular(for profileID: UUID) -> SessionSnapshot {
    let session = SessionSnapshot(
      id: UUID().uuidString,
      tag: profileID.uuidString,
      blockedProfileId: profileID,
      startTime: Date(),
      forceStarted: true)
    activeSharedSession = session
    return session
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

  static func resetBreak() {
    activeSharedSession?.breakStartTime = nil
    activeSharedSession?.breakEndTime = nil
  }

  static func setUsedBreakDurationInSeconds(_ duration: TimeInterval) {
    activeSharedSession?.usedBreakDurationInSeconds = duration
  }

  static func endBreak(date: Date, allowMultipleBreaks: Bool, totalAllowanceInSeconds: TimeInterval)
  {
    guard var session = activeSharedSession else { return }

    if allowMultipleBreaks, let breakStartTime = session.breakStartTime {
      let activeBreakDuration = max(0, date.timeIntervalSince(breakStartTime))
      let existingUsedDuration = session.usedBreakDurationInSeconds ?? 0
      session.usedBreakDurationInSeconds = min(
        totalAllowanceInSeconds,
        existingUsedDuration + activeBreakDuration
      )
    }

    session.breakEndTime = date
    activeSharedSession = session
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

extension SharedData.ProfileSnapshot {
  private enum CodingKeys: String, CodingKey {
    case id
    case name
    case selectedActivity
    case createdAt
    case updatedAt
    case blockingStrategyId
    case strategyData
    case order
    case enableLiveActivity
    case reminderTimeInSeconds
    case customReminderMessage
    case enableBreaks
    case breakTimeInMinutes
    case allowMultipleBreaks
    case enableStrictMode
    case enableBlockAppInstallation
    case enableAllowMode
    case enableAllowModeDomains
    case enableSafariBlocking
    case enableAdultContentBlocking
    case enableMacSync
    case domains
    case physicalUnblockNFCTagId
    case physicalUnblockQRCodeId
    case physicalUnblockItems
    case schedule
    case disableBackgroundStops
    case enableEmergencyUnblock
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    // Later profile settings use their model defaults when decoding snapshots from older releases.
    self.init(
      id: try container.decode(UUID.self, forKey: .id),
      name: try container.decode(String.self, forKey: .name),
      selectedActivity: try container.decode(
        FamilyActivitySelection.self,
        forKey: .selectedActivity
      ),
      createdAt: try container.decode(Date.self, forKey: .createdAt),
      updatedAt: try container.decode(Date.self, forKey: .updatedAt),
      blockingStrategyId: try container.decodeIfPresent(
        String.self,
        forKey: .blockingStrategyId
      ),
      strategyData: try container.decodeIfPresent(Data.self, forKey: .strategyData),
      order: try container.decode(Int.self, forKey: .order),
      enableLiveActivity: try container.decode(Bool.self, forKey: .enableLiveActivity),
      reminderTimeInSeconds: try container.decodeIfPresent(
        UInt32.self,
        forKey: .reminderTimeInSeconds
      ),
      customReminderMessage: try container.decodeIfPresent(
        String.self,
        forKey: .customReminderMessage
      ),
      enableBreaks: try container.decode(Bool.self, forKey: .enableBreaks),
      breakTimeInMinutes: try container.decodeIfPresent(
        Int.self,
        forKey: .breakTimeInMinutes
      ) ?? 15,
      allowMultipleBreaks: try container.decodeIfPresent(
        Bool.self,
        forKey: .allowMultipleBreaks
      ),
      enableStrictMode: try container.decode(Bool.self, forKey: .enableStrictMode),
      enableBlockAppInstallation: try container.decodeIfPresent(
        Bool.self,
        forKey: .enableBlockAppInstallation
      ) ?? false,
      enableAllowMode: try container.decode(Bool.self, forKey: .enableAllowMode),
      enableAllowModeDomains: try container.decode(
        Bool.self,
        forKey: .enableAllowModeDomains
      ),
      enableSafariBlocking: try container.decodeIfPresent(
        Bool.self,
        forKey: .enableSafariBlocking
      ) ?? true,
      enableAdultContentBlocking: try container.decodeIfPresent(
        Bool.self,
        forKey: .enableAdultContentBlocking
      ),
      enableMacSync: try container.decodeIfPresent(Bool.self, forKey: .enableMacSync),
      domains: try container.decodeIfPresent([String].self, forKey: .domains),
      physicalUnblockNFCTagId: try container.decodeIfPresent(
        String.self,
        forKey: .physicalUnblockNFCTagId
      ),
      physicalUnblockQRCodeId: try container.decodeIfPresent(
        String.self,
        forKey: .physicalUnblockQRCodeId
      ),
      physicalUnblockItems: try container.decodeIfPresent(
        [PhysicalUnblockItem].self,
        forKey: .physicalUnblockItems
      ),
      schedule: try container.decodeIfPresent(
        BlockedProfileSchedule.self,
        forKey: .schedule
      ),
      disableBackgroundStops: try container.decodeIfPresent(
        Bool.self,
        forKey: .disableBackgroundStops
      ),
      enableEmergencyUnblock: try container.decodeIfPresent(
        Bool.self,
        forKey: .enableEmergencyUnblock
      )
    )
  }
}
