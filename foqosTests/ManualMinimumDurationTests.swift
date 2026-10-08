import SwiftData
import XCTest

@testable import foqos

@MainActor
final class ManualMinimumDurationTests: ModelRegressionTestCase {
  func testMissingInvalidAndOtherStrategySettingsDefaultToOff() {
    for data in [nil, Data(), Data("{}".utf8), Data("{\"minimumDurationInMinutes\":-5}".utf8)] {
      XCTAssertEqual(ManualMinimumDuration.decode(data).seconds, 0)
    }
    XCTAssertEqual(
      ManualMinimumDuration.decode(StrategyTimerData.toData(from: .defaultConfiguration)).seconds, 0
    )
  }

  func testBoundaryUnlocksWithoutEndingSession() throws {
    let session = try makeSession()
    session.startTime = referenceDate
    XCTAssertEqual(session.minimumDurationRemaining(at: referenceDate.addingTimeInterval(299)), 1)
    XCTAssertEqual(session.minimumDurationRemaining(at: referenceDate.addingTimeInterval(300)), 0)
    XCTAssertEqual(session.minimumDurationRemaining(at: referenceDate.addingTimeInterval(3600)), 0)
    XCTAssertNil(session.endTime)
    XCTAssertNil(SharedData.getActiveSharedSession()?.endTime)
  }

  func testDurationIsPersistedAndDoesNotFollowProfileEdits() throws {
    let session = try makeSession()
    session.blockedProfile.strategyData = nil
    try context.save()
    let restored = try XCTUnwrap(
      BlockedProfileSession.findSession(byID: session.id, in: freshContext()))
    XCTAssertEqual(restored.minimumDurationInSeconds, 300)
    XCTAssertEqual(restored.startTime, session.startTime)

    let snapshot = try JSONDecoder().decode(
      SharedData.SessionSnapshot.self, from: JSONEncoder().encode(session.toSnapshot()))
    XCTAssertEqual(snapshot.minimumDurationInSeconds, 300)
    BlockedProfileSession.upsertSessionFromSnapshot(in: context, withSnapshot: snapshot)
    XCTAssertEqual(session.minimumDurationInSeconds, 300)

    var legacy = try XCTUnwrap(
      JSONSerialization.jsonObject(with: JSONEncoder().encode(snapshot)) as? [String: Any])
    legacy.removeValue(forKey: "minimumDurationInSeconds")
    let legacySnapshot = try JSONDecoder().decode(
      SharedData.SessionSnapshot.self, from: JSONSerialization.data(withJSONObject: legacy))
    XCTAssertNil(legacySnapshot.minimumDurationInSeconds)
  }

