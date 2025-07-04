import SwiftData
import SwiftUI

class NFCBlockingStrategy: BlockingStrategy {
  static var id: String = "NFCBlockingStrategy"

  var name: String = "NFC Tags"
  var description: String =
    "Block and unblock profiles by using the exact same NFC tag"
  var iconType: String = "wave.3.right.circle.fill"
  var color: Color = .yellow

  var onSessionCreation: ((SessionStatus) -> Void)?
  var onErrorMessage: ((String) -> Void)?

  private let nfcScanner: NFCScannerUtil = NFCScannerUtil()
  private let appBlocker: AppBlockerUtil = AppBlockerUtil()

  func getIdentifier() -> String {
    return NFCBlockingStrategy.id
  }

  func startBlocking(
    context: ModelContext,
    profile: BlockedProfiles,
    forceStart: Bool?
  ) -> (any View)? {
    nfcScanner.onTagScanned = { tag in
      self.appBlocker.activateRestrictions(for: profile)

      let tag = tag.url ?? tag.id
      let activeSession =
        BlockedProfileSession
        .createSession(
          in: context,
          withTag: tag,
          withProfile: profile,
          forceStart: forceStart ?? false
        )
      self.onSessionCreation?(.started(activeSession))
    }

    nfcScanner.scan(profileName: profile.name)

    return nil
  }

  func stopBlocking(
    context: ModelContext,
    session: BlockedProfileSession
  ) -> (any View)? {
    nfcScanner.onTagScanned = { tag in
      let tag = tag.url ?? tag.id

      // If it was force started, we don't care about the tag
      if !session.forceStarted && session.tag != tag {
        self.onErrorMessage?(
          "You must scan the original tag to stop focus"
        )
        return
      }

      session.endSession()
      self.appBlocker.deactivateRestrictions()

      self.onSessionCreation?(.ended(session.blockedProfile))
    }

    nfcScanner.scan(profileName: session.blockedProfile.name)

    return nil
  }
}
