import XCTest

@testable import foqos

final class WeeklySessionAggregatorTests: XCTestCase {
  private var calendar: Calendar!

  override func setUp() {
    super.setUp()
    calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    calendar.firstWeekday = 1
  }

  override func tearDown() {
    calendar = nil
    super.tearDown()
  }

  func testSingleDaySessionStaysOnSameDay() {
    let weekStart = date(2024, 3, 3)
    let sessions = [
      WeeklySessionInterval(
        startTime: date(2024, 3, 4, 10),
        endTime: date(2024, 3, 4, 14)
      )
    ]

    let result = WeeklySessionAggregator.aggregate(
      sessions: sessions, weekStart: weekStart, calendar: calendar)

    XCTAssertEqual(result.dailyDurations[1], 4 * 3600, accuracy: 0.1)
    XCTAssertEqual(result.dailySessionCounts[1], 1)
    XCTAssertEqual(result.totalFocusTime, 4 * 3600, accuracy: 0.1)
    XCTAssertEqual(result.overlappingSessionCount, 1)
  }

  func testOvernightSessionSplitsAcrossDays() {
    let weekStart = date(2024, 3, 3)
    let sessions = [
      WeeklySessionInterval(
        startTime: date(2024, 3, 4, 23),
        endTime: date(2024, 3, 5, 2)
      )
    ]

    let result = WeeklySessionAggregator.aggregate(
      sessions: sessions, weekStart: weekStart, calendar: calendar)

    XCTAssertEqual(result.dailyDurations[1], 3600, accuracy: 0.1)
    XCTAssertEqual(result.dailyDurations[2], 2 * 3600, accuracy: 0.1)
    XCTAssertEqual(result.dailySessionCounts[1], 1)
    XCTAssertEqual(result.dailySessionCounts[2], 1)
    XCTAssertEqual(result.totalFocusTime, 3 * 3600, accuracy: 0.1)
  }

  func testSessionCrossingIntoWeekOnlyCountsInWeekPortion() {
    let weekStart = date(2024, 3, 3)
    let sessions = [
      WeeklySessionInterval(
        startTime: date(2024, 3, 2, 23),
        endTime: date(2024, 3, 3, 2)
      )
    ]

    let result = WeeklySessionAggregator.aggregate(
      sessions: sessions, weekStart: weekStart, calendar: calendar)

    XCTAssertEqual(result.dailyDurations[0], 2 * 3600, accuracy: 0.1)
    XCTAssertEqual(result.dailySessionCounts[0], 1)
    XCTAssertEqual(result.totalFocusTime, 2 * 3600, accuracy: 0.1)
    XCTAssertEqual(result.overlappingSessionCount, 1)
  }

  func testSessionCrossingOutOfWeekOnlyCountsInWeekPortion() {
    let weekStart = date(2024, 3, 3)
    let sessions = [
      WeeklySessionInterval(
        startTime: date(2024, 3, 9, 23),
        endTime: date(2024, 3, 10, 2)
      )
    ]

    let result = WeeklySessionAggregator.aggregate(
      sessions: sessions, weekStart: weekStart, calendar: calendar)

    XCTAssertEqual(result.dailyDurations[6], 3600, accuracy: 0.1)
    XCTAssertEqual(result.dailySessionCounts[6], 1)
    XCTAssertEqual(result.totalFocusTime, 3600, accuracy: 0.1)
    XCTAssertEqual(result.overlappingSessionCount, 1)
  }

  func testLongSessionSpansMultipleDays() {
    let weekStart = date(2024, 3, 3)
    let sessions = [
      WeeklySessionInterval(
        startTime: date(2024, 3, 4, 22),
        endTime: date(2024, 3, 6, 2)
      )
    ]

    let result = WeeklySessionAggregator.aggregate(
      sessions: sessions, weekStart: weekStart, calendar: calendar)

    XCTAssertEqual(result.dailyDurations[1], 2 * 3600, accuracy: 0.1)
    XCTAssertEqual(result.dailyDurations[2], 24 * 3600, accuracy: 0.1)
    XCTAssertEqual(result.dailyDurations[3], 2 * 3600, accuracy: 0.1)
    XCTAssertEqual(result.totalFocusTime, 28 * 3600, accuracy: 0.1)
  }

  func testNonOverlappingSessionsAreIgnored() {
    let weekStart = date(2024, 3, 3)
    let sessions = [
      WeeklySessionInterval(
        startTime: date(2024, 2, 28, 10),
        endTime: date(2024, 2, 28, 12)
      ),
      WeeklySessionInterval(
        startTime: date(2024, 3, 10, 10),
        endTime: date(2024, 3, 10, 12)
      ),
    ]

    let result = WeeklySessionAggregator.aggregate(
      sessions: sessions, weekStart: weekStart, calendar: calendar)

    XCTAssertEqual(result.dailyDurations.reduce(0, +), 0, accuracy: 0.1)
    XCTAssertEqual(result.dailySessionCounts.reduce(0, +), 0)
    XCTAssertEqual(result.totalFocusTime, 0, accuracy: 0.1)
    XCTAssertEqual(result.overlappingSessionCount, 0)
  }

  func testStartOfWeekReturnsSundayForSundayFirstCalendar() {
    let result = WeeklySessionAggregator.startOfWeek(
      for: date(2024, 3, 6, 15),
      calendar: calendar
    )

    XCTAssertEqual(result, date(2024, 3, 3))
  }

  func testStartOfWeekReturnsMondayForMondayFirstCalendar() {
    calendar.firstWeekday = 2

    let result = WeeklySessionAggregator.startOfWeek(
      for: date(2026, 5, 6, 15),
      calendar: calendar
    )

    XCTAssertEqual(result, date(2026, 5, 4))
  }

  private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0) -> Date {
    calendar.date(
      from: DateComponents(
        calendar: calendar,
        timeZone: calendar.timeZone,
        year: year,
        month: month,
        day: day,
        hour: hour
      ))!
  }
}
