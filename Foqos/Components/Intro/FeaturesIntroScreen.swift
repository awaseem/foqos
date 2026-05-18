import SwiftUI

struct FeaturesIntroScreen: View {
  @EnvironmentObject private var themeManager: ThemeManager

  @State private var selectedFeature: Int = 0
  @State private var showContent: Bool = false

  let features = [
    Feature(
      imageName: "NFCStickerLogo",
      title: "NFC Tags",
      description:
        "Tap your phone on an NFC tag to instantly start or stop a focus session. You can buy them on Amazon for a few dollars."
    ),
    Feature(
      imageName: "QRStickerLogo",
      title: "QR Codes",
      description:
        "Scan a QR code to control your focus sessions. Place codes around your space to create intentional focus triggers. You can even use barcodes."
    ),
    Feature(
      imageName: "TimerSticker",
      title: "Smart Schedules",
      description:
        "Set up automatic focus sessions based on your routine. Create schedules for work, study, personal time, and more."
    ),
  ]

  var body: some View {
    VStack(spacing: 0) {
      // Header
      VStack(spacing: 8) {
        Text("Powerful Features")
          .font(.system(size: 34, weight: .bold))
          .foregroundColor(.primary)
          .opacity(showContent ? 1 : 0)
          .offset(y: showContent ? 0 : -20)

        Text("Everything you need to stay focused")
          .font(.system(size: 16))
          .foregroundColor(.secondary)
          .opacity(showContent ? 1 : 0)
          .offset(y: showContent ? 0 : -20)
      }

      Spacer()

      // Feature selector and display
      VStack(spacing: 0) {
        // Icon selector
        HStack(spacing: 20) {
          ForEach(0..<features.count, id: \.self) { index in
            Button(action: {
              withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedFeature = index
              }
            }) {
              Image(features[index].imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .opacity(selectedFeature == index ? 1.0 : 0.4)
                .scaleEffect(selectedFeature == index ? 1.12 : 1.0)
            }
          }
        }
        .opacity(showContent ? 1 : 0)
        .padding(.bottom, 50)

        // Feature content
        VStack(spacing: 30) {
          // Feature icon
          Image(features[selectedFeature].imageName)
            .resizable()
            .scaledToFit()
            .frame(width: 124, height: 124)
            .shadow(color: themeManager.themeColor.opacity(0.2), radius: 12, y: 6)
            .transition(.scale.combined(with: .opacity))
            .id("icon-\(selectedFeature)")

          // Feature text
          VStack(spacing: 12) {
            Text(features[selectedFeature].title)
              .font(.system(size: 28, weight: .bold))
              .foregroundColor(.primary)
              .multilineTextAlignment(.center)
              .transition(.opacity)
              .id("title-\(selectedFeature)")

            Text(features[selectedFeature].description)
              .font(.system(size: 17))
              .foregroundColor(.secondary)
              .multilineTextAlignment(.center)
              .lineSpacing(4)
              .padding(.horizontal, 32)
              .transition(.opacity)
              .id("description-\(selectedFeature)")
          }
        }
        .opacity(showContent ? 1 : 0)
      }

      Spacer()

      // Tap indicator
      HStack(spacing: 6) {
        Image(systemName: "hand.tap.fill")
          .font(.system(size: 14))
          .foregroundColor(.secondary)
        Text("Tap icons to explore features")
          .font(.system(size: 14))
          .foregroundColor(.secondary)
      }
      .opacity(showContent ? 0.7 : 0)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .onAppear {
      withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
        showContent = true
      }
    }
  }
}

struct Feature: Identifiable {
  let id = UUID()
  let imageName: String
  let title: String
  let description: String
}

#Preview {
  FeaturesIntroScreen()
    .background(Color(.systemBackground))
    .environmentObject(ThemeManager.shared)
}
