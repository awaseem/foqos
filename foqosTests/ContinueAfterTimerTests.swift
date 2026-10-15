import SwiftData
import XCTest

@testable import foqos

@MainActor
final class ContinueAfterTimerTests: ModelRegressionTestCase {
  func testLegacySettingsKeepTheirDurationAndStopOption() throws {
    let legacy = Data("{\"durationInMinutes\":30,\"hideStopButton\":true}".utf8)
    let settings = StrategyTimerData.decode(legacy)
    XCTAssertEqual(settings.durationInMinutes, 30)
    XCTAssertTrue(settings.hideStopButton)
    XCTAssertNotEqual(settings.continueAfterTimer, true)
    XCTAssertNotEqual(StrategyTimerData.decode(nil).continueAfterTimer, true)
  }

  func testCountdownTransitionsAtExpiryWithoutEndingSession() throws {
    let session = try makeSession(continues: true)
    let end = referenceDate.addingTimeInterval(900)
    XCTAssertFalse(
      SessionTimeCalculator.isContinuingAfterTimer(session, at: end.addingTimeInterval(-1)))
    XCTAssertEqual(
      SessionTimeCalculator.displayedTime(for: session, at: end.addingTimeInterval(-1)), 1)
    XCTAssertTrue(SessionTimeCalculator.isContinuingAfterTimer(session, at: end))
    XCTAssertEqual(SessionTimeCalculator.displayedTime(for: session, at: end), 900)
    XCTAssertFalse(
      SessionTimeCalculator.isCountdownExpired(for: session, at: end.addingTimeInterval(3600)))
    XCTAssertFalse(
      SessionTimeCalculator.isCountdownReloadDue(for: session, at: end.addingTimeInterval(3600)))
    XCTAssertFalse(session.blockedProfile.showStopButton(elapsedTime: 899))
    XCTAssertTrue(session.blockedProfile.showStopButton(elapsedTime: 900))
    XCTAssertNil(session.endTime)
  }

  func testTimerCallbackKeepsSessionUntilExplicitStop() throws {
    let session = try makeSession(continues: true)
    StrategyTimerActivity().stop(for: BlockedProfiles.getSnapshot(for: session.blockedProfile))
    XCTAssertEqual(SharedData.getActiveSharedSession()?.id, session.id)
    XCTAssertNil(session.endTime)
    _ = ShortcutTimerBlockingStrategy().stopBlocking(context: context, session: session)
    XCTAssertNotNil(session.endTime)
    XCTAssertNil(SharedData.getActiveSharedSession())
  }

  func testDefaultTimerStillEndsAutomatically() throws {
    let session = try makeSession(continues: false)
    XCTAssertTrue(
      SessionTimeCalculator.isCountdownExpired(
        for: session, at: referenceDate.addingTimeInterval(1000)))
    StrategyTimerActivity().stop(for: BlockedProfiles.getSnapshot(for: session.blockedProfile))
    XCTAssertNil(SharedData.getActiveSharedSession())
  }

  func testSettingAndTransitionSurviveReload() throws {
    let session = try makeSession(continues: true)
    let restored = try XCTUnwrap(
      BlockedProfileSession.findSession(byID: session.id, in: freshContext()))
    XCTAssertTrue(
      SessionTimeCalculator.isContinuingAfterTimer(
        restored, at: referenceDate.addingTimeInterval(900)))
    let snapshot = try XCTUnwrap(SharedData.snapshot(for: session.blockedProfile.id.uuidString))
    XCTAssertEqual(StrategyTimerData.decode(snapshot.strategyData).continueAfterTimer, true)
    XCTAssertNil(restored.endTime)
  }

  func testBreakStillHasItsOwnCountdownAfterTimerExpires() throws {
    let session = try makeSession(continues: true)
    session.blockedProfile.enableBreaks = true
    session.breakStartTime = referenceDate.addingTimeInterval(900)
    XCTAssertEqual(
      SessionTimeCalculator.displayedTime(for: session, at: referenceDate.addingTimeInterval(960)),
      840)
    session.breakEndTime = referenceDate.addingTimeInterval(1800)
    XCTAssertNil(
      SessionTimeCalculator.expectedEndTime(
        for: session, at: referenceDate.addingTimeInterval(1800)))
    XCTAssertTrue(
      SessionTimeCalculator.isContinuingAfterTimer(
        session, at: referenceDate.addingTimeInterval(1800)))
  }

  private func makeSession(continues: Bool) throws -> BlockedProfileSession {
    let profile = BlockedProfiles(
      name: "Timer", blockingStrategyId: ShortcutTimerBlockingStrategy.id,
      strategyData: StrategyTimerData.toData(
        from: StrategyTimerData(
          durationInMinutes: 15, hideStopButton: true, continueAfterTimer: continues)))
    context.insert(profile)
    BlockedProfiles.updateSnapshot(for: profile)
    let session = BlockedProfileSession.createSession(
      in: context, withTag: ShortcutTimerBlockingStrategy.id, withProfile: profile)
    session.startTime = referenceDate
    SharedData.createActiveSharedSession(for: session.toSnapshot())
    try context.save()
    return session
  }
}
