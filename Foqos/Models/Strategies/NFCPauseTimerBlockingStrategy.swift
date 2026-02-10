import SwiftData
import SwiftUI

class NFCPauseTimerBlockingStrategy: BlockingStrategy {
  static var id: String = "NFCPauseTimerBlockingStrategy"

  var name: String = "NFC + Pause Timer"
  var description: String =
    "Block with pause timer. Stop requires NFC scan to pause, scan again to fully stop."
  var iconType: String = "pause.circle.fill"
  var color: Color = .orange

  var hidden: Bool = false

  var onSessionCreation: ((SessionStatus) -> Void)?
  var onErrorMessage: ((String) -> Void)?

  private let nfcScanner: NFCScannerUtil = NFCScannerUtil()
  private let appBlocker: AppBlockerUtil = AppBlockerUtil()

  func getIdentifier() -> String {
    return NFCPauseTimerBlockingStrategy.id
  }

  func startBlocking(
    context: ModelContext,
    profile: BlockedProfiles,
    forceStart: Bool?
  ) -> (any View)? {
    return PauseDurationView(
      profileName: profile.name,
      onDurationSelected: { pauseDurationMinutes in
        // Save the pause duration to the profile
        let pauseTimerData = StrategyPauseTimerData(
          pauseDurationInMinutes: pauseDurationMinutes)
        if let data = StrategyPauseTimerData.toData(from: pauseTimerData) {
          profile.strategyData = data
          profile.updatedAt = Date()
          BlockedProfiles.updateSnapshot(for: profile)
          try? context.save()
        }

        // Immediately start blocking (like QRManualBlockingStrategy)
        self.appBlocker.activateRestrictions(for: BlockedProfiles.getSnapshot(for: profile))

        let activeSession = BlockedProfileSession.createSession(
          in: context,
          withTag: NFCPauseTimerBlockingStrategy.id,
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
    let isPauseActive = session.isPauseActive

    nfcScanner.onTagScanned = { tag in
      let tagId = tag.url ?? tag.id

      // Check strict mode - if physical unblock is set, it must match
      if let physicalUnblockNFCTagId = session.blockedProfile.physicalUnblockNFCTagId,
        physicalUnblockNFCTagId != tagId
      {
        self.onErrorMessage?(
          "This NFC tag is not allowed to unblock this profile. Physical unblock setting is on for this profile"
        )
        return
      }

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

        self.onSessionCreation?(.paused)
      }
    }

    if isPauseActive {
      nfcScanner.scan(profileName: session.blockedProfile.name)
    } else {
      nfcScanner.scan(profileName: "\(session.blockedProfile.name) - Pause")
    }

    return nil
  }
}
