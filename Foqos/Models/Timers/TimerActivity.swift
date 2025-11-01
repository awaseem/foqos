import DeviceActivity
import OSLog

protocol TimerActivity {
  static var id: String { get }

  func getDeviceActivityName(from profileId: String) -> DeviceActivityName

  func start(for profile: SharedData.ProfileSnapshot)
  func stop(for profile: SharedData.ProfileSnapshot)
}
