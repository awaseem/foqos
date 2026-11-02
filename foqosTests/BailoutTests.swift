import Foundation
import SwiftData
import XCTest

@testable import foqos

@MainActor
final class BailoutTests: ModelRegressionTestCase {
  func testGivenBailoutTiers_WhenInspectingIdentifiers_ThenProductIDsMatchTipManager() {
    let expectedIDs = [
      "tip_developer_support",
      "tip_developer_support_5",
      "tip_developer_support_10",
    ]

    let actualIDs = BailoutTier.allCases.map(\.id)
    XCTAssertEqual(actualIDs, expectedIDs)

    for tier in BailoutTier.allCases {
      XCTAssertFalse(tier.title.isEmpty)
      XCTAssertFalse(tier.defaultPriceString.isEmpty)
      XCTAssertFalse(tier.emoji.isEmpty)
      XCTAssertFalse(tier.subtitle.isEmpty)
    }
  }

  func testGivenWebhookPayload_WhenEncodedToJSON_ThenFieldsAreSerializedCorrectly() throws {
    let payload = BailoutWebhookPayload(
      tier: .tier2,
      profileName: "Deep Focus",
      timestamp: referenceDate
    )

    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    let data = try encoder.encode(payload)
    let json = try XCTUnwrap(
      JSONSerialization.jsonObject(with: data) as? [String: Any]
    )

    XCTAssertEqual(json["event"] as? String, "foqos_emergency_bailout")
    XCTAssertEqual(json["tier"] as? String, "tip_developer_support_5")
    XCTAssertEqual(json["amountEstimate"] as? String, "$4.99")
    XCTAssertEqual(json["profileName"] as? String, "Deep Focus")
    XCTAssertNotNil(json["timestamp"] as? String)
  }

  func testGivenBailoutModes_WhenEvaluatingDefinitions_ThenAllCasesAreDistinct() {
    XCTAssertEqual(BailoutMode.allCases.count, 3)

    let ids = Set(BailoutMode.allCases.map(\.id))
    XCTAssertEqual(ids.count, 3)

    for mode in BailoutMode.allCases {
      XCTAssertFalse(mode.title.isEmpty)
      XCTAssertFalse(mode.description.isEmpty)
    }
  }

  func testGivenActiveSession_WhenExecutingBailout_ThenSessionEndsAndBailoutCountIncrements() async throws {
    let strategyManager = StrategyManager.shared
    let bailoutManager = BailoutManager(isTestingMode: true)
    let initialCount = bailoutManager.totalBailoutsCompleted

    let profile = configuredProfile()
    context.insert(profile)
    try context.save()

    let session = BlockedProfileSession(
      id: UUID(),
      startedAt: referenceDate,
      blockedProfile: profile
    )
    context.insert(session)
    profile.sessions.append(session)
    try context.save()

    strategyManager.activeSession = session
    strategyManager.isBlocking = true

    let success = await bailoutManager.executeBailout(
      tier: .tier2,
      context: context,
      strategyManager: strategyManager,
      profileName: profile.name
    )

    XCTAssertTrue(success)
    XCTAssertEqual(bailoutManager.totalBailoutsCompleted, initialCount + 1)
    XCTAssertFalse(strategyManager.isBlocking)
    XCTAssertNil(strategyManager.activeSession)
  }
}
