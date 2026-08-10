import DeviceActivity
import XCTest

@testable import foqos

final class SoftUnblockTests: XCTestCase {
  func testStrategyConfigurationRoundTrips() {
    let configuration = SoftUnblockStrategyData(
      accessDurationInMinutes: 30,
      maximumUnblockCount: 6,
      allowanceResetIntervalInHours: 12
    )
    let encoded = SoftUnblockStrategyData.encode(configuration)

    XCTAssertEqual(SoftUnblockStrategyData.decode(encoded), configuration)
  }

  func testStrategyConfigurationFallsBackForMissingData() {
    let configuration = SoftUnblockStrategyData.decode(nil)

    XCTAssertEqual(
      configuration.accessDurationInMinutes,
      SoftUnblockStrategyData.defaultDurationInMinutes
    )
    XCTAssertEqual(
      configuration.maximumUnblockCount,
      SoftUnblockStrategyData.defaultMaximumUnblockCount
    )
    XCTAssertNil(configuration.allowanceResetIntervalInHours)
  }

  func testLifecycleRegistryBeginsSessionWithDefaultConfiguration() {
    SoftUnblockGrantStore.clearAll()
    defer { SoftUnblockGrantStore.clearAll() }

    let profileId = UUID()
    let sessionId = UUID().uuidString
    let startedAt = Date(timeIntervalSince1970: 1_000_000)
    let context = BlockingSessionLifecycleContext(
      strategyId: SoftUnblockSessionLifecycleHandler.nfcStrategyId,
      strategyData: nil,
      sessionId: sessionId,
      profileId: profileId,
      startedAt: startedAt
    )
    BlockingSessionLifecycleRegistry.sessionDidStart(context)

    let session = SoftUnblockGrantStore.currentSession(at: startedAt)
    XCTAssertEqual(session?.sessionId, sessionId)
    XCTAssertEqual(session?.profileId, profileId)
    XCTAssertEqual(
      session?.maximumUnblockCount,
      SoftUnblockStrategyData.defaultMaximumUnblockCount
    )
    XCTAssertEqual(session?.allowanceWindowStartedAt, startedAt)
    XCTAssertNil(session?.allowanceResetIntervalInHours)
  }

  func testLifecycleRegistryBeginsSessionWithSavedConfiguration() {
    SoftUnblockGrantStore.clearAll()
    defer { SoftUnblockGrantStore.clearAll() }

    let configuration = SoftUnblockStrategyData(
      accessDurationInMinutes: 30,
      maximumUnblockCount: 6,
      allowanceResetIntervalInHours: 12
    )
    let startedAt = Date(timeIntervalSince1970: 1_000_000)

    BlockingSessionLifecycleRegistry.sessionDidStart(
      BlockingSessionLifecycleContext(
        strategyId: SoftUnblockSessionLifecycleHandler.qrStrategyId,
        strategyData: SoftUnblockStrategyData.encode(configuration),
        sessionId: UUID().uuidString,
        profileId: UUID(),
        startedAt: startedAt
      )
    )

    let session = SoftUnblockGrantStore.currentSession(at: startedAt)
    XCTAssertEqual(session?.maximumUnblockCount, configuration.maximumUnblockCount)
    XCTAssertEqual(
      session?.allowanceResetIntervalInHours,
      configuration.allowanceResetIntervalInHours
    )
    XCTAssertEqual(
      session?.nextAllowanceResetAt,
      startedAt.addingTimeInterval(12 * 60 * 60)
    )
  }

  func testLifecycleRegistryClearsTemporaryAccessStateForAnotherStrategy() {
    SoftUnblockGrantStore.clearAll()
    defer { SoftUnblockGrantStore.clearAll() }

    BlockingSessionLifecycleRegistry.sessionDidStart(
      BlockingSessionLifecycleContext(
        strategyId: SoftUnblockSessionLifecycleHandler.nfcStrategyId,
        strategyData: nil,
        sessionId: UUID().uuidString,
        profileId: UUID(),
        startedAt: Date()
      )
    )
    XCTAssertNotNil(SoftUnblockGrantStore.activeSession)

    BlockingSessionLifecycleRegistry.sessionDidStart(
      BlockingSessionLifecycleContext(
        strategyId: ManualBlockingStrategy.id,
        strategyData: nil,
        sessionId: UUID().uuidString,
        profileId: UUID(),
        startedAt: Date()
      )
    )

    XCTAssertNil(SoftUnblockGrantStore.activeSession)
  }

