import SwiftUI
import UIKit

struct HomeProfileLauncher: View {
  @EnvironmentObject private var themeManager: ThemeManager
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  let onManageTapped: () -> Void
  let onStartTapped: () -> Void

  @State private var isShimmering = false

  private let shimmerAnimationDuration = 1.15
  private let shimmerRepeatDelay = 2.5

  var body: some View {
    HStack(spacing: 12) {
      Button(action: manageTapped) {
        Image(systemName: "person.2")
          .font(.system(size: 18, weight: .semibold))
          .frame(width: 56, height: 56)
          .background(
            Capsule()
              .fill(.thinMaterial)
              .overlay(
                Capsule()
                  .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
              )
          )
          .contentShape(Capsule())
      }
      .buttonStyle(LauncherButtonStyle())
      .foregroundStyle(.primary)
      .accessibilityLabel("Manage Profiles")

      Button(action: startTapped) {
        HStack(spacing: 8) {
          Image(systemName: "play.fill")
            .font(.system(size: 16, weight: .bold))

          Text("Start")
            .font(.headline)
            .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 56)
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
    .padding(.horizontal, 16)
    .padding(.top, 8)
    .onAppear {
      guard !reduceMotion else { return }
      isShimmering = true
    }
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

  private func manageTapped() {
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
    onManageTapped()
  }

  private func startTapped() {
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
    onStartTapped()
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
      onManageTapped: {},
      onStartTapped: {}
    )
  }
  .background(Color(.systemGroupedBackground))
  .environmentObject(ThemeManager.shared)
}
