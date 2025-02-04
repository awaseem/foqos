class NFCBlockingStrategy: BlockingStrategy {
    var id: String = "NFCBlockingStrategy"
    var name: String = "NFC Tags"
    var description: String = "Block and unblock profiles by using the exact same NFC tag"
    var iconType: String = "wave.3.right.circle.fill"
    
    private var nfcScanner: NFCScanner
    private var appBlocker: AppBlocker
    
    init(scanner: NFCScanner, blocker: AppBlocker) {
        self.nfcScanner = scanner
        self.appBlocker = blocker
    }

    func startBlocking(data: BlockingStrategyInputs, profile: BlockedProfiles) {
        
    }

    func stopBlocking(
        data: BlockingStrategyInputs,
        session: BlockedProfileSession
    ) {
        
    }

    
}
