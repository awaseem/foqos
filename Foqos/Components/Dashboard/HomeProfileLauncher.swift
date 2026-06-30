import SwiftUI
import UIKit

struct HomeProfileLauncher: View {
  @Environment(\.colorScheme) private var colorScheme
  @EnvironmentObject private var themeManager: ThemeManager

  let activeProfile: BlockedProfiles?
  let displayTime: TimeInterval
  var isBreakActive = false
  var isPauseActive = false
  let onStartTapped: () -> Void
  var onActiveTapped: () -> Void = {}

  private let inactiveButtonHeight: CGFloat = 64
  private let activeButtonHeight: CGFloat = 88
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
  }

  private var inactiveLauncherButtons: some View {
    ShimmerLauncherButton(
      title: "Start",
      imageName: "PlayStickerIcon",
      height: inactiveButtonHeight,
      accessibilityLabel: "Start Profile",
      action: startTapped
    )
  }

  private func activeProfileButton(_ profile: BlockedProfiles) -> some View {
    Button(action: activeTapped) {
      ProfileSummaryRow(
        profile: profile,
        isActive: true,
        metadata: .appsAndDomains,
        showsStatusLine: true,
        layout: .compact
      ) {
        activeAccessory
      }
      .padding(.horizontal, 20)
      .frame(maxWidth: .infinity)
      .frame(height: activeButtonHeight)
      .background(activeButtonBackground)
      .contentShape(RoundedRectangle(cornerRadius: activeButtonCornerRadius, style: .continuous))
    }
    .buttonStyle(LauncherButtonStyle())
    .foregroundStyle(.primary)
    .accessibilityLabel(activeAccessibilityLabel(for: profile))
  }

  @ViewBuilder
  private var activeAccessory: some View {
    if let activeStateTitle, let activeStateImageName {
      HStack(spacing: 6) {
        Image(activeStateImageName)
          .resizable()
          .scaledToFit()
          .frame(width: 24, height: 24)

        Text(activeStateTitle)
          .font(.headline)
          .fontWeight(.semibold)
          .lineLimit(1)
          .minimumScaleFactor(0.72)
      }
    } else {
      Text(DateFormatters.formatDurationClock(displayTime))
        .font(.system(size: 20, weight: .bold, design: .monospaced))
        .lineLimit(1)
        .minimumScaleFactor(0.72)
        .contentTransition(.numericText())
        .animation(.default, value: displayTime)
    }
  }

  private var activeStateTitle: String? {
    if isPauseActive {
      return "Paused"
    }
    if isBreakActive {
      return "On Break"
    }
    return nil
  }

  private var activeStateImageName: String? {
    if isPauseActive {
      return "PauseStickerIcon"
    }
    if isBreakActive {
      return "CoffeeStickerIcon"
    }
    return nil
  }

  private var activeButtonBackground: some View {
    CardBackground(
      isActive: true,
      customColor: activeBlobColor,
      backgroundColor: themeManager.themeColor,
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
      radius: 12,
      x: 0,
      y: 6
    )
    .shadow(
      color: Color.black.opacity(0.14),
      radius: 6,
      x: 0,
      y: 3
    )
  }

  private var activeBlobColor: Color {
    colorScheme == .dark ? Color.black.opacity(0.56) : Color.white.opacity(0.72)
  }

  private func startTapped() {
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
    onStartTapped()
  }

  private func activeTapped() {
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
    onActiveTapped()
  }

  private func activeAccessibilityLabel(for profile: BlockedProfiles) -> String {
    if let activeStateTitle {
      return "\(activeStateTitle) Profile \(profile.name)"
    }
    return "Active Profile \(profile.name)"
  }
}

#Preview("Inactive") {
  VStack {
    Spacer()
    HomeProfileLauncher(
      activeProfile: nil,
      displayTime: 0,
      onStartTapped: {}
    )
  }
  .background(Color(.systemGroupedBackground))
  .environmentObject(ThemeManager.shared)
}

#Preview("Active") {
  VStack {
    Spacer()
    HomeProfileLauncher(
      activeProfile: BlockedProfiles(
        name: "Work Focus",
        blockingStrategyId: ManualBlockingStrategy.id,
        enableLiveActivity: true,
        reminderTimeInSeconds: 3600,
        enableBreaks: true,
        domains: ["example.com", "social.example"]
      ),
      displayTime: 3665,
      onStartTapped: {}
    )
  }
  .background(Color(.systemGroupedBackground))
  .environmentObject(ThemeManager.shared)
}

#Preview("Paused") {
  VStack {
    Spacer()
    HomeProfileLauncher(
      activeProfile: BlockedProfiles(
        name: "Work Focus",
        blockingStrategyId: NFCPauseTimerBlockingStrategy.id,
        enableLiveActivity: true,
        reminderTimeInSeconds: 3600,
        enableBreaks: true,
        domains: ["example.com", "social.example"]
      ),
      displayTime: 900,
      isPauseActive: true,
      onStartTapped: {}
    )
  }
  .background(Color(.systemGroupedBackground))
  .environmentObject(ThemeManager.shared)
}
