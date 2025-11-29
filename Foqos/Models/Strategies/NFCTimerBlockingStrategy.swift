import SwiftData
import SwiftUI

class NFCTimerBlockingStrategy: BlockingStrategy {
  static var id: String = "NFCTimerBlockingStrategy"

  var name: String = "NFC + Timer"
  var description: String = "Block for a certain amount of hours, unblock by using any NFC tag"
  var iconType: String = "bolt.badge.clock.fill"
  var color: Color = .mint

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
    // TODO create a view that stores a timer
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

    // TODO create a timer a timer

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
