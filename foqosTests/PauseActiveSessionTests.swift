import SwiftData
import XCTest

@testable import foqos

@MainActor
final class PauseActiveSessionTests: XCTestCase {
  private enum SchedulerError: LocalizedError {
    case unavailable

    var errorDescription: String? {
      return "Device Activity is unavailable"
    }
  }

  override func setUp() {
    super.setUp()
    SharedData.flushActiveSession()
  }

  override func tearDown() {
    SharedData.flushActiveSession()
    super.tearDown()
  }

  func testNFCPauseStrategySchedulesPause() throws {
    let context = try makeContext()
    let profile = try makeActiveSession(
      strategyId: NFCPauseTimerBlockingStrategy.id,
      context: context
    ).blockedProfile
    var scheduledProfileId: UUID?

    let profileName = try StrategyManager().pauseActiveSessionFromBackground(
      context: context,
      schedulePause: { scheduledProfileId = $0.id }
    )

    XCTAssertEqual(profileName, profile.name)
    XCTAssertEqual(scheduledProfileId, profile.id)
  }

  func testQRPauseStrategySchedulesPause() throws {
    let context = try makeContext()
    let profile = try makeActiveSession(
      strategyId: QRPauseTimerBlockingStrategy.id,
      context: context
    ).blockedProfile
    var scheduledProfileId: UUID?

    let profileName = try StrategyManager().pauseActiveSessionFromBackground(
      context: context,
      schedulePause: { scheduledProfileId = $0.id }
    )

    XCTAssertEqual(profileName, profile.name)
    XCTAssertEqual(scheduledProfileId, profile.id)
  }

  func testNoActiveSessionThrows() throws {
    let context = try makeContext()
    var didSchedule = false

    XCTAssertThrowsError(
      try StrategyManager().pauseActiveSessionFromBackground(
        context: context,
        schedulePause: { _ in didSchedule = true }
      )
    ) { error in
      XCTAssertEqual(error as? PauseActiveSessionError, .noActiveSession)
    }
    XCTAssertFalse(didSchedule)
  }

  func testUnsupportedStrategiesThrow() throws {
    let unsupportedStrategyIds = [
      ManualBlockingStrategy.id,
      NFCTimerBlockingStrategy.id,
      UUID().uuidString,
    ]

    for strategyId in unsupportedStrategyIds {
      SharedData.flushActiveSession()
      let context = try makeContext()
      _ = try makeActiveSession(strategyId: strategyId, context: context)

      XCTAssertThrowsError(
        try StrategyManager().pauseActiveSessionFromBackground(
          context: context,
          schedulePause: { _ in XCTFail("Pause should not be scheduled") }
        )
      ) { error in
        XCTAssertEqual(
          error as? PauseActiveSessionError,
          .unsupportedStrategy(profileName: "Focus")
        )
      }
    }
  }

  func testAlreadyPausedSessionThrows() throws {
    let context = try makeContext()
    let session = try makeActiveSession(
      strategyId: NFCPauseTimerBlockingStrategy.id,
      context: context
    )
    session.startPause()
    try context.save()

    XCTAssertThrowsError(
      try StrategyManager().pauseActiveSessionFromBackground(
        context: context,
        schedulePause: { _ in XCTFail("Pause should not be scheduled") }
      )
    ) { error in
      XCTAssertEqual(
        error as? PauseActiveSessionError,
        .alreadyPaused(profileName: "Focus")
      )
    }
  }

  func testActiveBreakThrows() throws {
    let context = try makeContext()
    let session = try makeActiveSession(
      strategyId: NFCPauseTimerBlockingStrategy.id,
      enableBreaks: true,
      context: context
    )
    session.startBreak()
    try context.save()

    XCTAssertThrowsError(
      try StrategyManager().pauseActiveSessionFromBackground(
        context: context,
        schedulePause: { _ in XCTFail("Pause should not be scheduled") }
      )
    ) { error in
      XCTAssertEqual(
        error as? PauseActiveSessionError,
        .breakActive(profileName: "Focus")
      )
    }
  }

  func testMissingPauseConfigurationThrows() throws {
    let context = try makeContext()
    _ = try makeActiveSession(
      strategyId: NFCPauseTimerBlockingStrategy.id,
      includePauseConfiguration: false,
      context: context
    )

    XCTAssertThrowsError(
      try StrategyManager().pauseActiveSessionFromBackground(
        context: context,
        schedulePause: { _ in XCTFail("Pause should not be scheduled") }
      )
    ) { error in
      XCTAssertEqual(
        error as? PauseActiveSessionError,
        .missingPauseConfiguration(profileName: "Focus")
      )
    }
  }

  func testSchedulerFailureThrowsLocalizedError() throws {
    let context = try makeContext()
    _ = try makeActiveSession(
      strategyId: NFCPauseTimerBlockingStrategy.id,
      context: context
    )

    XCTAssertThrowsError(
      try StrategyManager().pauseActiveSessionFromBackground(
        context: context,
        schedulePause: { _ in throw SchedulerError.unavailable }
      )
    ) { error in
      XCTAssertEqual(
        error as? PauseActiveSessionError,
        .schedulingFailed(
          profileName: "Focus",
          reason: "Device Activity is unavailable"
        )
      )
    }
  }

  private func makeContext() throws -> ModelContext {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(
      for: BlockedProfileSession.self,
      BlockedProfiles.self,
      configurations: configuration
    )
    return ModelContext(container)
  }

  private func makeActiveSession(
    strategyId: String,
    includePauseConfiguration: Bool = true,
    enableBreaks: Bool = false,
    context: ModelContext
  ) throws -> BlockedProfileSession {
    let strategyData =
      includePauseConfiguration
      ? StrategyPauseTimerData.toData(
        from: StrategyPauseTimerData(pauseDurationInMinutes: 15)
      ) : nil
    let profile = BlockedProfiles(
      name: "Focus",
      blockingStrategyId: strategyId,
      strategyData: strategyData,
      enableBreaks: enableBreaks
    )
    context.insert(profile)

    let session = BlockedProfileSession.createSession(
      in: context,
      withTag: strategyId,
      withProfile: profile
    )
    try context.save()
    return session
  }
}
