import SwiftData
import SwiftUI

class PauseBlockingStrategy: BlockingStrategy {
  static var id: String = "PauseBlockingStrategy"

  var name: String = "Pause Mode"
  var description: String =
    "Start manually. When you open a blocked app, use the shield button for timed access to that app."
  var iconAssetName: String = "ShieldSticker"
  var color: Color = .purple

  var hasPauseMode: Bool = true
  var startsManually: Bool = true
  var isBeta: Bool = true

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
    SharedData.debugLog(
      "PauseBlockingStrategy.startBlocking profile=\(profile.id.uuidString) name=\(profile.name)"
    )

    return PauseDurationView(
      profileName: profile.name,
      onDurationSelected: { pauseDurationMinutes in
        SharedData.debugLog(
          "Pause duration selected profile=\(profile.id.uuidString) minutes=\(pauseDurationMinutes)"
        )

        let pauseTimerData = StrategyPauseTimerData(
          pauseDurationInMinutes: pauseDurationMinutes)
        if let data = StrategyPauseTimerData.toData(from: pauseTimerData) {
          profile.strategyData = data
          profile.updatedAt = Date()
          BlockedProfiles.updateSnapshot(for: profile)
          try? context.save()
          SharedData.debugLog(
            "Saved pause strategyData and snapshot profile=\(profile.id.uuidString)"
          )
        } else {
          SharedData.debugLog(
            "Failed to encode pause strategyData profile=\(profile.id.uuidString)"
          )
        }

        SharedData.startPauseMode(for: profile.id.uuidString)
        SharedData.debugLog(
          "Started shared pause mode activeProfileId=\(SharedData.pauseModeActiveProfileId ?? "nil")"
        )
        self.appBlocker.activateRestrictions(for: BlockedProfiles.getSnapshot(for: profile))

        let activeSession = BlockedProfileSession.createSession(
          in: context,
          withTag: PauseBlockingStrategy.id,
          withProfile: profile,
          forceStart: forceStart ?? false
        )

        SharedData.debugLog(
          "Created pause session id=\(activeSession.id) tag=\(activeSession.tag)"
        )
        self.onSessionCreation?(.started(activeSession))
      }
    )
  }

  func stopBlocking(
    context: ModelContext,
    session: BlockedProfileSession
  ) -> (any View)? {
    SharedData.debugLog(
      "PauseBlockingStrategy.stopBlocking profile=\(session.blockedProfile.id.uuidString) session=\(session.id)"
    )
    SharedData.clearPauseModeState()

    session.endSession()
    try? context.save()
    appBlocker.deactivateRestrictions()

    onSessionCreation?(.ended(session.blockedProfile))

    return nil
  }
}
