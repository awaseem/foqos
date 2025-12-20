import SwiftUI

struct TimerDurationView: View {
  @EnvironmentObject var themeManager: ThemeManager
  @Environment(\.dismiss) private var dismiss

  let profileName: String
  let onDurationSelected: (StrategyTimerData) -> Void

  // State for slider-based duration selection
  @State private var durationMinutes: Double = 60  // Default 1 hour
  @State private var isSliding = false

  // Constants
  private let minMinutes: Double = 15
  private let maxMinutes: Double = 1439  // 23h 59m
  private let smallIncrement: Double = 5
  private let largeIncrement: Double = 15

  // Common snap points (in minutes)
  private let snapPoints: [Double] = [15, 30, 45, 60, 90, 120, 180, 240, 360, 480, 720, 1440]
  private let snapThreshold: Double = 10  // How close to snap (in minutes)

  var body: some View {
    VStack(spacing: 32) {
      // Header
      VStack(alignment: .leading, spacing: 12) {
        Text("Timer Settings")
          .font(.title2).bold()

        Text(
          "Select how long you want \(profileName) to last."
        )
        .font(.callout)
        .foregroundColor(.secondary)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.top, 16)

      // Large time display
      timeDisplay

      // Slider with +/- buttons
      sliderControls

      Spacer()

      // Confirm button
      ActionButton(
        title: "Set Duration",
        backgroundColor: themeManager.themeColor,
        iconName: "checkmark.circle.fill"
      ) {
        handleConfirm()
      }
    }
    .padding(24)
  }

  private var timeDisplay: some View {
    VStack(spacing: 8) {
      Text(formattedDuration)
        .font(.system(size: 56, weight: .bold, design: .rounded))
        .contentTransition(.numericText())
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: durationMinutes)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 16)
  }

  private var sliderControls: some View {
    VStack(spacing: 16) {
      // +/- buttons with slider
      HStack(spacing: 16) {
        // Decrement button
        Button {
          decrementDuration()
        } label: {
          Image(systemName: "minus.circle.fill")
            .font(.system(size: 32))
            .foregroundColor(durationMinutes > minMinutes ? themeManager.themeColor : .gray)
        }
        .disabled(durationMinutes <= minMinutes)
        .scaleEffect(durationMinutes <= minMinutes ? 0.9 : 1.0)
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.5), trigger: durationMinutes)

        // Slider
        VStack(spacing: 8) {
          Slider(
            value: $durationMinutes,
            in: minMinutes...maxMinutes,
            step: 5,
            onEditingChanged: { editing in
              isSliding = editing
              if !editing {
                snapToNearestPreset()
              }
            }
          )
          .tint(themeManager.themeColor)
          .sensoryFeedback(.selection, trigger: durationMinutes)

          // Min/Max labels
          HStack {
            Text("15m")
              .font(.caption2)
              .foregroundColor(.secondary)
            Spacer()
            Text("24h")
              .font(.caption2)
              .foregroundColor(.secondary)
          }
        }

        // Increment button
        Button {
          incrementDuration()
        } label: {
          Image(systemName: "plus.circle.fill")
            .font(.system(size: 32))
            .foregroundColor(durationMinutes < maxMinutes ? themeManager.themeColor : .gray)
        }
        .disabled(durationMinutes >= maxMinutes)
        .scaleEffect(durationMinutes >= maxMinutes ? 0.9 : 1.0)
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.5), trigger: durationMinutes)
      }
    }
  }

  // MARK: - Helper Functions

  private var formattedDuration: String {
    let totalMinutes = Int(durationMinutes)
    let hours = totalMinutes / 60
    let minutes = totalMinutes % 60

    if hours == 0 {
      return "\(minutes)m"
    } else if minutes == 0 {
      return "\(hours)h"
    } else {
      return "\(hours)h \(minutes)m"
    }
  }

  private var descriptiveText: String {
    let totalMinutes = Int(durationMinutes)
    let hours = totalMinutes / 60
    let minutes = totalMinutes % 60

    if hours == 0 {
      return "\(minutes) minutes"
    } else if minutes == 0 {
      return hours == 1 ? "1 hour" : "\(hours) hours"
    } else {
      let hourText = hours == 1 ? "hour" : "hours"
      let minuteText = minutes == 1 ? "minute" : "minutes"
      return "\(hours) \(hourText) and \(minutes) \(minuteText)"
    }
  }

  private func incrementDuration() {
    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
      durationMinutes = min(durationMinutes + smallIncrement, maxMinutes)
    }
  }

  private func decrementDuration() {
    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
      durationMinutes = max(durationMinutes - smallIncrement, minMinutes)
    }
  }

  private func snapToNearestPreset() {
    // Find the closest snap point
    if let closest = snapPoints.min(by: { abs($0 - durationMinutes) < abs($1 - durationMinutes) }) {
      let distance = abs(closest - durationMinutes)
      if distance <= snapThreshold {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
          durationMinutes = closest
        }
      }
    }
  }

  private func handleConfirm() {
    let data = StrategyTimerData(durationInMinutes: Int(durationMinutes))
    onDurationSelected(data)
    dismiss()
  }
}

struct TimerDurationPreviewSheetHost: View {
  @State private var show: Bool = true

  var body: some View {
    Color.clear
      .sheet(isPresented: $show) {
        NavigationView {
          TimerDurationView(
            profileName: "Work Focus",
            onDurationSelected: { timerData in
              print("Selected duration: \(timerData.durationInMinutes) minutes")
            }
          )
        }
        .presentationDetents([.medium])
      }
  }
}

#Preview {
  TimerDurationPreviewSheetHost()
}
