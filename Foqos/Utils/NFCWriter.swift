import CoreNFC
import SwiftUI

/// Writes NDEF-formatted URLs to NFC tags
///
/// **Supported Tags:**
/// - Blank NTAG (NTAG213, NTAG215, NTAG216)
/// - MiFare Ultralight with NDEF formatting
/// - Other NDEF-compliant tags
///
/// **NOT Supported (will show error):**
/// - Amiibos (proprietary Nintendo format)
/// - Hotel key cards (proprietary lock system data)
/// - Read-only/locked tags
/// - Non-NDEF formatted tags
class NFCWriter: NSObject, ObservableObject {
  var scannedNFCTag: NFCResult?
  var isScanning: Bool = false
  var errorMessage: String?

  private var tagSession: NFCTagReaderSession?
  private var urlToWrite: String?

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

    urlToWrite = url

    // Use NFCTagReaderSession to detect ALL tag types (including non-NDEF)
    // This allows us to show proper errors for Amiibos, hotel cards, etc.
    tagSession = NFCTagReaderSession(
      pollingOption: [.iso14443, .iso15693],
      delegate: self,
      queue: nil
    )
    tagSession?.alertMessage = "Hold your iPhone near an NFC tag to write the profile."
    tagSession?.begin()

    isScanning = true
  }
}

// MARK: - NFCTagReaderSessionDelegate
extension NFCWriter: NFCTagReaderSessionDelegate {
  func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
    // Session became active
  }

  func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
    DispatchQueue.main.async {
      self.isScanning = false

      if let readerError = error as? NFCReaderError {
        switch readerError.code {
        case .readerSessionInvalidationErrorUserCanceled:
          // User canceled - not an error
          break
        case .readerSessionInvalidationErrorSessionTimeout:
          self.errorMessage = "Session timed out. Please try again."
        case .readerTransceiveErrorTagConnectionLost:
          self.errorMessage = "Tag moved away. Please hold it steady."
        default:
          // Log the actual error for debugging
          print("⚠️ NFC Writer error: \(readerError.code.rawValue) - \(error.localizedDescription)")
          self.errorMessage = error.localizedDescription
        }
      }
    }
  }

  func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
    guard let tag = tags.first else {
      session.invalidate(errorMessage: "No tag found")
      return
    }

    session.connect(to: tag) { error in
      if error != nil {
        session.invalidate(
          errorMessage: "Connection error. Please hold tag steady and try again.")
        return
      }

      // Handle different tag types
      switch tag {
      case .miFare(let miFareTag):
        self.handleMiFareTagWrite(miFareTag, session: session)
      case .iso15693(let iso15693Tag):
        self.handleISO15693TagWrite(iso15693Tag, session: session)
      case .iso7816:
        // ISO7816 tags (smart cards, payment cards) cannot be written to
        session.invalidate(
          errorMessage: "This type of card cannot be written to.")
      case .feliCa:
        // FeliCa tags (Sony) cannot be written to with NDEF
        session.invalidate(
          errorMessage: "This type of card cannot be written to.")
      @unknown default:
        session.invalidate(errorMessage: "Unsupported tag type")
      }
    }
  }

  // MARK: - MiFare Tag Writing
  private func handleMiFareTagWrite(_ tag: NFCMiFareTag, session: NFCTagReaderSession) {
    // Check if this MiFare tag supports NDEF
    tag.queryNDEFStatus { status, capacity, error in
      if error != nil {
        // Tag doesn't support NDEF queries (Amiibos, hotel cards, etc.)
        session.invalidate(
          errorMessage: "This tag cannot be written to. Use a blank NFC tag instead.")
        return
      }

      switch status {
      case .notSupported:
        // Tag detected but doesn't support NDEF (proprietary format)
        session.invalidate(
          errorMessage: "This tag uses a proprietary format. Use a blank NFC tag instead.")
      case .readOnly:
        session.invalidate(
          errorMessage: "This tag is locked and cannot be modified.")
      case .readWrite:
        self.writeNDEFToTag(tag, session: session, capacity: capacity)
      @unknown default:
        session.invalidate(errorMessage: "Unknown tag status")
      }
    }
  }

  // MARK: - ISO15693 Tag Writing
  private func handleISO15693TagWrite(_ tag: NFCISO15693Tag, session: NFCTagReaderSession) {
    // Check if this ISO15693 tag supports NDEF
    tag.queryNDEFStatus { status, capacity, error in
      if error != nil {
        session.invalidate(
          errorMessage: "This tag cannot be written to. Use a blank NFC tag instead.")
        return
      }

      switch status {
      case .notSupported:
        session.invalidate(
          errorMessage: "This tag uses a proprietary format. Use a blank NFC tag instead.")
      case .readOnly:
        session.invalidate(
          errorMessage: "This tag is locked and cannot be modified.")
      case .readWrite:
        self.writeNDEFToTag(tag, session: session, capacity: capacity)
      @unknown default:
        session.invalidate(errorMessage: "Unknown tag status")
      }
    }
  }

  // MARK: - Write NDEF to Tag
  private func writeNDEFToTag(_ tag: NFCNDEFTag, session: NFCTagReaderSession, capacity: Int) {
    guard let urlString = self.urlToWrite,
      let url = URL(string: urlString),
      let urlPayload = NFCNDEFPayload.wellKnownTypeURIPayload(url: url)
    else {
      session.invalidate(errorMessage: "Invalid URL format")
      return
    }

    let message = NFCNDEFMessage(records: [urlPayload])

    // Check if the message fits on the tag
    let messageSize = message.length
    if messageSize > capacity {
      session.invalidate(
        errorMessage: "URL too long for this tag (\(messageSize) > \(capacity) bytes)")
      return
    }

    // Write the NDEF message to the tag
    tag.writeNDEF(message) { error in
      if error != nil {
        session.invalidate(
          errorMessage: "Write failed. Please try again.")
      } else {
        session.alertMessage = "✓ Successfully wrote profile to tag"
        DispatchQueue.main.async {
          self.isScanning = false
        }
        session.invalidate()
      }
    }
  }
}
