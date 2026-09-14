import SwiftData
import XCTest

@testable import foqos

final class BlockedProfileSessionRegressionTests: ModelRegressionTestCase {
  func testInitializerLinksSessionOnceAndSetsDefaults() throws {
    let profile = BlockedProfiles(name: "Focus")
    let before = Date()
    let session = BlockedProfileSession(tag: "tag", blockedProfile: profile)
    XCTAssertNotNil(UUID(uuidString: session.id))
    XCTAssertEqual(session.tag, "tag")
    XCTAssertEqual(profile.sessions.map(\.id), [session.id])
    XCTAssertTrue(session.blockedProfile === profile)
    XCTAssertGreaterThanOrEqual(session.startTime, before)
    XCTAssertTrue(session.isActive)
    XCTAssertFalse(session.forceStarted)
    XCTAssertFalse(session.isPauseActive)
    XCTAssertFalse(session.isBreakActive)
    XCTAssertEqual(session.usedBreakDurationInSeconds, 0)
    XCTAssertNil(session.endTime)
    XCTAssertNil(session.breakStartTime)
    XCTAssertNil(session.breakEndTime)
    XCTAssertNil(session.pauseStartTime)
    XCTAssertNil(session.pauseEndTime)
    context.insert(profile)
    context.insert(session)
    try context.save()
    let reader = freshContext()
    let fetched = try XCTUnwrap(BlockedProfileSession.findSession(byID: session.id, in: reader))
    XCTAssertEqual(fetched.blockedProfile.id, profile.id)
    XCTAssertEqual(fetched.blockedProfile.sessions.map(\.id), [session.id])
  }

  func testCreateAndEndSessionPublishStateAndInvokeTemporaryAccessLifecycle() throws {
    let profile = BlockedProfiles(
      name: "Temporary", blockingStrategyId: NFCSoftUnblockBlockingStrategy.id)
    context.insert(profile)
    let session = BlockedProfileSession.createSession(
      in: context, withTag: "shortcut", withProfile: profile, forceStart: true)
    XCTAssertTrue(context.hasChanges)
    XCTAssertTrue(session.forceStarted)
    XCTAssertEqual(SharedData.activeSharedSession, session.toSnapshot())
    XCTAssertEqual(SoftUnblockGrantStore.activeSession?.sessionId, session.id)
    XCTAssertEqual(SoftUnblockGrantStore.activeSession?.profileId, profile.id)
    try context.save()
    let before = Date()
    session.endSession()
    XCTAssertGreaterThanOrEqual(try XCTUnwrap(session.endTime), before)
    XCTAssertFalse(session.isActive)
    XCTAssertNil(SharedData.activeSharedSession)
    XCTAssertNil(SoftUnblockGrantStore.activeSession)
    try context.save()
    XCTAssertNotNil(
      try BlockedProfileSession.findSession(byID: session.id, in: freshContext())?.endTime)
  }

  func testSingleBreakTransitionsAndSharedState() {
    let session = makeSession(multiple: false)
    XCTAssertTrue(session.isBreakAvailable)
    XCTAssertEqual(session.totalBreakAllowanceInSeconds, 300)
    session.startBreak(at: referenceDate)
    XCTAssertTrue(session.isBreakActive)
    XCTAssertEqual(SharedData.activeSharedSession?.breakStartTime, referenceDate)
    XCTAssertEqual(session.activeBreakElapsedTime(at: referenceDate.addingTimeInterval(-10)), 0)
    XCTAssertEqual(
      session.usedBreakDurationIncludingActiveBreak(at: referenceDate.addingTimeInterval(90)), 90)
    XCTAssertEqual(session.remainingBreakAllowance(at: referenceDate.addingTimeInterval(90)), 210)
    session.endBreak(at: referenceDate.addingTimeInterval(120))
    XCTAssertFalse(session.isBreakActive)
    XCTAssertFalse(session.isBreakAvailable)
    XCTAssertEqual(session.totalBreakDuration, 120)
    XCTAssertEqual(session.usedBreakDurationInSeconds, 0)
    XCTAssertEqual(
      session.usedBreakDurationIncludingActiveBreak(at: referenceDate.addingTimeInterval(1000)), 120
    )
    XCTAssertEqual(SharedData.activeSharedSession?.breakEndTime, session.breakEndTime)
  }

