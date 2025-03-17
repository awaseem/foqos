import SwiftUI
import SwiftData
import CodeScanner

class QRManualBlockingStrategy: BlockingStrategy {
    static var id: String = "QRManualBlockingStrategy"
    
    var name: String = "QR + Manual"
    var description: String = "Block manually, but unblock by using a QR code"
    var iconType: String = "bolt.square"
    var color: Color = .pink
    
    var onSessionCreation: ((SessionStatus) -> Void)?
    var onErrorMessage: ((String) -> Void)?
    
    private let appBlocker: AppBlockerUtil = AppBlockerUtil()
    
    func getIdentifier() -> String {
        return QRManualBlockingStrategy.id
    }
    
    func startBlocking(context: ModelContext, profile: BlockedProfiles) -> (any View)? {
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
        return LabeledCodeScannerView(
            heading: "Scan to stop",
            subtitle: "Point your camera at a QR code to deactiviate a profile."
        ) { result in
            switch result {
            case .success(_):
                session.endSession()
                self.appBlocker.deactivateRestrictions()
                
                self.onSessionCreation?(.ended(session.blockedProfile))
            case .failure(let error):
                self.onErrorMessage?(error.localizedDescription)
            }
        }
    }
}
