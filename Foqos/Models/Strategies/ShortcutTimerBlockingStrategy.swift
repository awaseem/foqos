import SwiftData
import SwiftUI

class ShortcutTimerBlockingStrategy: BlockingStrategy {
  static var id: String = "ShortcutTimerBlockingStrategy"

  var name: String = "Timer + Manual"
  var description: String =
    "Choose how long blocking should last. Stop early with the Stop button."
  var iconAssetName: String = "Manual + Timer"
  var color: Color = .mint

  var hasTimer: Bool = true
  var startsManually: Bool = true

  var onSessionCreation: ((SessionStatus) -> Void)?
  var onErrorMessage: ((String) -> Void)?

  private let appBlocker: AppBlockerUtil = AppBlockerUtil()

  func getIdentifier() -> String {
    return ShortcutTimerBlockingStrategy.id
  }

  func startBlocking(
    context: ModelContext,
    profile: BlockedProfiles,
    forceStart: Bool?
  ) -> (any View)? {
    if forceStart == true {
      return startTimerSession(context: context, profile: profile, forceStart: true)
    }

    return TimerDurationView(
      profileName: profile.name,
      onDurationSelected: { duration in
        if let strategyTimerData = StrategyTimerData.toData(from: duration) {
          profile.strategyData = strategyTimerData
          profile.updatedAt = Date()
          BlockedProfiles.updateSnapshot(for: profile)
          try? context.save()
        }

        _ = self.startTimerSession(context: context, profile: profile, forceStart: false)
      }
    )
  }

  private func startTimerSession(
    context: ModelContext,
    profile: BlockedProfiles,
    forceStart: Bool
  ) -> (any View)? {
    guard profile.strategyData != nil else {
      self.onErrorMessage?("No timer duration specified for this profile")
      return nil
    }

    let activeSession = BlockedProfileSession.createSession(
      in: context,
      withTag: profile.blockingStrategyId ?? "ManualBlockingStrategy",
      withProfile: profile,
      forceStart: forceStart
    )

    DeviceActivityCenterUtil.startStrategyTimerActivity(for: profile)

    self.onSessionCreation?(.started(activeSession))

    return nil
  }

  func stopBlocking(
    context: ModelContext,
    session: BlockedProfileSession
  ) -> (any View)? {
    session.endSession()
    try? context.save()
    self.appBlocker.deactivateRestrictions()

    self.onSessionCreation?(.ended(session.blockedProfile))

    return nil
  }
}
