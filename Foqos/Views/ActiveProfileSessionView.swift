import FamilyControls
import SwiftUI
import UIKit

struct ActiveProfileSessionView: View {
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var strategyManager: StrategyManager

  let profile: BlockedProfiles
  let elapsedTime: TimeInterval
  let displayTime: TimeInterval
  let isBreakAvailable: Bool
  let isBreakActive: Bool
  let isPauseActive: Bool
  let isCountdownExpired: Bool
  let onBreakTapped: () -> Void
  let onStopTapped: () -> Void
  let onExpiredCountdownReset: () -> Void

  @State private var showEmergencyView = false
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

  private var isSoftUnblockStrategy: Bool {
    guard let strategyId = profile.blockingStrategyId else { return false }
    return [
      NFCSoftUnblockBlockingStrategy.id,
      QRSoftUnblockBlockingStrategy.id,
    ].contains(strategyId)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      topControls

      Spacer(minLength: 24)

      timer
        .frame(maxWidth: .infinity)

      Spacer(minLength: 24)

      VStack(alignment: .leading, spacing: 18) {
        profileDetails
        actionSection
      }
    }
    .padding(.horizontal, 20)
    .padding(.top, 8)
    .padding(.bottom, 16)
    .sheet(isPresented: $showEmergencyView) {
      EmergencyView()
        .presentationDetents([.height(350), .large])
    }
    .sheet(isPresented: $strategyManager.showCustomStrategyView) {
      BlockingStrategyActionView(
        customView: strategyManager.customStrategyView,
        presentationDetents: strategyManager.customStrategyViewPresentationDetents
      )
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

  private var topControls: some View {
    HStack {
      if #available(iOS 26.0, *) {
        closeButton
          .buttonStyle(.glass)
          .buttonBorderShape(.circle)
      } else {
        closeButton
          .background(.ultraThinMaterial, in: Circle())
          .overlay {
            Circle()
              .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
          }
          .buttonStyle(ActiveSessionPressStyle())
      }

      Spacer()
    }
  }

  private var closeButton: some View {
    Button(action: { dismiss() }) {
      Image(systemName: "xmark")
        .font(.system(size: 18, weight: .semibold))
        .frame(width: 40, height: 40)
        .contentShape(Circle())
    }
    .foregroundStyle(.primary)
    .accessibilityLabel("Close")
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

  private var timer: some View {
    Text(DateFormatters.formatDurationClock(displayTime))
      .font(.system(size: 64, weight: .bold, design: .monospaced))
      .lineLimit(1)
      .minimumScaleFactor(0.5)
      .contentTransition(.numericText())
      .animation(.default, value: displayTime)
      .accessibilityLabel("Session time")
      .accessibilityValue(DateFormatters.formatDurationClock(displayTime))
  }

  private var profileDetails: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(profile.name)
        .font(.title3)
        .fontWeight(.bold)
        .lineLimit(2)

      HStack(spacing: 12) {
        HStack(spacing: 6) {
          BlockingStrategyIconImage(strategy: blockingStrategy)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.secondary)
            .frame(width: 20, height: 20)
            .accessibilityHidden(true)

          Text(strategyName)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
        }

        if let statusMessage, let statusIconName {
          HStack(spacing: 5) {
            Image(statusIconName)
              .resizable()
              .scaledToFit()
              .frame(width: 16, height: 16)

            Text(statusMessage)
              .font(.subheadline)
              .fontWeight(.semibold)
              .foregroundStyle(.secondary)
          }
        }
      }

