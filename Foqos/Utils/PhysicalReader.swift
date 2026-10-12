import CodeScanner
import CoreNFC
import SwiftUI

class PhysicalReader {
  private let nfcScanner: NFCScannerUtil

  init(nfcScanner: NFCScannerUtil = NFCScannerUtil()) {
    self.nfcScanner = nfcScanner
  }

  func readNFCTag(
    onSuccess: @escaping (String) -> Void,
    onFailure: @escaping (String) -> Void = { _ in }
  ) {
    nfcScanner.onTagScanned = { [weak nfcScanner] result in
      nfcScanner?.onTagScanned = nil
      nfcScanner?.onError = nil
      let tagId = result.url ?? result.id
      onSuccess(tagId)
    }
    nfcScanner.onError = { [weak nfcScanner] error in
      nfcScanner?.onTagScanned = nil
      nfcScanner?.onError = nil
      onFailure(error)
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
        onSuccess(scanResult.string)
      case .failure(let error):
        onFailure(error.localizedDescription)
      }
    }
  }
}
