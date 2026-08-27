import AVFoundation
import CodeScanner
import SwiftUI
import UIKit

private final class QRScannerCamera: ObservableObject {
  let device: AVCaptureDevice?
  let zoomRange: ClosedRange<Double>
  let zoomFactors: [Double]

  @Published private(set) var zoomFactor: Double

  var supportsZoom: Bool {
    zoomFactors.count > 1
  }

  init() {
    let device =
      AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
      ?? AVCaptureDevice.default(for: .video)
    let minimumZoomFactor = Double(device?.minAvailableVideoZoomFactor ?? 1)
    let deviceMaximumZoomFactor = Double(device?.maxAvailableVideoZoomFactor ?? 1)
    let maximumZoomFactor = max(minimumZoomFactor, min(deviceMaximumZoomFactor, 5))
    let zoomRange = minimumZoomFactor...maximumZoomFactor
    let standardZoomFactors = [1.0, 2.0, 5.0]
    let availableZoomFactors = standardZoomFactors.filter { zoomRange.contains($0) }
    let initialZoomFactor = availableZoomFactors.first ?? minimumZoomFactor

    self.device = device
    self.zoomRange = zoomRange
    self.zoomFactors =
      availableZoomFactors.isEmpty ? [initialZoomFactor] : availableZoomFactors
    self.zoomFactor = initialZoomFactor

    _ = applyZoomFactor(initialZoomFactor)
  }

  func setZoomFactor(_ zoomFactor: Double) {
    guard let device else { return }

    let clampedZoomFactor = min(
      max(zoomFactor, zoomRange.lowerBound),
      zoomRange.upperBound
    )

    if applyZoomFactor(clampedZoomFactor) {
      self.zoomFactor = clampedZoomFactor
    }
  }

  func cycleZoomFactor() {
    guard
      let currentIndex = zoomFactors.firstIndex(where: {
        abs($0 - zoomFactor) < 0.05
      })
    else {
      setZoomFactor(zoomFactors[0])
      return
    }

    let nextIndex = zoomFactors.index(after: currentIndex)
    setZoomFactor(nextIndex == zoomFactors.endIndex ? zoomFactors[0] : zoomFactors[nextIndex])
  }

  func formattedZoomFactor(_ zoomFactor: Double) -> String {
    String(format: "%.0fx", zoomFactor)
  }

  private func applyZoomFactor(_ zoomFactor: Double) -> Bool {
    guard let device else { return false }

    do {
      try device.lockForConfiguration()
      device.videoZoomFactor = CGFloat(zoomFactor)
      device.unlockForConfiguration()
      return true
    } catch {
      return false
    }
  }
}

struct LabeledCodeScannerView: View {
  let heading: String
  let subtitle: String
  let simulatedData: String?
  let onScanResult: (Result<ScanResult, ScanError>) -> Void

  @StateObject private var camera = QRScannerCamera()
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
        ZStack(alignment: .bottom) {
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
            videoCaptureDevice: camera.device,
            completion: handleScanResult
          )
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .cornerRadius(12)

          scannerControls
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

  private var scannerControls: some View {
    HStack {
      if camera.supportsZoom {
        Button {
          camera.cycleZoomFactor()
        } label: {
          Text(camera.formattedZoomFactor(camera.zoomFactor))
            .font(.caption.bold().monospacedDigit())
            .frame(width: 48, height: 48)
            .background(Color.black.opacity(0.65))
            .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Camera zoom")
        .accessibilityValue(camera.formattedZoomFactor(camera.zoomFactor))
        .accessibilityHint("Cycles through the available zoom levels")
      }

      Spacer()

      Button(action: {
        isTorchOn.toggle()
      }) {
        Image(systemName: isTorchOn ? "flashlight.on.fill" : "flashlight.slash")
          .font(.system(size: 22))
          .frame(width: 48, height: 48)
          .background(Color.black.opacity(0.65))
          .clipShape(Circle())
      }
      .buttonStyle(.plain)
      .accessibilityLabel(isTorchOn ? "Turn flashlight off" : "Turn flashlight on")
    }
    .foregroundStyle(.white)
    .frame(maxWidth: .infinity)
    .padding(16)
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
