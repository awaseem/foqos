import XCTest

@testable import foqos

final class StepChallengeTests: XCTestCase {
  func testStepConfigurationRequiresBoundedGoalAndRoundTrips() throws {
    var config = IntentionalAccessConfiguration()
    config.kind = .steps
    XCTAssertFalse(config.isValid)
    for goal in [-1, 0, 9, 10_001, Int.max] {
      config.stepGoal = goal
      XCTAssertFalse(config.isValid)
    }
    for goal in [10, 100, 10_000] {
      config.stepGoal = goal
      XCTAssertTrue(config.isValid)
      XCTAssertEqual(
        IntentionalAccessConfiguration.decode(try JSONEncoder().encode(config)), config)
    }
    config = .init()
    XCTAssertTrue(config.isValid)
  }

  @MainActor
  func testProgressCannotCompleteWithMissingInvalidOrUnmetTarget() {
    XCTAssertFalse(StepChallengeManager.isComplete(steps: 99, goal: 100))
    XCTAssertTrue(StepChallengeManager.isComplete(steps: 100, goal: 100))
    XCTAssertTrue(StepChallengeManager.isComplete(steps: 101, goal: 100))
    XCTAssertFalse(StepChallengeManager.isComplete(steps: 100, goal: 0))
    let manager = StepChallengeManager()
    manager.accept(steps: 500, for: Date())
    XCTAssertEqual(manager.steps, 0)
    manager.stop()
    manager.accept(steps: 500, for: Date())
    XCTAssertEqual(manager.steps, 0)
  }
}
