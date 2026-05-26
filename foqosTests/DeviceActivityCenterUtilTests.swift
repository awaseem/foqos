import XCTest

@testable import foqos

final class DeviceActivityCenterUtilTests: XCTestCase {
  private var calendar: Calendar!

  override func setUp() {
    super.setUp()
    calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
  }

  override func tearDown() {
    calendar = nil
    super.tearDown()
  }

  func testTimerIntervalCanEndAfterMidnight() {
    let result = DeviceActivityCenterUtil.getTimeIntervalStartAndEnd(
      from: 15,
      startingAt: date(2026, 5, 26, 23, 50),
      calendar: calendar
    )

    XCTAssertEqual(result.intervalStart.hour, 23)
    XCTAssertEqual(result.intervalStart.minute, 50)
    XCTAssertEqual(result.intervalEnd.hour, 0)
    XCTAssertEqual(result.intervalEnd.minute, 5)
  }

  func testTimerIntervalStaysOnSameDayWhenDurationDoesNotCrossMidnight() {
    let result = DeviceActivityCenterUtil.getTimeIntervalStartAndEnd(
      from: 15,
      startingAt: date(2026, 5, 26, 10, 20),
      calendar: calendar
    )

    XCTAssertEqual(result.intervalStart.hour, 10)
    XCTAssertEqual(result.intervalStart.minute, 20)
    XCTAssertEqual(result.intervalEnd.hour, 10)
    XCTAssertEqual(result.intervalEnd.minute, 35)
  }

  private func date(
    _ year: Int,
    _ month: Int,
    _ day: Int,
    _ hour: Int,
    _ minute: Int
  ) -> Date {
    DateComponents(
      calendar: calendar,
      timeZone: calendar.timeZone,
      year: year,
      month: month,
      day: day,
      hour: hour,
      minute: minute
    ).date!
  }
}
