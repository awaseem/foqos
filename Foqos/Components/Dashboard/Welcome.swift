import SwiftUI

struct Welcome: View {
  @EnvironmentObject var themeManager: ThemeManager
  let onGuidedTap: () -> Void
  let onAdvancedTap: () -> Void

  @State private var showStrategies = false

  private let featuredStrategyLogos = [
    "NFCStickerLogo",
    "QRStickerLogo",
    "ManualLogoSticker",
    "TimerSticker",
  ]

  private let logoPlacements: [(x: CGFloat, y: CGFloat, scale: CGFloat, rotation: Double)] = [
    (0.14, 0.72, 0.9, -14),
    (0.34, 0.28, 1.08, -5),
    (0.66, 0.28, 1.08, 6),
    (0.86, 0.72, 0.9, 14),
  ]

  var body: some View {
    VStack(spacing: 38) {
      strategyShowcase

      VStack(spacing: 14) {
        Text("Getting Started")
          .font(.title)
          .fontWeight(.bold)
          .foregroundColor(.primary)

        Text(
          "Let's get you started by creating your first profile. You can customize it as much or as little as you'd like."
        )
        .font(.subheadline)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, 8)

        ShimmerLauncherButton(
          title: "Create Profile",
          iconName: "brain.head.profile",
          height: 56,
          accessibilityLabel: "Start guided profile setup",
          action: onGuidedTap
        )
        .padding(.top, 6)

        Button(action: onAdvancedTap) {
          Text("Use the full profile editor")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(themeManager.themeColor)
        }
        .buttonStyle(.plain)
      }
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 22)
    .onAppear {
      showStrategies = true
    }
  }

  private var strategyShowcase: some View {
    GeometryReader { geometry in
      ZStack {
        ForEach(Array(featuredStrategyLogos.enumerated()), id: \.offset) { index, logoName in
          let placement = logoPlacements[index]

          WelcomeStrategyLogo(assetName: logoName)
            .scaleEffect(showStrategies ? placement.scale : 0.18)
            .opacity(showStrategies ? 1 : 0)
            .rotationEffect(.degrees(showStrategies ? placement.rotation : placement.rotation - 18))
            .position(
              x: geometry.size.width * placement.x,
              y: geometry.size.height * placement.y
            )
            .animation(
              .interpolatingSpring(stiffness: 185, damping: 11)
                .delay(Double(index) * 0.09),
              value: showStrategies
            )
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .frame(maxWidth: 320)
    .frame(height: 170)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("Blocking strategy options")
  }
}

private struct WelcomeStrategyLogo: View {
  let assetName: String

  var body: some View {
    Image(assetName)
      .resizable()
      .scaledToFit()
      .frame(width: 86, height: 86)
  }
}

#Preview {
  ZStack {
    Color.gray.opacity(0.1).ignoresSafeArea()

    Welcome(
      onGuidedTap: { print("Guided tapped") },
      onAdvancedTap: { print("Advanced tapped") }
    )
    .padding(.horizontal)
    .environmentObject(ThemeManager.shared)
  }
}
