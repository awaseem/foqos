import SwiftUI
import SwiftData

class QRCodeBlockingStrategy: BlockingStrategy {
    static var id: String = "QRCodeBlockingStrategy"
    
    var name: String = "QR Codes"
    var description: String = "Block and unblock profiles by scanning the same QR code"
    var iconType: String = "qrcode.viewfinder"
    
    var onSessionCreation: ((BlockedProfileSession?) -> Void)?
    var onErrorMessage: ((String) -> Void)?
    
    private let qrCodeScanner: QRCodeUtil = QRCodeUtil()
    private let appBlocker: AppBlockerUtil = AppBlockerUtil()
    
    func getIdentifier() -> String {
        return QRCodeBlockingStrategy.id
    }
    
    func startBlocking(context: ModelContext, profile: BlockedProfiles) -> (any View)? {
        //        qrCodeScanner.scanQRCode { result in
        //            self.appBlocker
        //                .activateRestrictions(selection: profile.selectedActivity)
        //
        //            let tag = result
        //            let activeSession = BlockedProfileSession
        //                .createSession(in: context, withTag: tag, withProfile: profile)
        //            self.onSessionCreation?(activeSession)
        //        }
        
        return VStack {
            Text("hello")
        }
    }
    
    func stopBlocking(
        context: ModelContext,
        session: BlockedProfileSession
    )  -> (any View)? {
        //        qrCodeScanner.scanQRCode { result in
        //            let tag = result
        //            if session.tag != tag {
        //                self.onErrorMessage?("You must scan the original QR code to stop focus")
        //                return
        //            }
        //
        //            session.endSession()
        //            self.appBlocker.deactivateRestrictions()
        //
        //            self.onSessionCreation?(nil)
        //        }
        
        return VStack {
            Text("hello")
        }
    }
}
