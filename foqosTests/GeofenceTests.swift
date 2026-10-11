import CoreLocation
import XCTest

@testable import foqos

@MainActor
final class GeofenceTests: ModelRegressionTestCase {
  func testPlaceValidationRejectsMissingNonFiniteAndOutOfRangeCoordinates() {
    var settings = GeofenceSettings()
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

  func testGeofenceIgnoresDisabledUnknownAndStaleEventsThenStartsAndStopsOwnedSession() throws {
    let profile = BlockedProfiles(name: "Family", blockingStrategyId: ManualBlockingStrategy.id)
    context.insert(profile)
    try context.save()
    let geofence = makeGeofence()
    geofence.settings.profileID = profile.id
    geofence.settings.latitude = 51
    geofence.settings.longitude = 0
    let region = CLCircularRegion(
      center: CLLocationCoordinate2D(latitude: 51, longitude: 0),
      radius: 200, identifier: "foqos.geofence.region")
    geofence.handleBoundary(.outside, region: region)
    XCTAssertNil(BlockedProfileSession.mostRecentActiveSession(in: context))
    geofence.settings.isEnabled = true
    geofence.handleBoundary(.unknown, region: region)
    let stale = CLCircularRegion(center: region.center, radius: 300, identifier: region.identifier)
    geofence.handleBoundary(.outside, region: stale)
    XCTAssertNil(BlockedProfileSession.mostRecentActiveSession(in: context))
    geofence.handleBoundary(.outside, region: region)
    let session = try XCTUnwrap(BlockedProfileSession.mostRecentActiveSession(in: context))
    geofence.handleBoundary(.inside, region: region)
    XCTAssertNotNil(session.endTime)
    geofence.settings.blockOutside = false
    geofence.handleBoundary(.outside, region: region)
    XCTAssertNil(BlockedProfileSession.mostRecentActiveSession(in: context))
    geofence.handleBoundary(.inside, region: region)
    XCTAssertNotNil(BlockedProfileSession.mostRecentActiveSession(in: context))
    geofence.setActive(false)
  }

  private func makeGeofence() -> GeofenceManager {
    let defaults = UserDefaults(suiteName: "geofence-tests.\(UUID())")!
    let control = ProfileSessionControl(
      context: context, key: "test", defaults: defaults,
      manager: StrategyManager(), isAuthorized: { true })
    return GeofenceManager(context: context, defaults: defaults, control: control)
  }
}
