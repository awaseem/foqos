import SwiftData
import SwiftUI

final class QRSoftUnblockBlockingStrategy: BlockingStrategy {
  static var id: String = "QRSoftUnblockBlockingStrategy"

  var name: String = "Temporary Access + QR"
  var description: String =
    "Block your apps, but allow a few short opens when you need them. Scan a QR code or barcode to stop the session."
  var iconAssetName: String = "Soft Unblock + QR"
  var color: Color = .purple
  var pickerCategory: BlockingStrategyPickerCategory = .forever

  var usesQRCode: Bool = true
  var startsManually: Bool = true
  var allowsTimedBreaks: Bool = false
  var isBeta: Bool = true
  var startViewPresentationDetents: Set<PresentationDetent> = [.large]

  var onSessionCreation: ((SessionStatus) -> Void)?
  var onErrorMessage: ((String) -> Void)?

  private let appBlocker = AppBlockerUtil()

  func getIdentifier() -> String {
    Self.id
  }

  func startBlocking(
    context: ModelContext,
    profile: BlockedProfiles,
    forceStart: Bool?
  ) -> (any View)? {
    SoftUnblockConfigurationView(
      profileName: profile.name,
      initialConfiguration: SoftUnblockStrategyData.decode(profile.strategyData),
      onStart: { configuration in
        guard let data = SoftUnblockStrategyData.encode(configuration) else {
          self.onErrorMessage?("Failed to save the temporary access settings.")
          return
        }

        profile.strategyData = data
        profile.updatedAt = Date()

        do {
          try context.save()
        } catch {
          self.onErrorMessage?("Failed to save the temporary access settings.")
          return
        }

        BlockedProfiles.updateSnapshot(for: profile)

        let activeSession = BlockedProfileSession.createSession(
          in: context,
          withTag: Self.id,
          withProfile: profile,
          forceStart: forceStart ?? false
        )

        SoftUnblockGrantScheduler.stopAll()
        SoftUnblockGrantStore.beginSession(
          sessionId: activeSession.id,
          profileId: profile.id,
          maximumUnblockCount: configuration.maximumUnblockCount,
          allowanceResetIntervalInHours: configuration.allowanceResetIntervalInHours,
          startedAt: activeSession.startTime
        )
        self.appBlocker.activateRestrictions(for: BlockedProfiles.getSnapshot(for: profile))
        self.onSessionCreation?(.started(activeSession))
      }
    )
  }

  func stopBlocking(
    context: ModelContext,
    session: BlockedProfileSession
  ) -> (any View)? {
    LabeledCodeScannerView(
      heading: "Scan to stop",
      subtitle: "Point your camera at a QR code or barcode to stop this profile."
    ) { result in
      switch result {
      case .success(let result):
        let code = result.string

        if session.blockedProfile.hasPhysicalUnblockItem(ofType: .qrCode)
          && !session.blockedProfile.canUnblock(withCode: code, type: .qrCode)
        {
          self.onErrorMessage?(
            "This QR code or barcode can't stop this profile."
          )
          return
        }

        self.endSession(context: context, session: session)
      case .failure(let error):
        self.onErrorMessage?(error.localizedDescription)
      }
    }
  }

  private func endSession(context: ModelContext, session: BlockedProfileSession) {
    SoftUnblockGrantScheduler.stopAll(sessionId: session.id)
    SoftUnblockGrantStore.endSession(sessionId: session.id)
    session.endSession()

    do {
      try context.save()
    } catch {
      onErrorMessage?("Failed to save the completed session.")
    }

    appBlocker.deactivateRestrictions()
    onSessionCreation?(.ended(session.blockedProfile))
  }
}
