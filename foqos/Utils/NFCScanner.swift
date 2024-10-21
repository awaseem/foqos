import SwiftUI
import CoreNFC

class NFCScanner: NSObject, ObservableObject {
    @Published var scannedNFCTag: String?
    @Published var isScanning: Bool = false
    @Published var errorMessage: String?
    
    private var nfcSession: NFCReaderSession?
    
    func scan() {
        print("Attempting to scan NFC...")
        
        guard NFCReaderSession.readingAvailable else {
            self.errorMessage = "NFC scanning not available on this device"
            return
        }
        
        print("NFC available, creating session...")
        nfcSession = NFCTagReaderSession(
            pollingOption: [.iso14443, .iso15693],
            delegate: self,
            queue: nil
        )
        nfcSession?.alertMessage = "Hold your iPhone near an NFC tag to change focus."
        nfcSession?.begin()
        
        print("NFC session begun")
        isScanning = true
    }
}

extension NFCScanner: NFCTagReaderSessionDelegate {
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        // This method is called when the session begins.
        return
    }
    
    func tagReaderSession(
        _ session: NFCTagReaderSession,
        didInvalidateWithError error: Error
    ) {
        DispatchQueue.main.async {
            self.isScanning = false
            self.errorMessage = error.localizedDescription
        }
    }
    
    func tagReaderSession(
        _ session: NFCTagReaderSession,
        didDetect tags: [NFCTag]
    ) {
        if tags.count > 1 {
            session.alertMessage = "More than 1 tag detected. Please present only 1 tag."
            return
        }
        
        guard let tag = tags.first else {
            return
        }
        
        session.connect(to: tag) { error in
            if let error = error {
                session
                    .invalidate(
                        errorMessage: "Connection error: \(error.localizedDescription)"
                    )
                return
            }
            
            switch tag {
            case .iso7816(let iso7816Tag):
                self.handleISO7816Tag(iso7816Tag, session: session)
            case .feliCa(let feliCaTag):
                self.handleFeliCaTag(feliCaTag, session: session)
            case .iso15693(let iso15693Tag):
                self.handleISO15693Tag(iso15693Tag, session: session)
            case .miFare(let miFareTag):
                self.handleMiFareTag(miFareTag, session: session)
            @unknown default:
                session.invalidate(errorMessage: "Unsupported tag type")
            }
        }
    }
    
    private func handleISO7816Tag(
        _ tag: NFCISO7816Tag,
        session: NFCTagReaderSession
    ) {
        // Example: Read AID (Application Identifier)
        let apdu = NFCISO7816APDU(
            instructionClass: 0x00,
            instructionCode: 0xA4,
            p1Parameter: 0x04,
            p2Parameter: 0x00,
            data: Data(),
            expectedResponseLength: -1
        )
        
        tag.sendCommand(apdu: apdu) {
            data,
            sw1,
            sw2,
            error in
            if let error = error {
                session
                    .invalidate(
                        errorMessage: "Error reading ISO7816 tag: \(error.localizedDescription)"
                    )
                return
            }
            
            let result = "ISO7816 AID: \(data.hexEncodedString()), Status: \(String(format: "%02X %02X", sw1, sw2))"
            self.completeScanning(with: result, session: session)
        }
    }
    
    private func handleFeliCaTag(
        _ tag: NFCFeliCaTag,
        session: NFCTagReaderSession
    ) {
        // Example: Read FeliCa System Code
        let systemCode = tag.currentSystemCode.hexEncodedString()
        let result = "FeliCa System Code: \(systemCode)"
        self.completeScanning(with: result, session: session)
    }
    
    private func handleISO15693Tag(
        _ tag: NFCISO15693Tag,
        session: NFCTagReaderSession
    ) {
        // Example: Read ISO15693 UID
        let uid = tag.identifier.hexEncodedString()
        let result = "ISO15693 UID: \(uid)"
        self.completeScanning(with: result, session: session)
    }
    
    private func handleMiFareTag(
        _ tag: NFCMiFareTag,
        session: NFCTagReaderSession
    ) {
        // Example: Read MIFARE UID
        let uid = tag.identifier.hexEncodedString()
        let result = "MIFARE UID: \(uid)"
        self.completeScanning(with: result, session: session)
    }
    
    private func completeScanning(
        with result: String,
        session: NFCTagReaderSession
    ) {
        DispatchQueue.main.async {
            let timeInterval = Date().timeIntervalSince1970
            self.scannedNFCTag = "\(result). Time Interval: \(timeInterval)"
            self.isScanning = false
            session.invalidate()
        }
    }
}

extension Data {
    func hexEncodedString() -> String {
        return map { String(format: "%02hhX", $0) }.joined()
    }
}