import CodeScanner
import CoreNFC
import SwiftUI

class PhysicalReader {
  private let nfcScanner: NFCScannerUtil = NFCScannerUtil()

  func readNFCTag(
    onSuccess: @escaping (String) -> Void,
  ) {
    nfcScanner.onTagScanned = { result in
      let tagId = result.url ?? result.id
      onSuccess(tagId)
    }

    nfcScanner.scan(profileName: "")
  }

  func readQRCode(
    onSuccess: @escaping (String) -> Void,
    onFailure: @escaping (String) -> Void
  ) -> some View {
    return LabeledCodeScannerView(
      heading: "Scan to set",
      subtitle: "Point your camera at a QR/Barcode code to set a physical unblock."
    ) { result in
      switch result {
      case .success(let scanResult):
        // Validate and sanitize the QR code for security
        let sanitizedCode = QRCodeValidator.sanitize(scanResult.string)
        let validationResult = QRCodeValidator.validate(sanitizedCode)

        if validationResult.isValid {
          onSuccess(sanitizedCode)
        } else {
          onFailure(validationResult.errorMessage ?? "Invalid QR code")
        }
      case .failure(let error):
        onFailure(error.localizedDescription)
      }
    }
  }
}
