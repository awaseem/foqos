import SwiftUI
import SwiftData

class NFCManualBlockingStrategy: BlockingStrategy {
    static var id: String = "NFCManualBlockingStrategy"
    
    var name: String = "NFC + Manual"
    var description: String = "Block manually, but unblock by using a NFC tag"
    var iconType: String = "badge.plus.radiowaves.forward"
    
    var onSessionCreation: ((SessionStatus) -> Void)?
    var onErrorMessage: ((String) -> Void)?
    
    private let nfcScanner: NFCScannerUtil = NFCScannerUtil()
    private let appBlocker: AppBlockerUtil = AppBlockerUtil()
    
    func getIdentifier() -> String {
        return NFCManualBlockingStrategy.id
    }
    
    func startBlocking(context: ModelContext, profile: BlockedProfiles)  -> (any View)? {
        self.appBlocker
            .activateRestrictions(selection: profile.selectedActivity)
        
        let activeSession = BlockedProfileSession
            .createSession(
                in: context,
                withTag: ManualBlockingStrategy.id,
                withProfile: profile
            )
        
        self.onSessionCreation?(.started(activeSession))
        
        return nil
    }
    
    func stopBlocking(
        context: ModelContext,
        session: BlockedProfileSession
    )  -> (any View)? {
        nfcScanner.onTagScanned = { tag in
            session.endSession()
            self.appBlocker.deactivateRestrictions()
            
            self.onSessionCreation?(.ended(session.blockedProfile))
        }
        
        nfcScanner.scan(profileName: session.blockedProfile.name)
        
        return nil
    }
}
