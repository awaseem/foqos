import XCTest

@testable import foqos

final class SessionTimerConsistencyTests: XCTestCase {
  private let start = Date(timeIntervalSinceReferenceDate: 1_000)

  func testGivenRegularSession_WhenDisplayingTimers_ThenEverySurfaceCountsUp() {
    let session = makeSession()
    assertTimers(
      session, at: start.addingTimeInterval(15 * 60), expected: 15 * 60, countsDown: false)
  }

  func testGivenTimerStrategies_WhenDisplayingTimers_ThenEverySurfaceCountsDown() {
    for strategy in [
      NFCTimerBlockingStrategy.id, QRTimerBlockingStrategy.id, ShortcutTimerBlockingStrategy.id,
    ] {
      let session = makeSession(strategy: strategy)
      assertTimers(
        session, at: start.addingTimeInterval(15 * 60), expected: 45 * 60, countsDown: true)
    }
  }

  func testGivenCompletedBreaks_WhenDisplayingElapsedTime_ThenSubtractEachBreakOnce() {
    for (allowsMultiple, accumulated, expected) in [
      (false, 0.0, 15.0), (true, 5.0, 15.0), (true, 8.0, 12.0), (false, 8.0, 12.0),
    ] {
      let session = makeSession()
      session.blockedProfile.allowMultipleBreaks = allowsMultiple
      session.breakStartTime = start.addingTimeInterval(5 * 60)
      session.breakEndTime = start.addingTimeInterval(10 * 60)
      session.usedBreakDurationInSeconds = accumulated * 60
      assertTimers(
        session, at: start.addingTimeInterval(20 * 60), expected: expected * 60, countsDown: false)
    }
  }

  func testGivenTimedSessionAfterBreak_WhenDisplayingTimers_ThenDeadlineIsUnchanged() {
    let session = makeSession(strategy: QRTimerBlockingStrategy.id)
    session.blockedProfile.allowMultipleBreaks = true
    session.breakStartTime = start.addingTimeInterval(5 * 60)
    session.breakEndTime = start.addingTimeInterval(10 * 60)
    session.usedBreakDurationInSeconds = 5 * 60
    assertTimers(
      session, at: start.addingTimeInterval(20 * 60), expected: 40 * 60, countsDown: true)
  }

  func testGivenBreakOrPause_WhenDisplayingTimers_ThenInterruptionDeadlineTakesPrecedence() {
    for isPause in [false, true] {
      let session = makeSession(
        strategy: isPause ? NFCPauseTimerBlockingStrategy.id : QRTimerBlockingStrategy.id)
      session.blockedProfile.strategyData =
        isPause
        ? StrategyPauseTimerData.toData(from: StrategyPauseTimerData(pauseDurationInMinutes: 15))
        : session.blockedProfile.strategyData
      if isPause {
        session.pauseStartTime = start.addingTimeInterval(10 * 60)
      } else {
        session.blockedProfile.allowMultipleBreaks = true
        session.usedBreakDurationInSeconds = 3 * 60
        session.breakStartTime = start.addingTimeInterval(10 * 60)
      }
      assertTimers(
        session, at: start.addingTimeInterval(12 * 60),
        expected: (isPause ? 13 : 10) * 60, countsDown: true)
      assertTimers(session, at: start.addingTimeInterval(26 * 60), expected: 0, countsDown: true)
    }
  }

  func testGivenExpiredTimer_WhenSessionIsStillActive_ThenEverySurfaceStaysAtZero() {
    let session = makeSession(strategy: QRTimerBlockingStrategy.id)
    for minutes in [60.0, 61.0, 90.0] {
      assertTimers(
        session, at: start.addingTimeInterval(minutes * 60), expected: 0, countsDown: true)
      XCTAssertNotNil(
        entry(for: session, at: start.addingTimeInterval(minutes * 60)).sessionEndTime)
    }
  }

