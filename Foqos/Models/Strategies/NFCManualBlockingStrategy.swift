import SwiftData
import SwiftUI

class NFCManualBlockingStrategy: BlockingStrategy {
  static var id: String = "NFCManualBlockingStrategy"

  var name: String = "NFC + Manual"
  var description: String = "Block manually, but unblock by using any NFC tag"
  var iconType: String = "badge.plus.radiowaves.forward"
  var color: Color = .yellow

  var onSessionCreation: ((SessionStatus) -> Void)?
  var onErrorMessage: ((String) -> Void)?

  private let nfcScanner: NFCScannerUtil = NFCScannerUtil()
  private let appBlocker: AppBlockerUtil = AppBlockerUtil()

  func getIdentifier() -> String {
    return NFCManualBlockingStrategy.id
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
        // Manually starting sessions, since nothing was scanned to start there is no tag to store for each session
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
    nfcScanner.onTagScanned = { tag in
      let tag = tag.url ?? tag.id

      if let physicalUnblockNFCTagId = session.blockedProfile.physicalUnblockNFCTagId,
        physicalUnblockNFCTagId != tag
      {
        self.onErrorMessage?(
          "This NFC tag is not allowed to unblock this profile. Physical unblock setting is on for this profile"
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
