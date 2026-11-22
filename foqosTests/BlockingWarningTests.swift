import DeviceActivity
import ManagedSettings
import XCTest

@testable import foqos

final class BlockingWarningTests: ModelRegressionTestCase {
  func testGivenGrantedDuration_WhenRegisteringWarnings_ThenUsesWholeMinutesWithinBounds() {
    for (duration, lead) in [(61, 1), (180, 1), (300, 1), (599, 1), (600, 2), (900, 3), (1800, 5)] {
      XCTAssertEqual(BlockingWarning.leadTime(for: TimeInterval(duration))?.minute, lead)
    }
    XCTAssertNil(BlockingWarning.leadTime(for: 60))
  }

  func testGivenClampedTimer_WhenRegisteringWarnings_ThenUsesTheRegisteredEnd() {
    let calendar = Calendar(identifier: .gregorian)
    let now = calendar.date(
      from: DateComponents(year: 2026, month: 11, day: 23, hour: 23, minute: 57))!
    let end = DateComponents(hour: 23, minute: 59, second: 59)
    XCTAssertEqual(
      BlockingWarning.leadTime(for: 1800, intervalEnd: end, now: now, calendar: calendar)?.minute, 1
    )
    XCTAssertNil(
      BlockingWarning.leadTime(
        for: 1800, intervalEnd: end, now: now.addingTimeInterval(120), calendar: calendar))
  }

  func testEndWarningOnlyFiresWithinTheLiveAccessWindow() {
    let end = referenceDate.addingTimeInterval(180)
    func due(_ date: Date, sessionEnd: Date? = nil) -> Bool {
      BlockingWarning.isEndWarningDue(at: date, end: end, leadMinutes: 3, sessionEnd: sessionEnd)
    }
    XCTAssertTrue(due(referenceDate))
    XCTAssertFalse(due(referenceDate.addingTimeInterval(-60)))
    XCTAssertTrue(due(referenceDate.addingTimeInterval(60)))
    XCTAssertFalse(due(end))
    XCTAssertFalse(due(referenceDate, sessionEnd: end))
    XCTAssertFalse(due(referenceDate, sessionEnd: end.addingTimeInterval(-60)))
  }

  func testGivenMidnightStart_WhenWarningFires_ThenChecksWeekdayAndAgeAtStart() {
    let calendar = Calendar(identifier: .gregorian)
    let start = calendar.date(
      from: DateComponents(year: 2026, month: 11, day: 23, hour: 0, minute: 5))!
    let warning = start.addingTimeInterval(-900)
    var schedule = BlockedProfileSchedule(
      days: [.monday], startHour: 0, startMinute: 5, endHour: 8, endMinute: 0,
      updatedAt: warning.addingTimeInterval(-1))
    func plannedStart(at date: Date) -> Date? {
      schedule.startForWarning(at: date, profileCreatedAt: .distantPast, calendar: calendar)
    }
    XCTAssertEqual(plannedStart(at: warning), start)
    XCTAssertNil(plannedStart(at: warning.addingTimeInterval(-60)))
    XCTAssertNil(plannedStart(at: warning.addingTimeInterval(60)))
    schedule.days = [.sunday]
    XCTAssertNil(plannedStart(at: warning))
    schedule.days = [.monday]
    schedule.updatedAt = warning
    XCTAssertNil(plannedStart(at: warning))
    XCTAssertFalse(
      schedule.isEligibleStart(start, profileCreatedAt: .distantPast, calendar: calendar))
  }

  func testGivenExistingSchedule_WhenOptingInAfterWarningTime_ThenStillEligibleToBlock() {
    let calendar = Calendar(identifier: .gregorian)
    let start = calendar.date(from: DateComponents(year: 2026, month: 11, day: 23, hour: 9))!
    var schedule = BlockedProfileSchedule(
      days: [.monday], startHour: 9, startMinute: 0, endHour: 17, endMinute: 0,
      updatedAt: .distantPast)
    let warning = start.addingTimeInterval(-900)
    schedule.registeredAt = warning.addingTimeInterval(10)
    XCTAssertNil(
      schedule.startForWarning(
        at: warning.addingTimeInterval(15), profileCreatedAt: .distantPast, calendar: calendar))
    XCTAssertTrue(
      schedule.isEligibleStart(start, profileCreatedAt: .distantPast, calendar: calendar))
    schedule.registeredAt = start.addingTimeInterval(60)
    XCTAssertFalse(
      schedule.isEligibleStart(start, profileCreatedAt: .distantPast, calendar: calendar))
  }

