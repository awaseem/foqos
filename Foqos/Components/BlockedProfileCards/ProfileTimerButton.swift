import SwiftUI

struct ProfileTimerButton: View {
  @EnvironmentObject var themeManager: ThemeManager

  let isActive: Bool

  let isBreakAvailable: Bool
  let isBreakActive: Bool

  let elapsedTime: TimeInterval?

  let onStartTapped: () -> Void
  let onStopTapped: () -> Void

  let onBreakTapped: () -> Void

  var breakMessage: String {
    return "Hold to" + (isBreakActive ? " Stop Break" : " Start Break")
  }

  var breakColor: Color? {
    return isBreakActive ? .orange : nil
  }

  var body: some View {
    VStack(spacing: Spacing.xs) {
      HStack(spacing: Spacing.xs) {
        if isActive, let elapsedTimeVal = elapsedTime {
          // Timer
          HStack(spacing: Spacing.xs) {
            Text(timeString(from: elapsedTimeVal))
              .foregroundColor(.primary)
              .font(Typography.timer())
              .contentTransition(.numericText(countsDown: isBreakActive))
              .animation(.snappy, value: elapsedTimeVal)
          }
          .padding(.vertical, 10)
          .padding(.horizontal, Spacing.sm)
          .frame(minWidth: 0, maxWidth: .infinity)
          .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
              .fill(.thinMaterial)
              .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                  .stroke(
                    themeManager.themeColor.opacity(Opacity.border),
                    lineWidth: 1
                  )
              )
          )
          .accessibilityElement(children: .combine)
          .accessibilityLabel(isBreakActive ? "Break time remaining" : "Session time")
          .accessibilityValue(accessibleTimeString(from: elapsedTimeVal))
          .accessibilityAddTraits(.updatesFrequently)

          // Stop button
          GlassButton(
            title: "Stop",
            icon: "stop.fill",
            fullWidth: false,
            equalWidth: true
          ) {
            HapticFeedback.medium.trigger()
            onStopTapped()
          }
        } else {
          // Start button (full width when no timer is shown)
          GlassButton(
            title: "Hold to Start",
            icon: "play.fill",
            fullWidth: true,
            longPressEnabled: true
          ) {
            HapticFeedback.medium.trigger()
            onStartTapped()
          }
        }
      }

      if isBreakAvailable {
        GlassButton(
          title: breakMessage,
          icon: "cup.and.heat.waves.fill",
          fullWidth: true,
          longPressEnabled: true,
          color: breakColor
        ) {
          HapticFeedback.light.trigger()
          onBreakTapped()
        }
      }
    }
  }

  // Format TimeInterval to HH:MM:SS
  private func timeString(from timeInterval: TimeInterval) -> String {
    let hours = Int(timeInterval) / 3600
    let minutes = Int(timeInterval) / 60 % 60
    let seconds = Int(timeInterval) % 60
    return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
  }

  // Accessible time format for VoiceOver
  private func accessibleTimeString(from interval: TimeInterval) -> String {
    let hours = Int(interval) / 3600
    let minutes = Int(interval) / 60 % 60
    let seconds = Int(interval) % 60

    if hours > 0 {
      return "\(hours) hours, \(minutes) minutes, \(seconds) seconds"
    } else if minutes > 0 {
      return "\(minutes) minutes, \(seconds) seconds"
    } else {
      return "\(seconds) seconds"
    }
  }
}

#Preview {
  VStack(spacing: 20) {
    ProfileTimerButton(
      isActive: false,
      isBreakAvailable: false,
      isBreakActive: false,
      elapsedTime: nil,
      onStartTapped: {},
      onStopTapped: {},
      onBreakTapped: {}
    )

    ProfileTimerButton(
      isActive: true,
      isBreakAvailable: true,
      isBreakActive: false,
      elapsedTime: 3665,
      onStartTapped: {},
      onStopTapped: {},
      onBreakTapped: {}
    )
  }
  .padding()
  .background(Color(.systemGroupedBackground))
}
