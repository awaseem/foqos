import CodeScanner
import SwiftData
import SwiftUI

class QRManualBlockingStrategy: BlockingStrategy {
  static var id: String = "QRManualBlockingStrategy"

  var name: String = "QR + Manual"
  var description: String = "Block manually, but unblock by using any QR/Barcode code"
  var iconType: String = "bolt.square"
  var color: Color = .pink

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
      subtitle: "Point your camera at a QR code to deactiviate a profile."
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
