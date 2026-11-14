import XCTest

@testable import foqos

final class SessionTimeCalculatorTests: XCTestCase {
  func testTimerSessionDisplaysRemainingTime() {
    let startTime = Date(timeIntervalSinceReferenceDate: 1_000)
    let profile = makeProfile(strategyId: NFCTimerBlockingStrategy.id, durationInMinutes: 60)
    let session = BlockedProfileSession(
      tag: NFCTimerBlockingStrategy.id,
      blockedProfile: profile
    )
    session.startTime = startTime

    let currentTime = startTime.addingTimeInterval(15 * 60)
    let elapsedTime = SessionTimeCalculator.elapsedFocusTime(for: session, at: currentTime)
    let displayTime = SessionTimeCalculator.displayedTime(
      for: session,
      elapsedFocusTime: elapsedTime,
      at: currentTime
    )

    XCTAssertEqual(elapsedTime, 15 * 60, accuracy: 0.1)
    XCTAssertEqual(displayTime, 45 * 60, accuracy: 0.1)
  }

  func testExpiredBreakCountdownIsDetectedAfterGracePeriod() {
    let startTime = Date(timeIntervalSinceReferenceDate: 1_000)
    let profile = makeProfile(
      strategyId: NFCTimerBlockingStrategy.id,
      durationInMinutes: 18 * 60,
      enableBreaks: true,
      breakTimeInMinutes: 30
    )
    let session = BlockedProfileSession(
      tag: NFCTimerBlockingStrategy.id,
      blockedProfile: profile
    )
    session.startTime = startTime
    session.breakStartTime = startTime.addingTimeInterval(6 * 60 * 60)

    let breakEndTime = session.breakStartTime!.addingTimeInterval(30 * 60)

    XCTAssertFalse(
      SessionTimeCalculator.isCountdownReloadDue(
        for: session,
        at: breakEndTime.addingTimeInterval(SessionTimeCalculator.countdownReloadDelay - 1)
      )
    )
    XCTAssertTrue(
      SessionTimeCalculator.isCountdownReloadDue(
        for: session,
        at: breakEndTime.addingTimeInterval(SessionTimeCalculator.countdownReloadDelay)
      )
    )

    XCTAssertFalse(
      SessionTimeCalculator.isCountdownExpired(
        for: session,
        at: breakEndTime
      )
    )
    XCTAssertFalse(
      SessionTimeCalculator.isCountdownExpired(
        for: session,
        at: breakEndTime.addingTimeInterval(
          SessionTimeCalculator.countdownResetGracePeriod - 1
        )
      )
    )
    XCTAssertTrue(
      SessionTimeCalculator.isCountdownExpired(
        for: session,
        at: breakEndTime.addingTimeInterval(
          SessionTimeCalculator.countdownResetGracePeriod
        )
      )
    )
  }

  func testManualSessionDoesNotHaveExpiredCountdown() {
    let startTime = Date(timeIntervalSinceReferenceDate: 1_000)
    let profile = makeProfile(strategyId: ManualBlockingStrategy.id)
    let session = BlockedProfileSession(
      tag: ManualBlockingStrategy.id,
      blockedProfile: profile
    )
    session.startTime = startTime

    XCTAssertFalse(
      SessionTimeCalculator.isCountdownExpired(
        for: session,
        at: startTime.addingTimeInterval(24 * 60 * 60)
      )
    )
  }

  func testManualSessionDisplaysElapsedTime() {
    let startTime = Date(timeIntervalSinceReferenceDate: 1_000)
    let profile = makeProfile(strategyId: ManualBlockingStrategy.id)
    let session = BlockedProfileSession(
      tag: ManualBlockingStrategy.id,
      blockedProfile: profile
    )
    session.startTime = startTime

    let currentTime = startTime.addingTimeInterval(20 * 60)
    let displayTime = SessionTimeCalculator.displayedTime(for: session, at: currentTime)

    XCTAssertEqual(displayTime, 20 * 60, accuracy: 0.1)
  }

  func testTimerDisplayMatchesLiveActivityEndTimeAfterBreak() {
    let startTime = Date(timeIntervalSinceReferenceDate: 1_000)
    let profile = makeProfile(
      strategyId: QRTimerBlockingStrategy.id,
      durationInMinutes: 60,
      enableBreaks: true
    )
    let session = BlockedProfileSession(
      tag: QRTimerBlockingStrategy.id,
      blockedProfile: profile
    )
    session.startTime = startTime
    session.breakStartTime = startTime.addingTimeInterval(10 * 60)
    session.breakEndTime = startTime.addingTimeInterval(20 * 60)

    let currentTime = startTime.addingTimeInterval(30 * 60)
    let elapsedTime = SessionTimeCalculator.elapsedFocusTime(for: session, at: currentTime)
    let displayTime = SessionTimeCalculator.displayedTime(
      for: session,
      elapsedFocusTime: elapsedTime,
      at: currentTime
    )

    XCTAssertEqual(elapsedTime, 20 * 60, accuracy: 0.1)
    XCTAssertEqual(displayTime, 30 * 60, accuracy: 0.1)
    XCTAssertEqual(
      SessionTimeCalculator.expectedEndTime(for: session),
      startTime.addingTimeInterval(60 * 60)
    )
  }

