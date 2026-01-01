import SwiftData
import SwiftUI

class QRTimerBlockingStrategy: BlockingStrategy {
  static var id: String = "QRTimerBlockingStrategy"

  var name: String = "QR + Timer"
  var description: String = "Block for a certain amount of minutes, unblock by using any QR code"
  var iconType: String = "bolt.badge.clock"
  var color: Color = .mint

  var hidden: Bool = false

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

        if let physicalUnblockQRCodeId = session.blockedProfile.physicalUnblockQRCodeId,
          physicalUnblockQRCodeId != tag
        {
          self.onErrorMessage?(
            "This QR code is not allowed to unblock this profile. Physical unblock setting is on for this profile"
          )
          return
        }

        session.endSession()
        self.appBlocker.deactivateRestrictions()

        self.onSessionCreation?(.ended(session.blockedProfile))
      case .failure(let error):
        self.onErrorMessage?(error.localizedDescription)
      }
    }
  }
}
