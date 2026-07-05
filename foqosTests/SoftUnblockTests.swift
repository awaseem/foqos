import DeviceActivity
import XCTest

@testable import foqos

final class SoftUnblockTests: XCTestCase {
  func testStrategyConfigurationRoundTrips() {
    let configuration = SoftUnblockStrategyData(
      accessDurationInMinutes: 30,
      maximumUnblockCount: 6
    )
    let encoded = SoftUnblockStrategyData.encode(configuration)

    XCTAssertEqual(SoftUnblockStrategyData.decode(encoded), configuration)
  }

  func testStrategyConfigurationFallsBackForMissingData() {
    let configuration = SoftUnblockStrategyData.decode(nil)

    XCTAssertEqual(
      configuration.accessDurationInMinutes,
      SoftUnblockStrategyData.defaultDurationInMinutes
    )
    XCTAssertEqual(
      configuration.maximumUnblockCount,
      SoftUnblockStrategyData.defaultMaximumUnblockCount
    )
  }

  func testActivityIdentifiersParseWithoutEmbeddingResourceTokens() {
    let profileId = UUID()
    let sessionId = UUID().uuidString
    let grantId = UUID()
    let activityName = DeviceActivityName(
      rawValue:
        "\(SoftUnblockGrantScheduler.activityId):\(profileId.uuidString)|\(sessionId)|\(grantId.uuidString)"
    )

    XCTAssertEqual(
      SoftUnblockGrantScheduler.identifiers(from: activityName),
      SoftUnblockGrantScheduler.ActivityIdentifiers(
        profileId: profileId,
        sessionId: sessionId,
        grantId: grantId
      )
    )
  }

  func testActivityIdentifiersRejectMalformedNames() {
    let activityName = DeviceActivityName(
      rawValue: "\(SoftUnblockGrantScheduler.activityId):invalid"
    )

    XCTAssertNil(SoftUnblockGrantScheduler.identifiers(from: activityName))
  }
}
