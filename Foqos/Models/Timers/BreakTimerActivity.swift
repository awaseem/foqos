import DeviceActivity
import OSLog

private let log = Logger(subsystem: "com.foqos.monitor", category: BreakTimerActivity.id)

class BreakTimerActivity: TimerActivity {
  static var id: String = "BreakScheduleActivity"

  private let appBlocker = AppBlockerUtil()

  func getDeviceActivityName(from profileId: String) -> DeviceActivityName {
    return DeviceActivityName(rawValue: "\(BreakTimerActivity.id):\(profileId)")
  }

  func getAllBreakTimerActivities(from activities: [DeviceActivityName]) -> [DeviceActivityName] {
    return activities.filter { $0.rawValue.starts(with: BreakTimerActivity.id) }
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
        "Stop break timer activity for \(profileId), active session profile does not match profile to start break"
      )
      return
    }

    // Check is a break is active before stopping the break
    if activeSession.breakStartTime != nil && activeSession.breakEndTime == nil {
      // Start restrictions again since break is ended
      appBlocker.activateRestrictions(for: profile)

      // Set the break end time
      let now = Date()
      SharedData.setBreakEndTime(date: now)
    }
  }

  func getBreakInterval(from minutes: Int) -> (
    intervalStart: DateComponents, intervalEnd: DateComponents
  ) {
    let intervalStart = DateComponents(hour: 0, minute: 0)

    // Get current time
    let now = Date()
    let currentComponents = Calendar.current.dateComponents([.hour, .minute], from: now)
    let currentHour = currentComponents.hour ?? 0
    let currentMinute = currentComponents.minute ?? 0

    // Calculate end time by adding minutes to current time
    let totalMinutes = currentMinute + minutes
    var endHour = currentHour + (totalMinutes / 60)
    var endMinute = totalMinutes % 60

    // Cap at 23:59 if it would roll over past midnight
    if endHour >= 24 || (endHour == 23 && endMinute >= 59) {
      endHour = 23
      endMinute = 59
    }

    let intervalEnd = DateComponents(hour: endHour, minute: endMinute)
    return (intervalStart: intervalStart, intervalEnd: intervalEnd)
  }
}
