import DeviceActivity

class BreakScheduleActivity: TimerActivity {
  static var id: String = "BreakScheduleActivity"

  func getDeviceActivityName(from profileId: String) -> DeviceActivityName {
    return DeviceActivityName(rawValue: "\(BreakScheduleActivity.id):\(profileId)")
  }

  func start() {
    print("BreakScheduleActivity started")
  }

  func stop() {
    print("BreakScheduleActivity stopped")
  }
}
