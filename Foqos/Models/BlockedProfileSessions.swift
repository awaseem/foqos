import Foundation
import SwiftData

@Model
class BlockedProfileSession {
  @Attribute(.unique) var id: String
  var tag: String

  @Relationship var blockedProfile: BlockedProfiles

  var startTime: Date
  var endTime: Date?

  var breakStartTime: Date?
  var breakEndTime: Date?
  var usedBreakDurationInSeconds: TimeInterval = 0

  var pauseStartTime: Date?
  var pauseEndTime: Date?

  var forceStarted: Bool = false

  var isActive: Bool {
    return endTime == nil
  }

  var isBreakAvailable: Bool {
    isBreakAvailable(at: Date())
  }

  func isBreakAvailable(at date: Date) -> Bool {
    guard blockedProfile.enableBreaks == true,
      blockedProfile.allowsTimedBreaks
    else {
      return false
    }

    if isBreakActive {
      return true
    }

    let usage = breakAllowanceUsage(at: date)
    switch blockedProfile.breakAllowanceMode {
    case .perBreak:
      if blockedProfile.breakAllowanceModeRawValue == nil,
        !blockedProfile.allowMultipleBreaks,
        breakEndTime != nil
      {
        return false
      }
      return blockedProfile.resolvedBreakCountLimit.map {
        usage.breaksStarted < $0
      } ?? true
    case .cumulative:
      return remainingBreakAllowance(at: date) > 0
    }
  }

  var isBreakActive: Bool {
    return blockedProfile.enableBreaks == true
      && blockedProfile.allowsTimedBreaks
      && breakStartTime != nil
      && breakEndTime == nil
  }

  var isPauseActive: Bool {
    return pauseStartTime != nil && pauseEndTime == nil
  }

  var duration: TimeInterval {
    let end = endTime ?? Date()
    return end.timeIntervalSince(startTime)
  }

  var totalBreakAllowanceInSeconds: TimeInterval {
    TimeInterval(blockedProfile.breakTimeInMinutes * 60)
  }

  /// Break time this session consumed, across every break it contained.
  ///
  /// `breakStartTime` and `breakEndTime` only ever describe the most recent break when a
  /// profile permits repeated breaks, so reporting has to
  /// read the accumulator and fall back to the timestamps for single-break sessions where it
  /// stays zero. If a session ends during a break, its end time closes that final partial break
  /// because the accumulator is only updated by `endBreak(at:)`. Deliberately independent of
  /// the profile's current allowance configuration, so toggling settings cannot rewrite
  /// sessions that are already recorded.
  var totalBreakDuration: TimeInterval {
    let accumulatedDuration = max(0, usedBreakDurationInSeconds)
    guard let breakStartTime else {
      return accumulatedDuration
    }

    if let breakEndTime {
      let lastBreakDuration = max(0, breakEndTime.timeIntervalSince(breakStartTime))
      return max(accumulatedDuration, lastBreakDuration)
    }

    guard let endTime else {
      return accumulatedDuration
    }

    let finalPartialBreakDuration = max(0, endTime.timeIntervalSince(breakStartTime))
    return accumulatedDuration + finalPartialBreakDuration
  }

  init(
    tag: String,
    blockedProfile: BlockedProfiles,
    forceStarted: Bool = false
  ) {
    self.id = UUID().uuidString
    self.tag = tag
    self.blockedProfile = blockedProfile
    self.startTime = Date()
    self.forceStarted = forceStarted

    // Add this session to the profile's sessions array
    blockedProfile.sessions.append(self)
  }

  func activeBreakElapsedTime(at date: Date = Date()) -> TimeInterval {
    guard isBreakActive, let breakStartTime else {
      return 0
    }

    return max(0, date.timeIntervalSince(breakStartTime))
  }

  func usedBreakDurationIncludingActiveBreak(at date: Date = Date()) -> TimeInterval {
    if blockedProfile.permitsMultipleBreaksPerPeriod {
      return usedBreakDurationInSeconds + activeBreakElapsedTime(at: date)
    }

    return completedSingleBreakDuration(at: date)
  }