  func testTogglingWarningsPreservesUpcomingStartAndProtectsAnOngoingInterval() throws {
    let calendar = Calendar(identifier: .gregorian)
    let start = try XCTUnwrap(
      calendar.date(from: DateComponents(year: 2026, month: 11, day: 23, hour: 9)))
    let schedule = BlockedProfileSchedule(
      days: [.monday], startHour: 9, startMinute: 0, endHour: 17, endMinute: 0,
      updatedAt: referenceDate)
    let before = start.addingTimeInterval(-300)
    XCTAssertEqual(
      schedule.updatedAtForRegistration(previous: schedule, now: before, calendar: calendar),
      referenceDate)
    let during = start.addingTimeInterval(300)
    XCTAssertEqual(
      schedule.updatedAtForRegistration(previous: schedule, now: during, calendar: calendar), during
    )
  }

  func testGivenExistingProfile_WhenSavingWarningPreference_ThenKeepsScheduleAgeAndSharesOptIn()
    throws
  {
    let profile = configuredProfile()
    // No live schedule is needed to test persisting an existing profile preference.
    profile.schedule?.days = []
    context.insert(profile)
    let age = profile.schedule?.updatedAt
    let draft = BlockedProfileDraft(profile: profile)
    XCTAssertFalse(draft.enableBlockingWarnings)
    draft.enableBlockingWarnings = true
    _ = try draft.save(existingProfile: profile, in: context)
    XCTAssertEqual(profile.schedule?.updatedAt, age)
    XCTAssertTrue(BlockedProfileDraft(profile: profile).enableBlockingWarnings)
    XCTAssertEqual(SharedData.snapshot(for: profile.id.uuidString)?.enableBlockingWarnings, true)
    let clone = try BlockedProfiles.cloneProfile(profile, in: context, newName: "Copy")
    XCTAssertTrue(clone.enableBlockingWarnings)

    draft.schedule.startMinute += 1
    _ = try draft.save(existingProfile: profile, in: context)
    XCTAssertNotEqual(profile.schedule?.updatedAt, age)
  }

  func testGivenLegacySnapshot_WhenDecoded_ThenWarningsDefaultOff() throws {
    var snapshot = BlockedProfiles.getSnapshot(for: configuredProfile())
    snapshot.enableBlockingWarnings = nil
    snapshot.schedule?.registeredAt = nil
    let data = try JSONEncoder().encode(snapshot)
    let decoded = try JSONDecoder().decode(SharedData.ProfileSnapshot.self, from: data)
    XCTAssertNil(decoded.enableBlockingWarnings)
    XCTAssertNil(decoded.schedule?.registeredAt)
  }

  func testOnlyTheActiveBreakOrPauseProducesAnEndWarning() {
    var session = sessionSnapshot(profileID: UUID())
    session.endTime = nil
    let id = session.blockedProfileId.uuidString
    let pause = PauseTimerActivity().getDeviceActivityName(from: id)
    let sessionBreak = BreakTimerActivity().getDeviceActivityName(from: id)
    func name(_ activity: DeviceActivityName) -> String? {
      DeviceActivityMonitorExtension.endingAccess(
        for: activity, session: session, at: referenceDate)
    }
    XCTAssertNil(name(StrategyTimerActivity().getDeviceActivityName(from: id)))
    XCTAssertNil(name(sessionBreak))
    session.breakEndTime = nil
    XCTAssertEqual(name(sessionBreak), "Break")
    XCTAssertNil(name(pause))
    session.pauseEndTime = nil
    XCTAssertEqual(name(pause), "Pause")
  }

  func testOnlyAnUnexpiredGrantInTheSameSessionProducesAnEndWarning() throws {
    let session = sessionSnapshot(profileID: UUID())
    let date = referenceDate
    let token = try JSONDecoder().decode(
      ApplicationToken.self, from: Data(#"{"data":"AAECAwQFBgcICQ=="}"#.utf8))
    let grant = SoftUnblockGrant(
      id: UUID(), sessionId: session.id, profileId: session.blockedProfileId,
      resource: .application(token),
      createdAt: date, expiresAt: date.addingTimeInterval(300))
    SoftUnblockGrantStore.beginSession(
      sessionId: session.id, profileId: grant.profileId, maximumUnblockCount: 1,
      allowanceResetIntervalInHours: nil, startedAt: date)
    XCTAssertTrue(SoftUnblockGrantStore.issue(grant))
    let activity = DeviceActivityName(
      rawValue:
        "\(SoftUnblockGrantScheduler.activityId):\(grant.profileId)|\(session.id)|\(grant.id)")
    XCTAssertEqual(
      DeviceActivityMonitorExtension.endingAccess(for: activity, session: session, at: date),
      "Temporary Access")
    XCTAssertNil(
      DeviceActivityMonitorExtension.endingAccess(
        for: activity, session: session, at: grant.expiresAt))
    var replacement = session
    replacement.id = UUID().uuidString
    XCTAssertNil(
      DeviceActivityMonitorExtension.endingAccess(for: activity, session: replacement, at: date))
  }
}
