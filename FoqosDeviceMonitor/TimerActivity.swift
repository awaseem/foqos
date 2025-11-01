import DeviceActivity

protocol TimerActivity {
  static var id: String { get }

  func getDeviceActivityName(from profileId: String) -> DeviceActivityName

  func start()
  func stop()
}