  func testSingleBreakIsUnavailableAfterItEnds() {
    let startTime = Date(timeIntervalSinceReferenceDate: 1_000)
    let profile = makeProfile(
      strategyId: ManualBlockingStrategy.id,
      enableBreaks: true,
      breakTimeInMinutes: 15,
      allowMultipleBreaks: false
    )
    let session = BlockedProfileSession(
      tag: ManualBlockingStrategy.id,
      blockedProfile: profile
    )
    session.startTime = startTime
    session.breakStartTime = startTime.addingTimeInterval(5 * 60)
    session.breakEndTime = startTime.addingTimeInterval(8 * 60)

    XCTAssertFalse(session.isBreakAvailable)
    XCTAssertEqual(
      SessionTimeCalculator.elapsedFocusTime(
        for: session,
        at: startTime.addingTimeInterval(10 * 60)
      ),
      7 * 60,
      accuracy: 0.1
    )
  }

  func testReusableBreakStoppedEarlyLeavesRemainingAllowance() {
    let startTime = Date(timeIntervalSinceReferenceDate: 1_000)
    let profile = makeProfile(
      strategyId: ManualBlockingStrategy.id,
      enableBreaks: true,
      breakTimeInMinutes: 15,
      allowMultipleBreaks: true
    )
    let session = BlockedProfileSession(
      tag: ManualBlockingStrategy.id,
      blockedProfile: profile
    )
    session.startTime = startTime
    session.breakStartTime = startTime.addingTimeInterval(5 * 60)
    session.breakEndTime = startTime.addingTimeInterval(8 * 60)
    session.usedBreakDurationInSeconds = 3 * 60

    XCTAssertTrue(session.isBreakAvailable)
    XCTAssertEqual(session.remainingBreakAllowance(), 12 * 60, accuracy: 0.1)
  }

  func testReusableBreakDisplaysRemainingAllowanceDuringSecondBreak() {
    let startTime = Date(timeIntervalSinceReferenceDate: 1_000)
    let profile = makeProfile(
      strategyId: ManualBlockingStrategy.id,
      enableBreaks: true,
      breakTimeInMinutes: 15,
      allowMultipleBreaks: true
    )
    let session = BlockedProfileSession(
      tag: ManualBlockingStrategy.id,
      blockedProfile: profile
    )
    session.startTime = startTime
    session.usedBreakDurationInSeconds = 3 * 60
    session.breakStartTime = startTime.addingTimeInterval(10 * 60)

    let currentTime = startTime.addingTimeInterval(12 * 60)
    let elapsedTime = SessionTimeCalculator.elapsedFocusTime(for: session, at: currentTime)
    let displayTime = SessionTimeCalculator.displayedTime(
      for: session,
      elapsedFocusTime: elapsedTime,
      at: currentTime
    )

    XCTAssertEqual(elapsedTime, 7 * 60, accuracy: 0.1)
    XCTAssertEqual(displayTime, 10 * 60, accuracy: 0.1)
  }

  func testReusableBreakUnavailableWhenAllowanceIsExhausted() {
    let profile = makeProfile(
      strategyId: ManualBlockingStrategy.id,
      enableBreaks: true,
      breakTimeInMinutes: 15,
      allowMultipleBreaks: true
    )
    let session = BlockedProfileSession(
      tag: ManualBlockingStrategy.id,
      blockedProfile: profile
    )
    session.usedBreakDurationInSeconds = 15 * 60

    XCTAssertFalse(session.isBreakAvailable)
    XCTAssertEqual(session.remainingBreakAllowance(), 0, accuracy: 0.1)
  }

  func testReusableBreakAllowanceResetsForNewSession() {
    let profile = makeProfile(
      strategyId: ManualBlockingStrategy.id,
      enableBreaks: true,
      breakTimeInMinutes: 15,
      allowMultipleBreaks: true
    )
    let session = BlockedProfileSession(
      tag: ManualBlockingStrategy.id,
      blockedProfile: profile
    )

    XCTAssertTrue(session.isBreakAvailable)
    XCTAssertEqual(session.remainingBreakAllowance(), 15 * 60, accuracy: 0.1)
  }

  func testGivenTimerStrategies_WhenCalculatingDeadline_ThenTagAndProfileUseTimerDuration() {
    let start = Date(timeIntervalSinceReferenceDate: 1_000)
    for strategyID in [
      NFCTimerBlockingStrategy.id, QRTimerBlockingStrategy.id, ShortcutTimerBlockingStrategy.id,
    ] {
      let profile = makeProfile(strategyId: strategyID, durationInMinutes: 30)
      let session = BlockedProfileSession(tag: "started-from-shortcut", blockedProfile: profile)
      session.startTime = start
      XCTAssertEqual(
        SessionTimeCalculator.expectedSessionEndTime(for: session),
        start.addingTimeInterval(30 * 60)
      )

      session.tag = strategyID
      profile.blockingStrategyId = ManualBlockingStrategy.id
      XCTAssertEqual(
        SessionTimeCalculator.expectedSessionEndTime(for: session),
        start.addingTimeInterval(30 * 60)
      )
    }
  }

