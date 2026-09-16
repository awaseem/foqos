import SwiftData
import XCTest

@testable import foqos

@MainActor
final class BreakSessionTests: XCTestCase {
  private var container: ModelContainer!
  private var manager: StrategyManager!
  private var context: ModelContext { container.mainContext }

  override func setUpWithError() throws {
    SharedData.flushActiveSession()
    SharedData.flushCompletedSessionsForSchedular()
    container = try ModelContainer(
      for: BlockedProfiles.self, BlockedProfileSession.self,
      configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    manager = StrategyManager()
  }

  override func tearDownWithError() throws {
    manager.stopTimer()
    SharedData.flushActiveSession()
    SharedData.flushCompletedSessionsForSchedular()
    manager = nil
    container = nil
  }

  func testStartLoadsSessionWithoutOpeningTheApp() throws {
    let session = try makeSession()
    var scheduledDuration: TimeInterval?

    let result = try manager.startBreakFromBackground(context: context) { profile, duration in
      XCTAssertEqual(profile.id, session.blockedProfile.id)
      scheduledDuration = duration
    }

    XCTAssertTrue(result.didChange)
    XCTAssertEqual(result.profileName, "Work")
    XCTAssertEqual(scheduledDuration, 600)
    XCTAssertTrue(session.isBreakActive)
    XCTAssertEqual(manager.activeSession?.id, session.id)
    XCTAssertNotNil(SharedData.getActiveSharedSession()?.breakStartTime)
    let persisted = try BlockedProfileSession.findSession(
      byID: session.id, in: ModelContext(container)
    )
    XCTAssertNotNil(persisted?.breakStartTime)
  }

  func testRepeatedStartDoesNotResetBreakOrScheduleAnotherTimer() throws {
    let session = try makeSession()
    session.startBreak(at: Date().addingTimeInterval(-60))
    try context.save()
    let startTime = session.breakStartTime

    let result = try manager.startBreakFromBackground(context: context) { _, _ in
      XCTFail("An existing break must keep its timer")
    }

    XCTAssertFalse(result.didChange)
    XCTAssertEqual(session.breakStartTime, startTime)
    XCTAssertNil(session.breakEndTime)
  }

  func testEndPreservesUnusedAllowanceAndCanBeRepeated() throws {
    let session = try makeSession()
    session.startBreak(at: Date().addingTimeInterval(-60))
    try context.save()

    let profileName = try manager.endBreakFromBackground(context: context)
    let usedDuration = session.usedBreakDurationInSeconds
    let endedAt = session.breakEndTime
    let repeatedResult = try manager.endBreakFromBackground(context: context)

    XCTAssertEqual(profileName, "Work")
    XCTAssertNil(repeatedResult)
    XCTAssertFalse(session.isBreakActive)
    XCTAssertNil(session.endTime)
    XCTAssertEqual(session.breakEndTime, endedAt)
    XCTAssertEqual(session.usedBreakDurationInSeconds, usedDuration)
    XCTAssertEqual(usedDuration, 60, accuracy: 2)
    XCTAssertEqual(session.remainingBreakAllowance(), 540, accuracy: 2)

    var nextDuration: TimeInterval = 0
    _ = try manager.startBreakFromBackground(context: context) { _, duration in
      nextDuration = duration
    }
    XCTAssertEqual(nextDuration, 600 - usedDuration, accuracy: 0.1)
  }

  func testEndingWithoutABreakDoesNotStartOne() throws {
    let session = try makeSession()

    XCTAssertNil(try manager.endBreakFromBackground(context: context))
    XCTAssertNil(session.breakStartTime)
    XCTAssertNil(session.endTime)
  }

  func testNoSessionRejectsStartAndAllowsEndAsNoOp() throws {
    assertStartError(.noActiveSession)
    XCTAssertNil(try manager.endBreakFromBackground(context: context))
  }

  func testDisabledBreaksRejectStart() throws {
    _ = try makeSession(enableBreaks: false)
    assertStartError(.breaksUnavailable(profileName: "Work"))
  }

  func testTemporaryAccessStrategyRejectsTimedBreak() throws {
    _ = try makeSession(strategyId: NFCSoftUnblockBlockingStrategy.id)
    assertStartError(.breaksUnavailable(profileName: "Work"))
  }

  func testActivePauseRejectsStart() throws {
    let session = try makeSession(strategyId: NFCPauseTimerBlockingStrategy.id)
    session.startPause()
    try context.save()
    assertStartError(.pauseActive(profileName: "Work"))
  }

  func testUsedSingleBreakCannotBeStartedAgain() throws {
    let session = try makeSession(allowMultipleBreaks: false)
    session.startBreak(at: Date().addingTimeInterval(-60))
    session.endBreak()
    try context.save()
    assertStartError(.breaksUnavailable(profileName: "Work"))
  }

  func testExhaustedAllowanceRejectsStart() throws {
    let session = try makeSession()
    session.usedBreakDurationInSeconds = 600
    SharedData.setUsedBreakDurationInSeconds(600)
    try context.save()
    assertStartError(.allowanceExhausted(profileName: "Work"))
  }

  func testSchedulerFailureLeavesSessionBlocking() throws {
    let session = try makeSession()

    XCTAssertThrowsError(
      try manager.startBreakFromBackground(context: context) { _, _ in
        throw NSError(
          domain: "BreakSessionTests", code: 1,
          userInfo: [NSLocalizedDescriptionKey: "Timer unavailable"]
        )
      }
    ) { error in
      XCTAssertEqual(
        error as? BreakSessionError, .schedulingFailed(reason: "Timer unavailable")
      )
    }

    XCTAssertNil(session.breakStartTime)
    XCTAssertNil(SharedData.getActiveSharedSession()?.breakStartTime)
    XCTAssertNil(session.endTime)
  }

  func testEndLoadsBreakChangesFromExtension() throws {
    let session = try makeSession()
    var snapshot = session.toSnapshot()
    snapshot.breakStartTime = Date().addingTimeInterval(-60)
    SharedData.createActiveSharedSession(for: snapshot)

    XCTAssertEqual(try manager.endBreakFromBackground(context: context), "Work")
    XCTAssertNotNil(session.breakEndTime)
    XCTAssertEqual(session.usedBreakDurationInSeconds, 60, accuracy: 2)
  }

  func testDelayedTimerStartDoesNotReopenEndedBreak() throws {
    let session = try makeSession()
    session.startBreak(at: Date().addingTimeInterval(-60))
    try context.save()
    _ = try manager.endBreakFromBackground(context: context)
    let endedAt = SharedData.getActiveSharedSession()?.breakEndTime
    let usedDuration = SharedData.getActiveSharedSession()?.usedBreakDurationInSeconds

    BreakTimerActivity().start(for: BlockedProfiles.getSnapshot(for: session.blockedProfile))

    XCTAssertEqual(SharedData.getActiveSharedSession()?.breakEndTime, endedAt)
    XCTAssertEqual(SharedData.getActiveSharedSession()?.usedBreakDurationInSeconds, usedDuration)
  }

  func testTimerStartDoesNotCreateBreakBeforeAppCommitsIt() throws {
    let session = try makeSession()

    BreakTimerActivity().start(for: BlockedProfiles.getSnapshot(for: session.blockedProfile))

    XCTAssertNil(SharedData.getActiveSharedSession()?.breakStartTime)
  }

  private func assertStartError(
    _ expected: BreakSessionError, file: StaticString = #filePath, line: UInt = #line
  ) {
    XCTAssertThrowsError(
      try manager.startBreakFromBackground(context: context) { _, _ in
        XCTFail("Invalid requests must not schedule a break", file: file, line: line)
      }, file: file, line: line
    ) { error in
      XCTAssertEqual(error as? BreakSessionError, expected, file: file, line: line)
    }
  }

  private func makeSession(
    enableBreaks: Bool = true,
    allowMultipleBreaks: Bool = true,
    strategyId: String = ManualBlockingStrategy.id
  ) throws -> BlockedProfileSession {
    let profile = BlockedProfiles(
      name: "Work", blockingStrategyId: strategyId, enableBreaks: enableBreaks,
      breakTimeInMinutes: 10, allowMultipleBreaks: allowMultipleBreaks
    )
    context.insert(profile)
    let session = BlockedProfileSession.createSession(
      in: context, withTag: strategyId, withProfile: profile
    )
    try context.save()
    return session
  }
}
