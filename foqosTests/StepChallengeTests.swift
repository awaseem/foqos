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
    let start = Date(timeIntervalSince1970: 1000)
    manager.begin(at: start)
    manager.accept(steps: 50, for: start)
    XCTAssertEqual(manager.steps, 50)
    manager.accept(steps: 30, for: start)
    XCTAssertEqual(manager.steps, 50)
    manager.accept(steps: 500, for: start.addingTimeInterval(-1))
    XCTAssertEqual(manager.steps, 50)
    manager.begin(at: start.addingTimeInterval(1))
    XCTAssertEqual(manager.steps, 0)
    manager.accept(steps: 500, for: start)
    XCTAssertEqual(manager.steps, 0)
    manager.accept(steps: -1, for: start.addingTimeInterval(1))
    XCTAssertEqual(manager.steps, 0)
    manager.accept(steps: 100, for: start.addingTimeInterval(1))
    XCTAssertEqual(manager.steps, 100)
    manager.stop()
    XCTAssertEqual(manager.steps, 0)
    manager.accept(steps: 500, for: Date())
    XCTAssertEqual(manager.steps, 0)
  }
}
