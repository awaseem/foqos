import SwiftUI

struct TimerDurationView: View {
  @Environment(\.dismiss) private var dismiss

  let profileName: String
  let onDurationSelected: (StrategyTimerData) -> Void

  @State private var selectedPreset: TimerPreset?
  @State private var isCustomSelected = false
  @State private var customMinutes: String = ""
  @State private var showError = false
  @State private var errorMessage = ""

  enum TimerPreset: CaseIterable {
    case fifteenMinutes
    case thirtyMinutes
    case oneHour
    case twoHours
    case threeHours
    case sixHours

    var title: String {
      switch self {
      case .fifteenMinutes: return "15m"
      case .thirtyMinutes: return "30m"
      case .oneHour: return "1h"
      case .twoHours: return "2h"
      case .threeHours: return "3h"
      case .sixHours: return "6h"
      }
    }

    var fullTitle: String {
      switch self {
      case .fifteenMinutes: return "15 Minutes"
      case .thirtyMinutes: return "30 Minutes"
      case .oneHour: return "1 Hour"
      case .twoHours: return "2 Hours"
      case .threeHours: return "3 Hours"
      case .sixHours: return "6 Hours"
      }
    }

    var minutes: Int {
      switch self {
      case .fifteenMinutes: return 15
      case .thirtyMinutes: return 30
      case .oneHour: return 60
      case .twoHours: return 120
      case .threeHours: return 180
      case .sixHours: return 360
      }
    }
  }

  var body: some View {
    ScrollView {
      VStack(spacing: 20) {
        header

        durationCard
      }
      .padding()
    }
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .navigationBarLeading) {
        Button {
          dismiss()
        } label: {
          Image(systemName: "xmark")
            .foregroundColor(.primary)
        }
      }
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(profileName)
        .font(.title2).bold()
    }
    .padding(.top, 16)
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var durationCard: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Image(systemName: "clock.fill")
          .font(.title3)
          .foregroundColor(.secondary)
        Text("Select Duration")
          .font(.headline)
        Spacer()
      }

      Text(
        "The timer will start when you start the profile and will stop when the duration is reached."
      )
      .font(.callout)
      .foregroundColor(.secondary)

      VStack(spacing: 12) {
        // Horizontal scrollable list with all options
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 12) {
            // Preset options
            ForEach(TimerPreset.allCases, id: \.self) { preset in
              Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                  selectedPreset = preset
                  isCustomSelected = false
                  customMinutes = ""
                  showError = false
                }
              } label: {
                Text(preset.title)
                  .font(.subheadline.bold())
                  .foregroundColor(selectedPreset == preset ? .white : .primary)
                  .padding(.horizontal, 20)
                  .padding(.vertical, 12)
                  .background(
                    Capsule()
                      .fill(selectedPreset == preset ? Color.purple : Color.secondary.opacity(0.1))
                  )
              }
              .scaleEffect(selectedPreset == preset ? 1.1 : 1.0)
              .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedPreset)
            }

            // Custom button (last in the list)
            Button {
              withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                selectedPreset = nil
                isCustomSelected = true
                showError = false
              }
            } label: {
              HStack(spacing: 6) {
                Image(systemName: "slider.horizontal.3")
                  .font(.caption)
                Text("Custom")
                  .font(.subheadline.bold())
              }
              .foregroundColor(isCustomSelected ? .white : .primary)
              .padding(.horizontal, 20)
              .padding(.vertical, 12)
              .background(
                Capsule()
                  .fill(isCustomSelected ? Color.purple : Color.secondary.opacity(0.1))
              )
            }
            .scaleEffect(isCustomSelected ? 1.1 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isCustomSelected)
          }
          .padding(.horizontal, 2)
        }
        .padding(.vertical, 4)

        // Custom input (shown when custom is selected)
        if isCustomSelected {
          VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
              TextField("Minutes", text: $customMinutes)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .onChange(of: customMinutes) { _, newValue in
                  // Limit to 4 digits (max 1439 for 23h 59m)
                  if newValue.count > 4 {
                    customMinutes = String(newValue.prefix(4))
                  }
                  // Only allow numbers
                  customMinutes = customMinutes.filter { $0.isNumber }
                  showError = false
                }

              Text("minutes")
                .font(.subheadline)
                .foregroundColor(.secondary)
            }

            if showError {
              Text(errorMessage)
                .font(.caption)
                .foregroundColor(.red)
            } else {
              Text("Enter minutes (15 min to 24 hours)")
                .font(.caption)
                .foregroundColor(.secondary)
            }
          }
          .transition(
            .opacity.combined(with: .scale(scale: 0.95).combined(with: .move(edge: .top))))
        }

        ActionButton(
          title: "Set Duration",
          backgroundColor: .purple,
          iconName: "checkmark.circle.fill",
          isDisabled: !canConfirm
        ) {
          handleConfirm()
        }
        .padding(.horizontal)
        .padding(.top, 16)
      }
      .padding(.vertical, 16)
    }
    .padding(16)
    .background(
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .fill(.thinMaterial)
    )
    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isCustomSelected)
  }

  private var canConfirm: Bool {
    if selectedPreset != nil {
      return true
    }

    if isCustomSelected && !customMinutes.isEmpty {
      return isValidCustomDuration()
    }

    return false
  }

  private func isValidCustomDuration() -> Bool {
    guard let minutes = Int(customMinutes) else { return false }
    return minutes >= 15 && minutes < 24 * 60
  }

  private func handleConfirm() {
    if let preset = selectedPreset {
      let data = StrategyTimerData(durationInMinutes: preset.minutes)
      onDurationSelected(data)
      dismiss()
    } else if isCustomSelected && !customMinutes.isEmpty {
      guard let minutes = Int(customMinutes) else { return }

      if minutes >= 24 * 60 {
        showError = true
        errorMessage = "Duration must be less than 24 hours (1439 minutes max)"
        return
      }

      if minutes < 15 {
        showError = true
        errorMessage = "Duration must be at least 15 minutes"
        return
      }

      let data = StrategyTimerData(durationInMinutes: minutes)
      onDurationSelected(data)
      dismiss()
    }
  }
}

#Preview {
  NavigationView {
    TimerDurationView(
      profileName: "Work Focus",
      onDurationSelected: { timerData in
        print("Selected duration: \(timerData.durationInMinutes) minutes")
      }
    )
  }
}
