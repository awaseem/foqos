import SwiftData
import SwiftUI

class NFCTimerBlockingStrategy: BlockingStrategy {
  static var id: String = "NFCTimerBlockingStrategy"

  var name: String = "Timed Lock with Early Unlock"
  var description: String = "Set a timer duration. Unlock early with DO Card, or auto-unlock when timer expires."
  var iconType: String = "alarm.waves.left.and.right"
  var color: Color = Color(hex: "#FF6B35").opacity(0.8)

  var hidden: Bool = false

  var onSessionCreation: ((SessionStatus) -> Void)?
  var onErrorMessage: ((String) -> Void)?

  private let nfcScanner: NFCScannerUtil = NFCScannerUtil()
  private let appBlocker: AppBlockerUtil = AppBlockerUtil()

  func getIdentifier() -> String {
    return NFCTimerBlockingStrategy.id
  }

  func startBlocking(
    context: ModelContext,
    profile: BlockedProfiles,
    forceStart: Bool?
  ) -> (any View)? {
    return TimerDurationView(
      profileName: profile.name,
      onDurationSelected: { duration in
        if let strategyTimerData = StrategyTimerData.toData(from: duration) {
          // Store the timer data so that its selected for the next time the profile is started
          // This is also useful if the profile is started from the background like a shortcut or intent
          profile.strategyData = strategyTimerData
          profile.updatedAt = Date()
          BlockedProfiles.updateSnapshot(for: profile)
          try? context.save()
        }

        let activeSession = BlockedProfileSession.createSession(
          in: context,
          withTag: NFCTimerBlockingStrategy.id,
          withProfile: profile,
          forceStart: forceStart ?? false
        )

        DeviceActivityCenterUtil.startStrategyTimerActivity(for: profile)

        self.onSessionCreation?(.started(activeSession))
      }
    )
  }

  func stopBlocking(
    context: ModelContext,
    session: BlockedProfileSession
  ) -> (any View)? {
    nfcScanner.onTagScanned = { tag in
      let tag = tag.url ?? tag.id

      if let physicalUnblockNFCTagId = session.blockedProfile.physicalUnblockNFCTagId,
        physicalUnblockNFCTagId != tag
      {
        self.onErrorMessage?(
          "This DO Card is not allowed to unlock this profile. Physical unlock setting is on for this profile."
        )
        return
      }

      session.endSession()
      try? context.save()
      self.appBlocker.deactivateRestrictions()

      self.onSessionCreation?(.ended(session.blockedProfile))
    }

    nfcScanner.scan(profileName: session.blockedProfile.name)

    return nil
  }
}
