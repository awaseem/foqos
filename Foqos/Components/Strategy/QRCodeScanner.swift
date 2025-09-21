import CodeScanner
import SwiftUI

struct LabeledCodeScannerView: View {
  let heading: String
  let subtitle: String
  let simulatedData: String?
  let onScanResult: (Result<ScanResult, ScanError>) -> Void

  @State private var isShowingScanner = true
  @State private var errorMessage: String? = nil

  init(
    heading: String,
    subtitle: String,
    simulatedData: String? = nil,
    onScanResult: @escaping (Result<ScanResult, ScanError>) -> Void
  ) {
    self.heading = heading
    self.subtitle = subtitle
    self.simulatedData = simulatedData
    self.onScanResult = onScanResult
  }

  var body: some View {
    VStack(alignment: .leading) {
      Text(heading)
        .font(.title2)
        .bold()
      Text(subtitle)
        .font(.subheadline)
        .foregroundColor(.gray)
        .padding(.bottom)

      if isShowingScanner {
        CodeScannerView(
          codeTypes: [
            .aztec,
            .code128,
            .code39,
            .code39Mod43,
            .code93,
            .ean8,
            .ean13,
            .interleaved2of5,
            .itf14,
            .pdf417,
            .upce,
            .qr,
            .dataMatrix,
          ],
          showViewfinder: true, shouldVibrateOnSuccess: true, completion: handleScanResult
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .cornerRadius(12)
        .padding(.vertical, 10)
      } else if let errorMessage = errorMessage {
        Text("Error: \(errorMessage)")
          .foregroundColor(.red)
          .padding()
      } else {

        Text("Scanner Paused or Not Available")
          .foregroundColor(.secondary)
          .padding()
      }

      Spacer()
    }
    .padding()
    .onAppear {
      isShowingScanner = true
      errorMessage = nil
    }
    .onDisappear {
      isShowingScanner = false
    }
  }

  private func handleScanResult(_ result: Result<ScanResult, ScanError>) {
    switch result {
    case .success(let scanResult):
      isShowingScanner = false
      errorMessage = nil
      onScanResult(.success(scanResult))
    case .failure(let error):
      isShowingScanner = false
      errorMessage = error.localizedDescription
      onScanResult(.failure(error))
    }
  }
}

#Preview {  // Using the #Preview macro
  LabeledCodeScannerView(
    heading: "Scan QR Code",
    subtitle: "Point your camera at a QR code to activate a feature.",
    simulatedData: "Simulated QR Code Data for Preview"  // For preview purposes
  ) { result in
    switch result {
    case .success(let result):
      print("Preview Scanned code: \(result.string)")
    case .failure(let error):
      print("Preview Scanning failed: \(error.localizedDescription)")
    }
  }
}
