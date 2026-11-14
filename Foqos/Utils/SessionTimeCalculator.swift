import Foundation

// Shared by the app and widget extension without loading blocking strategies.
enum SessionTimeCalculator {
  private static let timerStrategyIDs: Set<String> = [
    "NFCTimerBlockingStrategy", "QRTimerBlockingStrategy", "ShortcutTimerBlockingStrategy",
  ]

  static func breakOrPauseEndTime(for session: BlockedProfileSession) -> Date? {
    let profile = session.blockedProfile
    if let pauseStart = session.pauseStartTime, session.pauseEndTime == nil {
      let pauseData = StrategyPauseTimerData.toStrategyPauseTimerData(from: profile.strategyData)
      return pauseStart.addingTimeInterval(TimeInterval(pauseData.pauseDurationInMinutes * 60))
    }

    guard let breakStart = session.breakStartTime, session.breakEndTime == nil else { return nil }
    let allowance = TimeInterval(profile.breakTimeInMinutes * 60)
    // Later breaks use only the allowance left by completed breaks.
    let remaining =
      profile.allowMultipleBreaks
      ? max(0, allowance - session.usedBreakDurationInSeconds) : allowance
    return breakStart.addingTimeInterval(remaining)
  }

  static func expectedSessionEndTime(for session: BlockedProfileSession) -> Date? {
    if isScheduledSession(session) {
      return scheduledEndTime(for: session)
    }

    if isTimerSession(session), let timerDuration = timerDurationInSeconds(for: session) {
      return session.startTime.addingTimeInterval(timerDuration)
    }

    return nil
  }

  static func scheduledEndTime(for session: BlockedProfileSession) -> Date? {
    guard isScheduledSession(session), let schedule = session.blockedProfile.schedule
    else { return nil }

    return schedule.endDate(forSessionStartingAt: session.startTime)
  }

  static func completedBreakDuration(
    breakStartTime: Date?, breakEndTime: Date?, usedBreakDurationInSeconds: TimeInterval
  ) -> TimeInterval {
    let lastBreakDuration =
      breakStartTime.flatMap { start in
        breakEndTime.map { $0.timeIntervalSince(start) }
      } ?? 0
    // Reusable breaks already include the latest completed break in the accumulator.
    // Single-break sessions only have the timestamps.
    return max(0, usedBreakDurationInSeconds, lastBreakDuration)
  }

  static func focusStartTime(
    startTime: Date, breakStartTime: Date?, breakEndTime: Date?,
    usedBreakDurationInSeconds: TimeInterval
  ) -> Date {
    startTime.addingTimeInterval(
      completedBreakDuration(
        breakStartTime: breakStartTime, breakEndTime: breakEndTime,
        usedBreakDurationInSeconds: usedBreakDurationInSeconds)
    )
  }

  static func isTimerSession(_ session: BlockedProfileSession) -> Bool {
    Self.timerStrategyIDs.contains(session.tag)
      || Self.timerStrategyIDs.contains(session.blockedProfile.blockingStrategyId ?? "")
  }

  static func timerDurationInSeconds(for session: BlockedProfileSession) -> TimeInterval? {
    guard let strategyData = session.blockedProfile.strategyData else {
      return nil
    }

    let timerData = StrategyTimerData.toStrategyTimerData(from: strategyData)
    return TimeInterval(timerData.durationInMinutes * 60)
  }

  private static func isScheduledSession(_ session: BlockedProfileSession) -> Bool {
    session.blockedProfile.schedule?.isActive == true
      && UUID(uuidString: session.tag) == session.blockedProfile.id
  }
}
