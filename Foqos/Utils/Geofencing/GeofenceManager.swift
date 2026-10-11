import CoreLocation
import SwiftData
import SwiftUI

@MainActor
final class GeofenceManager: NSObject, ObservableObject, CLLocationManagerDelegate {
  @Published var settings: GeofenceSettings
  @Published var status = "Geofencing is off."
  @Published var errorMessage: String?
  private let defaults: UserDefaults
  private let control: ProfileSessionControl
  private let location = CLLocationManager()
  private let regionID = "foqos.geofence.region"
  private var isSettingLocation = false

  init(
    context: ModelContext, defaults: UserDefaults = .standard,
    control: ProfileSessionControl? = nil
  ) {
    self.defaults = defaults
    self.control =
      control ?? ProfileSessionControl(context: context, key: "geofence", defaults: defaults)
    settings =
      defaults.data(forKey: "geofence.settings").flatMap {
        try? JSONDecoder().decode(GeofenceSettings.self, from: $0)
      } ?? GeofenceSettings()
    super.init()
    location.delegate = self
    location.desiredAccuracy = kCLLocationAccuracyHundredMeters
    restoreMonitoring()
  }

  func saveSettings() {
    do {
      defaults.set(try JSONEncoder().encode(settings), forKey: "geofence.settings")
      restoreMonitoring()
    } catch { errorMessage = error.localizedDescription }
  }

  func setActive(_ active: Bool) {
    control.profileID = settings.profileID
    control.setActive(active)
    errorMessage = control.errorMessage
  }

  func setPlaceHere() {
    isSettingLocation = true
    if location.authorizationStatus == .notDetermined {
      location.requestWhenInUseAuthorization()
    } else {
      location.requestLocation()
    }
  }

  func requestBackgroundLocation() {
    location.requestAlwaysAuthorization()
  }

  func restoreMonitoring() {
    for region in location.monitoredRegions where region.identifier == regionID {
      location.stopMonitoring(for: region)
    }
    guard settings.isEnabled else {
      status = "Geofencing is off. Existing blocks stay active until stopped."
      return
    }
    if settings.hasValidRegion
      && CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self)
    {
      let region = CLCircularRegion(
        center: CLLocationCoordinate2D(
          latitude: settings.latitude!, longitude: settings.longitude!),
        radius: settings.radius, identifier: regionID)
      location.startMonitoring(for: region)
    }
    if settings.hasValidRegion {
      status =
        location.authorizationStatus == .authorizedAlways
        ? "Geofence armed. Boundary events can be delayed by iOS."
        : "Allow Always location access for background geofencing."
    } else {
      status = "Save a place to enable geofencing."
    }
  }

  nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    Task { @MainActor in
      if self.isSettingLocation,
        manager.authorizationStatus == .authorizedWhenInUse
          || manager.authorizationStatus == .authorizedAlways
      {
        manager.requestLocation()
      }
      self.restoreMonitoring()
    }
  }

  nonisolated func locationManager(
    _ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]
  ) {
    Task { @MainActor in
      guard self.isSettingLocation, let point = locations.last,
        point.horizontalAccuracy >= 0, point.horizontalAccuracy <= 200,
        abs(point.timestamp.timeIntervalSinceNow) < 60
      else { return }
      self.isSettingLocation = false
      self.settings.latitude = point.coordinate.latitude
      self.settings.longitude = point.coordinate.longitude
      self.saveSettings()
    }
  }

  nonisolated func locationManager(
    _ manager: CLLocationManager, didStartMonitoringFor region: CLRegion
  ) {
    manager.requestState(for: region)
  }

  nonisolated func locationManager(
    _ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion
  ) {
    Task { @MainActor in self.handleBoundary(state, region: region) }
  }

  nonisolated func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
    Task { @MainActor in self.handleBoundary(.inside, region: region) }
  }

  nonisolated func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
    Task { @MainActor in self.handleBoundary(.outside, region: region) }
  }

  func handleBoundary(_ state: CLRegionState, region: CLRegion) {
    guard settings.isEnabled, settings.hasValidRegion, region.identifier == regionID,
      let circle = region as? CLCircularRegion,
      circle.center.latitude == settings.latitude, circle.center.longitude == settings.longitude,
      circle.radius == settings.radius, state != .unknown
    else { return }
    let shouldBlock = (state == .outside) == settings.blockOutside
    setActive(shouldBlock)
  }

  nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    Task { @MainActor in
      self.isSettingLocation = false
      self.errorMessage = error.localizedDescription
    }
  }

  nonisolated func locationManager(
    _ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error
  ) {
    Task { @MainActor in self.errorMessage = error.localizedDescription }
  }
}
