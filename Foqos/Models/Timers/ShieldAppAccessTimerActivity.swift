import DeviceActivity
import OSLog

private let log = Logger(subsystem: "com.foqos.monitor", category: ShieldAppAccessTimerActivity.id)

class ShieldAppAccessTimerActivity: TimerActivity {
  static var id: String = "ShieldAppAccessTimerActivity"

  private let appBlocker = AppBlockerUtil()

  func getDeviceActivityName(from profileId: String) -> DeviceActivityName {
    return DeviceActivityName(rawValue: "\(ShieldAppAccessTimerActivity.id):\(profileId)")
  }

  func getDeviceActivityName(profileId: String, tokenKey: String) -> DeviceActivityName {
    return DeviceActivityName(
      rawValue: "\(ShieldAppAccessTimerActivity.id):\(profileId)|app|\(tokenKey)"
    )
  }

  func profileId(from activityName: DeviceActivityName) -> String {
    let payload = payload(from: activityName)
    return String(payload.split(separator: "|", maxSplits: 1).first ?? "")
  }

  func start(for profile: SharedData.ProfileSnapshot) {
    SharedData.debugLog("ShieldAppAccessTimerActivity.start profile=\(profile.id.uuidString)")
    log.info("Started app access timer for profile \(profile.id.uuidString)")
  }

  func stop(for profile: SharedData.ProfileSnapshot) {
    SharedData.debugLog("ShieldAppAccessTimerActivity.stop profile=\(profile.id.uuidString)")
    appBlocker.activateRestrictions(for: profile)
    log.info("Stopped app access timer for profile \(profile.id.uuidString)")
  }

  func stop(for profile: SharedData.ProfileSnapshot, activityName: DeviceActivityName) {
    let payload = payload(from: activityName)
    let components = payload.split(separator: "|", maxSplits: 2)

    guard components.count == 2 || components.count == 3 else {
      SharedData.debugLog(
        "ShieldAppAccessTimerActivity.stop could not parse token activity=\(activityName.rawValue)"
      )
      stop(for: profile)
      return
    }

    let resourceKind = components.count == 3 ? String(components[1]) : "app"
    let tokenKey = String(components[components.count - 1])

    if resourceKind == "category" {
      SharedData.debugLog(
        "Expiring category access profile=\(profile.id.uuidString) tokenKey=\(String(tokenKey.prefix(12)))"
      )
      SharedData.removePauseUnlockedCategoryToken(matching: tokenKey)
    } else {
      SharedData.debugLog(
        "Expiring app access profile=\(profile.id.uuidString) tokenKey=\(String(tokenKey.prefix(12)))"
      )
      SharedData.removePauseUnlockedApplicationToken(matching: tokenKey)
    }

    appBlocker.activateRestrictions(for: profile)

    log.info("Expired \(resourceKind) access for profile \(profile.id.uuidString)")
  }

  private func payload(from activityName: DeviceActivityName) -> String {
    let components = activityName.rawValue.split(separator: ":", maxSplits: 1)
    guard components.count == 2 else {
      return activityName.rawValue
    }

    return String(components[1])
  }
}
