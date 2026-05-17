import SwiftUI
import UIKit

struct ActiveProfileSessionView: View {
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var themeManager: ThemeManager

  let profile: BlockedProfiles
  let elapsedTime: TimeInterval
  let isBreakAvailable: Bool
  let isBreakActive: Bool
  let isPauseActive: Bool
  let onBreakTapped: () -> Void
  let onStopTapped: () -> Void

  @State private var showEmergencyView = false
  @State private var showProfileInsights = false
  @State private var focusMessageIndex = Self.initialFocusMessageIndex()

  private let focusMessageTimer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()

  private var showStopButton: Bool {
    profile.showStopButton(elapsedTime: elapsedTime)
  }

  private var stopButtonTitle: String {
    isPauseActive ? "End" : "Stop"
  }

  private var breakButtonTitle: String {
    "Hold to " + (isBreakActive ? "Stop Break" : "Start Break")
  }

  private var focusMessage: String {
    guard FocusMessages.messages.indices.contains(focusMessageIndex) else {
      return FocusMessages.getRandomMessage()
    }
    return FocusMessages.messages[focusMessageIndex]
  }

  var body: some View {
    ZStack {
      background

      VStack(alignment: .leading, spacing: 0) {
        header

        timerSection
          .padding(.top, 60)
          .frame(maxWidth: .infinity)

        Spacer(minLength: 48)

        actionSection
      }
      .padding(.horizontal, 24)
      .padding(.top, 18)
      .padding(.bottom, 20)
    }
    .sheet(isPresented: $showEmergencyView) {
      EmergencyView()
        .presentationDetents([.height(350)])
    }
    .sheet(isPresented: $showProfileInsights) {
      ProfileInsightsView(profile: profile)
    }
    .onReceive(focusMessageTimer) { _ in
      rotateFocusMessage()
    }
  }

  private var background: some View {
    ZStack {
      CardBackground(
        isActive: true,
        customColor: themeManager.themeColor,
        cornerRadius: 0,
        activeBlobScale: 6,
        activeBlobCount: 12,
        activeBlobSizeRange: 0.18...0.38,
        activeBlobWidthRange: 1.25...2.6,
        activeBlobHeightRange: 0.7...1.4
      )
      .ignoresSafeArea()

      LinearGradient(
        colors: [
          Color(.systemBackground).opacity(0.18),
          Color(.systemBackground).opacity(0.72),
        ],
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()
    }
  }

  private var header: some View {
    HStack(alignment: .top, spacing: 16) {
      VStack(alignment: .leading, spacing: 8) {
        Text(profile.name)
          .font(.largeTitle)
          .fontWeight(.bold)
          .lineLimit(2)
          .minimumScaleFactor(0.72)

        if let statusMessage {
          Text(statusMessage)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
        }
      }

      Spacer(minLength: 12)

      HStack(spacing: 10) {
        Button(action: { showProfileInsights = true }) {
          Image(systemName: "chart.line.uptrend.xyaxis")
            .font(.system(size: 16, weight: .semibold))
            .frame(width: 42, height: 42)
            .background(.thinMaterial, in: Circle())
            .contentShape(Circle())
        }
        .buttonStyle(ActiveSessionPressStyle())
        .foregroundStyle(.primary)
        .accessibilityLabel("Insights")

        Button(action: { dismiss() }) {
          Image(systemName: "xmark")
            .font(.system(size: 15, weight: .semibold))
            .frame(width: 42, height: 42)
            .background(.thinMaterial, in: Circle())
            .contentShape(Circle())
        }
        .buttonStyle(ActiveSessionPressStyle())
        .foregroundStyle(.primary)
        .accessibilityLabel("Close")
      }
    }
  }

  private var statusMessage: String? {
    if isPauseActive {
      return "Paused"
    }
    if isBreakActive {
      return "On a Break"
    }
    return nil
  }

  private var timerSection: some View {
    VStack(spacing: 14) {
      Text(DateFormatters.formatDurationClock(elapsedTime))
        .font(.system(size: 58, weight: .bold, design: .monospaced))
        .lineLimit(1)
        .minimumScaleFactor(0.55)
        .contentTransition(.numericText())
        .animation(.default, value: elapsedTime)

      Text(focusMessage)
        .font(.subheadline)
        .fontWeight(.semibold)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .lineLimit(2)
        .contentTransition(.opacity)
        .animation(.easeInOut(duration: 0.35), value: focusMessage)
    }
    .padding(.horizontal, 12)
  }

  private var actionSection: some View {
    VStack(spacing: 12) {
      if !isPauseActive && isBreakAvailable {
        ActiveSessionActionButton(
          title: breakButtonTitle,
          iconName: "cup.and.heat.waves.fill",
          role: isBreakActive ? .warning : .standard,
          requiresLongPress: true,
          action: onBreakTapped
        )
      }

      HStack(spacing: 12) {
        if showStopButton {
          ActiveSessionActionButton(
            title: stopButtonTitle,
            iconName: "stop.fill",
            role: .standard,
            action: onStopTapped
          )
        }

        if profile.enableEmergencyUnblock {
          ActiveSessionActionButton(
            title: "Emergency",
            iconName: "exclamationmark.triangle.fill",
            role: .warning,
            action: {
              showEmergencyView = true
            }
          )
        }
      }
    }
  }

  private func rotateFocusMessage() {
    guard !FocusMessages.messages.isEmpty else { return }
    withAnimation(.easeInOut(duration: 0.35)) {
      focusMessageIndex = (focusMessageIndex + 1) % FocusMessages.messages.count
    }
  }

  private static func initialFocusMessageIndex() -> Int {
    guard !FocusMessages.messages.isEmpty else { return 0 }
    return Int.random(in: 0..<FocusMessages.messages.count)
  }
}

private enum ActiveSessionActionRole {
  case standard
  case warning
}

private struct ActiveSessionActionButton: View {
  let title: String
  let iconName: String
  let role: ActiveSessionActionRole
  var requiresLongPress = false
  let action: () -> Void

