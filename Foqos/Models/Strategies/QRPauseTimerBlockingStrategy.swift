import CodeScanner
import SwiftData
import SwiftUI

class QRPauseTimerBlockingStrategy: BlockingStrategy {
  static var id: String = "QRPauseTimerBlockingStrategy"

  var name: String = "QR + Pause Timer"
  var description: String =
    "Set a pause duration, scan once to pause, and scan again to fully stop."
  var iconType: String = "pause.circle.fill"
  var color: Color = .indigo

  var usesQRCode: Bool = true
  var hasPauseMode: Bool = true
  var isBeta: Bool = true

  var hidden: Bool = false

  var onSessionCreation: ((SessionStatus) -> Void)?
  var onErrorMessage: ((String) -> Void)?

  private let appBlocker: AppBlockerUtil = AppBlockerUtil()

  func getIdentifier() -> String {
    return QRPauseTimerBlockingStrategy.id
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
          withTag: QRPauseTimerBlockingStrategy.id,
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
    let heading = isPauseActive ? "Scan to stop" : "Scan to pause"
    let subtitle =
      isPauseActive
      ? "Point your camera at a QR code to fully stop this profile."
      : "Point your camera at a QR code to temporarily pause this profile."

    return LabeledCodeScannerView(
      heading: heading,
      subtitle: subtitle
    ) { result in
      switch result {
      case .success(let result):
        let tag = result.string

        // Check strict mode - if physical unblock is set, it must match
        if let physicalUnblockQRCodeId = session.blockedProfile.physicalUnblockQRCodeId,
          physicalUnblockQRCodeId != tag
        {
          self.onErrorMessage?(
            "This QR code is not allowed to unblock this profile. Physical unblock setting is on for this profile"
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

      case .failure(let error):
        self.onErrorMessage?(error.localizedDescription)
      }
    }
  }
}
