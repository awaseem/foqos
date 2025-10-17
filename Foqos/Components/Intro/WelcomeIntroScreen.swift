import SwiftUI

let ORBIT_OFFSET: CGFloat = 145

struct WelcomeIntroScreen: View {
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

      // Logo container with orbiting icons
      ZStack {
        // Orbiting NFC Logo (0 degrees)
        Image("NFCLogo")
          .resizable()
          .scaledToFit()
          .frame(width: 50, height: 50)
          .offset(x: ORBIT_OFFSET)  // Orbit radius
          .rotationEffect(.degrees(orbitRotation))
          .opacity(showIcons ? 1 : 0)

        // Orbiting Barcode Icon (90 degrees)
        Image("BarcodeIcon")
          .resizable()
          .scaledToFit()
          .frame(width: 50, height: 50)
          .offset(x: ORBIT_OFFSET)  // Orbit radius
          .rotationEffect(.degrees(orbitRotation + 90))
          .opacity(showIcons ? 1 : 0)

        // Orbiting QR Code Logo (180 degrees)
        Image("QRCodeLogo")
          .resizable()
          .scaledToFit()
          .frame(width: 50, height: 50)
          .offset(x: ORBIT_OFFSET)  // Orbit radius
          .rotationEffect(.degrees(orbitRotation + 180))
          .opacity(showIcons ? 1 : 0)

        // Orbiting Schedule Icon (270 degrees)
        Image("ScheduleIcon")
          .resizable()
          .scaledToFit()
          .frame(width: 50, height: 50)
          .offset(x: ORBIT_OFFSET)  // Orbit radius
          .rotationEffect(.degrees(orbitRotation + 270))
          .opacity(showIcons ? 1 : 0)

        // 3D Logo (center/sun)
        Image("3DFoqosLogo")
          .resizable()
          .scaledToFit()
          .frame(width: 200, height: 200)
          .scaleEffect(logoScale)
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
      .padding(.horizontal, 10)
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
}
