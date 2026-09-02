import FamilyControls
import Foundation

enum BreakAllowanceMode: String, CaseIterable, Codable {
  case perBreak
  case cumulative

  var title: String {
    switch self {
    case .perBreak:
      return "Per Break"
    case .cumulative:
      return "Shared Daily Budget"
    }
  }
}

enum BreakResetPolicy: String, CaseIterable, Codable {
  case daily
  case never

  var title: String {
    switch self {
    case .daily:
      return "Daily"
    case .never:
      return "Never"
    }
  }
}

struct BreakAllowanceUsage: Codable, Equatable {
  var periodStart: Date
  var breaksStarted: Int
  var usedDurationInSeconds: TimeInterval
  var lastRecordedBreakStart: Date? = nil
  var resetPolicyRawValue: String? = nil
}

enum SharedData {
  private static let suite = UserDefaults(
    suiteName: "group.dev.ambitionsoftware.foqos"
  )!

  // MARK: – Keys
  private enum Key: String {
    case profileSnapshots
    case activeScheduleSession
    case completedScheduleSessions
    case breakAllowanceUsage
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
    var breakAllowanceModeRawValue: String? = nil
    var breakCountLimit: Int? = nil
    var isBreakCountUnlimited: Bool? = nil
    var breakResetHour: Int? = nil
    var breakResetMinute: Int? = nil
    var breakResetPolicyRawValue: String? = nil
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

    var breakAllowanceMode: BreakAllowanceMode {
      if let breakAllowanceModeRawValue,
        let mode = BreakAllowanceMode(rawValue: breakAllowanceModeRawValue)
      {
        return mode
      }
      return allowMultipleBreaks == true ? .cumulative : .perBreak
    }

    var resolvedBreakCountLimit: Int? {
      isBreakCountUnlimited == true ? nil : max(1, breakCountLimit ?? 1)
    }

    var resolvedBreakResetHour: Int {
      min(max(breakResetHour ?? 0, 0), 23)
    }

    var resolvedBreakResetMinute: Int {
      min(max(breakResetMinute ?? 0, 0), 59)
    }

