import CoreNFC
import SwiftUI


class NFCWriter: NSObject, ObservableObject {
   var scannedNFCTag: NFCResult?
     var isScanning: Bool = false
     var errorMessage: String?

    private var nfcSession: NFCReaderSession?
    private var urlToWrite: String?
    private var isWriteMode: Bool = false

    func resultFromURL(_ url: String) -> NFCResult {
        return NFCResult(id: url, url: url, DateScanned: Date())
    }

    func writeURL(_ url: String) {
        guard NFCReaderSession.readingAvailable else {
            self.errorMessage = "NFC writing not available on this device"
            return
        }

        guard URL(string: url) != nil else {
            self.errorMessage = "Invalid URL format"
            return
        }

        isWriteMode = true
        urlToWrite = url

        // Using NFCNDEFReaderSession for writing
        let ndefSession = NFCNDEFReaderSession(
            delegate: self, queue: nil, invalidateAfterFirstRead: false)
        ndefSession.alertMessage =
            "Hold your iPhone near an NFC tag to write the profile."
        ndefSession.begin()

        isScanning = true
    }
}

// New NDEF Writing Support
extension NFCWriter: NFCNDEFReaderSessionDelegate {
    func readerSession(
        _ session: NFCNDEFReaderSession,
        didDetectNDEFs messages: [NFCNDEFMessage]
    ) {
        // Not used for writing
    }

    func readerSession(
        _ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]
    ) {
        guard let tag = tags.first else {
            session.invalidate(errorMessage: "No tag found")
            return
        }

        session.connect(to: tag) { error in
            if let error = error {
                session.invalidate(
                    errorMessage:
                        "Connection error: \(error.localizedDescription)")
                return
            }

            tag.queryNDEFStatus { status, capacity, error in
                guard error == nil else {
                    session.invalidate(errorMessage: "Failed to query tag")
                    return
                }

                switch status {
                case .notSupported:
                    session.invalidate(
                        errorMessage: "Tag is not NDEF compliant")
                case .readOnly:
                    session.invalidate(errorMessage: "Tag is read-only")
                case .readWrite:
                    self.handleReadWrite(session, tag: tag)
                @unknown default:
                    session.invalidate(errorMessage: "Unknown tag status")
                }
            }
        }
    }

    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        // Session became active
    }

    func readerSession(
        _ session: NFCNDEFReaderSession, didInvalidateWithError error: Error
    ) {
        DispatchQueue.main.async {
            self.isScanning = false
            if let readerError = error as? NFCReaderError {
                switch readerError.code {
                case .readerSessionInvalidationErrorFirstNDEFTagRead,
                    .readerSessionInvalidationErrorUserCanceled:
                    // User canceled or first tag read
                    break
                default:
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func handleReadWrite(
        _ session: NFCNDEFReaderSession, tag: NFCNDEFTag
    ) {
        guard let urlString = self.urlToWrite,
            let url = URL(string: urlString),
            let urlPayload = NFCNDEFPayload.wellKnownTypeURIPayload(url: url)
        else {
            session.invalidate(errorMessage: "Invalid URL")
            return
        }

        let message = NFCNDEFMessage(records: [urlPayload])
        tag.writeNDEF(message) { error in
            if let error = error {
                session.invalidate(
                    errorMessage: "Write failed: \(error.localizedDescription)")
            } else {
                session.alertMessage = "Successfully wrote URL to tag"
                session.invalidate()
            }
        }
    }
}
