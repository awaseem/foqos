import SwiftUI

struct PermissionsIntroScreen: View {
  @EnvironmentObject private var themeManager: ThemeManager

  @State private var showContent: Bool = false
  @State private var shieldScale: CGFloat = 0.5
  @State private var pulseAnimation: Bool = false

  var body: some View {
    VStack(spacing: 0) {
      // Header
      Text("One Last Step")
        .font(.system(size: 34, weight: .bold))
        .foregroundColor(.primary)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : -20)

      Spacer()

      // Shield icon with pulse animation
      ZStack {
        // Pulse rings
        ForEach(0..<2) { index in
          Circle()
            .stroke(
              LinearGradient(
                gradient: Gradient(colors: [
                  themeManager.themeColor.opacity(0.3),
                  themeManager.themeColor.opacity(0.1),
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              ),
              lineWidth: 3
            )
            .frame(width: 220, height: 220)
            .scaleEffect(pulseAnimation ? 1.3 : 1.0)
            .opacity(pulseAnimation ? 0 : 0.6)
            .animation(
              .easeOut(duration: 2)
                .repeatForever(autoreverses: false)
                .delay(Double(index) * 0.6),
              value: pulseAnimation
            )
        }

        // Shield icon
        Image("ShieldSticker")
          .resizable()
          .scaledToFit()
          .frame(width: 200, height: 200)
          .scaleEffect(shieldScale)
          .shadow(color: themeManager.themeColor.opacity(0.22), radius: 16, y: 8)
          .opacity(showContent ? 1 : 0)
      }
      .frame(height: 300)

      Spacer()

      // Message text
      VStack(spacing: 16) {
        Text(
          "Foqos needs Screen Time access to block your chosen apps and websites during focus sessions."
        )
        .font(.system(size: 15))
        .foregroundColor(.primary)
        .multilineTextAlignment(.center)
        .lineSpacing(4)

        Text(
          "Your trust matters. Foqos is [100% open source](https://github.com/awaseem/foqos), so you can see exactly how it works. No account required. No tracking."
        )
        .font(.system(size: 16))
        .foregroundColor(.secondary)
        .tint(themeManager.themeColor)
        .multilineTextAlignment(.center)
        .lineSpacing(4)
      }
      .fixedSize(horizontal: false, vertical: true)
      .padding(.horizontal, 10)
      .opacity(showContent ? 1 : 0)
      .offset(y: showContent ? 0 : 20)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .onAppear {
      // Shield scale animation
      withAnimation(.spring(response: 0.8, dampingFraction: 0.6, blendDuration: 0).delay(0.2)) {
        shieldScale = 1.0
      }

      // Content fade in
      withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
        showContent = true
      }

      // Start pulse animation
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        pulseAnimation = true
      }
    }
  }
}

#Preview {
  PermissionsIntroScreen()
    .background(Color(.systemBackground))
    .environmentObject(ThemeManager.shared)
}
