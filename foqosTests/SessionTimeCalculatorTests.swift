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
