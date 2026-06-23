import SwiftData
import SwiftUI

class QRTimerBlockingStrategy: BlockingStrategy {
  static var id: String = "QRTimerBlockingStrategy"

  var name: String = "QR/Barcode + Timer"
  var description: String =
    "Choose how long blocking should last. To stop early, scan any QR code or barcode. Use Strict Unlocks if you want only selected codes to work."
  var iconAssetName: String = "QR+TimerSticker"
  var color: Color = .mint

  var usesQRCode: Bool = true
  var hasTimer: Bool = true

  var onSessionCreation: ((SessionStatus) -> Void)?
  var onErrorMessage: ((String) -> Void)?

  private let appBlocker: AppBlockerUtil = AppBlockerUtil()

  func getIdentifier() -> String {
    return QRTimerBlockingStrategy.id
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
          withTag: QRTimerBlockingStrategy.id,
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
    return LabeledCodeScannerView(
      heading: "Scan to stop",
      subtitle: "Point your camera at a QR code to deactivate a profile."
    ) { result in
      switch result {
      case .success(let result):
        let tag = result.string

        if session.blockedProfile.hasPhysicalUnblockItem(ofType: .qrCode)
          && !session.blockedProfile.canUnblock(withCode: tag, type: .qrCode)
        {
          self.onErrorMessage?(
            "This QR code is not allowed to unblock this profile. Physical unblock setting is on for this profile"
          )
          return
        }

        session.endSession()
        try? context.save()
        self.appBlocker.deactivateRestrictions()

        self.onSessionCreation?(.ended(session.blockedProfile))
      case .failure(let error):
        self.onErrorMessage?(error.localizedDescription)
      }
    }
  }
}
