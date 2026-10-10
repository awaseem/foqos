import CoreLocation
import CoreMotion
import FamilyControls
import SwiftData
import SwiftUI
import UserNotifications

@MainActor
final class FamilyOutingManager: NSObject, ObservableObject, CLLocationManagerDelegate {
  @Published var settings: FamilyOutingSettings
  @Published var status = "Family automation is off."
  @Published var activity = "Unknown"
  @Published var audit: [String]
  @Published var errorMessage: String?

  private let context: ModelContext
  private let strategyManager: StrategyManager
  private let isScreenTimeAuthorized: () -> Bool
  private let defaults: UserDefaults
  private let location = CLLocationManager()
  private let motion = CMMotionActivityManager()
  private let regionID = "foqos.family.region"
  private var isSettingLocation = false
  private var ownedSessionID: String?

  init(
    context: ModelContext, defaults: UserDefaults = .standard,
    strategyManager: StrategyManager = .shared,
    isScreenTimeAuthorized: @escaping () -> Bool = {
      AuthorizationCenter.shared.authorizationStatus == .approved
    }
  ) {
    self.strategyManager = strategyManager
    self.isScreenTimeAuthorized = isScreenTimeAuthorized
    self.context = context
    self.defaults = defaults
    settings =
      defaults.data(forKey: "family.settings").flatMap {
        try? JSONDecoder().decode(FamilyOutingSettings.self, from: $0)
      } ?? FamilyOutingSettings()
    audit = defaults.stringArray(forKey: "family.audit") ?? []
    ownedSessionID = defaults.string(forKey: "family.session")
    super.init()
    location.delegate = self
    location.desiredAccuracy = kCLLocationAccuracyHundredMeters
    restoreMonitoring()
  }

  func saveSettings() {
    do {
      defaults.set(try JSONEncoder().encode(settings), forKey: "family.settings")
      record("Family automation \(settings.isEnabled ? "enabled" : "disabled").")
      restoreMonitoring()
    } catch { errorMessage = error.localizedDescription }
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
    motion.stopActivityUpdates()
    guard settings.isEnabled else {
      status = "Family automation is off. Existing blocks stay active until stopped."
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
      status = "No place saved. Activity starts work only while the app runs."
    }
    if settings.blockWhileMoving {
      activity =
        CMMotionActivityManager.isActivityAvailable()
        ? "Waiting for activity"
        : "Motion detection is unavailable on this device"
      if CMMotionActivityManager.authorizationStatus() == .denied
        || CMMotionActivityManager.authorizationStatus() == .restricted
      {
        activity = "Motion access denied. Check iOS Settings."
      }
    }
    if settings.blockWhileMoving && CMMotionActivityManager.isActivityAvailable() {
      // shortcut: motion updates resume with the app, use geofences for background starts.
      motion.startActivityUpdates(to: .main) { [weak self] update in
        Task { @MainActor in
          guard let self, let update, self.settings.isEnabled, self.settings.blockWhileMoving else {
            return
          }
          self.activity =
            update.walking
            ? "Walking"
            : update.running
              ? "Running"
              : update.cycling ? "Cycling" : update.automotive ? "In a vehicle" : "Still / unknown"
          guard update.confidence != .low,
            update.walking || update.running || update.cycling
          else { return }
          self.apply(.start, source: "Activity: \(self.activity)")
        }
      }
    }
  }

  func apply(
    _ action: FamilyCommand.Action, source: String, message: String = "Phone away. Family time ❤️"
  ) {
    errorMessage = nil
    do {
      if action == .remind {
        let content = UNMutableNotificationContent()
        content.title = "Family time"
        content.body = String(message.prefix(200))
        content.sound = .default
        let request = UNNotificationRequest(
          identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { [weak self] error in
          if let error {
            Task { @MainActor in self?.errorMessage = error.localizedDescription }
          }
        }
        record("\(source): reminder received — \(content.body)")
        return
      }
      guard let profileID = settings.profileID,
        let profile = try BlockedProfiles.findProfile(byID: profileID, in: context),
        profile.blockingStrategyId == ManualBlockingStrategy.id
      else { throw FamilyOutingError.manualProfileRequired }
      let manager = strategyManager
      let current = BlockedProfileSession.mostRecentActiveSession(in: context)
      if action == .stop {
        // Never end a manually started, scheduled, or replacement session.
        guard let current, current.id == ownedSessionID else { return }
      } else {
        guard isScreenTimeAuthorized() else {
          throw FamilyOutingError.screenTimeRequired
        }
        if let current {
          if current.blockedProfile.id != profileID { throw FoqosControlError.anotherProfileActive }
          return
        }
      }
      let didChange = try manager.setProfileActiveFromControl(
        action == .start, profileID: profileID, context: context,
        expectedSessionID: action == .stop ? ownedSessionID : nil)
      guard didChange else { return }
      ownedSessionID =
        action == .start
        ? BlockedProfileSession.mostRecentActiveSession(in: context)?.id : nil
      defaults.set(ownedSessionID, forKey: "family.session")
      record("\(source): \(action.rawValue) — \(profile.name)")
    } catch {
      errorMessage = error.localizedDescription
      record("\(source): failed — \(error.localizedDescription)")
    }
  }

  func observeSession() {
    guard settings.profileID != nil else { return }
    let session = BlockedProfileSession.mostRecentActiveSession(in: context)
    let state = session.map { "\($0.id):\($0.isBreakActive):\($0.isPauseActive)" } ?? "inactive"
    guard state != defaults.string(forKey: "family.observedState") else { return }
    defaults.set(state, forKey: "family.observedState")
    record(
      session.map {
        "Observed \($0.blockedProfile.name): \($0.isBreakActive ? "break" : $0.isPauseActive ? "pause" : "active")"
      } ?? "Observed: no active session")
  }

  func snapshot() -> String {
    let session = BlockedProfileSession.mostRecentActiveSession(in: context)
    let state =
      session.map {
        "\($0.blockedProfile.name): \($0.isBreakActive ? "on break" : $0.isPauseActive ? "paused" : "active")"
      } ?? "No active session"
    return
      "Updated: \(Date().formatted())\n\(state)\nAutomation: \(settings.isEnabled ? "on" : "off")\n"
      + audit.suffix(30).joined(separator: "\n")
  }

  func record(_ text: String) {
    audit.append("\(Date().formatted()): \(text)")
    audit = Array(audit.suffix(100))
    defaults.set(audit, forKey: "family.audit")
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
    apply(shouldBlock ? .start : .stop, source: "Geofence")
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

enum FamilyOutingError: LocalizedError {
  case manualProfileRequired, screenTimeRequired, invalidInvitation

  var errorDescription: String? {
    switch self {
    case .manualProfileRequired: return "Choose a Manual profile for family controls."
    case .screenTimeRequired: return "Grant Screen Time access in Foqos first."
    case .invalidInvitation: return "Paste a private iCloud sharing invitation from your partner."
    }
  }
}
