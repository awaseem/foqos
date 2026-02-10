import SwiftData
import SwiftUI

class PauseTimerBlockingStrategy: BlockingStrategy {
  static var id: String = "PauseTimerBlockingStrategy"

  var name: String = "Pause Timer"
  var description: String =
    "Block with pause timer. Stop initiates a temporary pause, second tap fully stops."
  var iconType: String = "pause.circle.fill"
  var color: Color = .indigo

  var hidden: Bool = false

  var onSessionCreation: ((SessionStatus) -> Void)?
  var onErrorMessage: ((String) -> Void)?

  private let appBlocker: AppBlockerUtil = AppBlockerUtil()

  func getIdentifier() -> String {
    return PauseTimerBlockingStrategy.id
  }

  func startBlocking(
    context: ModelContext,
    profile: BlockedProfiles,
    forceStart: Bool?
  ) -> (any View)? {
    return TimerDurationView(
      profileName: profile.name,
      onDurationSelected: { duration in
        let pauseTimerData = StrategyPauseTimerData(
          pauseDurationInMinutes: duration.durationInMinutes)
        if let data = StrategyPauseTimerData.toData(from: pauseTimerData) {
          profile.strategyData = data
          profile.updatedAt = Date()
          BlockedProfiles.updateSnapshot(for: profile)
          try? context.save()
        }

        let activeSession = BlockedProfileSession.createSession(
          in: context,
          withTag: PauseTimerBlockingStrategy.id,
          withProfile: profile,
          forceStart: forceStart ?? false
        )

        self.onSessionCreation?(.started(activeSession))
      }
    )
  }

  func stopBlocking(
    context: ModelContext,
    session: BlockedProfileSession
  ) -> (any View)? {
    let isPauseActive =
      DeviceActivityCenterUtil.getActivePauseTimerActivity(
        for: session.blockedProfile) != nil

    if isPauseActive {
      // Pause is active - user wants to fully stop the session
      DeviceActivityCenterUtil.removePauseTimerActivity(for: session.blockedProfile)
      session.endSession()
      try? context.save()
      self.appBlocker.deactivateRestrictions()
      self.onSessionCreation?(.ended(session.blockedProfile))
    } else {
      // No pause active - initiate pause mode
      DeviceActivityCenterUtil.startPauseTimerActivity(for: session.blockedProfile)
      // Session continues, just in pause mode
      // Don't call onSessionCreation since session is still active
    }

    return nil
  }

  /// Ends the pause without ending the session (reactivates restrictions)
  func endPause(context: ModelContext, session: BlockedProfileSession) {
    DeviceActivityCenterUtil.removePauseTimerActivity(for: session.blockedProfile)
    // Note: We don't call session.endSession() here, just reactivate restrictions
    appBlocker.activateRestrictions(for: BlockedProfiles.getSnapshot(for: session.blockedProfile))
  }
}
