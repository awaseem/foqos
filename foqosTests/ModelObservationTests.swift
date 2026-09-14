import Observation
import XCTest

@testable import foqos

final class ModelObservationTests: ModelRegressionTestCase {
  func testMovedProfilePropertyStillNotifiesObservers() {
    let profile = BlockedProfiles(
      name: "Focus", strategyData: Data([1]), askForStartSettings: false)
    let changed = expectation(description: "Computed profile property invalidates its observer")
    withObservationTracking {
      XCTAssertFalse(profile.shouldAskForStartSettings)
    } onChange: {
      changed.fulfill()
    }
    profile.strategyData = nil
    wait(for: [changed], timeout: 1)
    XCTAssertTrue(profile.shouldAskForStartSettings)
  }

  func testMovedSessionPropertyTracksChangesThroughProfileRelationship() {
    let profile = BlockedProfiles(name: "Focus", enableBreaks: true)
    let session = BlockedProfileSession(tag: "test", blockedProfile: profile)
    let changed = expectation(description: "Session observer tracks its profile's break setting")
    withObservationTracking {
      XCTAssertTrue(session.isBreakAvailable)
    } onChange: {
      changed.fulfill()
    }
    profile.enableBreaks = false
    wait(for: [changed], timeout: 1)
    XCTAssertFalse(session.isBreakAvailable)
  }
}
