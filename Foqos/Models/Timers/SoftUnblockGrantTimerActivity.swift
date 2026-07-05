import DeviceActivity
import OSLog

private let log = Logger(
  subsystem: "dev.ambitionsoftware.foqos",
  category: SoftUnblockGrantTimerActivity.id
)

class SoftUnblockGrantTimerActivity: TimerActivity {
  static var id: String = SoftUnblockGrantScheduler.activityId

  private let appBlocker = AppBlockerUtil()

  func getDeviceActivityName(from profileId: String) -> DeviceActivityName {
    DeviceActivityName(rawValue: "\(SoftUnblockGrantTimerActivity.id):\(profileId)")
  }

  func profileId(from activityName: DeviceActivityName) -> String {
    SoftUnblockGrantScheduler.identifiers(from: activityName)?.profileId.uuidString ?? ""
  }

  func start(for profile: SharedData.ProfileSnapshot) {
    log.info("Started a soft-unblock expiration monitor for profile \(profile.id.uuidString)")
  }

  func stop(for profile: SharedData.ProfileSnapshot) {
    log.error("Soft-unblock expiration monitor ended without grant identifiers")
  }

  func stop(for profile: SharedData.ProfileSnapshot, activityName: DeviceActivityName) {
    guard let identifiers = SoftUnblockGrantScheduler.identifiers(from: activityName),
      SoftUnblockGrantStore.isActive(
        sessionId: identifiers.sessionId,
        profileId: identifiers.profileId
      ),
      let grant = SoftUnblockGrantStore.grant(
        id: identifiers.grantId,
        sessionId: identifiers.sessionId
      )
    else {
      return
    }

    guard grant.isExpired() else {
      do {
        try SoftUnblockGrantScheduler.scheduleExpiration(for: grant)
      } catch {
        log.error("Failed to reschedule a soft-unblock expiration: \(error.localizedDescription)")
      }
      return
    }

    SoftUnblockGrantStore.removeGrant(id: grant.id, sessionId: grant.sessionId)
    appBlocker.activateRestrictions(for: profile)

    log.info("Expired soft-unblock grant \(grant.id.uuidString)")
  }
}
