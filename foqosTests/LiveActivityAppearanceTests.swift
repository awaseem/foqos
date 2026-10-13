import SwiftUI
import XCTest

@testable import foqos

final class LiveActivityAppearanceTests: XCTestCase {
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
