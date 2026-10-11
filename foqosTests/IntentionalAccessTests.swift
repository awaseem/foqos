import XCTest

@testable import foqos

final class IntentionalAccessTests: ModelRegressionTestCase {
  func testConfigurationRoundTripAndRejectInvalidSettings() throws {
    var config = IntentionalAccessConfiguration()
    XCTAssertTrue(config.isValid)
    let data = try JSONEncoder().encode(config)
    XCTAssertEqual(IntentionalAccessConfiguration.decode(data), config)
    XCTAssertEqual(SoftUnblockStrategyData.decode(data).accessDurationInMinutes, 5)
    XCTAssertNil(IntentionalAccessConfiguration.decode(Data("invalid".utf8)))
    for invalid in [0, 4, 61, Int.max] {
      config.accessDurationInMinutes = invalid
      XCTAssertFalse(config.isValid)
    }
    config = .init()
    config.prompt = "  "
    XCTAssertFalse(config.isValid)
    config.prompt = String(repeating: "x", count: 501)
    XCTAssertFalse(config.isValid)
  }

  @MainActor
  func testStopRemainsVisibleAndStrategyDoesNotRequirePhysicalItem() {
    let profile = BlockedProfiles(
      name: "Intentional", blockingStrategyId: IntentionalAccessBlockingStrategy.id)
    XCTAssertTrue(profile.showStopButton(elapsedTime: 0))
    let strategy = StrategyManager.getStrategyFromId(id: IntentionalAccessBlockingStrategy.id)
    XCTAssertEqual(strategy.getIdentifier(), IntentionalAccessBlockingStrategy.id)
    XCTAssertTrue(strategy.supportsSessionControls)
    XCTAssertFalse(strategy.usesNFC)
    XCTAssertFalse(strategy.usesQRCode)
    XCTAssertFalse(strategy.allowsTimedBreaks)
    XCTAssertEqual(StrategyStartSettingsKind(strategy: strategy), .intentionalAccess)
  }

  func testIntentionalProfileCannotEnableUnsupportedMacSync() {
    let draft = BlockedProfileDraft()
    draft.enableMacSync = true
    draft.selectedStrategy = IntentionalAccessBlockingStrategy()
    XCTAssertFalse(draft.enableMacSync)
    let profile = BlockedProfiles(
      name: "Intentional",
      blockingStrategyId: IntentionalAccessBlockingStrategy.id, enableMacSync: true)
    XCTAssertFalse(BlockedProfileDraft(profile: profile).enableMacSync)
  }

  func testLifecycleInitializesAndEndsTemporaryAllowance() throws {
    let handler = SoftUnblockSessionLifecycleHandler(
      stopAllScheduledGrants: {}, stopScheduledGrantsForSession: { _ in })
    let profileID = UUID()
    let context = BlockingSessionLifecycleContext(
      strategyId: "IntentionalAccessBlockingStrategy",
      strategyData: try JSONEncoder().encode(IntentionalAccessConfiguration()),
      sessionId: UUID().uuidString,
      profileId: profileID, startedAt: Date())
    handler.sessionDidStart(context)
    XCTAssertEqual(SoftUnblockGrantStore.activeSession?.profileId, profileID)
    XCTAssertEqual(SoftUnblockGrantStore.activeSession?.maximumUnblockCount, 10)
    handler.sessionDidEnd(context)
    XCTAssertNil(SoftUnblockGrantStore.activeSession)
  }
  func testBackgroundStartPersistsDefaultsBeforeInitializingAllowance() throws {
    let profile = BlockedProfiles(
      name: "Intentional", blockingStrategyId: IntentionalAccessBlockingStrategy.id)
    context.insert(profile)
    try context.save()
    let manager = StrategyManager()
    defer { manager.stopTimer() }
    XCTAssertTrue(
      try manager.setProfileActiveFromControl(true, profileID: profile.id, context: context))
    XCTAssertNotNil(profile.strategyData)
    XCTAssertEqual(SoftUnblockGrantStore.activeSession?.maximumUnblockCount, 10)
    XCTAssertEqual(SoftUnblockGrantStore.activeSession?.allowanceResetIntervalInHours, 6)
    XCTAssertTrue(
      try manager.setProfileActiveFromControl(false, profileID: profile.id, context: context))
  }

  func testBackgroundStartRejectsInvalidSettingsAndTimerOverride() throws {
    let profile = BlockedProfiles(
      name: "Intentional", blockingStrategyId: IntentionalAccessBlockingStrategy.id,
      strategyData: Data("invalid".utf8))
    context.insert(profile)
    try context.save()
    let manager = StrategyManager()
    defer { manager.stopTimer() }
    XCTAssertThrowsError(
      try manager.setProfileActiveFromControl(true, profileID: profile.id, context: context))
    XCTAssertNil(BlockedProfileSession.mostRecentActiveSession(in: context))
    profile.strategyData = nil
    manager.startSessionFromBackground(profile.id, context: context, durationInMinutes: 30)
    XCTAssertNotNil(manager.errorMessage)
    XCTAssertNil(profile.strategyData)
    XCTAssertNil(BlockedProfileSession.mostRecentActiveSession(in: context))
  }

  func testDirectStartRequiresSettingsThenUsesPreparedAllowance() throws {
    let profile = BlockedProfiles(
      name: "Intentional", blockingStrategyId: IntentionalAccessBlockingStrategy.id,
      askForStartSettings: false)
    context.insert(profile)
    try context.save()
    let strategy = IntentionalAccessBlockingStrategy()
    XCTAssertNotNil(strategy.startBlocking(context: context, profile: profile, forceStart: false))
    XCTAssertNil(BlockedProfileSession.mostRecentActiveSession(in: context))
    try IntentionalAccessBlockingStrategy.prepareForStart(profile: profile, context: context)
    _ = strategy.startBlocking(context: context, profile: profile, forceStart: false)
    XCTAssertNotNil(profile.strategyData)
    XCTAssertEqual(SoftUnblockGrantStore.activeSession?.maximumUnblockCount, 10)
    let session = try XCTUnwrap(BlockedProfileSession.mostRecentActiveSession(in: context))
    _ = strategy.stopBlocking(context: context, session: session)
  }

}
