import SwiftUI

private let orbitOffset: CGFloat = 154

struct WelcomeIntroScreen: View {
  @EnvironmentObject private var themeManager: ThemeManager

  @State private var logoScale: CGFloat = 0.5
  @State private var showContent: Bool = false
  @State private var showIcons: Bool = false
  @State private var orbitRotation: Double = 0

  var body: some View {
    VStack(spacing: 0) {
      // Heading
      VStack(spacing: 8) {
        Text("Welcome to Foqos")
          .font(.system(size: 34, weight: .bold))
          .foregroundColor(.primary)
          .opacity(showContent ? 1 : 0)
          .offset(y: showContent ? 0 : -20)

        Text("Live your best life with focus and intention.")
          .font(.system(size: 16))
          .foregroundColor(.secondary)
          .opacity(showContent ? 1 : 0)
          .offset(y: showContent ? 0 : -20)
      }

      Spacer()

      // Logo container with orbiting stickers
      ZStack {
        // Orbiting NFC sticker (0 degrees)
        Image("NFCStickerLogo")
          .resizable()
          .scaledToFit()
          .frame(width: 52, height: 52)
          .shadow(color: themeManager.themeColor.opacity(0.18), radius: 8, y: 4)
          .offset(x: orbitOffset)
          .rotationEffect(.degrees(orbitRotation))
          .opacity(showIcons ? 1 : 0)

        // Orbiting QR sticker (90 degrees)
        Image("QRStickerLogo")
          .resizable()
          .scaledToFit()
          .frame(width: 52, height: 52)
          .shadow(color: themeManager.themeColor.opacity(0.18), radius: 8, y: 4)
          .offset(x: orbitOffset)
          .rotationEffect(.degrees(orbitRotation + 90))
          .opacity(showIcons ? 1 : 0)

        // Orbiting barcode sticker (180 degrees)
        Image("BarcodeSticker")
          .resizable()
          .scaledToFit()
          .frame(width: 52, height: 52)
          .shadow(color: themeManager.themeColor.opacity(0.18), radius: 8, y: 4)
          .offset(x: orbitOffset)
          .rotationEffect(.degrees(orbitRotation + 180))
          .opacity(showIcons ? 1 : 0)

        // Orbiting timer sticker (270 degrees)
        Image("TimerSticker")
          .resizable()
          .scaledToFit()
          .frame(width: 52, height: 52)
          .shadow(color: themeManager.themeColor.opacity(0.18), radius: 8, y: 4)
          .offset(x: orbitOffset)
          .rotationEffect(.degrees(orbitRotation + 270))
          .opacity(showIcons ? 1 : 0)

        // Foqos sticker logo (center/sun)
        Image("FoqosStickerLogo")
          .resizable()
          .scaledToFit()
          .frame(width: 210, height: 210)
          .scaleEffect(logoScale)
          .shadow(color: themeManager.themeColor.opacity(0.22), radius: 18, y: 10)
          .opacity(showContent ? 1 : 0)
      }
      .frame(height: 360)

      Spacer()

      // Message text
      VStack(spacing: 12) {
        Text(
          "No need to waste hundreds on gimmicky plastic bricks and overpriced metal cards."
        )
        .font(.system(size: 18, weight: .medium))
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
        .lineSpacing(4)
      }
      .padding(.horizontal, 15)
      .opacity(showContent ? 1 : 0)
      .offset(y: showContent ? 0 : 20)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .onAppear {
      // Logo scale animation (0.8s spring animation with 0.2s delay = 1.0s total)
      withAnimation(.spring(response: 0.8, dampingFraction: 0.6, blendDuration: 0).delay(0.2)) {
        logoScale = 1.0
      }

      // Content fade in
      withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
        showContent = true
      }

      // Show icons after logo animation completes (1.0s delay)
      withAnimation(.easeIn(duration: 0.2).delay(1.0)) {
        showIcons = true
      }

      // Start continuous orbit animation after icons appear
      withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
        orbitRotation = 360
      }
    }
  }
}

#Preview {
  WelcomeIntroScreen()
    .background(Color(.systemBackground))
    .environmentObject(ThemeManager.shared)
}
