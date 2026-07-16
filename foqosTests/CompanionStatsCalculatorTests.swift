import XCTest

@testable import foqos

final class CompanionStatsCalculatorTests: XCTestCase {
  private var calendar: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
  }

  // Fixed "now": 2026-07-15 14:00 UTC
  private var now: Date {
    DateComponents(
      calendar: calendar, year: 2026, month: 7, day: 15, hour: 14
    ).date!
  }

  private func interval(daysAgo: Int, hour: Int, minutes: Int) -> WeeklySessionInterval {
    let start = calendar.date(
      byAdding: .day, value: -daysAgo,
      to: DateComponents(calendar: calendar, year: 2026, month: 7, day: 15, hour: hour).date!
    )!
    return WeeklySessionInterval(
      startTime: start, endTime: start.addingTimeInterval(TimeInterval(minutes * 60)))
  }

  func testEmptySessionsProduceZeroStats() {
    let stats = CompanionStatsCalculator.stats(for: [], now: now, calendar: calendar)
    XCTAssertEqual(stats, .zero)
    XCTAssertEqual(stats.weekMinutes.count, 7)
  }

  func testTodayTotalAndWeekBuckets() {
    let stats = CompanionStatsCalculator.stats(
      for: [
        interval(daysAgo: 0, hour: 9, minutes: 30),
        interval(daysAgo: 0, hour: 11, minutes: 15),
        interval(daysAgo: 2, hour: 10, minutes: 60),
        interval(daysAgo: 6, hour: 10, minutes: 45),
        interval(daysAgo: 8, hour: 10, minutes: 90),  // outside the week window
      ],
      now: now, calendar: calendar
    )

    XCTAssertEqual(stats.todayFocusSeconds, 45 * 60)
    XCTAssertEqual(stats.weekMinutes, [45, 0, 0, 0, 60, 0, 45])
  }

  func testStreakCountsConsecutiveDaysEndingToday() {
    let stats = CompanionStatsCalculator.stats(
      for: [
        interval(daysAgo: 0, hour: 9, minutes: 10),
        interval(daysAgo: 1, hour: 9, minutes: 10),
        interval(daysAgo: 2, hour: 9, minutes: 10),
        interval(daysAgo: 4, hour: 9, minutes: 10),  // gap at day 3 ends the streak
      ],
      now: now, calendar: calendar
    )
    XCTAssertEqual(stats.streakDays, 3)
  }

  func testNoSessionTodayMeansZeroStreak() {
    // Matches ProfileInsightsUtil.currentStreakDays: the streak is anchored
    // to today, so a day without focus (so far) shows 0.
    let stats = CompanionStatsCalculator.stats(
      for: [interval(daysAgo: 1, hour: 9, minutes: 30)],
      now: now, calendar: calendar
    )
    XCTAssertEqual(stats.streakDays, 0)
  }

  func testOvernightSessionSplitsAcrossDaysAndExtendsStreak() {
    // 23:30 yesterday -> 00:30 today: 30 minutes in each bucket, both days count.
    let start = calendar.date(
      byAdding: .minute, value: 30,
      to: DateComponents(calendar: calendar, year: 2026, month: 7, day: 14, hour: 23).date!
    )!
    let stats = CompanionStatsCalculator.stats(
      for: [WeeklySessionInterval(startTime: start, endTime: start.addingTimeInterval(3600))],
      now: now, calendar: calendar
    )

    XCTAssertEqual(stats.weekMinutes[6], 30)  // today
    XCTAssertEqual(stats.weekMinutes[5], 30)  // yesterday
    XCTAssertEqual(stats.todayFocusSeconds, 30 * 60)
    XCTAssertEqual(stats.streakDays, 2)
  }
}
