import XCTest

@testable import foqos

final class ScheduledSessionDeadlineTests: XCTestCase {
  func testGivenLateScheduleStart_WhenCalculatingDeadline_ThenUseConfiguredEnd() {
    let session = makeSession(startHour: 9, endHour: 10, actualStartHour: 9, minute: 7)
    let expected = date(hour: 10)
    XCTAssertEqual(SessionTimeCalculator.expectedSessionEndTime(for: session), expected)
    XCTAssertEqual(SessionTimeCalculator.scheduledEndTime(for: session), expected)
    XCTAssertEqual(LiveActivityManager.makeContentState(for: session).timer.endTime, expected)
    XCTAssertEqual(WidgetSessionInfo(session: session).focusTimer.endTime, expected)
  }

  func testGivenOvernightSchedule_WhenStartedBeforeOrAfterMidnight_ThenUseSameEnd() {
    for (hour, day) in [(22, 14), (23, 14), (0, 15), (2, 15)] {
      let session = makeSession(startHour: 22, endHour: 6, actualStartHour: hour, day: day)
      XCTAssertEqual(
        SessionTimeCalculator.expectedSessionEndTime(for: session), date(hour: 6, day: 15))
      XCTAssertEqual(session.blockedProfile.schedule?.totalDurationInSeconds, 8 * 60 * 60)
    }
  }

  func testGivenFullDaySchedule_WhenCalculatingDeadline_ThenEndIsNextDay() {
    let session = makeSession(startHour: 9, endHour: 9, actualStartHour: 9)
    XCTAssertEqual(
      SessionTimeCalculator.expectedSessionEndTime(for: session), date(hour: 9, day: 15))
    XCTAssertEqual(session.blockedProfile.schedule?.totalDurationInSeconds, 24 * 60 * 60)
  }

  func testGivenManualStartOnScheduledProfile_WhenCalculatingDeadline_ThenKeepStrategyBehavior() {
    let session = makeSession(startHour: 9, endHour: 10, actualStartHour: 9)
    session.tag = ManualBlockingStrategy.id
    XCTAssertNil(SessionTimeCalculator.expectedSessionEndTime(for: session))
    session.tag = UUID().uuidString
    XCTAssertNil(SessionTimeCalculator.expectedSessionEndTime(for: session))
    session.blockedProfile.blockingStrategyId = QRTimerBlockingStrategy.id
    session.blockedProfile.strategyData = StrategyTimerData.toData(
      from: StrategyTimerData(durationInMinutes: 30, hideStopButton: false))
    XCTAssertEqual(
      SessionTimeCalculator.expectedSessionEndTime(for: session),
      session.startTime.addingTimeInterval(30 * 60))
  }

  func testGivenOvernightScheduleAcrossDaylightSaving_WhenCalculatingDeadline_ThenUseLocalClock() {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "America/Edmonton")!
    let schedule = BlockedProfileSchedule(
      days: [.saturday], startHour: 22, startMinute: 0, endHour: 6, endMinute: 0)
    // Historical transitions keep this independent of future timezone rule changes.
    for (month, day, hours) in [(3, 8, 7), (11, 1, 9)] {
      let start = calendar.date(from: DateComponents(year: 2025, month: month, day: day, hour: 22))!
      let end = schedule.endDate(forSessionStartingAt: start, calendar: calendar)!
      XCTAssertEqual(calendar.component(.hour, from: end), 6)
      XCTAssertEqual(end.timeIntervalSince(start), TimeInterval(hours * 60 * 60))
    }
  }

  private func makeSession(
    startHour: Int, endHour: Int, actualStartHour: Int, minute: Int = 0, day: Int = 14
  ) -> BlockedProfileSession {
    let profile = BlockedProfiles(name: "Scheduled", blockingStrategyId: ManualBlockingStrategy.id)
    profile.schedule = BlockedProfileSchedule(
      days: [.saturday], startHour: startHour, startMinute: 0, endHour: endHour, endMinute: 0)
    let session = BlockedProfileSession(tag: profile.id.uuidString, blockedProfile: profile)
    session.startTime = date(hour: actualStartHour, minute: minute, day: day)
    return session
  }

  private func date(hour: Int, minute: Int = 0, day: Int = 14) -> Date {
    Calendar.current.date(
      from: DateComponents(year: 2026, month: 11, day: day, hour: hour, minute: minute))!
  }
}
