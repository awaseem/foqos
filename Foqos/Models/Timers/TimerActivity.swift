import DeviceActivity
import OSLog

protocol TimerActivity {
  static var id: String { get }

  func getDeviceActivityName(from profileId: String) -> DeviceActivityName

  func start(for profile: SharedData.ProfileSnapshot)
  func stop(for profile: SharedData.ProfileSnapshot)
  func start(for profile: SharedData.ProfileSnapshot, activityName: DeviceActivityName)
  func stop(for profile: SharedData.ProfileSnapshot, activityName: DeviceActivityName)
  func profileId(from activityName: DeviceActivityName) -> String
}

extension TimerActivity {
  func start(for profile: SharedData.ProfileSnapshot, activityName _: DeviceActivityName) {
    start(for: profile)
  }

  func stop(for profile: SharedData.ProfileSnapshot, activityName _: DeviceActivityName) {
    stop(for: profile)
  }

  func profileId(from activityName: DeviceActivityName) -> String {
    let components = activityName.rawValue.split(separator: ":", maxSplits: 1)
    if components.count == 2 {
      return String(components[1])
    }

    return activityName.rawValue
  }
}
