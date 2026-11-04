import Foundation

// App behavior stays separate so widgets can use the same countdown calculations.
extension SessionTimeCalculator {
  static let countdownReloadDelay: TimeInterval = 30
  static let countdownResetGracePeriod: TimeInterval = 90

  static func hardModeUnlockTime(for session: BlockedProfileSession) -> Date? {
    let profile = session.blockedProfile
    guard profile.enableHardMode, profile.allowsHardMode else { return nil }
    let minutes = min(720, max(30, profile.hardModeDurationInMinutes))
    return session.startTime.addingTimeInterval(TimeInterval(minutes * 60))
  }

  static func elapsedFocusTime(
    for session: BlockedProfileSession,
    at date: Date = Date()
  ) -> TimeInterval {
    let rawElapsedTime = date.timeIntervalSince(session.startTime)
    let breakDuration = calculateBreakDuration(for: session, at: date)
    return max(0, rawElapsedTime - breakDuration)
  }

  static func displayedTime(
    for session: BlockedProfileSession,
    elapsedFocusTime: TimeInterval? = nil,
    at date: Date = Date()
  ) -> TimeInterval {
    if let expectedEndTime = expectedEndTime(for: session) {
      return max(0, expectedEndTime.timeIntervalSince(date))
    }

    return elapsedFocusTime ?? self.elapsedFocusTime(for: session, at: date)
  }

  static func isCountdownExpired(
    for session: BlockedProfileSession,
    at date: Date = Date()
  ) -> Bool {
    guard let expectedEndTime = expectedEndTime(for: session) else {
      return false
    }

    return expectedEndTime.addingTimeInterval(countdownResetGracePeriod) <= date
  }

  static func isCountdownReloadDue(
    for session: BlockedProfileSession,
    at date: Date = Date()
  ) -> Bool {
    guard let expectedEndTime = expectedEndTime(for: session) else {
      return false
    }

    return expectedEndTime.addingTimeInterval(countdownReloadDelay) <= date
  }

  static func expectedEndTime(for session: BlockedProfileSession) -> Date? {
    if session.isPauseActive || session.isBreakActive {
      return breakOrPauseEndTime(for: session)
    }
    return expectedSessionEndTime(for: session)
  }

  private static func calculateBreakDuration(
    for session: BlockedProfileSession,
    at date: Date
  ) -> TimeInterval {
    if session.blockedProfile.allowMultipleBreaks {
      return session.usedBreakDurationIncludingActiveBreak(at: date)
    }

    guard let breakStartTime = session.breakStartTime else {
      return 0
    }

    if let breakEndTime = session.breakEndTime {
      return max(0, breakEndTime.timeIntervalSince(breakStartTime))
    }

    if session.isBreakActive {
      return max(0, date.timeIntervalSince(breakStartTime))
    }

    return 0
  }
}