      Text(focusMessage)
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.leading)
        .lineLimit(2)
        .contentTransition(.opacity)
        .animation(.easeInOut(duration: 0.35), value: focusMessage)

      if isSoftUnblockStrategy {
        SoftUnblockActiveGrantsCard(profileId: profile.id)
          .padding(.top, 4)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var actionSection: some View {
    VStack(spacing: 12) {
      if isCountdownExpired {
        VStack(spacing: 8) {
          Text("This timer finished, but the session is still active.")
            .font(.footnote)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)

          ActiveSessionActionButton(
            title: "Reset Session",
            iconName: "arrow.counterclockwise",
            role: .destructive,
            action: onExpiredCountdownReset
          )
        }
      } else {
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

private struct SoftUnblockActiveGrantsCard: View {
  private static let visibleGrantLimit = 3

  let profileId: UUID

  var body: some View {
    TimelineView(.periodic(from: .now, by: 1)) { timeline in
      let activeGrants = SoftUnblockGrantStore.activeGrants(
        for: profileId,
        at: timeline.date
      )
      .sorted { lhs, rhs in
        if lhs.expiresAt == rhs.expiresAt {
          return lhs.createdAt < rhs.createdAt
        }
        return lhs.expiresAt < rhs.expiresAt
      }
      let visibleGrants = Array(activeGrants.prefix(Self.visibleGrantLimit))
      let overflowCount = activeGrants.count - visibleGrants.count

      if !activeGrants.isEmpty {
        VStack(spacing: 0) {
          ForEach(Array(visibleGrants.enumerated()), id: \.element.id) { index, grant in
            if index > 0 {
              Divider()
                .opacity(0.45)
            }

            SoftUnblockActiveGrantRow(
              grant: grant,
              date: timeline.date
            )
          }

          if overflowCount > 0 {
            Divider()
              .opacity(0.45)

            Text("+\(overflowCount) more active")
              .font(.footnote)
              .fontWeight(.semibold)
              .foregroundStyle(.secondary)
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(.vertical, 10)
          }
        }
        .padding(16)
        .background(
          .thinMaterial,
          in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .overlay {
          RoundedRectangle(cornerRadius: 20, style: .continuous)
            .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.easeInOut(duration: 0.25), value: activeGrants.map(\.id))
      }
    }
  }
}

private struct SoftUnblockActiveGrantRow: View {
  let grant: SoftUnblockGrant
  let date: Date

  private var remainingSeconds: Int {
    max(Int(ceil(grant.expiresAt.timeIntervalSince(date))), 0)
  }

  private var countdownText: String {
    String(
      format: "%02d:%02d",
      remainingSeconds / 60,
      remainingSeconds % 60
    )
  }

  private var accessibilityCountdownText: String {
    let minutes = remainingSeconds / 60
    let seconds = remainingSeconds % 60
    let minuteLabel = minutes == 1 ? "minute" : "minutes"
    let secondLabel = seconds == 1 ? "second" : "seconds"
    return "\(minutes) \(minuteLabel), \(seconds) \(secondLabel) remaining"
  }

  var body: some View {
    HStack(spacing: 12) {
      resourceLabel
        .font(.subheadline)
        .fontWeight(.semibold)
        .lineLimit(1)
        .minimumScaleFactor(0.8)

      Spacer(minLength: 8)

      Text(countdownText)
        .font(.system(.subheadline, design: .monospaced, weight: .bold))
        .contentTransition(.numericText(countsDown: true))
        .accessibilityLabel(accessibilityCountdownText)
    }
    .padding(.vertical, 10)
  }

  @ViewBuilder
  private var resourceLabel: some View {
    switch grant.resource {
    case .application(let token):
      Label(token)
    case .category(let token):
      Label(token)
    }
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

  private var backgroundOpacity: Double {
    switch role {
    case .standard:
      return 0.08
    case .warning, .destructive:
      return 0.12
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
        .font(.subheadline)
        .fontWeight(.semibold)
        .lineLimit(1)
        .minimumScaleFactor(0.82)
    }
    .frame(maxWidth: .infinity)
    .frame(height: 48)
    .foregroundStyle(foregroundColor)
    .background(
      foregroundColor.opacity(backgroundOpacity),
      in: RoundedRectangle(cornerRadius: 14, style: .continuous)
    )
    .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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
    displayTime: 3665,
    isBreakAvailable: true,
    isBreakActive: false,
    isPauseActive: false,
    isCountdownExpired: false,
    onBreakTapped: {},
    onStopTapped: {},
    onExpiredCountdownReset: {}
  )
  .environmentObject(StrategyManager())
}
