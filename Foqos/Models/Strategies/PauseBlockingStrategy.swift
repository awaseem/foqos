import SwiftData
import SwiftUI

class PauseBlockingStrategy: BlockingStrategy {
  static let id: String = "PauseBlockingStrategy"

  var name: String = "Pause Mode"
  var description: String = "Shows a countdown before temporarily unlocking each app you tap."
  var iconType: String = "hourglass"
  var color: Color = .purple

  var hasPauseMode: Bool = true
  var startsManually: Bool = true

  var hidden: Bool = false

  var onSessionCreation: ((SessionStatus) -> Void)?
  var onErrorMessage: ((String) -> Void)?

  private let appBlocker: AppBlockerUtil = AppBlockerUtil()

  func getIdentifier() -> String {
    return PauseBlockingStrategy.id
  }

  func startBlocking(
    context: ModelContext,
    profile: BlockedProfiles,
    forceStart: Bool?
  ) -> (any View)? {
    // Activate restrictions first
    self.appBlocker
      .activateRestrictions(for: BlockedProfiles.getSnapshot(for: profile))

    let activeSession =
      BlockedProfileSession
      .createSession(
        in: context,
        withTag: PauseBlockingStrategy.id,
        withProfile: profile,
        forceStart: forceStart ?? false
      )

    // Signal to shield extensions that pause mode is active for this profile
    SharedData.pauseModeActiveProfileId = profile.id.uuidString

    self.onSessionCreation?(.started(activeSession))

    return nil
  }

  func stopBlocking(
    context: ModelContext,
    session: BlockedProfileSession
  ) -> (any View)? {
    // Clear SharedData FIRST so extensions stop reading stale state
    SharedData.pauseModeActiveProfileId = nil
    SharedData.clearAllPauseTimers()
    SharedData.clearUnlockedApps()

    // Restore full restrictions (re-block all apps in profile)
    self.appBlocker.deactivateRestrictions()

    session.endSession()
    try? context.save()

    self.onSessionCreation?(.ended(session.blockedProfile))

    return nil
  }
}
