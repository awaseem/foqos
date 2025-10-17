import SwiftUI

struct WelcomeIntroScreen: View {
  @State private var logoScale: CGFloat = 0.3
  @State private var logoRotation: Double = -180
  @State private var showContent: Bool = false

  var body: some View {
    VStack(spacing: 0) {
      Spacer()

      // Animated Logo
      ZStack {
        // Outer circle animation
        Circle()
          .fill(
            LinearGradient(
              gradient: Gradient(colors: [
                Color.purple.opacity(0.3),
                Color.purple.opacity(0.1),
                Color.clear,
              ]),
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )
          .frame(width: 180, height: 180)
          .scaleEffect(showContent ? 1.2 : 0.8)
          .opacity(showContent ? 0.4 : 0)
          .animation(
            .easeInOut(duration: 2)
              .repeatForever(autoreverses: true),
            value: showContent
          )

        // Middle circle
        Circle()
          .fill(
            LinearGradient(
              gradient: Gradient(colors: [
                Color.purple.opacity(0.2),
                Color.purple.opacity(0.05),
              ]),
              startPoint: .top,
              endPoint: .bottom
            )
          )
          .frame(width: 140, height: 140)
          .scaleEffect(showContent ? 1.1 : 0.9)
          .opacity(showContent ? 0.6 : 0)
          .animation(
            .easeInOut(duration: 1.5)
              .repeatForever(autoreverses: true)
              .delay(0.2),
            value: showContent
          )

        // Logo icon
        Image(systemName: "hourglass")
          .font(.system(size: 60, weight: .light))
          .foregroundStyle(
            LinearGradient(
              gradient: Gradient(colors: [Color.purple, Color.blue]),
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )
          .scaleEffect(logoScale)
          .rotationEffect(.degrees(logoRotation))
      }
      .frame(height: 220)
      .padding(.bottom, 40)

      // Welcome text
      VStack(spacing: 12) {
        Text("Welcome to")
          .font(.system(size: 24, weight: .regular))
          .foregroundColor(.secondary)
          .opacity(showContent ? 1 : 0)
          .offset(y: showContent ? 0 : 20)

        Text("Foqos")
          .font(.system(size: 56, weight: .bold))
          .foregroundStyle(
            LinearGradient(
              gradient: Gradient(colors: [Color.purple, Color.blue]),
              startPoint: .leading,
              endPoint: .trailing
            )
          )
          .opacity(showContent ? 1 : 0)
          .offset(y: showContent ? 0 : 20)

        Text("Your Personal Focus Companion")
          .font(.system(size: 18, weight: .medium))
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
          .padding(.horizontal, 40)
          .opacity(showContent ? 1 : 0)
          .offset(y: showContent ? 0 : 20)
      }
      .padding(.bottom, 24)

      // Feature highlights
      VStack(spacing: 16) {
        FeatureTag(icon: "lock.shield.fill", text: "Block Distractions")
          .opacity(showContent ? 1 : 0)
          .offset(x: showContent ? 0 : -30)

        FeatureTag(icon: "chart.line.uptrend.xyaxis", text: "Track Progress")
          .opacity(showContent ? 1 : 0)
          .offset(x: showContent ? 0 : 30)

        FeatureTag(icon: "sparkles", text: "Build Better Habits")
          .opacity(showContent ? 1 : 0)
          .offset(x: showContent ? 0 : -30)
      }
      .padding(.horizontal, 40)

      Spacer()
      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .onAppear {
      // Logo animation
      withAnimation(.spring(response: 0.8, dampingFraction: 0.6, blendDuration: 0).delay(0.2)) {
        logoScale = 1.0
        logoRotation = 0
      }

      // Content fade in
      withAnimation(.easeOut(duration: 0.6).delay(0.5)) {
        showContent = true
      }
    }
  }
}

struct FeatureTag: View {
  let icon: String
  let text: String

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: icon)
        .font(.system(size: 18, weight: .semibold))
        .foregroundColor(.purple)
        .frame(width: 24)

      Text(text)
        .font(.system(size: 16, weight: .medium))
        .foregroundColor(.primary)

      Spacer()
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 14)
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(Color.purple.opacity(0.08))
    )
  }
}

#Preview {
  WelcomeIntroScreen()
    .background(Color(.systemBackground))
}
