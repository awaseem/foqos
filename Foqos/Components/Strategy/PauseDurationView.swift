import SwiftUI

struct PauseDurationView: View {
  @EnvironmentObject var themeManager: ThemeManager
  @Environment(\.dismiss) private var dismiss

  let profileName: String
  let onDurationSelected: (Int) -> Void

  // State for slider-based duration selection
  @State private var durationMinutes: Double = 15  // Default 15 minutes
  @State private var isSliding = false

  // Constants - max 1 hour for pause duration
  private let minMinutes: Double = 5
  private let maxMinutes: Double = 60
  private let smallIncrement: Double = 5

  // Common snap points (in minutes)
  private let snapPoints: [Double] = [5, 10, 15, 20, 30, 45, 60]
  private let snapThreshold: Double = 3  // How close to snap (in minutes)

  var body: some View {
    VStack(spacing: 32) {
      // Header
      VStack(alignment: .leading, spacing: 12) {
        Text("Pause Duration")
          .font(.title2).bold()

        Text(
          "Select how long you want to allow access when pausing \(profileName)."
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

      // Confirm button
      ActionButton(
        title: "Start Blocking",
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

      Text("access duration")
        .font(.subheadline)
        .foregroundColor(.secondary)
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
            Text("5m")
              .font(.caption2)
              .foregroundColor(.secondary)
            Spacer()
            Text("1h")
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
    onDurationSelected(Int(durationMinutes))
    dismiss()
  }
}

struct PauseDurationPreviewSheetHost: View {
  @State private var show: Bool = true

  var body: some View {
    Color.clear
      .sheet(isPresented: $show) {
        NavigationView {
          PauseDurationView(
            profileName: "Work Focus",
            onDurationSelected: { minutes in
              print("Selected pause duration: \(minutes) minutes")
            }
          )
        }
        .presentationDetents([.medium])
      }
  }
}

#Preview {
  PauseDurationPreviewSheetHost()
}
