import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI
import UIKit

struct QRCodeView: View {
  @Environment(\.dismiss) private var dismiss

  let url: String
  let profileName: String
  @State private var qrCodeImage: UIImage? = nil

  var body: some View {
    NavigationView {
      VStack(spacing: 30) {
        // Profile name heading
        Text(profileName)
          .font(.title)
          .fontWeight(.bold)
          .multilineTextAlignment(.center)
          .padding(.top)

        // QR Code
        if let qrCodeImage {
          Image(uiImage: qrCodeImage)
            .interpolation(.none)
            .resizable()
            .scaledToFit()
            .frame(width: 250, height: 250)
        } else {
          ProgressView()
            .frame(width: 250, height: 250)
        }

        // Description text
        Text("Scan this code without the app running to start/stop this profile")
          .font(.body)
          .multilineTextAlignment(.center)
          .foregroundColor(.secondary)
          .padding(.horizontal)
          .fixedSize(horizontal: false, vertical: true)

        // Share button using ShareLink
        if let qrCodeImage {
          ShareLink(
            item: Image(uiImage: qrCodeImage),
            preview: SharePreview(
              profileName,
              image: Image(uiImage: qrCodeImage)
            )
          ) {
            HStack {
              Image(systemName: "square.and.arrow.up")
              Text("Share QR code")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.purple)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
          }
          .padding(.horizontal)
        }
      }
      .padding()
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button {
            dismiss()
          } label: {
            Image(systemName: "xmark")
              .foregroundColor(.primary)
          }
        }
      }
      .onAppear {
        generateQRCode(from: url)
      }
    }
  }

  private func generateQRCode(from string: String) {
    // Create the QR code filter
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()

    // Set the input message
    let data = Data(string.utf8)
    filter.setValue(data, forKey: "inputMessage")
    filter.setValue("M", forKey: "inputCorrectionLevel")

    // Get the output image
    if let outputImage = filter.outputImage {
      // Scale the image
      let transform = CGAffineTransform(scaleX: 10, y: 10)
      let scaledImage = outputImage.transformed(by: transform)

      // Convert to UIImage
      if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
        self.qrCodeImage = UIImage(cgImage: cgImage)
      }
    }
  }
}
