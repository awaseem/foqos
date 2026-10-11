import FamilyControls
import Foundation
import ManagedSettings

@MainActor
enum IntentionalAccessGrant {
  static func issue(
    token: ApplicationToken, profile: BlockedProfiles, sessionID: String,
    schedule: (SoftUnblockGrant) throws -> Void = SoftUnblockGrantScheduler.scheduleGrant,
    apply: (SharedData.ProfileSnapshot, [SoftUnblockGrant]) -> Void = { profile, grants in
      let applications = Set(
        grants.compactMap { grant -> ApplicationToken? in
          if case .application(let token) = grant.resource { return token }
          return nil
        })
      AppBlockerUtil().activateSoftUnblockRestrictions(
        for: profile,
        unblockedApplicationTokens: applications, unblockedCategoryTokens: [])
    }
  ) throws {
    guard AuthorizationCenter.shared.authorizationStatus == .approved else {
      throw ProfileSessionControlError.screenTimeRequired
    }
    guard profile.blockingStrategyId == IntentionalAccessBlockingStrategy.id,
      !profile.enableAllowMode,
      profile.selectedActivity.applicationTokens.contains(token),
      let configuration = IntentionalAccessConfiguration.decode(profile.strategyData),
      let session = SoftUnblockGrantStore.activeSession,
      session.sessionId == sessionID, session.profileId == profile.id,
      SharedData.getActiveSharedSession()?.id == sessionID
    else { throw FoqosControlError.sessionChanged }
    let now = Date()
    let grant = SoftUnblockGrant(
      id: UUID(), sessionId: sessionID, profileId: profile.id,
      resource: .application(token), createdAt: now,
      expiresAt: now.addingTimeInterval(Double(configuration.accessDurationInMinutes * 60)))
    guard SoftUnblockGrantStore.issue(grant) else {
      throw FoqosControlError.actionFailed("No opens remain. You can stop the session instead.")
    }
    do { try schedule(grant) } catch {
      SoftUnblockGrantStore.rollbackIssuedGrant(id: grant.id, sessionId: sessionID)
      throw error
    }
    apply(
      BlockedProfiles.getSnapshot(for: profile), SoftUnblockGrantStore.activeGrants(for: profile.id)
    )
  }
}