  func testGivenScheduledTimerProfile_WhenCalculatingDeadline_ThenScheduleTakesPrecedence() {
    let profile = makeProfile(strategyId: QRTimerBlockingStrategy.id, durationInMinutes: 30)
    profile.schedule = BlockedProfileSchedule(
      days: [.monday], startHour: 9, startMinute: 0, endHour: 10, endMinute: 0)
    let session = BlockedProfileSession(tag: profile.id.uuidString, blockedProfile: profile)
    session.startTime = Calendar.current.date(
      bySettingHour: 9, minute: 0, second: 0, of: Date(timeIntervalSinceReferenceDate: 1_000))!

    XCTAssertEqual(
      SessionTimeCalculator.expectedSessionEndTime(for: session),
      session.startTime.addingTimeInterval(60 * 60)
    )
  }

  func testGivenPauseDuration_WhenCalculatingDeadline_ThenAppAndWidgetUseSameFallbacks() {
    let start = Date(timeIntervalSinceReferenceDate: 1_000)
    let cases: [(Data?, Int)] = [
      (StrategyPauseTimerData.toData(from: StrategyPauseTimerData(pauseDurationInMinutes: 5)), 5),
      (nil, 15),
      (Data("invalid".utf8), 15),
    ]
    for (data, minutes) in cases {
      let profile = makeProfile(strategyId: NFCPauseTimerBlockingStrategy.id)
      profile.strategyData = data
      let session = BlockedProfileSession(
        tag: NFCPauseTimerBlockingStrategy.id, blockedProfile: profile)
      session.pauseStartTime = start

      let expected = start.addingTimeInterval(TimeInterval(minutes * 60))
      XCTAssertEqual(SessionTimeCalculator.expectedEndTime(for: session), expected)
      XCTAssertEqual(SessionTimeCalculator.breakOrPauseEndTime(for: session), expected)
    }
  }

  func testGivenReusableBreak_WhenCalculatingDeadline_ThenCompletedBreaksReduceBothCountdowns() {
    let profile = makeProfile(
      strategyId: ManualBlockingStrategy.id, enableBreaks: true,
      breakTimeInMinutes: 15, allowMultipleBreaks: true)
    let session = BlockedProfileSession(tag: ManualBlockingStrategy.id, blockedProfile: profile)
    let start = Date(timeIntervalSinceReferenceDate: 1_000)
    session.breakStartTime = start

    for (usedMinutes, remainingMinutes) in [(3, 12), (15, 0), (20, 0)] {
      session.usedBreakDurationInSeconds = TimeInterval(usedMinutes * 60)
      let expected = start.addingTimeInterval(TimeInterval(remainingMinutes * 60))
      XCTAssertEqual(SessionTimeCalculator.expectedEndTime(for: session), expected)
      XCTAssertEqual(SessionTimeCalculator.breakOrPauseEndTime(for: session), expected)
    }
  }

  func testGivenCompletedInterruptions_WhenCalculatingDeadline_ThenFocusDeadlineResumes() {
    let profile = makeProfile(
      strategyId: QRTimerBlockingStrategy.id, durationInMinutes: 30, enableBreaks: true)
    let session = BlockedProfileSession(tag: QRTimerBlockingStrategy.id, blockedProfile: profile)
    let start = Date(timeIntervalSinceReferenceDate: 1_000)
    session.startTime = start
    session.breakStartTime = start.addingTimeInterval(60)
    session.breakEndTime = start.addingTimeInterval(120)
    session.pauseStartTime = start.addingTimeInterval(180)
    session.pauseEndTime = start.addingTimeInterval(240)

    XCTAssertNil(SessionTimeCalculator.breakOrPauseEndTime(for: session))
    XCTAssertEqual(
      SessionTimeCalculator.expectedEndTime(for: session), start.addingTimeInterval(30 * 60))
  }

  private func makeProfile(
    strategyId: String,
    durationInMinutes: Int? = nil,
    enableBreaks: Bool = false,
    breakTimeInMinutes: Int = 15,
    allowMultipleBreaks: Bool = false
  ) -> BlockedProfiles {
    let strategyData = durationInMinutes.flatMap {
      StrategyTimerData.toData(
        from: StrategyTimerData(durationInMinutes: $0, hideStopButton: false)
      )
    }

    return BlockedProfiles(
      name: "Focus",
      blockingStrategyId: strategyId,
      strategyData: strategyData,
      enableBreaks: enableBreaks,
      breakTimeInMinutes: breakTimeInMinutes,
      allowMultipleBreaks: allowMultipleBreaks
    )
  }
}
