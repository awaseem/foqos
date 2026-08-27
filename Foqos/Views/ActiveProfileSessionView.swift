import FamilyControls
import SwiftUI
import UIKit

struct ActiveProfileSessionView: View {
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var strategyManager: StrategyManager
  @EnvironmentObject private var themeManager: ThemeManager

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
  @State private var animationSettings = ActiveSessionAnimationSettings.defaultValue

  #if DEBUG
    @State private var showingAnimationTuning = false
  #endif

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

      timerPresentation

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

      #if DEBUG
        animationTuningControl
      #endif
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

  #if DEBUG
    private var animationTuningControl: some View {
      ZStack {
        if #available(iOS 26.0, *) {
          animationTuningButton
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
        } else {
          animationTuningButton
            .background(.ultraThinMaterial, in: Circle())
            .overlay {
              Circle()
                .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
            }
            .buttonStyle(ActiveSessionPressStyle())
        }
      }
      .popover(isPresented: $showingAnimationTuning) {
        ActiveSessionAnimationTuningView(
          settings: $animationSettings,
          tint: themeManager.themeColor
        )
        .presentationCompactAdaptation(.popover)
      }
    }

    private var animationTuningButton: some View {
      Button(action: { showingAnimationTuning = true }) {
        Image(systemName: "slider.horizontal.3")
          .font(.system(size: 16, weight: .semibold))
          .frame(width: 40, height: 40)
          .contentShape(Circle())
      }
      .foregroundStyle(.primary)
      .accessibilityLabel("Animation controls")
    }
  #endif

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

  private var timerPresentation: some View {
    ZStack {
      ActiveSessionPetalAnimation(
        color: themeManager.themeColor,
        settings: animationSettings,
        timerTick: Int(max(elapsedTime, 0).rounded(.down))
      )
      .frame(maxWidth: 360, maxHeight: 300)

      timer
        .padding(.horizontal, 16)
    }
    .frame(maxWidth: .infinity)
    .frame(height: 300)
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

private struct ActiveSessionAnimationSettings: Equatable {
  static let defaultValue = ActiveSessionAnimationSettings(
    petalCount: 8,
    visibility: 1.15,
    petalWidth: 0.9,
    petalLength: 1.08,
    bloomScale: 1,
    centerOpening: 44,
    breathingDuration: 18
  )

  var petalCount: Double
  var visibility: Double
  var petalWidth: Double
  var petalLength: Double
  var bloomScale: Double
  var centerOpening: Double
  var breathingDuration: Double
}

#if DEBUG
  private struct ActiveSessionAnimationTuningView: View {
    @Binding var settings: ActiveSessionAnimationSettings

    let tint: Color

    var body: some View {
      VStack(alignment: .leading, spacing: 16) {
        HStack {
          Text("Rose Petals")
            .font(.headline)

          Spacer()

          Button("Reset") {
            settings = .defaultValue
          }
          .font(.subheadline.weight(.semibold))
        }

        tuningSlider(
          title: "Petals",
          valueText: String(Int(settings.petalCount.rounded())),
          value: $settings.petalCount,
          range: 5...12,
          step: 1
        )

        tuningSlider(
          title: "Petal visibility",
          valueText: String(format: "%.2f×", settings.visibility),
          value: $settings.visibility,
          range: 0.25...2.5,
          step: 0.05
        )

        tuningSlider(
          title: "Petal width",
          valueText: String(format: "%.2f×", settings.petalWidth),
          value: $settings.petalWidth,
          range: 0.5...2,
          step: 0.05
        )

        tuningSlider(
          title: "Petal length",
          valueText: String(format: "%.2f×", settings.petalLength),
          value: $settings.petalLength,
          range: 0.8...1.25,
          step: 0.05
        )

        tuningSlider(
          title: "Bloom size",
          valueText: String(format: "%.2f×", settings.bloomScale),
          value: $settings.bloomScale,
          range: 0.75...1.15,
          step: 0.05
        )

        tuningSlider(
          title: "Center opening",
          valueText: String(format: "%.0f pt", settings.centerOpening),
          value: $settings.centerOpening,
          range: 0...80,
          step: 2
        )

        tuningSlider(
          title: "Breathing cycle",
          valueText: String(format: "%.0fs", settings.breathingDuration),
          value: $settings.breathingDuration,
          range: 10...30,
          step: 1
        )

        Text("Debug only · Values reset when this screen closes")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      .padding(20)
      .frame(width: 320)
      .tint(tint)
    }

    private func tuningSlider(
      title: String,
      valueText: String,
      value: Binding<Double>,
      range: ClosedRange<Double>,
      step: Double
    ) -> some View {
      VStack(alignment: .leading, spacing: 6) {
        HStack {
          Text(title)
            .font(.subheadline)

          Spacer()

          Text(valueText)
            .font(.system(.caption, design: .monospaced, weight: .semibold))
            .foregroundStyle(.secondary)
        }

        Slider(value: value, in: range, step: step)
      }
    }
  }
#endif

private struct ActiveSessionPetalAnimation: View {
  @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion

  let color: Color
  let settings: ActiveSessionAnimationSettings
  let timerTick: Int

  private var petalCount: Int {
    max(Int(settings.petalCount.rounded()), 1)
  }

  var body: some View {
    GeometryReader { geometry in
      let radiusX = max(geometry.size.width / 2 - 18, 0) * CGFloat(settings.bloomScale)
      let radiusY = max(geometry.size.height / 2 - 18, 0) * CGFloat(settings.bloomScale)

      ZStack {
        ForEach(0..<petalCount, id: \.self) { index in
          let petalAngle =
            Double(index) / Double(petalCount) * 2 * Double.pi - Double.pi / 2
          let breathing = breathingProgress(for: index, at: timerTick)
          let horizontalRadius = CGFloat(cos(petalAngle)) * radiusX
          let verticalRadius = CGFloat(sin(petalAngle)) * radiusY
          let baseLength = hypot(horizontalRadius, verticalRadius)
          let centerOpening = CGFloat(settings.centerOpening)
          let restingLength = max(baseLength - centerOpening, 1)
          let petalLength =
            restingLength * CGFloat(settings.petalLength) * (0.94 + 0.12 * breathing)
          let petalWidth = (52 + 8 * breathing) * CGFloat(settings.petalWidth)
          let petalCenterRadius = centerOpening + petalLength / 2

          ActiveSessionRosePetalShape()
            .fill(
              LinearGradient(
                stops: [
                  .init(color: color.opacity(0.88), location: 0),
                  .init(color: color.opacity(0.54), location: 0.5),
                  .init(color: color.opacity(0.1), location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
              )
            )
            .frame(
              width: petalWidth,
              height: petalLength
            )
            .rotationEffect(.radians(petalAngle + Double.pi / 2))
            .position(
              x: geometry.size.width / 2
                + CGFloat(cos(petalAngle)) * petalCenterRadius,
              y: geometry.size.height / 2
                + CGFloat(sin(petalAngle)) * petalCenterRadius
            )
            .opacity(
              min((0.48 + 0.18 * Double(breathing)) * settings.visibility, 0.82)
            )
            .blur(radius: 0.8)
            .zIndex(Double(breathing))
        }
      }
      .drawingGroup()
      .animation(accessibilityReduceMotion ? nil : .default, value: timerTick)
    }
    .allowsHitTesting(false)
    .accessibilityHidden(true)
  }

  private func breathingProgress(for index: Int, at timerTick: Int) -> CGFloat {
    guard !accessibilityReduceMotion else { return 0 }

    let cycleDuration = max(Int(settings.breathingDuration.rounded()), 1)
    let cycleTick = timerTick % cycleDuration
    let cycleProgress = Double(cycleTick) / Double(cycleDuration)
    let petalProgress = cycleProgress * Double(petalCount)
    let activePetal = min(Int(petalProgress), petalCount - 1)

    guard index == activePetal else { return 0 }

    let localProgress = petalProgress - Double(activePetal)
    return CGFloat((1 - cos(localProgress * 2 * Double.pi)) / 2)
  }
}

private struct ActiveSessionRosePetalShape: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
    path.addCurve(
      to: CGPoint(x: rect.minX + rect.width * 0.08, y: rect.minY + rect.height * 0.38),
      control1: CGPoint(x: rect.minX + rect.width * 0.25, y: rect.minY + rect.height * 0.86),
      control2: CGPoint(x: rect.minX + rect.width * 0.02, y: rect.minY + rect.height * 0.65)
    )
    path.addCurve(
      to: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.05),
      control1: CGPoint(x: rect.minX + rect.width * 0.05, y: rect.minY + rect.height * 0.16),
      control2: CGPoint(x: rect.minX + rect.width * 0.3, y: rect.minY + rect.height * 0.02)
    )
    path.addCurve(
      to: CGPoint(x: rect.maxX - rect.width * 0.08, y: rect.minY + rect.height * 0.38),
      control1: CGPoint(x: rect.maxX - rect.width * 0.3, y: rect.minY + rect.height * 0.02),
      control2: CGPoint(x: rect.maxX - rect.width * 0.05, y: rect.minY + rect.height * 0.16)
    )
    path.addCurve(
      to: CGPoint(x: rect.midX, y: rect.maxY),
      control1: CGPoint(x: rect.maxX - rect.width * 0.02, y: rect.minY + rect.height * 0.65),
      control2: CGPoint(x: rect.maxX - rect.width * 0.25, y: rect.minY + rect.height * 0.86)
    )
    path.closeSubpath()
    return path
  }
}

private enum SoftUnblockActiveGrantResource {
  case stored(SoftUnblockResource)
  case preview(title: String, systemImageName: String)
}

private struct SoftUnblockActiveGrantDisplay: Identifiable {
  let id: UUID
  let resource: SoftUnblockActiveGrantResource
  let createdAt: Date
  let expiresAt: Date

  init(grant: SoftUnblockGrant) {
    id = grant.id
    resource = .stored(grant.resource)
    createdAt = grant.createdAt
    expiresAt = grant.expiresAt
  }

  init(
    id: UUID,
    title: String,
    systemImageName: String,
    createdAt: Date,
    expiresAt: Date
  ) {
    self.id = id
    resource = .preview(title: title, systemImageName: systemImageName)
    self.createdAt = createdAt
    self.expiresAt = expiresAt
  }
}

private enum SoftUnblockActiveGrantsSource {
  case live
  case preview([SoftUnblockActiveGrantDisplay])

  func activeGrants(for profileId: UUID, at date: Date) -> [SoftUnblockActiveGrantDisplay] {
    switch self {
    case .live:
      return SoftUnblockGrantStore.activeGrants(for: profileId, at: date).map {
        SoftUnblockActiveGrantDisplay(grant: $0)
      }
    case .preview(let grants):
      return grants.filter { $0.expiresAt > date }
    }
  }
}

private struct SoftUnblockActiveGrantsSourceKey: EnvironmentKey {
  static let defaultValue = SoftUnblockActiveGrantsSource.live
}

extension EnvironmentValues {
  fileprivate var softUnblockActiveGrantsSource: SoftUnblockActiveGrantsSource {
    get { self[SoftUnblockActiveGrantsSourceKey.self] }
    set { self[SoftUnblockActiveGrantsSourceKey.self] = newValue }
  }
}

private struct SoftUnblockActiveGrantsCard: View {
  private static let visibleGrantLimit = 3

  @Environment(\.softUnblockActiveGrantsSource) private var activeGrantsSource

  let profileId: UUID

  var body: some View {
    TimelineView(.periodic(from: .now, by: 1)) { timeline in
      let activeGrants = activeGrantsSource.activeGrants(for: profileId, at: timeline.date)
        .sorted { lhs, rhs in
          if lhs.expiresAt == rhs.expiresAt {
            return lhs.createdAt < rhs.createdAt
          }
          return lhs.expiresAt < rhs.expiresAt
        }
      let visibleGrants = Array(activeGrants.prefix(Self.visibleGrantLimit))
      let overflowCount = activeGrants.count - visibleGrants.count

      if !activeGrants.isEmpty {
        VStack(spacing: 4) {
          ForEach(visibleGrants) { grant in
            SoftUnblockActiveGrantRow(
              grant: grant,
              date: timeline.date
            )
          }

          if overflowCount > 0 {
            Text("+\(overflowCount) more active")
              .font(.caption)
              .fontWeight(.medium)
              .foregroundStyle(.secondary)
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(.top, 4)
          }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
          Color.primary.opacity(0.045),
          in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.easeInOut(duration: 0.25), value: activeGrants.map(\.id))
      }
    }
  }
}

private struct SoftUnblockActiveGrantRow: View {
  let grant: SoftUnblockActiveGrantDisplay
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
    HStack(spacing: 10) {
      resourceLabel
        .font(.subheadline)
        .fontWeight(.medium)
        .lineLimit(1)
        .minimumScaleFactor(0.8)

      Spacer(minLength: 8)

      Text(countdownText)
        .font(.system(.footnote, design: .monospaced, weight: .semibold))
        .foregroundStyle(.secondary)
        .contentTransition(.numericText(countsDown: true))
        .accessibilityLabel(accessibilityCountdownText)
    }
    .padding(.vertical, 6)
  }

  @ViewBuilder
  private var resourceLabel: some View {
    switch grant.resource {
    case .stored(.application(let token)):
      Label(token)
    case .stored(.category(let token)):
      Label(token)
    case .preview(let title, let systemImageName):
      Label(title, systemImage: systemImageName)
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
          .scaleEffect(isPressed ? 0.95 : 1)
          .animation(.spring(response: 0.22, dampingFraction: 0.72), value: isPressed)
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
    HStack(spacing: 10) {
      icon

      Text(title)
        .font(.headline)
        .fontWeight(.semibold)
        .lineLimit(1)
        .minimumScaleFactor(0.76)
    }
    .frame(maxWidth: .infinity)
    .frame(height: 58)
    .foregroundStyle(foregroundColor)
    .background(
      foregroundColor.opacity(backgroundOpacity),
      in: Capsule()
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
        .font(.system(size: 17, weight: .bold))
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
      .scaleEffect(configuration.isPressed ? 0.95 : 1)
      .animation(
        .spring(response: 0.22, dampingFraction: 0.72),
        value: configuration.isPressed
      )
  }
}

#Preview("Standard Session") {
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
  .environmentObject(ThemeManager())
}

#Preview("Temporary Access · One App") {
  let previewDate = Date()
  let profile = BlockedProfiles(
    id: UUID(uuidString: "8C58F66A-1F6E-45D7-97CC-95756AB663C2")!,
    name: "Deep Work",
    blockingStrategyId: NFCSoftUnblockBlockingStrategy.id,
    enableBreaks: false
  )

  ActiveProfileSessionView(
    profile: profile,
    elapsedTime: 733,
    displayTime: 733,
    isBreakAvailable: false,
    isBreakActive: false,
    isPauseActive: false,
    isCountdownExpired: false,
    onBreakTapped: {},
    onStopTapped: {},
    onExpiredCountdownReset: {}
  )
  .environment(
    \.softUnblockActiveGrantsSource,
    .preview([
      SoftUnblockActiveGrantDisplay(
        id: UUID(uuidString: "B0C1B326-E87C-4692-BE1E-04AEEDC04880")!,
        title: "Instagram",
        systemImageName: "camera.fill",
        createdAt: previewDate.addingTimeInterval(-38),
        expiresAt: previewDate.addingTimeInterval(262)
      )
    ])
  )
  .environmentObject(StrategyManager())
  .environmentObject(ThemeManager())
}

