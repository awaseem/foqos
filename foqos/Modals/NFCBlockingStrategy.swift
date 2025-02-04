import SwiftData

class NFCBlockingStrategy: BlockingStrategy {
    static var id: String = "NFCBlockingStrategy"
    
    var name: String = "NFC Tags"
    var description: String = "Block and unblock profiles by using the exact same NFC tag"
    var iconType: String = "wave.3.right.circle.fill"
    
    var onSessionCreation: ((BlockedProfileSession?) -> Void)?
    var onErrorMessage: ((String) -> Void)?
    
    private let nfcScanner: NFCScannerUtil = NFCScannerUtil()
    private let appBlocker: AppBlockerUtil = AppBlockerUtil()

    func startBlocking(context: ModelContext, profile: BlockedProfiles) {
        nfcScanner.onTagScanned = { tag in
            self.appBlocker
                .activateRestrictions(selection: profile.selectedActivity)
            
            let tag = tag.url ?? tag.id
            let activeSession = BlockedProfileSession
                .createSession(in: context, withTag: tag, withProfile: profile)
            self.onSessionCreation?(activeSession)
        }
        nfcScanner.onError = { error in
            self.onErrorMessage?(error)
        }
        
        nfcScanner.scan(profileName: profile.name)
    }

    func stopBlocking(
        context: ModelContext,
        session: BlockedProfileSession
    ) {
        nfcScanner.onTagScanned = { tag in
            let tag = tag.url ?? tag.id
            if session.tag != tag {
                self.onErrorMessage?("You must scan the original tag to stop focus")
                return
            }

            session.endSession()
            self.appBlocker.deactivateRestrictions()
            
            self.onSessionCreation?(nil)
        }
        nfcScanner.onError = { error in
            self.onErrorMessage?(error)
        }
        
        nfcScanner.scan(profileName: session.blockedProfile.name)
    }
}
