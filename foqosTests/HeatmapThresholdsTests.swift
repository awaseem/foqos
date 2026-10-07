import XCTest

@testable import foqos

final class HeatmapThresholdsTests: XCTestCase {
  func testDefaultThresholdsMatchExistingHeatmapBuckets() {
    let thresholds = HeatmapThresholds.defaults

    XCTAssertEqual(thresholds.opacity(for: 0.25), 0.3)
    XCTAssertEqual(thresholds.opacity(for: 1.5), 0.5)
    XCTAssertEqual(thresholds.opacity(for: 4.0), 0.7)
    XCTAssertEqual(thresholds.opacity(for: 6.0), 0.9)
  }

  func testNormalizationKeepsThresholdsOrderedWithMinimumGap() {
    let thresholds = HeatmapThresholds(
      lowHours: 8,
      mediumHours: 3,
      highHours: 2
    ).normalized

    XCTAssertEqual(thresholds.lowHours, 8)
    XCTAssertEqual(thresholds.mediumHours, 8.5)
    XCTAssertEqual(thresholds.highHours, 9)
  }
}