  func remainingBreakAllowance(at date: Date = Date()) -> TimeInterval {
    switch blockedProfile.breakAllowanceMode {
    case .perBreak:
      return max(0, totalBreakAllowanceInSeconds - activeBreakElapsedTime(at: date))
    case .cumulative:
      let usageDate = isBreakActive ? breakStartTime ?? date : date
      let persistedUsage = breakAllowanceUsage(at: usageDate).usedDurationInSeconds
      let completedUsage =
        blockedProfile.breakAllowanceModeRawValue == nil
        ? max(persistedUsage, usedBreakDurationInSeconds) : persistedUsage
      return max(
        0,
        totalBreakAllowanceInSeconds - completedUsage - activeBreakElapsedTime(at: date)
      )
    }
  }

  func remainingBreakCount(at date: Date = Date()) -> Int? {
    guard blockedProfile.breakAllowanceMode == .perBreak,
      let breakCountLimit = blockedProfile.resolvedBreakCountLimit
    else {
      return nil
    }

    return max(0, breakCountLimit - breakAllowanceUsage(at: date).breaksStarted)
  }

  @discardableResult
  func startBreak(at date: Date = Date()) -> Bool {
    guard !isBreakActive else {
      return false
    }

    guard
      SharedData.beginBreak(
        for: blockedProfile.id,
        mode: blockedProfile.breakAllowanceMode,
        breakCountLimit: blockedProfile.resolvedBreakCountLimit,
        totalAllowanceInSeconds: totalBreakAllowanceInSeconds,
        at: date,
        resetHour: blockedProfile.breakResetHour,
        resetMinute: blockedProfile.breakResetMinute,
        resetPolicy: blockedProfile.breakResetPolicy
      )
    else {
      return false
    }

    let breakStartTime = date

    if blockedProfile.permitsMultipleBreaksPerPeriod {
      SharedData.resetBreak()
      self.breakStartTime = nil
      self.breakEndTime = nil
    }

    SharedData.setBreakStartTime(date: breakStartTime)
    self.breakStartTime = breakStartTime
    return true
  }

  func endBreak(at date: Date = Date()) {
    let breakEndTime = date

    if blockedProfile.permitsMultipleBreaksPerPeriod {
      let availableDuration = remainingBreakAllowance(at: breakStartTime ?? breakEndTime)
      let completedDuration = min(
        availableDuration,
        activeBreakElapsedTime(at: breakEndTime)
      )
      let updatedUsedDuration = usedBreakDurationInSeconds + completedDuration
      usedBreakDurationInSeconds = updatedUsedDuration
      SharedData.setUsedBreakDurationInSeconds(updatedUsedDuration)
    }

    if blockedProfile.breakAllowanceMode == .cumulative, let breakStartTime {
      SharedData.recordCumulativeBreakDuration(
        for: blockedProfile.id,
        breakStart: breakStartTime,
        breakEnd: breakEndTime,
        totalAllowanceInSeconds: totalBreakAllowanceInSeconds,
        resetHour: blockedProfile.breakResetHour,
        resetMinute: blockedProfile.breakResetMinute,
        resetPolicy: blockedProfile.breakResetPolicy
      )
    }

    SharedData.setBreakEndTime(date: breakEndTime)
    self.breakEndTime = breakEndTime
  }

  private func breakAllowanceUsage(at date: Date) -> BreakAllowanceUsage {
    SharedData.breakAllowanceUsage(
      for: blockedProfile.id,
      at: date,
      resetHour: blockedProfile.breakResetHour,
      resetMinute: blockedProfile.breakResetMinute,
      resetPolicy: blockedProfile.breakResetPolicy
    )
  }

  private func completedSingleBreakDuration(at date: Date) -> TimeInterval {
    guard let breakStartTime else {
      return 0
    }

    if let breakEndTime {
      return max(0, breakEndTime.timeIntervalSince(breakStartTime))
    }

    if isBreakActive {
      return max(0, date.timeIntervalSince(breakStartTime))
    }

    return 0
  }

  func startPause() {
    let pauseStartTime = Date()

    SharedData.setPauseStartTime(date: pauseStartTime)
    self.pauseStartTime = pauseStartTime
  }

  func endPause() {
    let pauseEndTime = Date()

    SharedData.setPauseEndTime(date: pauseEndTime)
    self.pauseEndTime = pauseEndTime
  }

  func endSession() {
    let endTime = Date()

    if isBreakActive {
      endBreak(at: endTime)
    }

    BlockingSessionLifecycleRegistry.sessionDidEnd(
      BlockingSessionLifecycleContext(
        profile: BlockedProfiles.getSnapshot(for: blockedProfile),
        session: toSnapshot()
      )
    )

    // Set the end time in shared data in case its being saved
    SharedData.setEndTime(date: endTime)
    self.endTime = endTime

    SharedData.flushActiveSession()
  }

