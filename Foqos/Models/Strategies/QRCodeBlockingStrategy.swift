import CodeScanner
import SwiftData
import SwiftUI

class QRCodeBlockingStrategy: BlockingStrategy {
  static var id: String = "QRCodeBlockingStrategy"

  var name: String = "QR Codes"
  var description: String =
    "Block and unblock profiles by scanning the same QR code"
  var iconType: String = "qrcode.viewfinder"
  var color: Color = .pink

  var onSessionCreation: ((SessionStatus) -> Void)?
  var onErrorMessage: ((String) -> Void)?

  private let appBlocker: AppBlockerUtil = AppBlockerUtil()

  func getIdentifier() -> String {
    return QRCodeBlockingStrategy.id
  }

  func startBlocking(
    context: ModelContext,
    profile: BlockedProfiles,
    forceStart: Bool?
  ) -> (any View)? {
    return LabeledCodeScannerView(
      heading: "Scan to start",
      subtitle: "Point your camera at a QR code to activate a profile."
    ) { result in
      switch result {
      case .success(let result):
        self.appBlocker.activateRestrictions(for: profile)

        let tag = result.string
        let activeSession =
          BlockedProfileSession
          .createSession(
            in: context,
            withTag: tag,
            withProfile: profile,
            forceStart: forceStart ?? false
          )
        self.onSessionCreation?(.started(activeSession))
      case .failure(let error):
        self.onErrorMessage?(error.localizedDescription)
      }
    }
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

        // if the session was force started, we don't need to check the tag
        if !session.forceStarted && session.tag != tag {
          self.onErrorMessage?(
            "You must scan the original QR code to stop focus"
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
