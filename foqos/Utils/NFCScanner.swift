import CoreNFC
import SwiftUI

struct NFCResult: Equatable {
    var id: String
    var url: String?
    var DateScanned: Date
}

class NFCScanner: NSObject, ObservableObject {
    @Published var scannedNFCTag: NFCResult?
    @Published var errorMessage: String?

    private var nfcSession: NFCReaderSession?
    private var urlToWrite: String?
    private var isWriteMode: Bool = false

    func resultFromURL(_ url: String) -> NFCResult {
        return NFCResult(id: url, url: url, DateScanned: Date())
    }

    func scan(profileName: String) {
        guard NFCReaderSession.readingAvailable else {
            self.errorMessage = "NFC scanning not available on this device"
            return
        }

        isWriteMode = false
        nfcSession = NFCTagReaderSession(
            pollingOption: [.iso14443, .iso15693],
            delegate: self,
            queue: nil
        )
        nfcSession?.alertMessage =
        "Hold your iPhone near an NFC tag to trigger " + profileName
        nfcSession?.begin()
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
    }
}

// Existing NFCTagReaderSessionDelegate
extension NFCScanner: NFCTagReaderSessionDelegate {
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        // Session started
    }

    func tagReaderSession(
        _ session: NFCTagReaderSession, didInvalidateWithError error: Error
    ) {
        DispatchQueue.main.async {
            self.errorMessage = error.localizedDescription
        }
    }

    func tagReaderSession(
        _ session: NFCTagReaderSession, didDetect tags: [NFCTag]
    ) {
        guard let tag = tags.first else { return }

        session.connect(to: tag) { error in
            if let error = error {
                session.invalidate(
                    errorMessage:
                        "Connection error: \(error.localizedDescription)")
                return
            }

            switch tag {
            case .iso15693(let tag):
                self.readISO15693Tag(tag, session: session)
            case .miFare(let tag):
                self.readMiFareTag(tag, session: session)
            default:
                session.invalidate(errorMessage: "Unsupported tag type")
            }
        }
    }

    private func updateWithNDEFMessageURL(_ message: NFCNDEFMessage) -> String?
    {
        // UI elements are updated based on the received NDEF message.
        let urls: [URLComponents] = message.records.compactMap {
            (payload: NFCNDEFPayload) -> URLComponents? in
            // Search for URL record with matching domain host and scheme.
            if let url = payload.wellKnownTypeURIPayload() {
                let components = URLComponents(
                    url: url, resolvingAgainstBaseURL: false)
                if components?.host == "foqos.app"
                    && components?.scheme == "https"
                {
                    return components
                }
            }
            return nil
        }

        // Valid tag should only contain 1 URL and contain multiple query items.
        guard urls.count == 1,
            let item = urls.first?.string
        else {
            return nil
        }

        return item
    }

    private func readMiFareTag(
        _ tag: NFCMiFareTag, session: NFCTagReaderSession
    ) {
        tag.readNDEF { (message: NFCNDEFMessage?, error: Error?) in
            if error != nil || message == nil {
                if let nfcError = error as? NFCReaderError,
                    nfcError.code
                        == NFCReaderError
                        .ndefReaderSessionErrorZeroLengthMessage
                {
                    self.handleTagData(
                        id: tag.identifier.hexEncodedString(),
                        url: nil,
                        session: session
                    )
                    return
                }

                session.invalidate(
                    errorMessage: "Read error. Please try again.")
                return
            }

            let url = self.updateWithNDEFMessageURL(message!)
            self.handleTagData(
                id: tag.identifier.hexEncodedString(),
                url: url,
                session: session
            )
        }
    }

    private func readISO15693Tag(
        _ tag: NFCISO15693Tag, session: NFCTagReaderSession
    ) {
        tag.readNDEF { (message: NFCNDEFMessage?, error: Error?) in
            if error != nil || message == nil {
                if let nfcError = error as? NFCReaderError,
                    nfcError.code
                        == NFCReaderError
                        .ndefReaderSessionErrorZeroLengthMessage
                {
                    self.handleTagData(
                        id: tag.identifier.hexEncodedString(),
                        url: nil,
                        session: session
                    )
                    return
                }

                session.invalidate(
                    errorMessage: "Read error. Please try again.")
                return
            }

            let url = self.updateWithNDEFMessageURL(message!)
            self.handleTagData(
                id: tag.identifier.hexEncodedString(),
                url: url,
                session: session
            )
        }
    }

    private func handleTagData(
        id: String, url: String?, session: NFCTagReaderSession
    ) {
        let result = NFCResult(
            id: id,
            url: url,
            DateScanned: Date()
        )

        DispatchQueue.main.async {
            self.scannedNFCTag = result
            session.invalidate()
        }
    }
}

// New NDEF Writing Support
extension NFCScanner: NFCNDEFReaderSessionDelegate {
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

extension Data {
    func hexEncodedString() -> String {
        return map { String(format: "%02hhX", $0) }.joined()
    }
}
