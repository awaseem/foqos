import SwiftUI
import SwiftData

class ManualBlockingStrategy: BlockingStrategy {
    static var id: String = "ManualBlockingStrategy"
    
    var name: String = "Manual"
    var description: String = "Block and unblock profiles manually through the app"
    var iconType: String = "button.horizontal.top.press.fill"
    
    var onSessionCreation: ((BlockedProfileSession?) -> Void)?
    var onErrorMessage: ((String) -> Void)?
    
    var showCustomView: Bool = false
    var customView: (any View)? = nil
    
    private let appBlocker: AppBlockerUtil = AppBlockerUtil()
    
    func getIdentifier() -> String {
        return ManualBlockingStrategy.id
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
        session.endSession()
        self.appBlocker.deactivateRestrictions()
        
        self.onSessionCreation?(nil)
    }
}