#Preview("Temporary Access · Multiple") {
  let previewDate = Date()
  let profile = BlockedProfiles(
    id: UUID(uuidString: "31C8D175-A37C-4C82-919E-6BB06E9C9B6B")!,
    name: "Study Session",
    blockingStrategyId: QRSoftUnblockBlockingStrategy.id,
    enableBreaks: false
  )

  ActiveProfileSessionView(
    profile: profile,
    elapsedTime: 1_254,
    displayTime: 1_254,
    isBreakAvailable: false,
    isBreakActive: false,
    isPauseActive: false,
    isCountdownExpired: false,
    onBreakTapped: {},
    onStopTapped: {},
    onExpiredCountdownReset: {}
  )
  .environment(
    \.softUnblockActiveGrantsSource,
    .preview([
      SoftUnblockActiveGrantDisplay(
        id: UUID(uuidString: "B00A56CF-F936-4B5C-875C-77943D503961")!,
        title: "Instagram",
        systemImageName: "camera.fill",
        createdAt: previewDate.addingTimeInterval(-61),
        expiresAt: previewDate.addingTimeInterval(119)
      ),
      SoftUnblockActiveGrantDisplay(
        id: UUID(uuidString: "7921AAAF-DCC0-41CC-82BC-8E5291C53B65")!,
        title: "Social",
        systemImageName: "person.2.fill",
        createdAt: previewDate.addingTimeInterval(-28),
        expiresAt: previewDate.addingTimeInterval(212)
      ),
      SoftUnblockActiveGrantDisplay(
        id: UUID(uuidString: "A792D79C-E42C-498F-9DEE-CA417F13D398")!,
        title: "YouTube",
        systemImageName: "play.rectangle.fill",
        createdAt: previewDate.addingTimeInterval(-23),
        expiresAt: previewDate.addingTimeInterval(397)
      ),
      SoftUnblockActiveGrantDisplay(
        id: UUID(uuidString: "41764C6B-1592-4A15-BB7E-8F5CB827B4BC")!,
        title: "Entertainment",
        systemImageName: "film.fill",
        createdAt: previewDate.addingTimeInterval(-10),
        expiresAt: previewDate.addingTimeInterval(530)
      ),
    ])
  )
  .environmentObject(StrategyManager())
  .environmentObject(ThemeManager())
  .preferredColorScheme(.dark)
}
