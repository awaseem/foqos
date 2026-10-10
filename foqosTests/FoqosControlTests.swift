import SwiftData
import XCTest

@testable import foqos

@MainActor
final class FoqosControlTests: ModelRegressionTestCase {
  private var manager: StrategyManager!

  override func setUpWithError() throws {
    try super.setUpWithError()
    manager = StrategyManager()
  }

  override func tearDownWithError() throws {
    manager.stopTimer()
    manager = nil
    try super.tearDownWithError()
  }

  func testStartAndStopPersistAndRepeatedValuesAreIdempotent() throws {
    let profile = try makeProfile()
    XCTAssertTrue(
      try manager.setProfileActiveFromControl(true, profileID: profile.id, context: context))
    let session = try XCTUnwrap(BlockedProfileSession.mostRecentActiveSession(in: context))
    XCTAssertFalse(
      try manager.setProfileActiveFromControl(true, profileID: profile.id, context: context))
    XCTAssertEqual(BlockedProfileSession.mostRecentActiveSession(in: context)?.id, session.id)
    XCTAssertTrue(controlState.isProfileActive(profile.id.uuidString))
    XCTAssertNotNil(try BlockedProfileSession.findSession(byID: session.id, in: freshContext()))

    try manager.setProfileActiveFromControl(false, profileID: profile.id, context: context)
    try manager.setProfileActiveFromControl(false, profileID: profile.id, context: context)
    XCTAssertNotNil(session.endTime)
    XCTAssertFalse(controlState.isProfileActive(profile.id.uuidString))
    XCTAssertNotNil(
      try BlockedProfileSession.findSession(byID: session.id, in: freshContext())?.endTime
    )
  }

  func testAnotherProfileCannotReplaceOrStopTheCurrentSession() throws {
    let session = try makeSession()
    let other = try makeProfile(name: "Reading")
    XCTAssertThrowsError(
      try manager.setProfileActiveFromControl(true, profileID: other.id, context: context)
    ) { XCTAssertEqual($0 as? FoqosControlError, .anotherProfileActive) }
    try manager.setProfileActiveFromControl(false, profileID: other.id, context: context)
    XCTAssertNil(session.endTime)
    XCTAssertEqual(SharedData.getActiveSharedSession()?.id, session.id)
  }

  func testDisabledBackgroundStopLeavesSessionAndBreakIntact() throws {
    let session = try makeSession()
    session.blockedProfile.disableBackgroundStops = true
    session.startBreak()
    try context.save()
    XCTAssertThrowsError(
      try manager.setProfileActiveFromControl(
        false, profileID: session.blockedProfile.id, context: context
      )
    ) { XCTAssertEqual($0 as? FoqosControlError, .backgroundStopDisabled) }
    XCTAssertNil(session.endTime)
    XCTAssertTrue(session.isBreakActive)
  }

  func testStaleFamilyStopCannotEndReplacementSessionForSameProfile() throws {
    let session = try makeSession()
    XCTAssertThrowsError(
      try manager.setProfileActiveFromControl(
        false, profileID: session.blockedProfile.id, context: context,
        expectedSessionID: "old-family-session")
    ) { XCTAssertEqual($0 as? FoqosControlError, .sessionChanged) }
    XCTAssertNil(session.endTime)
    try manager.setProfileActiveFromControl(
      false, profileID: session.blockedProfile.id, context: context, expectedSessionID: session.id)
    XCTAssertNotNil(session.endTime)
  }

  func testDeletedProfileReturnsAnError() {
    XCTAssertThrowsError(
      try manager.setProfileActiveFromControl(true, profileID: UUID(), context: context)
    ) { XCTAssertEqual($0 as? FoqosControlError, .profileUnavailable) }
  }

