import SwiftUI
import UIKit

struct HomeProfileLauncher: View {
  @EnvironmentObject private var themeManager: ThemeManager
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  let activeProfile: BlockedProfiles?
  let elapsedTime: TimeInterval
  let onStartTapped: () -> Void
  var onActiveTapped: () -> Void = {}

  @State private var isShimmering = false

  private let shimmerAnimationDuration = 1.15
  private let shimmerRepeatDelay = 2.5
  private let inactiveButtonHeight: CGFloat = 64
  private let activeButtonHeight: CGFloat = 74
  private let activeButtonCornerRadius: CGFloat = 24
  private let activeButtonBlobScale: CGFloat = 2.6
  private let activeButtonBlobCount = 9
  private let activeButtonBlobSizeRange: ClosedRange<CGFloat> = 0.18...0.34
  private let activeButtonBlobWidthRange: ClosedRange<CGFloat> = 1.45...2.65
  private let activeButtonBlobHeightRange: ClosedRange<CGFloat> = 0.65...1.15

  var body: some View {
    Group {
      if let activeProfile {
        activeProfileButton(activeProfile)
      } else {
        inactiveLauncherButtons
      }
    }
    .padding(.horizontal, 16)
    .padding(.top, 8)
    .onAppear {
      guard !reduceMotion else { return }
      isShimmering = true
    }
  }

  private var inactiveLauncherButtons: some View {
    Button(action: startTapped) {
      HStack(spacing: 10) {
        Image(systemName: "play.fill")
          .font(.system(size: 18, weight: .bold))

        Text("Start")
          .font(.title3)
          .fontWeight(.semibold)
      }
      .frame(maxWidth: .infinity)
      .frame(height: inactiveButtonHeight)
      .background(startButtonBackground)
      .shadow(
        color: themeManager.themeColor.opacity(0.24),
        radius: 12,
        x: 0,
        y: 6
      )
      .contentShape(Capsule())
    }
    .buttonStyle(LauncherButtonStyle())
    .foregroundStyle(.white)
    .accessibilityLabel("Start Profile")
  }

  private func activeProfileButton(_ profile: BlockedProfiles) -> some View {
    Button(action: activeTapped) {
      HStack(spacing: 12) {
        VStack(alignment: .leading, spacing: 4) {
          Text("Active")
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)

          Text(profile.name)
            .font(.headline)
            .fontWeight(.semibold)
            .lineLimit(1)
        }

        Spacer(minLength: 12)

        Text(DateFormatters.formatDurationClock(elapsedTime))
          .font(.system(size: 20, weight: .bold, design: .monospaced))
          .contentTransition(.numericText())
          .animation(.default, value: elapsedTime)
      }
      .padding(.horizontal, 20)
      .frame(maxWidth: .infinity)
      .frame(height: activeButtonHeight)
      .background(activeButtonBackground)
      .contentShape(RoundedRectangle(cornerRadius: activeButtonCornerRadius, style: .continuous))
    }
    .buttonStyle(LauncherButtonStyle())
    .foregroundStyle(.primary)
    .accessibilityLabel("Active Profile \(profile.name)")
  }

  private var activeButtonBackground: some View {
    CardBackground(
      isActive: true,
      customColor: themeManager.themeColor,
      cornerRadius: activeButtonCornerRadius,
      activeBlobScale: activeButtonBlobScale,
      activeBlobCount: activeButtonBlobCount,
      activeBlobSizeRange: activeButtonBlobSizeRange,
      activeBlobWidthRange: activeButtonBlobWidthRange,
      activeBlobHeightRange: activeButtonBlobHeightRange
    )
    .frame(height: activeButtonHeight)
    .clipShape(RoundedRectangle(cornerRadius: activeButtonCornerRadius, style: .continuous))
    .shadow(
      color: themeManager.themeColor.opacity(0.18),
      radius: 14,
      x: 0,
      y: 8
    )
  }

  private var startButtonBackground: some View {
    Capsule()
      .fill(themeManager.themeColor.opacity(0.72))
      .background(
        Capsule()
          .fill(.ultraThinMaterial)
      )
      .overlay(
        Capsule()
          .strokeBorder(.white.opacity(0.24), lineWidth: 1)
      )
      .overlay {
        if !reduceMotion {
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

  private func startTapped() {
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
    onStartTapped()
  }

  private func activeTapped() {
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
    onActiveTapped()
  }
}

private struct LauncherButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.94 : 1)
      .animation(
        .spring(response: 0.22, dampingFraction: 0.72),
        value: configuration.isPressed
      )
  }
}

#Preview {
  VStack {
    Spacer()
    HomeProfileLauncher(
      activeProfile: nil,
      elapsedTime: 0,
      onStartTapped: {}
    )
  }
  .background(Color(.systemGroupedBackground))
  .environmentObject(ThemeManager.shared)
}
