import XCTest

@testable import foqos

final class BlockedProfileDraftTests: XCTestCase {
  func testSelectingTemporaryAccessDisablesAllowMode() {
    let draft = BlockedProfileDraft()
    draft.enableAllowMode = true

    draft.selectedStrategy = NFCSoftUnblockBlockingStrategy()

    XCTAssertFalse(draft.enableAllowMode)
    XCTAssertFalse(draft.selectedStrategySupportsAllowMode)
  }

  func testLoadingTemporaryAccessProfileDisablesAllowMode() {
    let profile = BlockedProfiles(
      name: "Temporary Access",
      blockingStrategyId: QRSoftUnblockBlockingStrategy.id,
      enableAllowMode: true
    )

    let draft = BlockedProfileDraft(profile: profile)

    XCTAssertFalse(draft.enableAllowMode)
    XCTAssertFalse(draft.selectedStrategySupportsAllowMode)
  }

  func testOtherStrategiesContinueToSupportAllowMode() {
    let draft = BlockedProfileDraft()

    draft.enableAllowMode = true

    XCTAssertTrue(draft.enableAllowMode)
    XCTAssertTrue(draft.selectedStrategySupportsAllowMode)
  }

  func testLoadingProfilePreservesNeverResetPolicy() {
    let profile = BlockedProfiles(
      name: "Focus",
      breakResetPolicy: .never
    )

    let draft = BlockedProfileDraft(profile: profile)

    XCTAssertEqual(draft.breakResetPolicy, .never)
  }
}