  func testMultipleBreaksAccumulateResetTimestampsAndCapAllowance() {
    let session = makeSession(multiple: true)
    session.startBreak(at: referenceDate)
    session.endBreak(at: referenceDate.addingTimeInterval(120))
    XCTAssertEqual(session.usedBreakDurationInSeconds, 120)
    XCTAssertTrue(session.isBreakAvailable)
    session.startBreak(at: referenceDate.addingTimeInterval(200))
    XCTAssertNil(session.breakEndTime)
    XCTAssertNil(SharedData.activeSharedSession?.breakEndTime)
    XCTAssertEqual(session.remainingBreakAllowance(at: referenceDate.addingTimeInterval(260)), 120)
    session.endBreak(at: referenceDate.addingTimeInterval(1000))
    XCTAssertEqual(session.usedBreakDurationInSeconds, 300)
    XCTAssertEqual(SharedData.activeSharedSession?.usedBreakDurationInSeconds, 300)
    XCTAssertEqual(session.remainingBreakAllowance(), 0)
    XCTAssertFalse(session.isBreakAvailable)
    session.endBreak(at: referenceDate.addingTimeInterval(1100))
    XCTAssertEqual(session.usedBreakDurationInSeconds, 300)
  }

  func testBreaksRequireEnabledSettingAndCompatibleStrategy() {
    let session = makeSession(multiple: true)
    session.breakStartTime = referenceDate
    session.blockedProfile.enableBreaks = false
    XCTAssertFalse(session.isBreakAvailable)
    XCTAssertFalse(session.isBreakActive)
    XCTAssertEqual(session.activeBreakElapsedTime(at: referenceDate.addingTimeInterval(60)), 0)
    session.blockedProfile.enableBreaks = true
    session.blockedProfile.blockingStrategyId = QRSoftUnblockBlockingStrategy.id
    XCTAssertFalse(session.isBreakAvailable)
    XCTAssertFalse(session.isBreakActive)
  }

  func testTotalBreakDurationKeepsHistoryWhenSettingsChangeAndSessionEndsMidBreak() {
    let session = makeSession(multiple: true)
    session.usedBreakDurationInSeconds = 120
    session.breakStartTime = referenceDate
    XCTAssertEqual(session.totalBreakDuration, 120)
    session.endTime = referenceDate.addingTimeInterval(30)
    XCTAssertEqual(session.totalBreakDuration, 150)
    session.blockedProfile.allowMultipleBreaks = false
    session.blockedProfile.enableBreaks = false
    XCTAssertEqual(session.totalBreakDuration, 150)
    session.breakEndTime = referenceDate.addingTimeInterval(30)
    XCTAssertEqual(session.totalBreakDuration, 120)
    session.usedBreakDurationInSeconds = 0
    XCTAssertEqual(session.totalBreakDuration, 30)
    session.breakEndTime = referenceDate.addingTimeInterval(-20)
    session.usedBreakDurationInSeconds = -10
    XCTAssertEqual(session.totalBreakDuration, 0)
  }

  func testPauseTransitionsUpdateSharedStateAndSnapshot() throws {
    let session = makeSession(multiple: false)
    session.startPause()
    XCTAssertTrue(session.isPauseActive)
    XCTAssertEqual(SharedData.activeSharedSession?.pauseStartTime, session.pauseStartTime)
    session.endPause()
    XCTAssertFalse(session.isPauseActive)
    XCTAssertEqual(SharedData.activeSharedSession?.pauseEndTime, session.pauseEndTime)
    XCTAssertGreaterThanOrEqual(
      try XCTUnwrap(session.pauseEndTime), try XCTUnwrap(session.pauseStartTime))
    XCTAssertEqual(session.toSnapshot().pauseStartTime, session.pauseStartTime)
    XCTAssertEqual(session.toSnapshot().pauseEndTime, session.pauseEndTime)
  }

  func testDurationUsesRecordedEndOrCurrentTime() {
    let session = makeSession(multiple: false)
    session.startTime = Date().addingTimeInterval(-60)
    XCTAssertEqual(session.duration, 60, accuracy: 1)
    session.startTime = referenceDate
    session.endTime = referenceDate.addingTimeInterval(1234)
    XCTAssertEqual(session.duration, 1234)
    XCTAssertFalse(session.isActive)
  }

