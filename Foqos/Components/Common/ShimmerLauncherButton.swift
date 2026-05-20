import SwiftUI

struct ShimmerLauncherButton: View {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @EnvironmentObject private var themeManager: ThemeManager

  let title: String
  let iconName: String
  let imageName: String?
  let height: CGFloat
  let isEnabled: Bool
  let accessibilityLabel: String
  let action: () -> Void

  @State private var isShimmering = false

  private let shimmerAnimationDuration = 1.15
  private let shimmerRepeatDelay = 2.5

  init(
    title: String,
    iconName: String = "play.fill",
    imageName: String? = nil,
    height: CGFloat = 64,
    isEnabled: Bool = true,
    accessibilityLabel: String,
    action: @escaping () -> Void
  ) {
    self.title = title
    self.iconName = iconName
    self.imageName = imageName
    self.height = height
    self.isEnabled = isEnabled
    self.accessibilityLabel = accessibilityLabel
    self.action = action
  }

  var body: some View {
    Button(action: action) {
      HStack(spacing: 10) {
        icon

        Text(title)
          .font(.title3)
          .fontWeight(.semibold)
      }
      .frame(maxWidth: .infinity)
      .frame(height: height)
      .background(buttonBackground)
      .shadow(
        color: themeManager.themeColor.opacity(isEnabled ? 0.24 : 0),
        radius: 12,
        x: 0,
        y: 6
      )
      .contentShape(Capsule())
    }
    .buttonStyle(LauncherButtonStyle())
    .foregroundStyle(.white)
    .disabled(!isEnabled)
    .accessibilityLabel(Text(accessibilityLabel))
    .onAppear {
      guard !reduceMotion else { return }
      isShimmering = true
    }
  }

  private var buttonBackground: some View {
    Capsule()
      .fill(themeManager.themeColor.opacity(isEnabled ? 0.72 : 0.34))
      .background(
        Capsule()
          .fill(.ultraThinMaterial)
      )
      .overlay(
        Capsule()
          .strokeBorder(.white.opacity(isEnabled ? 0.24 : 0.14), lineWidth: 1)
      )
      .overlay {
        if isEnabled && !reduceMotion {
          GeometryReader { geometry in
            LinearGradient(
              colors: [
                .clear,
                .white.opacity(0.12),
                .white.opacity(0.38),
                .white.opacity(0.12),
                .clear,
              ],
              startPoint: .top,
              endPoint: .bottom
            )
            .frame(width: geometry.size.width * 0.34, height: geometry.size.height * 2.2)
            .rotationEffect(.degrees(18))
            .offset(
              x: isShimmering ? geometry.size.width * 1.15 : -geometry.size.width * 0.55,
              y: -geometry.size.height * 0.55
            )
            .animation(
              .linear(duration: shimmerAnimationDuration)
                .delay(shimmerRepeatDelay)
                .repeatForever(autoreverses: false),
              value: isShimmering
            )
          }
          .clipShape(Capsule())
          .blendMode(.screen)
        }
      }
  }

  @ViewBuilder
  private var icon: some View {
    if let imageName {
      Image(imageName)
        .resizable()
        .scaledToFit()
        .frame(width: 24, height: 24)
    } else {
      Image(systemName: iconName)
        .font(.system(size: 18, weight: .bold))
    }
  }
}

struct LauncherButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.94 : 1)
      .animation(
        .spring(response: 0.22, dampingFraction: 0.72),
        value: configuration.isPressed
      )
  }
}
