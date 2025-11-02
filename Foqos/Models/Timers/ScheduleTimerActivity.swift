import DeviceActivity
import OSLog

class ScheduleTimerActivity: TimerActivity {
  static var id: String = "ScheduleTimerActivity"

  private let log = Logger(subsystem: "com.foqos.monitor", category: ScheduleTimerActivity.id)

  private let appBlocker = AppBlockerUtil()

  func getDeviceActivityName(from profileId: String) -> DeviceActivityName {
    // Since schedules were implemented before the timer activities, the profile id is used as the device activity name for
    // backward compatibility
    return DeviceActivityName(rawValue: profileId)
  }

  func start(for profile: SharedData.ProfileSnapshot) {
    let profileId = profile.id.uuidString

    guard let schedule = profile.schedule
    else {
      log.info("Start schedule timer activity for \(profileId), no schedule for profile found")
      return
    }

    if !schedule.isTodayScheduled() {
      log.info(
        "Start schedule timer activity for \(profileId), schedule is not scheduled for today")
      return
    }

    if !schedule.olderThan15Minutes() {
      log.info("Start schedule timer activity for \(profileId), schedule is too new")
      return
    }

    log.info("Start schedule timer activity for \(profileId), profile: \(profileId)")

    if let existingSession = SharedData.getActiveSharedSession() {
      if existingSession.blockedProfileId == profile.id {
        log.info(
          "Start schedule timer activity for \(profileId), existing session profile matches device activity profile, continuing active session"
        )
        return
      } else {
        log.info(
          "Start schedule timer activity for \(profileId), existing session profile does not match device activity profile, ending active session"
        )
        SharedData.endActiveSharedSession()
      }
    }

    // Create a new active scheduled session for the profile
    SharedData.createSessionForSchedular(for: profile.id)

    // Start restrictions
    appBlocker.activateRestrictions(for: profile)
  }

  func stop(for profile: SharedData.ProfileSnapshot) {
    let profileId = profile.id.uuidString

    guard let activeSession = SharedData.getActiveSharedSession() else {
      log.info("Stop schedule timer activity for \(profileId), no active session found")
      return
    }

    // Check to make sure the active session is the same as the profile before disabling restrictions
    if activeSession.blockedProfileId != profile.id {
      log.info(
        "Stop schedule timer activity for \(profileId), active session profile does not match device activity profile"
      )
      return
    }

    // End restrictions
    appBlocker.deactivateRestrictions()

    // End the active scheduled session
    SharedData.endActiveSharedSession()
  }


  func getScheduleInterval(from schedule: BlockedProfileSchedule) -> (
    intervalStart: DateComponents, intervalEnd: DateComponents
  ) {
    let intervalStart = DateComponents(hour: schedule.startHour, minute: schedule.startMinute)
    let intervalEnd = DateComponents(hour: schedule.endHour, minute: schedule.endMinute)
    return (intervalStart: intervalStart, intervalEnd: intervalEnd)
  }
}