  @State private var isPressed = false

  private var foregroundColor: Color {
    role == .warning ? .orange : .primary
  }

  var body: some View {
    Group {
      if requiresLongPress {
        label
          .scaleEffect(isPressed ? 0.97 : 1)
          .animation(.spring(response: 0.24, dampingFraction: 0.74), value: isPressed)
          .onLongPressGesture(
            minimumDuration: 0.8,
            pressing: { pressing in
              isPressed = pressing
            },
            perform: triggerAction
          )
      } else {
        Button(action: triggerAction) {
          label
        }
        .buttonStyle(ActiveSessionPressStyle())
      }
    }
  }

  private var label: some View {
    HStack(spacing: 8) {
      Image(systemName: iconName)
        .font(.system(size: 15, weight: .bold))

      Text(title)
        .font(.headline)
        .fontWeight(.semibold)
        .lineLimit(1)
        .minimumScaleFactor(0.82)
    }
    .frame(maxWidth: .infinity)
    .frame(height: 56)
    .foregroundStyle(foregroundColor)
    .background(.thinMaterial, in: Capsule())
    .overlay(
      Capsule()
        .strokeBorder(foregroundColor.opacity(0.22), lineWidth: 1)
    )
    .contentShape(Capsule())
  }

  private func triggerAction() {
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
    action()
  }
}

private struct ActiveSessionPressStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.96 : 1)
      .animation(
        .spring(response: 0.24, dampingFraction: 0.74),
        value: configuration.isPressed
      )
  }
}

#Preview {
  ActiveProfileSessionView(
    profile: BlockedProfiles(name: "Work Focus"),
    elapsedTime: 3665,
    isBreakAvailable: true,
    isBreakActive: false,
    isPauseActive: false,
    onBreakTapped: {},
    onStopTapped: {}
  )
  .environmentObject(ThemeManager.shared)
}