  func testMinimumSurvivesReopeningPersistentStore() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let configuration = ModelConfiguration(url: directory.appendingPathComponent("minimum.store"))
    let sessionID: String
    do {
      let store = try ModelContainer(
        for: BlockedProfileSession.self, BlockedProfiles.self, configurations: configuration)
      let writer = ModelContext(store)
      let profile = BlockedProfiles(
        name: "Persistent", blockingStrategyId: ManualBlockingStrategy.id)
      writer.insert(profile)
      let session = BlockedProfileSession.createSession(
        in: writer, withTag: ManualBlockingStrategy.id, withProfile: profile,
        minimumDurationInSeconds: 300)
      session.startTime = referenceDate
      sessionID = session.id
      try writer.save()
    }
    let reopened = try ModelContainer(
      for: BlockedProfileSession.self, BlockedProfiles.self, configurations: configuration)
    let restored = try XCTUnwrap(
      BlockedProfileSession.findSession(byID: sessionID, in: ModelContext(reopened)))
    XCTAssertEqual(restored.startTime, referenceDate)
    XCTAssertEqual(restored.minimumDurationInSeconds, 300)
    XCTAssertEqual(restored.minimumDurationRemaining(at: referenceDate.addingTimeInterval(299)), 1)
    XCTAssertNil(restored.endTime)
  }

  func testManualStopIsRejectedBeforeExpiryAndAllowedAfterwards() throws {
    let session = try makeSession()
    let strategy = ManualBlockingStrategy()
    var message: String?
    strategy.onErrorMessage = { message = $0 }
    _ = strategy.stopBlocking(context: context, session: session)
    XCTAssertNotNil(message)
    XCTAssertNil(session.endTime)
    XCTAssertEqual(SharedData.getActiveSharedSession()?.id, session.id)

    session.startTime = Date().addingTimeInterval(-301)
    _ = strategy.stopBlocking(context: context, session: session)
    XCTAssertNotNil(session.endTime)
    XCTAssertNil(SharedData.getActiveSharedSession())
  }

  func testBackgroundControlDeeplinkAndEmergencyCannotBypassMinimum() throws {
    let session = try makeSession()
    let manager = StrategyManager()
    defer { manager.stopTimer() }
    manager.loadActiveSession(context: context)
    manager.toggleBlocking(context: context, activeProfile: session.blockedProfile)
    XCTAssertNil(session.endTime)
    manager.stopSessionFromBackground(session.blockedProfile.id, context: context)
    XCTAssertNotNil(manager.errorMessage)
    XCTAssertNil(session.endTime)
    XCTAssertThrowsError(
      try manager.setProfileActiveFromControl(
        false, profileID: session.blockedProfile.id, context: context))
    let other = BlockedProfiles(name: "Other", blockingStrategyId: ManualBlockingStrategy.id)
    context.insert(other)
    try context.save()
    manager.toggleSessionFromDeeplink(
      other.id.uuidString, url: URL(string: "https://foqos.app")!, context: context)
    XCTAssertEqual(SharedData.getActiveSharedSession()?.id, session.id)
    let unblocks = manager.getRemainingEmergencyUnblocks()
    manager.emergencyUnblock(context: context)
    XCTAssertEqual(manager.getRemainingEmergencyUnblocks(), unblocks)
    XCTAssertNil(session.endTime)
  }

  func testExpiredBreakResetCannotBypassMinimum() throws {
    let session = try makeSession()
    session.minimumDurationInSeconds = 3600
    session.blockedProfile.enableBreaks = true
    session.blockedProfile.breakTimeInMinutes = 5
    session.breakStartTime = Date().addingTimeInterval(-600)
    SharedData.createActiveSharedSession(for: session.toSnapshot())
    let manager = StrategyManager()
    defer { manager.stopTimer() }
    manager.loadActiveSession(context: context)
    manager.resetExpiredCountdown(context: context)
    XCTAssertNotNil(manager.errorMessage)
    XCTAssertNil(session.endTime)
  }

  func testScheduleAndStaleTimerCannotAutomaticallyEndManualSession() throws {
    let session = try makeSession()
    // Even after the minimum expires, this session must be stopped explicitly.
    session.startTime = Date().addingTimeInterval(-301)
    SharedData.createActiveSharedSession(for: session.toSnapshot())
    let profile = BlockedProfiles.getSnapshot(for: session.blockedProfile)
    ScheduleTimerActivity().stop(for: profile)
    StrategyTimerActivity().stop(for: profile)
    XCTAssertEqual(SharedData.getActiveSharedSession()?.id, session.id)
    XCTAssertNil(SharedData.getActiveSharedSession()?.endTime)
  }

  func testManualStrategyCopiesSettingsAndDefaultRemainsOff() throws {
    let profile = BlockedProfiles(name: "Manual", blockingStrategyId: ManualBlockingStrategy.id)
    context.insert(profile)
    let strategy = ManualBlockingStrategy()
    _ = strategy.startBlocking(context: context, profile: profile, forceStart: false)
    let defaultSession = try XCTUnwrap(BlockedProfileSession.mostRecentActiveSession(in: context))
    XCTAssertEqual(defaultSession.minimumDurationInSeconds, 0)
    _ = strategy.stopBlocking(context: context, session: defaultSession)
    profile.strategyData = ManualMinimumDuration(minimumDurationInMinutes: 10).encode()
    _ = strategy.startBlocking(context: context, profile: profile, forceStart: true)
    let session = try XCTUnwrap(BlockedProfileSession.mostRecentActiveSession(in: context))
    XCTAssertEqual(session.minimumDurationInSeconds, 600)
    XCTAssertEqual(SharedData.getActiveSharedSession()?.minimumDurationInSeconds, 600)
  }

  private func makeSession() throws -> BlockedProfileSession {
    let profile = BlockedProfiles(name: "Work", blockingStrategyId: ManualBlockingStrategy.id)
    context.insert(profile)
    let session = BlockedProfileSession.createSession(
      in: context, withTag: ManualBlockingStrategy.id, withProfile: profile,
      minimumDurationInSeconds: 300)
    try context.save()
    return session
  }
}