  func testBreakControlStartsAndEndsWithoutEndingTheProfile() throws {
    let session = try makeSession()
    var scheduleCount = 0
    for _ in 0..<2 {
      try manager.setBreakActiveFromControl(true, sessionID: session.id, context: context) {
        _, duration in
        scheduleCount += 1
        XCTAssertEqual(duration, 600)
      }
    }
    XCTAssertEqual(scheduleCount, 1)
    XCTAssertTrue(controlState.isBreakActive)
    XCTAssertTrue(controlState.isProfileActive(session.blockedProfile.id.uuidString))

    try manager.setBreakActiveFromControl(false, sessionID: session.id, context: context)
    try manager.setBreakActiveFromControl(false, sessionID: session.id, context: context)
    XCTAssertFalse(controlState.isBreakActive)
    XCTAssertTrue(controlState.isProfileActive(session.blockedProfile.id.uuidString))
  }

  func testStaleBreakControlCannotAffectAReplacementSession() throws {
    let session = try makeSession()
    for desiredState in [true, false] {
      XCTAssertThrowsError(
        try manager.setBreakActiveFromControl(
          desiredState, sessionID: "previous-session", context: context
        )
      ) { XCTAssertEqual($0 as? FoqosControlError, .sessionChanged) }
    }
    XCTAssertNil(session.breakStartTime)
    XCTAssertNil(session.endTime)
  }

  func testBreakControlEnforcesAllowanceAndEnabledSetting() throws {
    let session = try makeSession()
    session.blockedProfile.enableBreaks = false
    XCTAssertThrowsError(
      try manager.setBreakActiveFromControl(true, sessionID: session.id, context: context)
    ) { XCTAssertEqual($0 as? BreakSessionError, .breaksUnavailable(profileName: "Work")) }

    session.blockedProfile.enableBreaks = true
    session.usedBreakDurationInSeconds = 600
    SharedData.createActiveSharedSession(for: session.toSnapshot())
    try context.save()
    XCTAssertThrowsError(
      try manager.setBreakActiveFromControl(true, sessionID: session.id, context: context)
    ) { XCTAssertEqual($0 as? BreakSessionError, .allowanceExhausted(profileName: "Work")) }
    XCTAssertNil(session.breakStartTime)
  }

  func testBreakControlRequiresAnActiveSession() throws {
    XCTAssertThrowsError(
      try manager.setBreakActiveFromControl(true, sessionID: "", context: context)
    ) { XCTAssertEqual($0 as? BreakSessionError, .noActiveSession) }
    try manager.setBreakActiveFromControl(false, sessionID: "", context: context)
  }

  func testStateReadsExtensionChangesAndIgnoresCompletedSessions() throws {
    let session = try makeSession()
    SharedData.setBreakStartTime(date: Date())
    XCTAssertTrue(controlState.isBreakActive)
    SharedData.setBreakEndTime(date: Date())
    XCTAssertFalse(controlState.isBreakActive)
    XCTAssertTrue(controlState.isProfileActive(session.blockedProfile.id.uuidString))
    SharedData.setEndTime(date: Date())
    XCTAssertFalse(controlState.isProfileActive(session.blockedProfile.id.uuidString))
    XCTAssertFalse(controlState.isBreakActive)
    XCTAssertFalse(controlState.isProfileActive(nil))
    XCTAssertFalse(controlState.isProfileActive("invalid"))
  }

  private var controlState: FoqosControlState {
    FoqosControlState(session: SharedData.getActiveSharedSession())
  }

  private func makeProfile(name: String = "Work") throws -> BlockedProfiles {
    let profile = BlockedProfiles(
      name: name, blockingStrategyId: ManualBlockingStrategy.id,
      enableLiveActivity: false, enableBreaks: true, breakTimeInMinutes: 10,
      allowMultipleBreaks: true
    )
    context.insert(profile)
    try context.save()
    return profile
  }

  private func makeSession() throws -> BlockedProfileSession {
    let profile = try makeProfile()
    let session = BlockedProfileSession.createSession(
      in: context, withTag: ManualBlockingStrategy.id, withProfile: profile
    )
    try context.save()
    return session
  }
}
