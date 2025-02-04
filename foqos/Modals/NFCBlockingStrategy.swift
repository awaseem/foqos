class NFCBlockingStrategy: BlockingStrategy {
    static var id: String = "NFCBlockingStrategy"
    
    var name: String = "NFC Tags"
    var description: String = "Block and unblock profiles by using the exact same NFC tag"
    var iconType: String = "wave.3.right.circle.fill"
    
    private var nfcScanner: NFCScannerUtil = NFCScannerUtil()
    private var appBlocker: AppBlockerUtil = AppBlockerUtil()

    func startBlocking(profile: BlockedProfiles) {
        nfcScanner.onTagScanned = { tag in
            self.appBlocker
                .activateRestrictions(selection: profile.selectedActivity)
        }
        nfcScanner.onError = { error in
            // TODO: somehow handle errors here?
        }
        
        nfcScanner.scan(profileName: profile.name)
    }

    func stopBlocking(
        session: BlockedProfileSession
    ) {
        appBlocker.deactivateRestrictions()
    }

    
}
