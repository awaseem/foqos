import XCTest

@testable import foqos

@MainActor
final class ProfileSessionControlTests: ModelRegressionTestCase {
  private var defaults: UserDefaults!
  private var manager: StrategyManager!
  private var suiteName: String!

  override func setUpWithError() throws {
    try super.setUpWithError()
    suiteName = "family-tests.\(UUID())"
    defaults = UserDefaults(suiteName: suiteName)
    manager = StrategyManager()
  }

  override func tearDownWithError() throws {
    manager.stopTimer()
    defaults.removePersistentDomain(forName: suiteName)
    manager = nil
    defaults = nil
    try super.tearDownWithError()
  }

  func testFamilyStartIsIdempotentAndOnlyOwnedSessionStops() throws {
    let profile = BlockedProfiles(name: "Family", blockingStrategyId: ManualBlockingStrategy.id)
    context.insert(profile)
    try context.save()
    let outing = makeControl(authorized: true)
    outing.profileID = profile.id
    outing.setActive(true)
    let session = try XCTUnwrap(BlockedProfileSession.mostRecentActiveSession(in: context))
    outing.setActive(true)
    XCTAssertEqual(BlockedProfileSession.mostRecentActiveSession(in: context)?.id, session.id)
    // A restart retains ownership.
    let restored = makeControl(authorized: true)
    restored.profileID = profile.id
    restored.setActive(false)
    XCTAssertNotNil(session.endTime)
  }

  func testFamilyCannotTakeOwnershipOfManualSessionOrStopIt() throws {
    let profile = BlockedProfiles(name: "Family", blockingStrategyId: ManualBlockingStrategy.id)
    context.insert(profile)
    let session = BlockedProfileSession.createSession(
      in: context, withTag: "manual", withProfile: profile)
    try context.save()
    let outing = makeControl(authorized: true)
    outing.profileID = profile.id
    outing.setActive(true)
    outing.setActive(false)
    XCTAssertNil(session.endTime)
    XCTAssertNil(defaults.string(forKey: "test.session"))
  }

  func testFamilyRejectsPhysicalStrategyAndMissingScreenTime() throws {
    let profile = BlockedProfiles(name: "Family", blockingStrategyId: NFCBlockingStrategy.id)
    context.insert(profile)
    try context.save()
    let outing = makeControl(authorized: false)
    outing.profileID = profile.id
    outing.setActive(true)
    XCTAssertEqual(
      outing.errorMessage, ProfileSessionControlError.manualProfileRequired.localizedDescription)
    profile.blockingStrategyId = ManualBlockingStrategy.id
    outing.setActive(true)
    XCTAssertEqual(
      outing.errorMessage, ProfileSessionControlError.screenTimeRequired.localizedDescription)
    XCTAssertNil(BlockedProfileSession.mostRecentActiveSession(in: context))
  }

  func testIndependentControlsCannotStopEachOthersSessions() throws {
    let profile = BlockedProfiles(name: "Family", blockingStrategyId: ManualBlockingStrategy.id)
    context.insert(profile)
    try context.save()
    let first = makeControl(authorized: true)
    first.profileID = profile.id
    XCTAssertTrue(first.setActive(true))
    let other = ProfileSessionControl(
      context: context, key: "other", defaults: defaults,
      manager: manager, isAuthorized: { true })
    other.profileID = profile.id
    XCTAssertFalse(other.setActive(true))
    XCTAssertFalse(other.setActive(false))
    XCTAssertNotNil(BlockedProfileSession.mostRecentActiveSession(in: context))
    XCTAssertTrue(first.setActive(false))
  }

  private func makeControl(authorized: Bool) -> ProfileSessionControl {
    ProfileSessionControl(
      context: context, key: "test", defaults: defaults,
      manager: manager, isAuthorized: { authorized })
  }
}
