import CodeScanner
import SwiftData
import SwiftUI

class QRManualBlockingStrategy: BlockingStrategy {
  static var id: String = "QRManualBlockingStrategy"

  var name: String = "QR/Barcode + Manual"
  var description: String =
    "Start in the app. To stop, scan any QR code or barcode. Use Strict Unlocks if you want only selected codes to work."
  var iconAssetName: String = "Manual+QRSticker"
  var color: Color = .pink
  var pickerCategory: BlockingStrategyPickerCategory = .easyToStart

  var usesQRCode: Bool = true
  var startsManually: Bool = true

  var onSessionCreation: ((SessionStatus) -> Void)?
  var onErrorMessage: ((String) -> Void)?

  private let appBlocker: AppBlockerUtil = AppBlockerUtil()

  func getIdentifier() -> String {
    return QRManualBlockingStrategy.id
  }

  func startBlocking(
    context: ModelContext,
    profile: BlockedProfiles,
    forceStart: Bool?
  ) -> (any View)? {
    self.appBlocker.activateRestrictions(for: BlockedProfiles.getSnapshot(for: profile))

    let activeSession =
      BlockedProfileSession
      .createSession(
        in: context,
        withTag: ManualBlockingStrategy.id,
        withProfile: profile,
        forceStart: forceStart ?? false
      )

    self.onSessionCreation?(.started(activeSession))

    return nil
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
