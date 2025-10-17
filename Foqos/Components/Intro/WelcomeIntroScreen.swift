import SwiftUI

struct WelcomeIntroScreen: View {
  @State private var logoScale: CGFloat = 0.3
  @State private var logoRotation: Double = -180
  @State private var showContent: Bool = false

  var body: some View {
    VStack(spacing: 0) {
      // Heading
      Text("Welcome to Foqos")
        .font(.system(size: 34, weight: .bold))
        .foregroundColor(.primary)
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : -20)
        .padding(.bottom, 32)

      // 3D Logo
      Image("3DFoqosLogo")
        .resizable()
        .scaledToFit()
        .frame(width: 200, height: 200)
        .scaleEffect(logoScale)
        .rotationEffect(.degrees(logoRotation))
        .opacity(showContent ? 1 : 0)
        .padding(.vertical, 80)

      // Message text
      Text(
        "You made the right decision not spending hundreds of dollars on plastic bricks, metal cards or subscription fees to get focused time in your life."
      )
      .font(.system(size: 18, weight: .medium))
      .foregroundColor(.secondary)
      .multilineTextAlignment(.center)
      .lineSpacing(4)
      .padding(.horizontal, 40)
      .opacity(showContent ? 1 : 0)
      .offset(y: showContent ? 0 : 20)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .onAppear {
      // Logo animation
      withAnimation(.spring(response: 0.8, dampingFraction: 0.6, blendDuration: 0).delay(0.2)) {
        logoScale = 1.0
        logoRotation = 0
      }

      // Content fade in
      withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
        showContent = true
      }
    }
  }
}

#Preview {
  WelcomeIntroScreen()
    .background(Color(.systemBackground))
}
