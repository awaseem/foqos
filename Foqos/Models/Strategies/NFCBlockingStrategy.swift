import SwiftData
import SwiftUI

/**
 NFC-based blocking strategy that uses NFC tags for session management.

 This strategy allows users to start blocking sessions by scanning an NFC tag and then
 unlock the session by scanning either the same tag (legacy mode) or any tag in the
 profile's whitelist (new mode). Supports both legacy single-tag configuration and
 new multi-tag whitelist functionality.

 ## Features:
 - Legacy single NFC tag support for backward compatibility
 - Multiple NFC tag whitelist for enhanced flexibility
 - Optimized Set-based lookup for performance with large whitelists
 - Comprehensive error handling and user feedback

 ## Usage:
 ```swift
 let strategy = NFCBlockingStrategy()
 strategy.startBlocking(context: context, profile: profile, forceStart: false)
 ```
 */
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
      self.appBlocker.activateRestrictions(for: BlockedProfiles.getSnapshot(for: profile))

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

      // Check if this tag can unlock the profile
      if let legacyTagId = session.blockedProfile.physicalUnblockNFCTagId {
        // Legacy single tag mode
        if legacyTagId != tag {
          self.onErrorMessage?("This NFC tag cannot unlock this profile")
          return
        }
      } else if !session.blockedProfile.nfcWhitelist.isEmpty {
        // Whitelist mode - check if tag is allowed
        let isAllowed = session.blockedProfile.nfcWhitelist.contains { $0.tagId == tag }
        if !isAllowed {
          self.onErrorMessage?("This NFC tag is not in the whitelist")
          return
        }
      } else if !session.forceStarted && session.tag != tag {
        // Original mode - must use same tag that started session
        self.onErrorMessage?("You must scan the original tag to stop focus")
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