  func toSnapshot() -> SharedData.SessionSnapshot {
    return SharedData.SessionSnapshot(
      id: id,
      tag: tag,
      blockedProfileId: blockedProfile.id,
      startTime: startTime,
      endTime: endTime,
      breakStartTime: breakStartTime,
      breakEndTime: breakEndTime,
      usedBreakDurationInSeconds: usedBreakDurationInSeconds,
      pauseStartTime: pauseStartTime,
      pauseEndTime: pauseEndTime,
      forceStarted: forceStarted
    )
  }

  static func mostRecentActiveSession(in context: ModelContext)
    -> BlockedProfileSession?
  {
    var descriptor = FetchDescriptor<BlockedProfileSession>(
      predicate: #Predicate { $0.endTime == nil },
      sortBy: [SortDescriptor(\.startTime, order: .reverse)]
    )
    descriptor.fetchLimit = 1

    return try? context.fetch(descriptor).first
  }

  static func createSession(
    in context: ModelContext,
    withTag tag: String,
    withProfile profile: BlockedProfiles,
    forceStart: Bool = false
  ) -> BlockedProfileSession {
    let newSession = BlockedProfileSession(
      tag: tag,
      blockedProfile: profile,
      forceStarted: forceStart
    )

    let sessionSnapshot = newSession.toSnapshot()
    let profileSnapshot = BlockedProfiles.getSnapshot(for: profile)

    SharedData.createActiveSharedSession(for: sessionSnapshot)
    BlockingSessionLifecycleRegistry.sessionDidStart(
      BlockingSessionLifecycleContext(
        profile: profileSnapshot,
        session: sessionSnapshot
      )
    )

    context.insert(newSession)
    return newSession
  }

  static func upsertSessionFromSnapshot(
    in context: ModelContext,
    withSnapshot snapshot: SharedData.SessionSnapshot
  ) {
    let profileID = snapshot.blockedProfileId

    guard let existingProfile = try? BlockedProfiles.findProfile(byID: profileID, in: context)
    else {
      print("Profile not found when creating session from snapshot")
      return
    }

    // Try to find an existing session by id
    if let existingSession = try? findSession(byID: snapshot.id, in: context) {
      existingSession.tag = snapshot.tag
      existingSession.startTime = snapshot.startTime
      existingSession.endTime = snapshot.endTime
      existingSession.breakStartTime = snapshot.breakStartTime
      existingSession.breakEndTime = snapshot.breakEndTime
      existingSession.usedBreakDurationInSeconds = snapshot.usedBreakDurationInSeconds ?? 0
      existingSession.pauseStartTime = snapshot.pauseStartTime
      existingSession.pauseEndTime = snapshot.pauseEndTime
      existingSession.forceStarted = snapshot.forceStarted

      // manually save to ensure changes are persisted
      try? context.save()
      return
    }

    // Create new session from snapshot
    let newSession = BlockedProfileSession(
      tag: snapshot.tag,
      blockedProfile: existingProfile,
      forceStarted: snapshot.forceStarted
    )
    // Override auto-generated values with snapshot-provided ones
    newSession.id = snapshot.id
    newSession.startTime = snapshot.startTime
    newSession.endTime = snapshot.endTime
    newSession.breakStartTime = snapshot.breakStartTime
    newSession.breakEndTime = snapshot.breakEndTime
    newSession.usedBreakDurationInSeconds = snapshot.usedBreakDurationInSeconds ?? 0
    newSession.pauseStartTime = snapshot.pauseStartTime
    newSession.pauseEndTime = snapshot.pauseEndTime

    // Let auto-save handle inserts
    context.insert(newSession)
  }

  static func findSession(
    byID id: String,
    in context: ModelContext
  ) throws -> BlockedProfileSession? {
    let descriptor = FetchDescriptor<BlockedProfileSession>(
      predicate: #Predicate { $0.id == id }
    )
    return try context.fetch(descriptor).first
  }

  static func recentInactiveSessions(
    in context: ModelContext,
    limit: Int = 50
  ) -> [BlockedProfileSession] {
    var descriptor = FetchDescriptor<BlockedProfileSession>(
      predicate: #Predicate { $0.endTime != nil },
      sortBy: [SortDescriptor(\.endTime, order: .reverse)]
    )
    descriptor.fetchLimit = limit

    return (try? context.fetch(descriptor)) ?? []
  }
}
