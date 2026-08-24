import SwiftData
import XCTest

@testable import foqos

@MainActor
final class ProfileInsightsUtilTests: XCTestCase {
  override func setUp() {
    super.setUp()
    SharedData.flushActiveSession()
  }

  override func tearDown() {
    SharedData.flushActiveSession()
    super.tearDown()
  }

  func testMultipleBreaksOnlyLeaveTheLastBreakOnTheTimestamps() throws {
    let context = try makeContext()
    let profile = makeProfile(in: context, allowMultipleBreaks: true, breakTimeInMinutes: 30)
    let start = Date(timeIntervalSinceReferenceDate: 1_000)
    let session = makeSession(
      for: profile,
      in: context,
      startingAt: start,
      breaks: [(60, 10), (120, 10), (180, 5)],
      endingAfter: 240
    )
    try context.save()

    XCTAssertEqual(session.breakStartTime, start.addingTimeInterval(180 * 60))
    XCTAssertEqual(session.breakEndTime, start.addingTimeInterval(185 * 60))
    XCTAssertEqual(session.usedBreakDurationInSeconds, 25 * 60, accuracy: 0.1)
    XCTAssertEqual(session.totalBreakDuration, 25 * 60, accuracy: 0.1)
  }

  func testTotalBreakTimeCountsEveryBreakInASession() throws {
    let context = try makeContext()
    let profile = makeProfile(in: context, allowMultipleBreaks: true, breakTimeInMinutes: 30)
    let start = Date(timeIntervalSinceReferenceDate: 1_000)
    _ = makeSession(
      for: profile,
      in: context,
      startingAt: start,
      breaks: [(60, 10), (120, 10), (180, 5)],
      endingAfter: 240
    )
    try context.save()

    let metrics = ProfileInsightsUtil(profile: profile).metrics

    XCTAssertEqual(metrics.totalBreakTime, 25 * 60, accuracy: 0.1)
    XCTAssertEqual(metrics.averageBreakDuration ?? 0, 25 * 60, accuracy: 0.1)
    XCTAssertEqual(metrics.sessionsWithBreaks, 1)
    XCTAssertEqual(metrics.sessionsWithoutBreaks, 0)
  }

  func testTotalBreakTimeIsCappedByTheConfiguredAllowance() throws {
    let context = try makeContext()
    let profile = makeProfile(in: context, allowMultipleBreaks: true, breakTimeInMinutes: 30)
    let start = Date(timeIntervalSinceReferenceDate: 1_000)
    _ = makeSession(
      for: profile,
      in: context,
      startingAt: start,
      breaks: [(60, 25), (120, 25)],
      endingAfter: 240
    )
    try context.save()

    let metrics = ProfileInsightsUtil(profile: profile).metrics

    XCTAssertEqual(metrics.totalBreakTime, 30 * 60, accuracy: 0.1)
  }

  func testSingleBreakSessionStillReportsItsBreak() throws {
    let context = try makeContext()
    let profile = makeProfile(in: context, allowMultipleBreaks: false, breakTimeInMinutes: 15)
    let start = Date(timeIntervalSinceReferenceDate: 1_000)
    let session = makeSession(
      for: profile,
      in: context,
      startingAt: start,
      breaks: [(30, 12)],
      endingAfter: 120
    )
    try context.save()

    // The accumulator is only maintained for reusable breaks, so single-break sessions have
    // to keep falling back to the timestamp pair.
    XCTAssertEqual(session.usedBreakDurationInSeconds, 0, accuracy: 0.1)
    XCTAssertEqual(session.totalBreakDuration, 12 * 60, accuracy: 0.1)

    let metrics = ProfileInsightsUtil(profile: profile).metrics

    XCTAssertEqual(metrics.totalBreakTime, 12 * 60, accuracy: 0.1)
    XCTAssertEqual(metrics.sessionsWithBreaks, 1)
  }

