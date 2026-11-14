import Foundation

struct WidgetProfileInfo {
  let enableStrictMode: Bool
  let enableAllowMode: Bool
  let selectedItemCount: Int
  var strategyID: String? = nil
}

struct WidgetSessionInfo {
  let blockedProfileId: UUID
  let startTime: Date
  let endTime: Date?
  let breakStartTime: Date?
  let breakEndTime: Date?
  let pauseStartTime: Date?
  let pauseEndTime: Date?
  var expectedEndTime: Date? = nil
  var breakOrPauseEndTime: Date? = nil
  var usedBreakDurationInSeconds: TimeInterval = 0

  var focusTimer: SessionTimer {
    SessionTimer(
      startTime: SessionTimeCalculator.focusStartTime(
        startTime: startTime, breakStartTime: breakStartTime, breakEndTime: breakEndTime,
        usedBreakDurationInSeconds: usedBreakDurationInSeconds),
      endTime: expectedEndTime)
  }
}

extension WidgetSessionInfo {
  init(session: BlockedProfileSession) {
    self.init(
      blockedProfileId: session.blockedProfile.id, startTime: session.startTime,
      endTime: session.endTime, breakStartTime: session.breakStartTime,
      breakEndTime: session.breakEndTime, pauseStartTime: session.pauseStartTime,
      pauseEndTime: session.pauseEndTime,
      expectedEndTime: SessionTimeCalculator.expectedSessionEndTime(for: session),
      breakOrPauseEndTime: SessionTimeCalculator.breakOrPauseEndTime(for: session),
      usedBreakDurationInSeconds: session.usedBreakDurationInSeconds)
  }
}
