import CodeScanner
import SwiftUI
import UIKit

struct LabeledCodeScannerView: View {
  let heading: String
  let subtitle: String
  let simulatedData: String?
  let onScanResult: (Result<ScanResult, ScanError>) -> Void

  @State private var isShowingScanner = true
  @State private var errorMessage: String? = nil
  @State private var scanError: ScanError? = nil
  @State private var isTorchOn = false

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
        ZStack(alignment: .bottomTrailing) {
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
            showViewfinder: true,
            shouldVibrateOnSuccess: true,
            isTorchOn: isTorchOn,
            completion: handleScanResult
          )
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .cornerRadius(12)

          // Flashlight toggle button
          Button(action: {
            isTorchOn.toggle()
          }) {
            Image(systemName: isTorchOn ? "flashlight.on.fill" : "flashlight.slash")
              .font(.system(size: 24))
              .foregroundColor(.white)
              .padding(12)
              .background(Color.black.opacity(0.6))
              .clipShape(Circle())
          }
          .padding(16)
        }
        .padding(.vertical, 10)
      } else if let scanError = scanError {
        if case ScanError.permissionDenied = scanError {
          VStack(spacing: 16) {
            Image(systemName: "camera.fill")
              .font(.system(size: 30))

            Text("Camera Access Required")
              .font(.headline)

            Text("To scan QR codes, you need to grant camera access to Foqos.")
              .font(.subheadline)
              .multilineTextAlignment(.center)
              .foregroundColor(.secondary)
              .padding(.horizontal)

            ActionButton(
              title: "Open Settings",
              backgroundColor: .red,
              iconName: "gearshape.fill"
            ) {
              if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
              }
            }
            .padding(.horizontal, 24)
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 30)
        } else {
          Text("Error: \(errorMessage ?? "Unknown error")")
            .foregroundColor(.red)
            .padding()
        }
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
      scanError = nil
      isTorchOn = false
    }
    .onDisappear {
      isShowingScanner = false
      scanError = nil
      isTorchOn = false
    }
  }

  private func handleScanResult(_ result: Result<ScanResult, ScanError>) {
    switch result {
    case .success(let scanResult):
      isShowingScanner = false
      errorMessage = nil
      scanError = nil
      onScanResult(.success(scanResult))
    case .failure(let error):
      if case ScanError.permissionDenied = error {
        isShowingScanner = false
        errorMessage = error.localizedDescription
        scanError = error
      } else {
        isShowingScanner = false
        errorMessage = error.localizedDescription
        scanError = error
        onScanResult(.failure(error))
      }
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
