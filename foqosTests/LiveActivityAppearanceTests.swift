import SwiftUI
import XCTest

@testable import foqos

final class LiveActivityAppearanceTests: XCTestCase {
  func testGivenTimedFocus_WhenDisplayingIsland_ThenUsePlainIcon() {
    let start = Date.now.addingTimeInterval(-10 * 60)
    let end = start.addingTimeInterval(30 * 60)
    let state = FoqosWidgetAttributes.ContentState(startTime: start, expectedEndTime: end)

    XCTAssertNil(state.progressRange)
  }

  func testGivenInterruption_WhenDisplayingRing_ThenRangeStartsAtBreakOrPause() {
    let start = Date.now.addingTimeInterval(-30 * 60)
    let breakStart = start.addingTimeInterval(20 * 60)
    let pauseStart = start.addingTimeInterval(25 * 60)
    let end = Date.now.addingTimeInterval(5 * 60)
    var state = FoqosWidgetAttributes.ContentState(
      startTime: start, expectedEndTime: end, isBreakActive: true, breakStartTime: breakStart)

    XCTAssertEqual(state.progressRange, breakStart...end)
    state.isPauseActive = true
    state.pauseStartTime = pauseStart
    XCTAssertEqual(state.progressRange, pauseStart...end)
  }

  func testGivenUnavailableOrExpiredDeadline_WhenDisplayingRing_ThenUsePlainIcon() {
    let now = Date.now
    var state = FoqosWidgetAttributes.ContentState(
      startTime: now.addingTimeInterval(-60), isBreakActive: true,
      breakStartTime: now.addingTimeInterval(-60))
    XCTAssertNil(state.progressRange)

    state.expectedEndTime = now.addingTimeInterval(-30)
    XCTAssertNil(state.progressRange)

    state.breakStartTime = now.addingTimeInterval(120)
    state.expectedEndTime = now.addingTimeInterval(60)
    XCTAssertNil(state.progressRange)

    state.isBreakActive = false
    state.isPauseActive = true
    XCTAssertNil(state.progressRange)
  }

  func testGivenLegacyActivity_WhenDecoded_ThenDefaultAppearanceIsUsed() throws {
    let data = Data(
      """
      {
        "startTime": 1000,
        "expectedEndTime": 4600,
        "isBreakActive": false,
        "usedBreakDurationInSeconds": 300,
        "isPauseActive": false
      }
      """.utf8
    )

    let state = try JSONDecoder().decode(FoqosWidgetAttributes.ContentState.self, from: data)

    XCTAssertNil(state.themeColorName)
    XCTAssertNil(state.appIconName)
    XCTAssertEqual(state.appIcon, .defaultIcon)
    XCTAssertEqual(state.themeColor, Color(hex: "#894fa3"))
    XCTAssertEqual(state.startTime, Date(timeIntervalSinceReferenceDate: 1000))
    XCTAssertEqual(state.usedBreakDurationInSeconds, 300)
  }
}
