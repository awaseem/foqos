import SwiftUI
import UIKit

struct ActiveProfileSessionView: View {
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var strategyManager: StrategyManager
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
  @State private var showingAlert = false
  @State private var alertMessage = ""
  @State private var focusMessageIndex = Self.initialFocusMessageIndex()

  private let focusMessageTimer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()

  private var showStopButton: Bool {
    profile.showStopButton(elapsedTime: elapsedTime)
  }

  private var stopButtonAction: BlockingStrategySessionAction {
    blockingStrategy?.activeSessionAction(isPauseActive: isPauseActive) ?? .stop()
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

  private var strategyName: String {
    guard let strategyId = profile.blockingStrategyId else {
      return "No Strategy"
    }
    return StrategyManager.getStrategyFromId(id: strategyId).name
  }

  private var blockingStrategy: BlockingStrategy? {
    guard let strategyId = profile.blockingStrategyId else {
      return nil
    }
    return StrategyManager.getStrategyFromId(id: strategyId)
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
        .presentationDetents([.height(350), .large])
    }
    .sheet(isPresented: $showProfileInsights) {
      ProfileInsightsView(profile: profile)
    }
    .sheet(isPresented: $strategyManager.showCustomStrategyView) {
      BlockingStrategyActionView(
        customView: strategyManager.customStrategyView
      )
      .presentationDetents([.medium, .large])
    }
    .onReceive(focusMessageTimer) { _ in
      rotateFocusMessage()
    }
    .onReceive(strategyManager.$errorMessage) { errorMessage in
      guard let message = errorMessage else { return }
      alertMessage = message
      showingAlert = true
    }
    .alert("Whoops", isPresented: $showingAlert) {
      Button("OK", role: .cancel) {
        dismissAlert()
      }
    } message: {
      Text(alertMessage)
    }
  }

