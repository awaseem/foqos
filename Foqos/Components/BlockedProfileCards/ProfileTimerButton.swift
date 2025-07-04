import SwiftUI

struct ProfileTimerButton: View {
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
    VStack(spacing: 8) {
      HStack(spacing: 8) {
        if isActive, let elapsedTimeVal = elapsedTime {
          // Timer with clock icon
          HStack(spacing: 8) {
            Image(systemName: "clock.fill")
              .font(.system(size: 14))
              .foregroundColor(.primary.opacity(0.7))

            Text(timeString(from: elapsedTimeVal))
              .foregroundColor(.primary)
              .font(.system(size: 16, weight: .semibold))
              .contentTransition(.numericText())
              .animation(.default, value: elapsedTimeVal)
          }
          .padding(.vertical, 10)
          .padding(.horizontal, 12)
          .frame(minWidth: 0, maxWidth: .infinity)
          .background(
            RoundedRectangle(cornerRadius: 16)
              .fill(.thinMaterial)
              .overlay(
                RoundedRectangle(cornerRadius: 16)
                  .stroke(
                    Color.primary.opacity(0.2),
                    lineWidth: 1
                  )
              )
          )

          // Stop button
          GlassButton(
            title: "Stop",
            icon: "stop.fill",
            fullWidth: false,
            equalWidth: true
          ) {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
