import XCTest

@testable import foqos

final class IntentionalAccessTests: XCTestCase {
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
}