  private var background: some View {
    ZStack {
      ActiveSessionGradientBackground(baseColor: themeManager.themeColor)

      LinearGradient(
        colors: [
          Color(.systemBackground).opacity(0.02),
          Color(.systemBackground).opacity(0.34),
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

        if let statusMessage, let statusIconName {
          HStack(spacing: 6) {
            Image(statusIconName)
              .resizable()
              .scaledToFit()
              .frame(width: 18, height: 18)

            Text(statusMessage)
              .font(.subheadline)
              .fontWeight(.semibold)
              .foregroundStyle(.secondary)
          }
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

  private var statusIconName: String? {
    if isPauseActive {
      return "PauseStickerIcon"
    }
    if isBreakActive {
      return "CoffeeStickerIcon"
    }
    return nil
  }

  private var timerSection: some View {
    VStack(spacing: 14) {
      HStack(spacing: 8) {
        BlockingStrategyIconImage(strategy: blockingStrategy)
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(.primary)
          .frame(width: 34, height: 34)
          .accessibilityHidden(true)

        Text(strategyName)
          .font(.subheadline)
          .fontWeight(.semibold)
          .foregroundStyle(.secondary)
      }

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
          imageName: "CoffeeStickerIcon",
          role: isBreakActive ? .warning : .standard,
          requiresLongPress: true,
          action: onBreakTapped
        )
      }

      HStack(spacing: 12) {
        if profile.enableEmergencyUnblock {
          ActiveSessionActionButton(
            title: "Emergency",
            iconName: "exclamationmark.triangle.fill",
            role: .destructive,
            action: {
              showEmergencyView = true
            }
          )
        }

        if showStopButton {
          ActiveSessionActionButton(
            title: stopButtonAction.title,
            iconName: stopButtonAction.systemImageName,
            imageName: stopButtonAction.assetImageName,
            role: .standard,
            action: onStopTapped
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

  private func dismissAlert() {
    showingAlert = false
    strategyManager.errorMessage = nil
  }

  private static func initialFocusMessageIndex() -> Int {
    guard !FocusMessages.messages.isEmpty else { return 0 }
    return Int.random(in: 0..<FocusMessages.messages.count)
  }
}

private struct ActiveSessionGradientBackground: View {
  let baseColor: Color

  var body: some View {
    TimelineView(.animation) { timeline in
      let t = timeline.date.timeIntervalSinceReferenceDate

      ZStack {
        LinearGradient(
          colors: [
            shiftedColor(hue: -0.08, saturation: 1.22, brightness: 0.95),
            shiftedColor(hue: 0.02, saturation: 1.1, brightness: 0.82),
            shiftedColor(hue: 0.10, saturation: 1.18, brightness: 0.64),
          ],
          startPoint: UnitPoint(
            x: 0.18 + 0.18 * normalizedSin(t * 0.08),
            y: 0.02
          ),
          endPoint: UnitPoint(
            x: 0.88,
            y: 0.92 - 0.16 * normalizedCos(t * 0.07)
          )
        )

        animatedBlob(
          t: t,
          hue: 0.09,
          saturation: 1.35,
          brightness: 1.1,
          opacity: 0.48,
          width: 0.86,
          height: 0.42,
          x: 0.18 + 0.18 * normalizedCos(t * 0.12),
          y: 0.62 + 0.08 * normalizedSin(t * 0.10),
          blur: 34
        )

        animatedBlob(
          t: t,
          hue: -0.12,
          saturation: 1.18,
          brightness: 0.92,
          opacity: 0.42,
          width: 0.72,
          height: 0.50,
          x: 0.84 - 0.20 * normalizedSin(t * 0.09),
          y: 0.72 + 0.10 * normalizedCos(t * 0.11),
          blur: 42
        )

        animatedBlob(
          t: t,
          hue: 0.16,
          saturation: 1.28,
          brightness: 0.78,
          opacity: 0.38,
          width: 0.98,
          height: 0.46,
          x: 0.52 + 0.16 * normalizedSin(t * 0.07),
          y: 0.92 - 0.10 * normalizedCos(t * 0.13),
          blur: 46
        )

        Rectangle()
          .fill(Color.black.opacity(0.10))
      }
      .ignoresSafeArea()
    }
  }

  private func animatedBlob(
    t: TimeInterval,
    hue: Double,
    saturation: Double,
    brightness: Double,
    opacity: Double,
    width: CGFloat,
    height: CGFloat,
    x: CGFloat,
    y: CGFloat,
    blur: CGFloat
  ) -> some View {
    GeometryReader { geometry in
      Ellipse()
        .fill(
          RadialGradient(
            colors: [
              shiftedColor(hue: hue, saturation: saturation, brightness: brightness).opacity(
                opacity),
              .clear,
            ],
            center: .center,
            startRadius: 0,
            endRadius: min(geometry.size.width, geometry.size.height) * 0.42
          )
        )
        .frame(
          width: geometry.size.width * width,
          height: geometry.size.height * height
        )
        .position(
          x: geometry.size.width * x,
          y: geometry.size.height * y
        )
        .blur(radius: blur)
        .scaleEffect(0.94 + 0.10 * normalizedSin(t * 0.18 + Double(width)))
        .blendMode(.plusLighter)
    }
  }

  private func shiftedColor(hue: Double, saturation: Double, brightness: Double) -> Color {
    let ui = UIColor(baseColor)
    var h: CGFloat = 0
    var s: CGFloat = 0
    var b: CGFloat = 0
    var a: CGFloat = 0

    if ui.getHue(&h, saturation: &s, brightness: &b, alpha: &a) {
      let shiftedHue = (h + CGFloat(hue)).truncatingRemainder(dividingBy: 1)
      return Color(
        UIColor(
          hue: shiftedHue < 0 ? shiftedHue + 1 : shiftedHue,
          saturation: min(1, max(0, s * CGFloat(saturation))),
          brightness: min(1, max(0, b * CGFloat(brightness))),
          alpha: a
        )
      )
    }

    return baseColor
  }

  private func normalizedSin(_ value: Double) -> CGFloat {
    CGFloat((sin(value) + 1) / 2)
  }

  private func normalizedCos(_ value: Double) -> CGFloat {
    CGFloat((cos(value) + 1) / 2)
  }
}

private enum ActiveSessionActionRole {
  case standard
  case warning
  case destructive
}

private struct ActiveSessionActionButton: View {
  let title: String
  let iconName: String
  var imageName: String? = nil
  let role: ActiveSessionActionRole
  var requiresLongPress = false
  let action: () -> Void

  @State private var isPressed = false

  private var foregroundColor: Color {
    switch role {
    case .standard:
      return .primary
    case .warning:
      return .orange
    case .destructive:
      return .red
    }
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
      icon

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

  @ViewBuilder
  private var icon: some View {
    if let imageName {
      Image(imageName)
        .resizable()
        .scaledToFit()
        .frame(width: 24, height: 24)
    } else {
      Image(systemName: iconName)
        .font(.system(size: 15, weight: .bold))
    }
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
  .environmentObject(StrategyManager())
  .environmentObject(ThemeManager.shared)
}
