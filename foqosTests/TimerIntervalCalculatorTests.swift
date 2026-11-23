import XCTest

@testable import foqos

final class TimerIntervalCalculatorTests: XCTestCase {
  private var calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    return calendar
  }()

  func testSameDayTimerKeepsTheStartOfDayInterval() {
    let (start, end) = interval(startingAt: "10:00", forMinutes: 15)

    assertTime(start, hour: 0, minute: 0, second: 0)
    assertTime(end, hour: 10, minute: 15, second: 0)
  }

  func testTimerCrossingMidnightEndsAtItsRealTimeInsteadOfMidnight() {
    let (start, end) = interval(startingAt: "23:50", forMinutes: 15)

    // Previously clamped to 23:59:59, which ended the break at midnight.
    assertTime(end, hour: 0, minute: 5, second: 0)
    assertTime(start, hour: 23, minute: 35, second: 0)
    XCTAssertTrue(
      secondsSinceMidnight(start) > secondsSinceMidnight(end),
      "A timer ending tomorrow needs an interval that spans midnight"
    )
  }

  func testTimerEndingExactlyAtMidnightIsNotCutShort() {
    let (start, end) = interval(startingAt: "23:45", forMinutes: 15)

    assertTime(end, hour: 0, minute: 0, second: 0)
    assertTime(start, hour: 23, minute: 30, second: 0)
  }

  func testShortTimerAfterMidnightStillGetsAMonitorableInterval() {
    // A reusable break allowance can leave only a few minutes, and a start of day interval would
    // be too short for DeviceActivityCenter to accept.
    let (start, end) = interval(startingAt: "00:05", forMinutes: 3)

    assertTime(start, hour: 23, minute: 50, second: 0)
    assertTime(end, hour: 0, minute: 8, second: 0)
  }

  func testTimerAfterMidnightKeepsTheStartOfDayIntervalWhenItIsLongEnough() {
    let (start, end) = interval(startingAt: "00:05", forMinutes: 20)

    assertTime(start, hour: 0, minute: 0, second: 0)
    assertTime(end, hour: 0, minute: 25, second: 0)
  }

  func testTimerStartedExactlyAtMidnightDoesNotStartOnItsOwnStartTime() {
    // A start of day interval would begin at the very moment monitoring starts, which is the shape
    // that made the previous attempt at this fix unreliable.
    let (start, end) = interval(startingAt: "00:00", forMinutes: 60)

    assertTime(start, hour: 23, minute: 45, second: 0)
    assertTime(end, hour: 1, minute: 0, second: 0)
  }

  func testEveryIntervalClearsTheFrameworkMinimum() {
    for minutesFromMidnight in stride(from: 0, to: 24 * 60, by: 5) {
      for durationInMinutes in [1, 3, 15, 60, 8 * 60, 23 * 60] {
        let startTime = date(minutesFromMidnight: minutesFromMidnight)
        let (start, end) = TimerIntervalCalculator.interval(
          durationInSeconds: TimeInterval(durationInMinutes * 60),
          now: startTime,
          calendar: calendar
        )

        let startSeconds = secondsSinceMidnight(start)
        let endSeconds = secondsSinceMidnight(end)
        let length =
          startSeconds <= endSeconds
          ? endSeconds - startSeconds
          : (24 * 60 * 60) - startSeconds + endSeconds

        XCTAssertGreaterThanOrEqual(
          length,
          TimerIntervalCalculator.minimumMonitoringWindow,
          "Interval starting at \(startSeconds)s for \(durationInMinutes)m is too short to monitor"
        )

        // Monitoring has to begin with the device already inside the interval, otherwise the end
        // of the interval is not reliably reported.
        let nowSeconds = TimeInterval(minutesFromMidnight * 60)
        let offsetFromStart = (nowSeconds - startSeconds).truncatingRemainder(
          dividingBy: 24 * 60 * 60)
        let normalizedOffset =
          offsetFromStart < 0 ? offsetFromStart + (24 * 60 * 60) : offsetFromStart
        XCTAssertTrue(
          normalizedOffset > 0 && normalizedOffset < length,
          "Interval for \(durationInMinutes)m started at \(startSeconds)s does not contain the current time"
        )
      }
    }
  }

  func testDurationIsClampedIntoASchedulableRange() {
    // A timer longer than the maximum duration is clamped instead of inverting the interval.
    let (_, dayLongEnd) = interval(startingAt: "10:00", forMinutes: 24 * 60)
    assertTime(dayLongEnd, hour: 9, minute: 30, second: 0)

    let (_, emptyEnd) = interval(startingAt: "10:00", forMinutes: 0)
    assertTime(emptyEnd, hour: 10, minute: 0, second: 1)
  }

  // MARK: - Helpers

  private func interval(startingAt time: String, forMinutes minutes: Int) -> (
    DateComponents, DateComponents
  ) {
    let parts = time.split(separator: ":").compactMap { Int($0) }
    let now = date(minutesFromMidnight: parts[0] * 60 + parts[1])
    return TimerIntervalCalculator.interval(
      durationInSeconds: TimeInterval(minutes * 60),
      now: now,
      calendar: calendar
    )
  }

  private func date(minutesFromMidnight: Int) -> Date {
    let midnight = calendar.date(from: DateComponents(year: 2026, month: 5, day: 26))!
    return midnight.addingTimeInterval(TimeInterval(minutesFromMidnight * 60))
  }

  private func assertTime(
    _ components: DateComponents,
    hour: Int,
    minute: Int,
    second: Int,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    XCTAssertEqual(components.hour, hour, "hour", file: file, line: line)
    XCTAssertEqual(components.minute, minute, "minute", file: file, line: line)
    XCTAssertEqual(components.second, second, "second", file: file, line: line)
  }

  private func secondsSinceMidnight(_ components: DateComponents) -> TimeInterval {
    let hour = components.hour ?? 0
    let minute = components.minute ?? 0
    let second = components.second ?? 0
    return TimeInterval(hour * 3600 + minute * 60 + second)
  }
}