  func testTemporaryAccessLifecycleHandlerEndsMatchingSession() {
    SoftUnblockGrantStore.clearAll()
    defer { SoftUnblockGrantStore.clearAll() }

    let sessionId = UUID().uuidString
    var stoppedSessionId: String?
    let context = BlockingSessionLifecycleContext(
      strategyId: SoftUnblockSessionLifecycleHandler.nfcStrategyId,
      strategyData: nil,
      sessionId: sessionId,
      profileId: UUID(),
      startedAt: Date()
    )
    let handler = SoftUnblockSessionLifecycleHandler(
      stopAllScheduledGrants: {},
      stopScheduledGrantsForSession: { stoppedSessionId = $0 }
    )
    handler.sessionDidStart(context)

    handler.sessionDidEnd(context)

    XCTAssertEqual(stoppedSessionId, sessionId)
    XCTAssertNil(SoftUnblockGrantStore.activeSession)
  }

  func testAllowanceDoesNotResetBeforeBoundary() {
    let start = Date(timeIntervalSince1970: 1_000_000)
    var session = makeSession(startedAt: start, resetHours: 6, usedUnblocks: 2)

    XCTAssertFalse(
      session.resetAllowanceIfNeeded(at: start.addingTimeInterval((6 * 60 * 60) - 1))
    )
    XCTAssertEqual(session.usedUnblockCount, 2)
  }

  func testAllowanceResetsAtBoundary() {
    let start = Date(timeIntervalSince1970: 1_000_000)
    var session = makeSession(startedAt: start, resetHours: 6, usedUnblocks: 2)
    let boundary = start.addingTimeInterval(6 * 60 * 60)

    XCTAssertTrue(session.resetAllowanceIfNeeded(at: boundary))
    XCTAssertEqual(session.usedUnblockCount, 0)
    XCTAssertEqual(session.allowanceWindowStartedAt, boundary)
    XCTAssertEqual(session.nextAllowanceResetAt, boundary.addingTimeInterval(6 * 60 * 60))
  }

  func testAllowanceAdvancesAcrossMissedWindows() {
    let start = Date(timeIntervalSince1970: 1_000_000)
    var session = makeSession(startedAt: start, resetHours: 6, usedUnblocks: 2)
    let currentDate = start.addingTimeInterval((19 * 60 * 60) + 10)

    XCTAssertTrue(session.resetAllowanceIfNeeded(at: currentDate))
    XCTAssertEqual(session.usedUnblockCount, 0)
    XCTAssertEqual(
      session.allowanceWindowStartedAt,
      start.addingTimeInterval(18 * 60 * 60)
    )
    XCTAssertEqual(
      session.nextAllowanceResetAt,
      start.addingTimeInterval(24 * 60 * 60)
    )
  }

  func testNeverResetPreservesUsage() {
    let start = Date(timeIntervalSince1970: 1_000_000)
    var session = makeSession(startedAt: start, resetHours: nil, usedUnblocks: 2)

    XCTAssertFalse(
      session.resetAllowanceIfNeeded(at: start.addingTimeInterval(48 * 60 * 60))
    )
    XCTAssertEqual(session.usedUnblockCount, 2)
  }

  func testRollbackOnlyMatchesCurrentAllowanceWindow() {
    let start = Date(timeIntervalSince1970: 1_000_000)
    var session = makeSession(startedAt: start, resetHours: 6, usedUnblocks: 2)
    let resetBoundary = start.addingTimeInterval(6 * 60 * 60)
    session.resetAllowanceIfNeeded(at: resetBoundary)

    XCTAssertFalse(
      session.containsAllowanceUse(createdAt: resetBoundary.addingTimeInterval(-1))
    )
    XCTAssertTrue(
      session.containsAllowanceUse(createdAt: resetBoundary.addingTimeInterval(1))
    )
  }

  func testActivityIdentifiersParseWithoutEmbeddingResourceTokens() {
    let profileId = UUID()
    let sessionId = UUID().uuidString
    let grantId = UUID()
    let activityName = DeviceActivityName(
      rawValue:
        "\(SoftUnblockGrantScheduler.activityId):\(profileId.uuidString)|\(sessionId)|\(grantId.uuidString)"
    )

    XCTAssertEqual(
      SoftUnblockGrantScheduler.identifiers(from: activityName),
      SoftUnblockGrantScheduler.ActivityIdentifiers(
        profileId: profileId,
        sessionId: sessionId,
        grantId: grantId
      )
    )
  }

  func testActivityIdentifiersRejectMalformedNames() {
    let activityName = DeviceActivityName(
      rawValue: "\(SoftUnblockGrantScheduler.activityId):invalid"
    )

    XCTAssertNil(SoftUnblockGrantScheduler.identifiers(from: activityName))
  }

  private func makeSession(
    startedAt: Date,
    resetHours: Int?,
    usedUnblocks: Int
  ) -> SoftUnblockSessionState {
    SoftUnblockSessionState(
      sessionId: UUID().uuidString,
      profileId: UUID(),
      maximumUnblockCount: 3,
      allowanceResetIntervalInHours: resetHours,
      allowanceWindowStartedAt: startedAt,
      nextAllowanceResetAt: resetHours.map {
        startedAt.addingTimeInterval(TimeInterval($0 * 60 * 60))
      },
      usedUnblockCount: usedUnblocks
    )
  }
}
