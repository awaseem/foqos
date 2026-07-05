import DeviceActivity
import OSLog

private let log = Logger(
  subsystem: "dev.ambitionsoftware.foqos",
  category: SoftUnblockGrantTimerActivity.id
)

class SoftUnblockGrantTimerActivity: TimerActivity {
  static var id: String = SoftUnblockGrantScheduler.activityId

  private let appBlocker = AppBlockerUtil()

  func profileId(from activityName: DeviceActivityName) -> String {
    SoftUnblockGrantScheduler.identifiers(from: activityName)?.profileId.uuidString ?? ""
  }

  func start(for profile: SharedData.ProfileSnapshot) {
    log.error("Soft-unblock expiration monitor started without grant identifiers")
  }

  func start(for profile: SharedData.ProfileSnapshot, activityName: DeviceActivityName) {
    guard let grant = activeGrant(for: activityName) else { return }

    guard !grant.isExpired() else {
      expire(grant, for: profile)
      return
    }

    applyActiveGrants(for: profile)
    log.info("Started soft-unblock grant \(grant.id.uuidString)")
  }

  func stop(for profile: SharedData.ProfileSnapshot) {
    log.error("Soft-unblock expiration monitor ended without grant identifiers")
  }

  func stop(for profile: SharedData.ProfileSnapshot, activityName: DeviceActivityName) {
    guard let grant = activeGrant(for: activityName) else { return }
    guard grant.isExpired() else { return }

    expire(grant, for: profile)
    log.info("Expired soft-unblock grant \(grant.id.uuidString)")
  }

  private func activeGrant(for activityName: DeviceActivityName) -> SoftUnblockGrant? {
    guard let identifiers = SoftUnblockGrantScheduler.identifiers(from: activityName),
      SoftUnblockGrantStore.isActive(
        sessionId: identifiers.sessionId,
        profileId: identifiers.profileId
      )
    else {
      return nil
    }

    return SoftUnblockGrantStore.grant(
      id: identifiers.grantId,
      sessionId: identifiers.sessionId
    )
  }

  private func expire(_ grant: SoftUnblockGrant, for profile: SharedData.ProfileSnapshot) {
    SoftUnblockGrantStore.removeGrant(id: grant.id, sessionId: grant.sessionId)
    applyActiveGrants(for: profile)
  }

  private func applyActiveGrants(for profile: SharedData.ProfileSnapshot) {
    let activeGrants = SoftUnblockGrantStore.activeGrants(for: profile.id)
    let unblockedApplicationTokens = Set(
      activeGrants.compactMap(\.resource.applicationToken)
    )
    let unblockedCategoryTokens = Set(
      activeGrants.compactMap(\.resource.categoryToken)
    )

    appBlocker.activateSoftUnblockRestrictions(
      for: profile,
      unblockedApplicationTokens: unblockedApplicationTokens,
      unblockedCategoryTokens: unblockedCategoryTokens
    )
  }
}
