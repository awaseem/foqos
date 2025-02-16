import SwiftUI
import SwiftData
import CodeScanner

class QRCodeBlockingStrategy: BlockingStrategy {
    static var id: String = "QRCodeBlockingStrategy"
    
    var name: String = "QR Codes"
    var description: String = "Block and unblock profiles by scanning the same QR code"
    var iconType: String = "qrcode.viewfinder"
    
    var onSessionCreation: ((BlockedProfileSession?) -> Void)?
    var onErrorMessage: ((String) -> Void)?
    
    private let appBlocker: AppBlockerUtil = AppBlockerUtil()
    
    func getIdentifier() -> String {
        return QRCodeBlockingStrategy.id
    }
    
    func startBlocking(context: ModelContext, profile: BlockedProfiles) -> (any View)? {
        return LabeledCodeScannerView(
            heading: "Scan to start",
            subtitle: "Point your camera at a QR code to activate a profile."
        ) { result in
            switch result {
            case .success(let result):
                self.appBlocker
                    .activateRestrictions(selection: profile.selectedActivity)
                
                let tag = result.string
                let activeSession = BlockedProfileSession
                    .createSession(in: context, withTag: tag, withProfile: profile)
                self.onSessionCreation?(activeSession)
            case .failure(let error):
                self.onErrorMessage?(error.localizedDescription)
            }
        }
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
            case .success(let result):
                let tag = result.string
                if session.tag != tag {
                    self.onErrorMessage?("You must scan the original QR code to stop focus")
                    return
                }
                
                session.endSession()
                self.appBlocker.deactivateRestrictions()
                
                self.onSessionCreation?(nil)
            case .failure(let error):
                self.onErrorMessage?(error.localizedDescription)
            }
        }
    }
}