  func testGivenOtherSelectedProfileOrEndedSession_WhenDisplayingWidget_ThenNoTimer() {
    let session = makeSession()
    session.endTime = start.addingTimeInterval(60)
    var widget = entry(for: session, at: start.addingTimeInterval(60))
    XCTAssertNil(widget.timer)

    session.endTime = nil
    let other = makeSession()
    widget = ProfileWidgetEntry(
      date: start, selectedProfileId: other.blockedProfile.id.uuidString, profileName: "Other",
      activeSession: WidgetSessionInfo(session: session), profileInfo: nil,
      deepLinkURL: nil, focusMessage: "", useProfileURL: false)
    XCTAssertNil(widget.timer)
  }

  func testGivenCountdownNearExpiry_WhenBuildingTimeline_ThenZeroEntryIsIncluded() {
    let session = makeSession(strategy: QRTimerBlockingStrategy.id)
    let now = start.addingTimeInterval(59 * 60 + 30)
    let entries = entry(for: session, at: now).timeline().entries
    XCTAssertEqual(entries.map(\.date), [now, start.addingTimeInterval(60 * 60)])
    XCTAssertEqual(entries.last?.timer?.displayedTime(at: entries.last!.date), 0)
    XCTAssertEqual(entries.last?.timer?.countsDown, true)
  }

  func testGivenLongPause_WhenBuildingTimeline_ThenMinuteLabelsKeepUpdating() {
    let session = makeSession(strategy: NFCPauseTimerBlockingStrategy.id)
    session.blockedProfile.strategyData = StrategyPauseTimerData.toData(
      from: StrategyPauseTimerData(pauseDurationInMinutes: 120))
    session.pauseStartTime = start.addingTimeInterval(17)
    let now = start.addingTimeInterval(10 * 60)
    let entries = entry(for: session, at: now).timeline().entries
    XCTAssertEqual(entries.count, 6)
    XCTAssertEqual(entries[1].date, now.addingTimeInterval(17))
    XCTAssertEqual(entries[1].timer?.displayedTime(at: entries[1].date), 110 * 60)
  }

  func testGivenFocusAfterBreak_WhenBuildingTimeline_ThenUseAdjustedMinuteBoundaries() {
    let session = makeSession()
    session.breakStartTime = start.addingTimeInterval(60)
    session.breakEndTime = start.addingTimeInterval(137)
    let now = start.addingTimeInterval(70 * 60)
    let entries = entry(for: session, at: now).timeline().entries
    XCTAssertEqual(entries[1].date, now.addingTimeInterval(17))
    XCTAssertEqual(entries[1].timer?.displayedTime(at: entries[1].date), 69 * 60)
  }

  private func makeSession(strategy: String = ManualBlockingStrategy.id) -> BlockedProfileSession {
    let profile = BlockedProfiles(
      name: "Focus", blockingStrategyId: strategy,
      strategyData: StrategyTimerData.toData(
        from: StrategyTimerData(durationInMinutes: 60, hideStopButton: false)),
      enableBreaks: true, breakTimeInMinutes: 15)
    let session = BlockedProfileSession(tag: strategy, blockedProfile: profile)
    session.startTime = start
    return session
  }

  private func entry(for session: BlockedProfileSession, at date: Date) -> ProfileWidgetEntry {
    ProfileWidgetEntry(
      date: date, selectedProfileId: session.blockedProfile.id.uuidString, profileName: "Focus",
      activeSession: WidgetSessionInfo(session: session), profileInfo: nil,
      deepLinkURL: nil, focusMessage: "", useProfileURL: false)
  }

  private func assertTimers(
    _ session: BlockedProfileSession, at date: Date, expected: TimeInterval, countsDown: Bool,
    file: StaticString = #filePath, line: UInt = #line
  ) {
    let liveActivity = LiveActivityManager.makeContentState(for: session)
    let widget = entry(for: session, at: date)
    XCTAssertEqual(
      SessionTimeCalculator.displayedTime(for: session, at: date), expected, accuracy: 0.001,
      file: file, line: line)
    XCTAssertEqual(liveActivity.timer.countsDown, countsDown, file: file, line: line)
    XCTAssertEqual(widget.timer?.countsDown, countsDown, file: file, line: line)
    XCTAssertEqual(liveActivity.timer.displayedTime(at: date), expected, file: file, line: line)
    XCTAssertEqual(widget.timer?.displayedTime(at: date), expected, file: file, line: line)
  }
}
