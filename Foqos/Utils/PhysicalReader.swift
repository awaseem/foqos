import CodeScanner
import CoreNFC
import SwiftUI

class PhysicalReader {
  private let nfcScanner: NFCScannerUtil = NFCScannerUtil()

  func readNFCTag(
    onSuccess: @escaping (String) -> Void,
    onFailure: @escaping (String) -> Void = { _ in }
  ) {
    nfcScanner.onTagScanned = { result in
      onSuccess(result.id)
    }
    nfcScanner.onError = onFailure

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
        onSuccess(scanResult.string)
      case .failure(let error):
        onFailure(error.localizedDescription)
      }
    }
  }
}
