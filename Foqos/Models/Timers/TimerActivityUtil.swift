import DeviceActivity

class TimerActivityUtil {
  static func startTimerActivity(for activity: DeviceActivityName) {
    let parts = getTimerParts(from: activity)

    guard let timerActivity = getTimerActivity(for: parts.deviceActivityId),
      let profile = getProfile(for: timerActivity.profileId(from: activity))
    else {
      return
    }

    let previousSession = SharedData.getActiveSharedSession()
    timerActivity.start(for: profile, activityName: activity)
    publishSessionChange(from: previousSession, callbackProfile: profile)
  }

  static func stopTimerActivity(for activity: DeviceActivityName) {
    let parts = getTimerParts(from: activity)

    guard let timerActivity = getTimerActivity(for: parts.deviceActivityId),
      let profile = getProfile(for: timerActivity.profileId(from: activity))
    else {
      return
    }

    let previousSession = SharedData.getActiveSharedSession()
    timerActivity.stop(for: profile, activityName: activity)
    publishSessionChange(from: previousSession, callbackProfile: profile)
  }

  private static func publishSessionChange(
    from previousSession: SharedData.SessionSnapshot?,
    callbackProfile: SharedData.ProfileSnapshot
  ) {
    let currentSession = SharedData.getActiveSharedSession()
    guard currentSession != previousSession else { return }

    let currentProfile = getProfile(for: currentSession, callbackProfile: callbackProfile)
    // A missing profile must not turn an unrelated active session into an inactive cloud record.
    guard currentSession == nil || currentProfile != nil else { return }
    guard
      currentProfile?.enableMacSync == true
        || getProfile(for: previousSession, callbackProfile: callbackProfile)?.enableMacSync == true
    else { return }

    ActiveProfileSyncStore.publish(session: currentSession, profile: currentProfile)
  }

  private static func getTimerParts(from activity: DeviceActivityName) -> (
    deviceActivityId: String, profileId: String
  ) {
    let activityName = activity.rawValue
    let components = activityName.split(separator: ":", maxSplits: 1)

    // For versions >= 1.24, the activity name format is "type:profileId"
    if components.count == 2 {
      return (deviceActivityId: String(components[0]), profileId: String(components[1]))
    }

    // For versions < 1.24, the activity name format is just "profileId" and only supports schedule timer activity
    // This is to support backward compatibility for older schedules
    return (deviceActivityId: ScheduleTimerActivity.id, profileId: activityName)
  }

  private static func getTimerActivity(for deviceActivityId: String) -> TimerActivity? {
    switch deviceActivityId {
    case ScheduleTimerActivity.id:
      return ScheduleTimerActivity()
    case BreakTimerActivity.id:
      return BreakTimerActivity()
    case StrategyTimerActivity.id:
      return StrategyTimerActivity()
    case PauseTimerActivity.id:
      return PauseTimerActivity()
    case SoftUnblockGrantTimerActivity.id:
      return SoftUnblockGrantTimerActivity()
    default:
      return nil
    }
  }

  private static func getProfile(for profileId: String) -> SharedData.ProfileSnapshot? {
    return SharedData.snapshot(for: profileId)
  }

  private static func getProfile(
    for session: SharedData.SessionSnapshot?,
    callbackProfile: SharedData.ProfileSnapshot
  ) -> SharedData.ProfileSnapshot? {
    guard let session else { return nil }
    if session.blockedProfileId == callbackProfile.id {
      return callbackProfile
    }
    return getProfile(for: session.blockedProfileId.uuidString)
  }
}
