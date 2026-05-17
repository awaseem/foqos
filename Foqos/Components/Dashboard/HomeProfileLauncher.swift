import SwiftUI
import UIKit

struct HomeProfileLauncher: View {
  @EnvironmentObject private var themeManager: ThemeManager
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  let isStartEnabled: Bool
  let onManageTapped: () -> Void
  let onStartTapped: () -> Void

  @State private var isShimmering = false

  private let shimmerAnimationDuration = 1.15
  private let shimmerRepeatDelay = 1.5

  var body: some View {
    HStack(spacing: 12) {
      Button(action: manageTapped) {
        Image(systemName: "person.2")
          .font(.system(size: 18, weight: .semibold))
          .frame(width: 56, height: 56)
      }
      .buttonStyle(.plain)
      .foregroundStyle(.primary)
      .background(
        Capsule()
          .fill(.thinMaterial)
          .overlay(
            Capsule()
              .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
          )
      )
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
      }
      .buttonStyle(.plain)
      .foregroundStyle(.white)
      .background(startButtonBackground)
      .shadow(
        color: isStartEnabled ? themeManager.themeColor.opacity(0.24) : .clear,
        radius: 12,
        x: 0,
        y: 6
      )
      .disabled(!isStartEnabled)
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
      .fill(themeManager.themeColor.opacity(isStartEnabled ? 0.72 : 0.36))
      .background(
        Capsule()
          .fill(.ultraThinMaterial)
      )
      .overlay(
        Capsule()
          .strokeBorder(.white.opacity(isStartEnabled ? 0.24 : 0.12), lineWidth: 1)
      )
      .overlay {
        if isStartEnabled && !reduceMotion {
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

#Preview {
  VStack {
    Spacer()
    HomeProfileLauncher(
      isStartEnabled: true,
      onManageTapped: {},
      onStartTapped: {}
    )
  }
  .background(Color(.systemGroupedBackground))
  .environmentObject(ThemeManager.shared)
}
