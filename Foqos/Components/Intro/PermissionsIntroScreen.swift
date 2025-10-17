import SwiftUI

struct PermissionsIntroScreen: View {
  @State private var showContent: Bool = false
  @State private var animateShield: Bool = false
  let onRequestAuthorization: () -> Void

  var body: some View {
    VStack(spacing: 0) {
      Spacer()

      // Shield animation
      ZStack {
        // Animated rings
        ForEach(0..<3) { index in
          Circle()
            .stroke(
              LinearGradient(
                gradient: Gradient(colors: [
                  Color.purple.opacity(0.3),
                  Color.blue.opacity(0.2),
                  Color.clear,
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              ),
              lineWidth: 2
            )
            .frame(width: 140 + CGFloat(index * 40), height: 140 + CGFloat(index * 40))
            .scaleEffect(animateShield ? 1.2 : 1.0)
            .opacity(animateShield ? 0 : 0.6)
            .animation(
              .easeOut(duration: 2)
                .repeatForever(autoreverses: false)
                .delay(Double(index) * 0.3),
              value: animateShield
            )
        }

        // Shield icon
        ZStack {
          Circle()
            .fill(
              LinearGradient(
                gradient: Gradient(colors: [
                  Color.purple.opacity(0.2),
                  Color.blue.opacity(0.1),
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
            )
            .frame(width: 120, height: 120)

          Image(systemName: "shield.checkered")
            .font(.system(size: 50, weight: .medium))
            .foregroundStyle(
              LinearGradient(
                gradient: Gradient(colors: [Color.purple, Color.blue]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
            )
        }
        .scaleEffect(showContent ? 1.0 : 0.5)
        .rotationEffect(.degrees(showContent ? 0 : -180))
      }
      .frame(height: 240)
      .padding(.bottom, 32)

      // Content
      VStack(spacing: 16) {
        Text("One More Step")
          .font(.system(size: 34, weight: .bold))
          .foregroundColor(.primary)
          .opacity(showContent ? 1 : 0)
          .offset(y: showContent ? 0 : 20)

        Text("We need your permission to help you focus")
          .font(.system(size: 18))
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
          .padding(.horizontal, 40)
          .opacity(showContent ? 1 : 0)
          .offset(y: showContent ? 0 : 20)
      }
      .padding(.bottom, 32)

      // Permission details
      VStack(spacing: 16) {
        PermissionRow(
          icon: "hourglass.circle.fill",
          title: "Screen Time Access",
          description: "Required to block apps during focus sessions"
        )
        .opacity(showContent ? 1 : 0)
        .offset(x: showContent ? 0 : -30)

        PermissionRow(
          icon: "lock.shield.fill",
          title: "Privacy First",
          description: "Your data never leaves your device"
        )
        .opacity(showContent ? 1 : 0)
        .offset(x: showContent ? 0 : 30)

        PermissionRow(
          icon: "checkmark.seal.fill",
          title: "You're In Control",
          description: "Change permissions anytime in Settings"
        )
        .opacity(showContent ? 1 : 0)
        .offset(x: showContent ? 0 : -30)
      }
      .padding(.horizontal, 32)

      Spacer()
      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .onAppear {
      withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2)) {
        showContent = true
      }

      // Start shield animation
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        animateShield = true
      }
    }
  }
}

struct PermissionRow: View {
  let icon: String
  let title: String
  let description: String

  var body: some View {
    HStack(alignment: .top, spacing: 16) {
      Image(systemName: icon)
        .font(.system(size: 24, weight: .semibold))
        .foregroundStyle(
          LinearGradient(
            gradient: Gradient(colors: [Color.purple, Color.blue]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .frame(width: 28)

      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(.system(size: 16, weight: .semibold))
          .foregroundColor(.primary)

        Text(description)
          .font(.system(size: 14))
          .foregroundColor(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }

      Spacer()
    }
    .padding(16)
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(Color(.secondarySystemBackground))
    )
  }
}

#Preview {
  PermissionsIntroScreen(onRequestAuthorization: {
    print("Request authorization")
  })
  .background(Color(.systemBackground))
}
