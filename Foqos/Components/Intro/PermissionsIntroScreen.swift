import SwiftUI

struct PermissionsIntroScreen: View {
  let showPasscodeMessage: Bool

  @State private var showContent: Bool = false
  @State private var shieldScale: CGFloat = 0.5
  @State private var pulseAnimation: Bool = false

  var body: some View {
    VStack(spacing: 0) {
      // Heading
      // Header
      VStack(spacing: 8) {
        Text("One Last Step")
          .font(.system(size: 34, weight: .bold))
          .foregroundColor(.primary)
          .opacity(showContent ? 1 : 0)
          .offset(y: showContent ? 0 : -20)

        Text("We need Screen Time Access to get started")
          .font(.system(size: 16))
          .foregroundColor(.secondary)
          .opacity(showContent ? 1 : 0)
          .offset(y: showContent ? 0 : -20)
      }

      Spacer()

      // Shield icon with pulse animation
      ZStack {
        // Pulse rings
        ForEach(0..<2) { index in
          Circle()
            .stroke(
              LinearGradient(
                gradient: Gradient(colors: [
                  Color.accentColor.opacity(0.3),
                  Color.accentColor.opacity(0.1),
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
        Image("ShieldIcon")
          .resizable()
          .scaledToFit()
          .frame(width: 200, height: 200)
          .scaleEffect(shieldScale)
          .opacity(showContent ? 1 : 0)
      }
      .frame(height: 360)

      Spacer()

      // Message text
      VStack(spacing: 16) {
        (Text("Foqos is 100% open source, ")
          + Text("read the code yourself")
          .foregroundColor(.accentColor)
          + Text(
            " if you're skeptical. We don't care who you are, we just want you to live with focus and intention."
          ))
          .font(.system(size: 16, weight: .medium))
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
          .lineSpacing(4)
          .onTapGesture {
            if let url = URL(string: "https://github.com/awaseem/foqos") {
              UIApplication.shared.open(url)
            }
          }

        Text("No account required. No subscription fees. No tracking. No BS.")
          .font(.system(size: 16, weight: .medium))
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
          .lineSpacing(4)

        // Passcode warning message
        if showPasscodeMessage {
          HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
              .foregroundColor(.orange)
            Text("Still here? You need to set a passcode on your phone for Screen Time to work properly.")
              .font(.system(size: 14, weight: .medium))
              .foregroundColor(.orange)
              .multilineTextAlignment(.center)
          }
          .padding(.horizontal, 16)
          .padding(.vertical, 12)
          .background(
            RoundedRectangle(cornerRadius: 12)
              .fill(Color.orange.opacity(0.15))
          )
          .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
      }
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
  PermissionsIntroScreen(showPasscodeMessage: false)
    .background(Color(.systemBackground))
}
