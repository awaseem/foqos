import SwiftData

class NFCManualBlockingStrategy: BlockingStrategy {
    static var id: String = "NFCManualBlockingStrategy"
    
    var name: String = "NFC + Manual"
    var description: String = "Block manually, but unblock by using a NFC tag"
    var iconType: String = "badge.plus.radiowaves.forward"
    
    var onSessionCreation: ((BlockedProfileSession?) -> Void)?
    var onErrorMessage: ((String) -> Void)?
    
    private let nfcScanner: NFCScannerUtil = NFCScannerUtil()
    private let appBlocker: AppBlockerUtil = AppBlockerUtil()
    
    func getIdentifier() -> String {
        return NFCManualBlockingStrategy.id
    }

    func startBlocking(context: ModelContext, profile: BlockedProfiles) {
        self.appBlocker
            .activateRestrictions(selection: profile.selectedActivity)
        
        let activeSession = BlockedProfileSession
            .createSession(
                in: context,
                withTag: ManualBlockingStrategy.id,
                withProfile: profile
            )
        
        self.onSessionCreation?(activeSession)
    }

    func stopBlocking(
        context: ModelContext,
        session: BlockedProfileSession
    ) {
        nfcScanner.onTagScanned = { tag in
            session.endSession()
            self.appBlocker.deactivateRestrictions()
            
            self.onSessionCreation?(nil)
        }

        nfcScanner.scan(profileName: session.blockedProfile.name)
    }
}
