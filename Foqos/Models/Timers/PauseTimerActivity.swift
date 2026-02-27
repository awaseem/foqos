import DeviceActivity
import OSLog

private let log = Logger(subsystem: "com.foqos.monitor", category: PauseTimerActivity.id)

class PauseTimerActivity: TimerActivity {
  static var id: String = "PauseScheduleActivity"

  private let appBlocker = AppBlockerUtil()

  func getDeviceActivityName(from profileId: String) -> DeviceActivityName {
    return DeviceActivityName(rawValue: "\(PauseTimerActivity.id):\(profileId)")
  }

  func getAllPauseTimerActivities(from activities: [DeviceActivityName]) -> [DeviceActivityName] {
    return activities.filter { $0.rawValue.starts(with: PauseTimerActivity.id) }
  }

  func start(for profile: SharedData.ProfileSnapshot) {
    let profileId = profile.id.uuidString

    guard let activeSession = SharedData.getActiveSharedSession() else {
      log.info("Start pause timer activity for \(profileId), no active session found")
      return
    }

    // Check to make sure the active session is the same as the profile before starting pause
    if activeSession.blockedProfileId != profile.id {
      log.info(
        "Start pause timer activity for \(profileId), active session profile does not match profile to start pause"
      )
      return
    }

    // End restrictions for pause, preserving strict mode if enabled
    appBlocker.deactivateRestrictionsForBreak(for: profile)

    // Track pause start time
    let now = Date()

    SharedData.resetPause()
    SharedData.setPauseStartTime(date: now)

    log.info("Started pause for profile \(profileId)")
  }

  func stop(for profile: SharedData.ProfileSnapshot) {
    let profileId = profile.id.uuidString

    guard let activeSession = SharedData.getActiveSharedSession() else {
      log.info("Stop pause timer activity for \(profileId), no active session found")
      return
    }

    // Check to make sure the active session is the same as the profile before stopping the pause
    if activeSession.blockedProfileId != profile.id {
      log.info(
        "Stop pause timer activity for \(profileId), active session profile does not match profile to start pause"
      )
      return
    }

    // Check if a pause is active before stopping the pause
    if activeSession.pauseStartTime != nil && activeSession.pauseEndTime == nil {
      // Start restrictions again since pause is ended
      appBlocker.activateRestrictions(for: profile)

      // Set the pause end time
      let now = Date()
      SharedData.setPauseEndTime(date: now)
    }

    log.info("Ended pause for profile \(profileId)")
  }
}
