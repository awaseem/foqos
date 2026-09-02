import XCTest

@testable import foqos

final class BreakAllowanceTests: XCTestCase {
  func testDailyPeriodUsesConfiguredResetTime() throws {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "America/Los_Angeles"))
    let beforeReset = try XCTUnwrap(
      calendar.date(from: DateComponents(year: 2026, month: 9, day: 1, hour: 3, minute: 59))
    )
    let afterReset = try XCTUnwrap(
      calendar.date(from: DateComponents(year: 2026, month: 9, day: 1, hour: 4))
    )

    let beforePeriod = SharedData.breakAllowancePeriodStart(
      containing: beforeReset,
      resetHour: 4,
      resetMinute: 0,
      calendar: calendar
    )
    let afterPeriod = SharedData.breakAllowancePeriodStart(
      containing: afterReset,
      resetHour: 4,
      resetMinute: 0,
      calendar: calendar
    )

    XCTAssertEqual(calendar.component(.day, from: beforePeriod), 31)
    XCTAssertEqual(calendar.component(.hour, from: beforePeriod), 4)
    XCTAssertEqual(calendar.component(.day, from: afterPeriod), 1)
    XCTAssertEqual(calendar.component(.hour, from: afterPeriod), 4)
  }

  func testPerBreakModeLimitsBreakCountUntilNextReset() {
    let profile = BlockedProfiles(
      name: "Focus",
      blockingStrategyId: ManualBlockingStrategy.id,
      enableBreaks: true,
      breakTimeInMinutes: 15,
      breakAllowanceMode: .perBreak,
      breakCountLimit: 2,
      breakResetHour: 4
    )
    defer { SharedData.resetBreakAllowanceUsage(for: profile.id) }

    let periodStart = SharedData.breakAllowancePeriodStart(
      containing: Date(),
      resetHour: 4,
      resetMinute: 0
    )
    let firstBreak = periodStart.addingTimeInterval(60)
    let session = BlockedProfileSession(
      tag: ManualBlockingStrategy.id,
      blockedProfile: profile
    )

    XCTAssertTrue(session.startBreak(at: firstBreak))
    XCTAssertEqual(session.remainingBreakCount(at: firstBreak), 1)
    session.endBreak(at: firstBreak.addingTimeInterval(5 * 60))
    XCTAssertTrue(session.startBreak(at: firstBreak.addingTimeInterval(10 * 60)))
    XCTAssertEqual(session.remainingBreakCount(at: firstBreak.addingTimeInterval(10 * 60)), 0)
    session.endBreak(at: firstBreak.addingTimeInterval(15 * 60))
    XCTAssertFalse(session.isBreakAvailable(at: firstBreak.addingTimeInterval(20 * 60)))
    XCTAssertFalse(session.startBreak(at: firstBreak.addingTimeInterval(20 * 60)))
    let secondSession = BlockedProfileSession(
      tag: ManualBlockingStrategy.id,
      blockedProfile: profile
    )
    XCTAssertFalse(secondSession.isBreakAvailable(at: firstBreak.addingTimeInterval(20 * 60)))

    let nextPeriod = Calendar.current.date(byAdding: .day, value: 1, to: periodStart)!
    XCTAssertTrue(secondSession.isBreakAvailable(at: nextPeriod.addingTimeInterval(60)))
  }

  func testPerBreakModeProvidesFullDurationForEveryBreak() {
    let profile = BlockedProfiles(
      name: "Focus",
      blockingStrategyId: ManualBlockingStrategy.id,
      enableBreaks: true,
      breakTimeInMinutes: 15,
      breakAllowanceMode: .perBreak,
      breakCountLimit: 3
    )
    defer { SharedData.resetBreakAllowanceUsage(for: profile.id) }
    let session = BlockedProfileSession(
      tag: ManualBlockingStrategy.id,
      blockedProfile: profile
    )
    let firstBreak = Date()

    XCTAssertTrue(session.startBreak(at: firstBreak))
    session.endBreak(at: firstBreak.addingTimeInterval(5 * 60))
    XCTAssertTrue(session.startBreak(at: firstBreak.addingTimeInterval(10 * 60)))

    XCTAssertEqual(
      session.remainingBreakAllowance(at: firstBreak.addingTimeInterval(12 * 60)),
      13 * 60,
      accuracy: 0.1
    )
  }

  func testCumulativeModeSharesBudgetAcrossSessionsAndResetsDaily() {
    let profile = BlockedProfiles(
      name: "Focus",
      blockingStrategyId: ManualBlockingStrategy.id,
      enableBreaks: true,
      breakTimeInMinutes: 15,
      breakAllowanceMode: .cumulative,
      breakResetHour: 4
    )
    defer { SharedData.resetBreakAllowanceUsage(for: profile.id) }
    let periodStart = SharedData.breakAllowancePeriodStart(
      containing: Date(),
      resetHour: 4,
      resetMinute: 0
    )
    let firstBreak = periodStart.addingTimeInterval(60)
    let firstSession = BlockedProfileSession(
      tag: ManualBlockingStrategy.id,
      blockedProfile: profile
    )

    XCTAssertTrue(firstSession.startBreak(at: firstBreak))
    firstSession.endBreak(at: firstBreak.addingTimeInterval(5 * 60))

    let secondSession = BlockedProfileSession(
      tag: ManualBlockingStrategy.id,
      blockedProfile: profile
    )
    XCTAssertEqual(
      secondSession.remainingBreakAllowance(at: firstBreak.addingTimeInterval(10 * 60)),
      10 * 60,
      accuracy: 0.1
    )

    let nextPeriod = Calendar.current.date(byAdding: .day, value: 1, to: periodStart)!
    XCTAssertEqual(
      secondSession.remainingBreakAllowance(at: nextPeriod.addingTimeInterval(60)),
      15 * 60,
      accuracy: 0.1
    )
  }

  func testCumulativeModeSupportsTwentyFourHourBudget() {
    let profile = BlockedProfiles(
      name: "Focus",
      blockingStrategyId: ManualBlockingStrategy.id,
      enableBreaks: true,
      breakTimeInMinutes: 24 * 60,
      breakAllowanceMode: .cumulative
    )
    defer { SharedData.resetBreakAllowanceUsage(for: profile.id) }
    let session = BlockedProfileSession(
      tag: ManualBlockingStrategy.id,
      blockedProfile: profile
    )

    XCTAssertEqual(
      session.remainingBreakAllowance(),
      24 * 60 * 60,
      accuracy: 0.1
    )
  }

  func testCumulativeBreakSpanningResetChargesNewPeriod() throws {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "America/Los_Angeles"))
    let profile = BlockedProfiles(
      name: "Focus",
      blockingStrategyId: ManualBlockingStrategy.id,
      enableBreaks: true,
      breakTimeInMinutes: 15,
      breakAllowanceMode: .cumulative,
      breakResetHour: 4
    )
    defer { SharedData.resetBreakAllowanceUsage(for: profile.id) }
    let breakStart = try XCTUnwrap(
      calendar.date(from: DateComponents(year: 2026, month: 9, day: 1, hour: 3, minute: 55))
    )
    let afterReset = try XCTUnwrap(
      calendar.date(from: DateComponents(year: 2026, month: 9, day: 1, hour: 4, minute: 5))
    )
    let breakEnd = try XCTUnwrap(
      calendar.date(from: DateComponents(year: 2026, month: 9, day: 1, hour: 4, minute: 10))
    )
    let session = BlockedProfileSession(
      tag: ManualBlockingStrategy.id,
      blockedProfile: profile
    )

    XCTAssertTrue(session.startBreak(at: breakStart))
    XCTAssertEqual(session.remainingBreakAllowance(at: afterReset), 5 * 60, accuracy: 0.1)
    session.endBreak(at: breakEnd)

    let nextSession = BlockedProfileSession(
      tag: ManualBlockingStrategy.id,
      blockedProfile: profile
    )
    XCTAssertEqual(
      nextSession.remainingBreakAllowance(at: breakEnd),
      5 * 60,
      accuracy: 0.1
    )
  }

  func testPerBreakModeCanRemainExhaustedUntilManualReset() {
    let profile = BlockedProfiles(
      name: "Focus",
      blockingStrategyId: ManualBlockingStrategy.id,
      enableBreaks: true,
      breakAllowanceMode: .perBreak,
      breakCountLimit: 1,
      breakResetPolicy: .never
    )
    defer { SharedData.resetBreakAllowanceUsage(for: profile.id) }
    let firstSession = BlockedProfileSession(
      tag: ManualBlockingStrategy.id,
      blockedProfile: profile
    )
    let firstBreak = Date()

    XCTAssertTrue(firstSession.startBreak(at: firstBreak))
    firstSession.endBreak(at: firstBreak.addingTimeInterval(5 * 60))

    let secondSession = BlockedProfileSession(
      tag: ManualBlockingStrategy.id,
      blockedProfile: profile
    )
    let laterDate = Calendar.current.date(byAdding: .day, value: 30, to: firstBreak)!
    XCTAssertFalse(secondSession.isBreakAvailable(at: laterDate))

    SharedData.resetBreakAllowanceUsage(for: profile.id)

    XCTAssertTrue(secondSession.isBreakAvailable(at: laterDate))
  }

  func testCumulativeModeCanPreserveUsageWithoutAutomaticReset() {
    let profile = BlockedProfiles(
      name: "Focus",
      blockingStrategyId: ManualBlockingStrategy.id,
      enableBreaks: true,
      breakTimeInMinutes: 15,
      breakAllowanceMode: .cumulative,
      breakResetPolicy: .never
    )
    defer { SharedData.resetBreakAllowanceUsage(for: profile.id) }
    let firstSession = BlockedProfileSession(
      tag: ManualBlockingStrategy.id,
      blockedProfile: profile
    )
    let firstBreak = Date()

    XCTAssertTrue(firstSession.startBreak(at: firstBreak))
    firstSession.endBreak(at: firstBreak.addingTimeInterval(5 * 60))

    let secondSession = BlockedProfileSession(
      tag: ManualBlockingStrategy.id,
      blockedProfile: profile
    )
    let laterDate = Calendar.current.date(byAdding: .day, value: 30, to: firstBreak)!
    XCTAssertEqual(
      secondSession.remainingBreakAllowance(at: laterDate),
      10 * 60,
      accuracy: 0.1
    )
  }

  func testCumulativeBreakRecordingIsIdempotent() {
    let profileID = UUID()
    defer { SharedData.resetBreakAllowanceUsage(for: profileID) }
    let breakStart = Date()
    let breakEnd = breakStart.addingTimeInterval(5 * 60)

    SharedData.recordCumulativeBreakDuration(
      for: profileID,
      breakStart: breakStart,
      breakEnd: breakEnd,
      totalAllowanceInSeconds: 15 * 60,
      resetHour: 0,
      resetMinute: 0
    )
    SharedData.recordCumulativeBreakDuration(
      for: profileID,
      breakStart: breakStart,
      breakEnd: breakEnd,
      totalAllowanceInSeconds: 15 * 60,
      resetHour: 0,
      resetMinute: 0
    )

    XCTAssertEqual(
      SharedData.breakAllowanceUsage(
        for: profileID,
        at: breakEnd,
        resetHour: 0,
        resetMinute: 0
      ).usedDurationInSeconds,
      5 * 60,
      accuracy: 0.1
    )
  }

  func testHistoricalUsageReadDoesNotReplaceCurrentPeriod() {
    let profileID = UUID()
    defer { SharedData.resetBreakAllowanceUsage(for: profileID) }
    let currentPeriod = SharedData.breakAllowancePeriodStart(
      containing: Date(),
      resetHour: 0,
      resetMinute: 0
    )
    let previousPeriod = Calendar.current.date(byAdding: .day, value: -1, to: currentPeriod)!

    XCTAssertTrue(
      SharedData.beginBreak(
        for: profileID,
        mode: .perBreak,
        breakCountLimit: 1,
        totalAllowanceInSeconds: 15 * 60,
        at: currentPeriod.addingTimeInterval(60),
        resetHour: 0,
        resetMinute: 0
      )
    )
    _ = SharedData.breakAllowanceUsage(
      for: profileID,
      at: previousPeriod.addingTimeInterval(60),
      resetHour: 0,
      resetMinute: 0
    )

    XCTAssertEqual(
      SharedData.breakAllowanceUsage(
        for: profileID,
        at: currentPeriod.addingTimeInterval(120),
        resetHour: 0,
        resetMinute: 0
      ).breaksStarted,
      1
    )
  }
}
