import XCTest

@testable import foqos

@MainActor
final class ActivityStartTests: ModelRegressionTestCase {
  func testDisabledLowConfidenceAndStationaryNeverStartOrStop() throws {
    let profile = BlockedProfiles(name: "Activity", blockingStrategyId: ManualBlockingStrategy.id)
    context.insert(profile)
    try context.save()
    let suite = "activity-tests.\(UUID())"
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }
    let strategy = StrategyManager()
    defer { strategy.stopTimer() }
    let control = ProfileSessionControl(
      context: context, key: "test", defaults: defaults,
      manager: strategy, isAuthorized: { true })
    let activity = ActivityStartManager(context: context, defaults: defaults, control: control)
    activity.profileID = profile.id
    activity.handleActivity(walking: true, running: false, cycling: false, confident: true)
    XCTAssertNil(BlockedProfileSession.mostRecentActiveSession(in: context))
    activity.isEnabled = true
    activity.handleActivity(walking: true, running: false, cycling: false, confident: false)
    activity.handleActivity(walking: false, running: false, cycling: false, confident: true)
    XCTAssertNil(BlockedProfileSession.mostRecentActiveSession(in: context))
    for mode in 0...2 {
      activity.handleActivity(
        walking: mode == 0, running: mode == 1,
        cycling: mode == 2, confident: true)
      let session = try XCTUnwrap(BlockedProfileSession.mostRecentActiveSession(in: context))
      activity.handleActivity(walking: false, running: false, cycling: false, confident: true)
      XCTAssertNil(session.endTime)
      activity.isEnabled = false
      XCTAssertNil(session.endTime)
      activity.setActive(false)
      XCTAssertNotNil(session.endTime)
      activity.isEnabled = true
    }
    activity.isEnabled = false
  }
}
