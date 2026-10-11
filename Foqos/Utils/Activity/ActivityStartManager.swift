import CoreMotion
import SwiftData
import SwiftUI

@MainActor
final class ActivityStartManager: ObservableObject {
  @Published var profileID: UUID? {
    didSet { control.profileID = profileID }
  }
  @Published var isEnabled: Bool {
    didSet {
      defaults.set(isEnabled, forKey: "activity.enabled")
      restoreMonitoring()
    }
  }
  @Published var status = "Activity starts are off."
  @Published var errorMessage: String?
  private let defaults: UserDefaults
  private let control: ProfileSessionControl
  private var motion: CMMotionActivityManager?

  init(
    context: ModelContext, defaults: UserDefaults = .standard,
    control: ProfileSessionControl? = nil
  ) {
    self.defaults = defaults
    let control =
      control ?? ProfileSessionControl(context: context, key: "activity", defaults: defaults)
    self.control = control
    profileID = control.profileID
    isEnabled = defaults.bool(forKey: "activity.enabled")
    restoreMonitoring()
  }

  func restoreMonitoring() {
    motion?.stopActivityUpdates()
    guard isEnabled else {
      status = "Activity starts are off. Existing blocks stay active."
      return
    }
    guard CMMotionActivityManager.isActivityAvailable() else {
      status = "Motion detection is unavailable on this device."
      return
    }
    guard CMMotionActivityManager.authorizationStatus() != .denied,
      CMMotionActivityManager.authorizationStatus() != .restricted
    else {
      status = "Motion access denied. Check iOS Settings."
      return
    }
    status = "Waiting for walking, running or cycling."
    let motion = self.motion ?? CMMotionActivityManager()
    self.motion = motion
    // shortcut: motion updates pause during suspension, use a location automation for background starts.
    motion.startActivityUpdates(to: .main) { [weak self] update in
      Task { @MainActor in
        guard let self, let update else { return }
        self.handleActivity(
          walking: update.walking, running: update.running,
          cycling: update.cycling, confident: update.confidence != .low)
      }
    }
  }

  func handleActivity(walking: Bool, running: Bool, cycling: Bool, confident: Bool) {
    guard isEnabled, confident, walking || running || cycling else { return }
    status = walking ? "Walking" : running ? "Running" : "Cycling"
    setActive(true)
  }

  func setActive(_ active: Bool) {
    control.setActive(active)
    errorMessage = control.errorMessage
  }
}
