import DeviceActivity
import OSLog

class BreakTimerActivity: TimerActivity {
  static var id: String = "BreakScheduleActivity"

  private let appBlocker = AppBlockerUtil()
  private let log = Logger(subsystem: "com.foqos.monitor", category: BreakTimerActivity.id)

  func getDeviceActivityName(from profileId: String) -> DeviceActivityName {
    return DeviceActivityName(rawValue: "\(BreakTimerActivity.id):\(profileId)")
  }

  func start(for profile: SharedData.ProfileSnapshot) {
    let profileId = profile.id.uuidString

    guard let activeSession = SharedData.getActiveSharedSession() else {
      log.info(
        "Start break timer activity for \(profileId), no active session found to start break")
      return
    }

    // Check to make sure the active session is the same as the profile before starting break
    if activeSession.blockedProfileId != profile.id {
      log.info(
        "Start break timer activity for \(profileId), active session profile does not match profile to start break"
      )
      return
    }

    // End restrictions for break
    appBlocker.deactivateRestrictions()

    // End the active scheduled session
    let now = Date()
    SharedData.setBreakStartTime(date: now)
  }

  func stop(for profile: SharedData.ProfileSnapshot) {
    let profileId = profile.id.uuidString

    guard let activeSession = SharedData.getActiveSharedSession() else {
      log.info(
        "Stop break timer activity for \(profileId), no active session found to stop break")
      return
    }

    // Check to make sure the active session is the same as the profile before stopping the break
    if activeSession.blockedProfileId != profile.id {
      log.info(
        "Start break timer activity for \(profileId), active session profile does not match profile to start break"
      )
      return
    }

    // Start restrictions again since break is ended
    appBlocker.activateRestrictions(for: profile)

    // Set the break end time
    let now = Date()
    SharedData.setBreakEndTime(date: now)
  }
}