  func testSnapshotInsertUpdateAndLegacyMissingAccumulatorPreserveEveryField() throws {
    let profile = BlockedProfiles(name: "Focus")
    context.insert(profile)
    try context.save()
    var snapshot = sessionSnapshot(profileID: profile.id)
    BlockedProfileSession.upsertSessionFromSnapshot(in: context, withSnapshot: snapshot)
    XCTAssertTrue(context.hasChanges)
    try context.save()
    var reader = freshContext()
    let inserted = try XCTUnwrap(BlockedProfileSession.findSession(byID: snapshot.id, in: reader))
    XCTAssertEqual(inserted.toSnapshot(), snapshot)
    XCTAssertEqual(inserted.blockedProfile.sessions.map(\.id), [snapshot.id])
    snapshot.tag = "updated"
    snapshot.startTime = referenceDate.addingTimeInterval(10)
    snapshot.endTime = nil
    snapshot.breakStartTime = nil
    snapshot.breakEndTime = nil
    snapshot.usedBreakDurationInSeconds = nil
    snapshot.pauseStartTime = nil
    snapshot.pauseEndTime = nil
    snapshot.forceStarted = false
    BlockedProfileSession.upsertSessionFromSnapshot(in: context, withSnapshot: snapshot)
    reader = freshContext()
    let updated = try XCTUnwrap(BlockedProfileSession.findSession(byID: snapshot.id, in: reader))
    snapshot.usedBreakDurationInSeconds = 0
    XCTAssertEqual(updated.toSnapshot(), snapshot)
    XCTAssertEqual(try reader.fetchCount(FetchDescriptor<BlockedProfileSession>()), 1)
    XCTAssertFalse(context.hasChanges)
  }

  func testLegacySnapshotInsertDefaultsMissingBreakAccumulatorToZero() throws {
    let profile = BlockedProfiles(name: "Legacy")
    context.insert(profile)
    var snapshot = sessionSnapshot(profileID: profile.id)
    snapshot.usedBreakDurationInSeconds = nil
    BlockedProfileSession.upsertSessionFromSnapshot(in: context, withSnapshot: snapshot)
    try context.save()
    XCTAssertEqual(
      try BlockedProfileSession.findSession(byID: snapshot.id, in: freshContext())?
        .usedBreakDurationInSeconds, 0)
  }

  func testSnapshotForMissingProfileDoesNotInsertOrModifyExistingSession() throws {
    let session = makeSession(multiple: false)
    context.insert(session.blockedProfile)
    context.insert(session)
    try context.save()
    var snapshot = sessionSnapshot(profileID: UUID())
    snapshot.id = session.id
    BlockedProfileSession.upsertSessionFromSnapshot(in: context, withSnapshot: snapshot)
    XCTAssertEqual(session.tag, "test")
    snapshot.id = "missing-profile"
    BlockedProfileSession.upsertSessionFromSnapshot(in: context, withSnapshot: snapshot)
    XCTAssertEqual(try context.fetchCount(FetchDescriptor<BlockedProfileSession>()), 1)
    XCTAssertNil(try BlockedProfileSession.findSession(byID: snapshot.id, in: context))
  }

  func testActiveAndInactiveQueriesUseCorrectDatesFilteringAndLimit() throws {
    XCTAssertNil(BlockedProfileSession.mostRecentActiveSession(in: context))
    XCTAssertTrue(BlockedProfileSession.recentInactiveSessions(in: context).isEmpty)
    let profile = BlockedProfiles(name: "History")
    context.insert(profile)
    for index in 0..<5 {
      let session = BlockedProfileSession(tag: "\(index)", blockedProfile: profile)
      session.startTime = referenceDate.addingTimeInterval(Double(index * 100))
      if index < 3 {
        session.endTime = referenceDate.addingTimeInterval(Double(1000 - index * 100))
      }
      context.insert(session)
    }
    try context.save()
    let reader = freshContext()
    XCTAssertEqual(BlockedProfileSession.mostRecentActiveSession(in: reader)?.tag, "4")
    XCTAssertEqual(
      BlockedProfileSession.recentInactiveSessions(in: reader).map(\.tag), ["0", "1", "2"])
    XCTAssertEqual(
      BlockedProfileSession.recentInactiveSessions(in: reader, limit: 2).map(\.tag), ["0", "1"])
  }

  private func makeSession(multiple: Bool) -> BlockedProfileSession {
    let profile = BlockedProfiles(
      name: "Focus", blockingStrategyId: ManualBlockingStrategy.id,
      enableBreaks: true, breakTimeInMinutes: 5, allowMultipleBreaks: multiple)
    let session = BlockedProfileSession(tag: "test", blockedProfile: profile)
    SharedData.createActiveSharedSession(for: session.toSnapshot())
    return session
  }
}
