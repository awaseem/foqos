//
//  PomodoroTimerView.swift
//  foqos
//
//  Pomodoro timer component with visual feedback
//

import SwiftUI

struct PomodoroTimerView: View {
  // Use @Bindable for SwiftData @Model classes (iOS 17+)
  @Bindable var session: PomodoroSession
  @Binding var remainingSeconds: TimeInterval
  @State private var isRunning: Bool = false

  @EnvironmentObject var themeManager: ThemeManager
  @Environment(\.accessibilityReduceMotion) var reduceMotion

  // Timer for countdown
  private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

  // Progress calculation
  private var progress: Double {
    guard session.currentPhaseDurationSeconds > 0 else { return 0 }
    return 1 - (remainingSeconds / session.currentPhaseDurationSeconds)
  }

  // Formatted time display
  private var timeDisplay: String {
    let minutes = Int(remainingSeconds) / 60
    let seconds = Int(remainingSeconds) % 60
    return String(format: "%02d:%02d", minutes, seconds)
  }

  // Accessibility time description
  private var accessibleTimeDisplay: String {
    let minutes = Int(remainingSeconds) / 60
    let seconds = Int(remainingSeconds) % 60
    if minutes > 0 {
      return "\(minutes) minutes and \(seconds) seconds remaining"
    } else {
      return "\(seconds) seconds remaining"
    }
  }

  // Phase color
  private var phaseColor: Color {
    Color(hex: session.currentPhase.color)
  }

  var body: some View {
    VStack(spacing: Spacing.lg) {
      // Phase indicator
      HStack(spacing: Spacing.xs) {
        Image(systemName: session.currentPhase.icon)
          .font(.title3)
        Text(session.currentPhase.displayName)
          .font(.headline)
      }
      .foregroundColor(phaseColor)
      .accessibilityElement(children: .combine)
      .accessibilityLabel("Current phase: \(session.currentPhase.displayName)")

      // Circular progress timer
      ZStack {
        // Background circle
        Circle()
          .stroke(
            Color.secondary.opacity(Opacity.tertiary),
            lineWidth: 12
          )

        // Progress circle
        Circle()
          .trim(from: 0, to: progress)
          .stroke(
            phaseColor,
            style: StrokeStyle(
              lineWidth: 12,
              lineCap: .round
            )
          )
          .rotationEffect(.degrees(-90))
          .animation(reduceMotion ? nil : .standard, value: progress)

        // Time display
        VStack(spacing: Spacing.xs) {
          Text(timeDisplay)
            .font(.system(size: 56, weight: .bold, design: .monospaced))
            .foregroundColor(.primary)

          Text("Pomodoro \(session.completedPomodoros + 1)")
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
      }
      .frame(width: 240, height: 240)
      .accessibilityElement(children: .ignore)
      .accessibilityLabel(accessibleTimeDisplay)
      .accessibilityAddTraits(.updatesFrequently)

      // Completed pomodoros indicator
      HStack(spacing: Spacing.xs) {
        ForEach(0..<session.sessionsUntilLongBreak, id: \.self) { index in
          Circle()
            .fill(index < session.completedPomodoros % session.sessionsUntilLongBreak
                  ? phaseColor
                  : Color.secondary.opacity(0.3))
            .frame(width: 12, height: 12)
            .animation(reduceMotion ? nil : .snappy, value: session.completedPomodoros)
        }
      }
      .accessibilityElement(children: .ignore)
      .accessibilityLabel("\(session.completedPomodoros % session.sessionsUntilLongBreak) of \(session.sessionsUntilLongBreak) pomodoros until long break")

      // Control buttons
      HStack(spacing: Spacing.lg) {
        // Reset button
        Button {
          HapticFeedback.medium.trigger()
          resetTimer()
        } label: {
          Image(systemName: "arrow.counterclockwise")
            .font(.title2)
            .foregroundColor(.secondary)
            .frame(width: TouchTarget.comfortable, height: TouchTarget.comfortable)
            .background(
              Circle()
                .fill(Color.secondary.opacity(0.1))
            )
        }
        .accessibilityLabel("Reset timer")
        .accessibilityHint("Resets the current phase timer to its starting value")

        // Play/Pause button
        Button {
          HapticFeedback.medium.trigger()
          isRunning.toggle()
          if isRunning && !session.isActive {
            session.startSession()
          }
        } label: {
          Image(systemName: isRunning ? "pause.fill" : "play.fill")
            .font(.title)
            .foregroundColor(.white)
            .frame(width: TouchTarget.large, height: TouchTarget.large)
            .background(
              Circle()
                .fill(phaseColor)
            )
        }
        .accessibilityLabel(isRunning ? "Pause" : "Start")
        .accessibilityHint(isRunning ? "Pauses the timer" : "Starts the countdown timer")

        // Skip button
        Button {
          HapticFeedback.light.trigger()
          skipPhase()
        } label: {
          Image(systemName: "forward.fill")
            .font(.title2)
            .foregroundColor(.secondary)
            .frame(width: TouchTarget.comfortable, height: TouchTarget.comfortable)
            .background(
              Circle()
                .fill(Color.secondary.opacity(0.1))
            )
        }
        .accessibilityLabel("Skip to next phase")
        .accessibilityHint("Skips to \(session.isBreakPhase ? "focus" : "break") phase")
      }

      // Session stats
      if session.completedPomodoros > 0 {
        HStack(spacing: Spacing.lg) {
          VStack(spacing: Spacing.xxs) {
            Text("\(session.completedPomodoros)")
              .font(.title2)
              .fontWeight(.bold)
            Text("Pomodoros")
              .font(.caption)
              .foregroundColor(.secondary)
          }

          Divider()
            .frame(height: 30)

          VStack(spacing: Spacing.xxs) {
            Text(formatTotalTime(session.totalFocusTimeSeconds))
              .font(.title2)
              .fontWeight(.bold)
            Text("Focus Time")
              .font(.caption)
              .foregroundColor(.secondary)
          }
        }
        .padding(.top, Spacing.sm)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Completed \(session.completedPomodoros) pomodoros. Total focus time: \(formatTotalTime(session.totalFocusTimeSeconds))")
      }
    }
    .padding(Spacing.lg)
    .onReceive(timer) { _ in
      guard isRunning else { return }
      if remainingSeconds > 0 {
        remainingSeconds -= 1
      } else {
        phaseCompleted()
      }
    }
  }

  // MARK: - Helper Methods

  private func resetTimer() {
    remainingSeconds = session.currentPhaseDurationSeconds
    isRunning = false
  }

  private func skipPhase() {
    session.completePhase()
    remainingSeconds = session.currentPhaseDurationSeconds
  }

  private func phaseCompleted() {
    HapticFeedback.success.trigger()
    session.completePhase()
    remainingSeconds = session.currentPhaseDurationSeconds
    // Auto-pause at phase end for user to acknowledge
    isRunning = false
  }

  private func formatTotalTime(_ seconds: TimeInterval) -> String {
    let hours = Int(seconds) / 3600
    let minutes = (Int(seconds) % 3600) / 60

    if hours > 0 {
      return "\(hours)h \(minutes)m"
    } else {
      return "\(minutes)m"
    }
  }
}

#Preview {
  struct PreviewWrapper: View {
    @State private var session = PomodoroSession()
    @State private var remaining: TimeInterval = 25 * 60

    var body: some View {
      PomodoroTimerView(session: session, remainingSeconds: $remaining)
        .environmentObject(ThemeManager.shared)
    }
  }

  return PreviewWrapper()
}