  func testTotalBreakTimeIsUnaffectedByLaterSettingChanges() throws {
    let context = try makeContext()
    let profile = makeProfile(in: context, allowMultipleBreaks: true, breakTimeInMinutes: 30)
    let start = Date(timeIntervalSinceReferenceDate: 1_000)
    let session = makeSession(
      for: profile,
      in: context,
      startingAt: start,
      breaks: [(60, 10), (120, 10)],
      endingAfter: 240
    )
    try context.save()

    profile.allowMultipleBreaks = false
    try context.save()

    XCTAssertEqual(session.totalBreakDuration, 20 * 60, accuracy: 0.1)
    XCTAssertEqual(
      ProfileInsightsUtil(profile: profile).metrics.totalBreakTime,
      20 * 60,
      accuracy: 0.1
    )
  }

  func testSessionWithoutBreaksReportsNoBreakTime() throws {
    let context = try makeContext()
    let profile = makeProfile(in: context, allowMultipleBreaks: true, breakTimeInMinutes: 30)
    let start = Date(timeIntervalSinceReferenceDate: 1_000)
    _ = makeSession(for: profile, in: context, startingAt: start, breaks: [], endingAfter: 120)
    try context.save()

    let metrics = ProfileInsightsUtil(profile: profile).metrics

    XCTAssertEqual(metrics.totalBreakTime, 0, accuracy: 0.1)
    XCTAssertNil(metrics.averageBreakDuration)
    XCTAssertEqual(metrics.sessionsWithBreaks, 0)
    XCTAssertEqual(metrics.sessionsWithoutBreaks, 1)
  }

  func testBreakDailyAggregateSumsEveryBreakInTheDay() throws {
    let context = try makeContext()
    let profile = makeProfile(in: context, allowMultipleBreaks: true, breakTimeInMinutes: 30)
    let calendar = Calendar.current
    let day = calendar.startOfDay(for: Date(timeIntervalSinceReferenceDate: 400 * 24 * 60 * 60))
    let start = day.addingTimeInterval(8 * 60 * 60)
    _ = makeSession(
      for: profile,
      in: context,
      startingAt: start,
      breaks: [(60, 10), (120, 10), (180, 5)],
      endingAfter: 240
    )
    try context.save()

    let aggregates = ProfileInsightsUtil(profile: profile).breakDailyAggregates(endingOn: day)
    let today = aggregates.first { calendar.isDate($0.date, inSameDayAs: day) }

    XCTAssertEqual(today?.totalBreakDuration ?? 0, 25 * 60, accuracy: 0.1)
  }

  // MARK: - Helpers

  private func makeContext() throws -> ModelContext {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(
      for: BlockedProfileSession.self,
      BlockedProfiles.self,
      configurations: configuration
    )
    return ModelContext(container)
  }

  private func makeProfile(
    in context: ModelContext,
    allowMultipleBreaks: Bool,
    breakTimeInMinutes: Int
  ) -> BlockedProfiles {
    let profile = BlockedProfiles(
      name: "Focus",
      blockingStrategyId: ManualBlockingStrategy.id,
      enableBreaks: true,
      breakTimeInMinutes: breakTimeInMinutes,
      allowMultipleBreaks: allowMultipleBreaks
    )
    context.insert(profile)
    return profile
  }

  /// Builds a completed session by driving the real break API, so the timestamps end up in the
  /// same state the app leaves them in. Break offsets and durations are in minutes from the
  /// session start.
  private func makeSession(
    for profile: BlockedProfiles,
    in context: ModelContext,
    startingAt start: Date,
    breaks: [(offset: Int, duration: Int)],
    endingAfter minutes: Int
  ) -> BlockedProfileSession {
    let session = BlockedProfileSession(
      tag: ManualBlockingStrategy.id,
      blockedProfile: profile
    )
    session.startTime = start
    context.insert(session)

    for entry in breaks {
      session.startBreak(at: start.addingTimeInterval(TimeInterval(entry.offset * 60)))
      session.endBreak(
        at: start.addingTimeInterval(TimeInterval((entry.offset + entry.duration) * 60))
      )
    }

    session.endTime = start.addingTimeInterval(TimeInterval(minutes * 60))
    return session
  }
}
