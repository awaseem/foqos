import CoreLocation
import XCTest

@testable import foqos

final class FamilyOutingTests: XCTestCase {
  func testPlaceValidationRejectsMissingNonFiniteAndOutOfRangeCoordinates() {
    var settings = FamilyOutingSettings()
    XCTAssertFalse(settings.hasValidRegion)
    settings.latitude = 51
    settings.longitude = 0
    XCTAssertTrue(settings.hasValidRegion)
    settings.latitude = .nan
    XCTAssertFalse(settings.hasValidRegion)
    settings.latitude = 91
    XCTAssertFalse(settings.hasValidRegion)
    settings.latitude = 51
    settings.longitude = 181
    XCTAssertFalse(settings.hasValidRegion)
    settings.longitude = 0
    settings.radius = 99
    XCTAssertFalse(settings.hasValidRegion)
    settings.radius = .infinity
    XCTAssertFalse(settings.hasValidRegion)
  }

  func testPartnerCommandsExpireAndRejectFutureDatesAndOversizedMessages() throws {
    let now = Date(timeIntervalSince1970: 1000)
    var command = FamilyCommand(action: .start, createdAt: now)
    XCTAssertTrue(command.isFresh(at: now))
    XCTAssertTrue(command.isFresh(at: now.addingTimeInterval(300)))
    XCTAssertFalse(command.isFresh(at: now.addingTimeInterval(301)))
    XCTAssertFalse(command.isFresh(at: now.addingTimeInterval(-61)))
    command.message = String(repeating: "x", count: 201)
    XCTAssertFalse(command.isFresh(at: now))
    let decoded = try JSONDecoder().decode(FamilyCommand.self, from: JSONEncoder().encode(command))
    XCTAssertEqual(decoded.id, command.id)
    XCTAssertEqual(decoded.action, .start)
  }
}

@MainActor
final class FamilyOutingControlTests: ModelRegressionTestCase {
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
    let outing = makeOuting(authorized: true)
    outing.settings.profileID = profile.id
    outing.apply(.start, source: "Test")
    let session = try XCTUnwrap(BlockedProfileSession.mostRecentActiveSession(in: context))
    outing.apply(.start, source: "Test duplicate")
    XCTAssertEqual(BlockedProfileSession.mostRecentActiveSession(in: context)?.id, session.id)
    // A restart retains ownership.
    let restored = makeOuting(authorized: true)
    restored.settings.profileID = profile.id
    restored.apply(.stop, source: "Test")
    XCTAssertNotNil(session.endTime)
  }

  func testFamilyCannotTakeOwnershipOfManualSessionOrStopIt() throws {
    let profile = BlockedProfiles(name: "Family", blockingStrategyId: ManualBlockingStrategy.id)
    context.insert(profile)
    let session = BlockedProfileSession.createSession(
      in: context, withTag: "manual", withProfile: profile)
    try context.save()
    let outing = makeOuting(authorized: true)
    outing.settings.profileID = profile.id
    outing.apply(.start, source: "Test")
    outing.apply(.stop, source: "Test")
    XCTAssertNil(session.endTime)
    XCTAssertNil(defaults.string(forKey: "family.session"))
  }

  func testFamilyRejectsPhysicalStrategyAndMissingScreenTime() throws {
    let profile = BlockedProfiles(name: "Family", blockingStrategyId: NFCBlockingStrategy.id)
    context.insert(profile)
    try context.save()
    let outing = makeOuting(authorized: false)
    outing.settings.profileID = profile.id
    outing.apply(.start, source: "Test")
    XCTAssertEqual(
      outing.errorMessage, FamilyOutingError.manualProfileRequired.localizedDescription)
    profile.blockingStrategyId = ManualBlockingStrategy.id
    outing.apply(.start, source: "Test")
    XCTAssertEqual(outing.errorMessage, FamilyOutingError.screenTimeRequired.localizedDescription)
    XCTAssertNil(BlockedProfileSession.mostRecentActiveSession(in: context))
  }

  func testGeofenceIgnoresDisabledUnknownAndStaleEventsThenStartsAndStopsOwnedSession() throws {
    let profile = BlockedProfiles(name: "Family", blockingStrategyId: ManualBlockingStrategy.id)
    context.insert(profile)
    try context.save()
    let outing = makeOuting(authorized: true)
    outing.settings.profileID = profile.id
    outing.settings.latitude = 51
    outing.settings.longitude = 0
    let region = CLCircularRegion(
      center: CLLocationCoordinate2D(latitude: 51, longitude: 0),
      radius: 200, identifier: "foqos.family.region")
    outing.handleBoundary(.outside, region: region)
    XCTAssertNil(BlockedProfileSession.mostRecentActiveSession(in: context))
    outing.settings.isEnabled = true
    outing.handleBoundary(.unknown, region: region)
    let stale = CLCircularRegion(center: region.center, radius: 300, identifier: region.identifier)
    outing.handleBoundary(.outside, region: stale)
    XCTAssertNil(BlockedProfileSession.mostRecentActiveSession(in: context))
    outing.handleBoundary(.outside, region: region)
    let session = try XCTUnwrap(BlockedProfileSession.mostRecentActiveSession(in: context))
    outing.handleBoundary(.inside, region: region)
    XCTAssertNotNil(session.endTime)
    outing.settings.blockOutside = false
    outing.handleBoundary(.outside, region: region)
    XCTAssertNil(BlockedProfileSession.mostRecentActiveSession(in: context))
    outing.handleBoundary(.inside, region: region)
    XCTAssertNotNil(BlockedProfileSession.mostRecentActiveSession(in: context))
    outing.apply(.stop, source: "Test cleanup")
  }

  private func makeOuting(authorized: Bool) -> FamilyOutingManager {
    FamilyOutingManager(
      context: context, defaults: defaults, strategyManager: manager,
      isScreenTimeAuthorized: { authorized })
  }
}