    var breakResetPolicy: BreakResetPolicy {
      guard let breakResetPolicyRawValue,
        let policy = BreakResetPolicy(rawValue: breakResetPolicyRawValue)
      else {
        return .daily
      }
      return policy
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

  private static var breakAllowanceUsageByProfile: [String: BreakAllowanceUsage] {
    get {
      guard let data = suite.data(forKey: Key.breakAllowanceUsage.rawValue) else { return [:] }
      return (try? JSONDecoder().decode([String: BreakAllowanceUsage].self, from: data)) ?? [:]
    }
    set {
      guard let data = try? JSONEncoder().encode(newValue) else { return }
      suite.set(data, forKey: Key.breakAllowanceUsage.rawValue)
    }
  }

  static func breakAllowanceUsage(
    for profileID: UUID,
    at date: Date = Date(),
    resetHour: Int,
    resetMinute: Int,
    resetPolicy: BreakResetPolicy = .daily,
    calendar: Calendar = .current
  ) -> BreakAllowanceUsage {
    let periodStart =
      resetPolicy == .daily
      ? breakAllowancePeriodStart(
        containing: date,
        resetHour: resetHour,
        resetMinute: resetMinute,
        calendar: calendar
      ) : Date(timeIntervalSinceReferenceDate: 0)
    let key = profileID.uuidString
    var allUsage = breakAllowanceUsageByProfile

    if var usage = allUsage[key] {
      let storedPolicy =
        usage.resetPolicyRawValue.flatMap(BreakResetPolicy.init(rawValue:)) ?? .daily

      if storedPolicy != resetPolicy {
        usage.periodStart = periodStart
        usage.resetPolicyRawValue = resetPolicy.rawValue
        allUsage[key] = usage
        breakAllowanceUsageByProfile = allUsage
        return usage
      }

      if resetPolicy == .never || usage.periodStart == periodStart {
        return usage
      }

      if usage.periodStart > periodStart {
        return BreakAllowanceUsage(
          periodStart: periodStart,
          breaksStarted: 0,
          usedDurationInSeconds: 0,
          resetPolicyRawValue: resetPolicy.rawValue
        )
      }
    }

    let usage = BreakAllowanceUsage(
      periodStart: periodStart,
      breaksStarted: 0,
      usedDurationInSeconds: 0,
      resetPolicyRawValue: resetPolicy.rawValue
    )
    allUsage[key] = usage
    breakAllowanceUsageByProfile = allUsage
    return usage
  }

  static func beginBreak(
    for profileID: UUID,
    mode: BreakAllowanceMode,
    breakCountLimit: Int?,
    totalAllowanceInSeconds: TimeInterval,
    at date: Date = Date(),
    resetHour: Int,
    resetMinute: Int,
    resetPolicy: BreakResetPolicy = .daily,
    calendar: Calendar = .current
  ) -> Bool {
    var usage = breakAllowanceUsage(
      for: profileID,
      at: date,
      resetHour: resetHour,
      resetMinute: resetMinute,
      resetPolicy: resetPolicy,
      calendar: calendar
    )

    switch mode {
    case .perBreak:
      guard breakCountLimit.map({ usage.breaksStarted < $0 }) ?? true else {
        return false
      }
      if breakCountLimit != nil {
        usage.breaksStarted += 1
      }
    case .cumulative:
      guard usage.usedDurationInSeconds < totalAllowanceInSeconds else {
        return false
      }
    }

    var allUsage = breakAllowanceUsageByProfile
    allUsage[profileID.uuidString] = usage
    breakAllowanceUsageByProfile = allUsage
    return true
  }

  static func recordCumulativeBreakDuration(
    for profileID: UUID,
    breakStart: Date,
    breakEnd: Date,
    totalAllowanceInSeconds: TimeInterval,
    resetHour: Int,
    resetMinute: Int,
    resetPolicy: BreakResetPolicy = .daily,
    calendar: Calendar = .current
  ) {
    guard breakEnd > breakStart else {
      return
    }

    let breakPeriodStart =
      resetPolicy == .daily
      ? breakAllowancePeriodStart(
        containing: breakEnd,
        resetHour: resetHour,
        resetMinute: resetMinute,
        calendar: calendar
      ) : Date(timeIntervalSinceReferenceDate: 0)
    let key = profileID.uuidString
    var allUsage = breakAllowanceUsageByProfile
    let storedUsage = allUsage[key]

    guard storedUsage?.periodStart ?? breakPeriodStart <= breakPeriodStart else {
      return
    }

    var usage: BreakAllowanceUsage
    if let storedUsage,
      storedUsage.periodStart == breakPeriodStart,
      (storedUsage.resetPolicyRawValue.flatMap(BreakResetPolicy.init(rawValue:)) ?? .daily)
        == resetPolicy
    {
      usage = storedUsage
    } else {
      usage = BreakAllowanceUsage(
        periodStart: breakPeriodStart,
        breaksStarted: 0,
        usedDurationInSeconds: 0,
        resetPolicyRawValue: resetPolicy.rawValue
      )
    }

    guard usage.lastRecordedBreakStart != breakStart else {
      return
    }

    let durationStart = max(breakStart, breakPeriodStart)
    usage.usedDurationInSeconds = min(
      totalAllowanceInSeconds,
      usage.usedDurationInSeconds + breakEnd.timeIntervalSince(durationStart)
    )
    usage.lastRecordedBreakStart = breakStart
    allUsage[key] = usage
    breakAllowanceUsageByProfile = allUsage
  }

  static func resetBreakAllowanceUsage(for profileID: UUID) {
    var allUsage = breakAllowanceUsageByProfile
    allUsage.removeValue(forKey: profileID.uuidString)
    breakAllowanceUsageByProfile = allUsage
  }

  static func breakAllowancePeriodStart(
    containing date: Date,
    resetHour: Int,
    resetMinute: Int,
    calendar: Calendar = .current
  ) -> Date {
    let startOfDay = calendar.startOfDay(for: date)
    let resetComponents = DateComponents(
      hour: min(max(resetHour, 0), 23),
      minute: min(max(resetMinute, 0), 59)
    )
    let resetToday =
      calendar.nextDate(
        after: startOfDay.addingTimeInterval(-1),
        matching: resetComponents,
        matchingPolicy: .nextTime,
        repeatedTimePolicy: .first,
        direction: .forward
      ) ?? startOfDay

    if date >= resetToday {
      return resetToday
    }

    let previousDay = calendar.date(byAdding: .day, value: -1, to: startOfDay) ?? startOfDay
    return calendar.nextDate(
      after: previousDay.addingTimeInterval(-1),
      matching: resetComponents,
      matchingPolicy: .nextTime,
      repeatedTimePolicy: .first,
      direction: .forward
    ) ?? previousDay
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

  static func endBreak(
    date: Date,
    allowsMultipleBreaks: Bool
  ) {
    guard var session = activeSharedSession else { return }

    if allowsMultipleBreaks, let breakStartTime = session.breakStartTime {
      let activeBreakDuration = max(0, date.timeIntervalSince(breakStartTime))
      let existingUsedDuration = session.usedBreakDurationInSeconds ?? 0
      session.usedBreakDurationInSeconds = existingUsedDuration + activeBreakDuration
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
