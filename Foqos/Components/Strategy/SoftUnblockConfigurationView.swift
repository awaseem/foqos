import SwiftUI

struct SoftUnblockConfigurationView: View {
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var themeManager: ThemeManager

  let profileName: String
  let onStart: (SoftUnblockStrategyData) -> Void

  @State private var maximumUnblockCount: Int
  @State private var accessDurationInMinutes: Int
  @State private var allowanceResetIntervalInHours: Int?

  init(
    profileName: String,
    initialConfiguration: SoftUnblockStrategyData,
    onStart: @escaping (SoftUnblockStrategyData) -> Void
  ) {
    self.profileName = profileName
    self.onStart = onStart
    _maximumUnblockCount = State(initialValue: initialConfiguration.maximumUnblockCount)
    _accessDurationInMinutes = State(
      initialValue: initialConfiguration.accessDurationInMinutes
    )
    _allowanceResetIntervalInHours = State(
      initialValue: initialConfiguration.allowanceResetIntervalInHours
    )
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        ScrollView {
          VStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: 8) {
              Text("Temporary Access")
                .font(.title2.bold())

              Text("Choose how many times blocked apps can open, and for how long.")
                .font(.callout)
                .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 12) {
              Text("Allowed Opens")
                .font(.headline)

              Stepper(
                value: $maximumUnblockCount,
                in: SoftUnblockStrategyData.unblockCountRange
              ) {
                HStack(alignment: .firstTextBaseline) {
                  Text("\(maximumUnblockCount)")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())

                  Text(maximumUnblockCount == 1 ? "open" : "opens")
                    .foregroundColor(.secondary)
                }
              }
              .sensoryFeedback(.selection, trigger: maximumUnblockCount)

              Text("Each time you open a blocked app or category, it uses one.")
                .font(.caption)
                .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 12) {
              Text("Open Time")
                .font(.headline)

              Text(formattedDuration)
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .contentTransition(.numericText())

              Slider(
                value: durationBinding,
                in: Double(
                  SoftUnblockStrategyData.durationRange.lowerBound)...Double(
                    SoftUnblockStrategyData.durationRange.upperBound),
                step: 5
              )
              .tint(themeManager.themeColor)
              .sensoryFeedback(.selection, trigger: accessDurationInMinutes)

              HStack {
                Text("5m")
                Spacer()
                Text("1h")
              }
              .font(.caption2)
              .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 12) {
              Text("Reset Opens")
                .font(.headline)

              Picker("Reset Opens", selection: $allowanceResetIntervalInHours) {
                Text("Never").tag(Int?.none)
                ForEach(SoftUnblockStrategyData.allowanceResetIntervalsInHours, id: \.self) {
                  hours in
                  Text("\(hours)h").tag(Int?.some(hours))
                }
              }
              .pickerStyle(.segmented)

              Text(resetDescription)
                .font(.caption)
                .foregroundColor(.secondary)
            }
          }
          .padding(.horizontal, 24)
          .padding(.top, 24)
          .padding(.bottom, 16)
        }

        startButton
          .padding(.horizontal, 24)
          .padding(.top, 12)
          .padding(.bottom, 16)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button(action: { dismiss() }) {
            Image(systemName: "xmark")
          }
          .accessibilityLabel("Cancel")
        }
      }
    }
  }

  private var startButton: some View {
    ActionButton(
      title: "Start Blocking",
      backgroundColor: themeManager.themeColor,
      iconName: "checkmark.circle.fill"
    ) {
      onStart(
        SoftUnblockStrategyData(
          accessDurationInMinutes: accessDurationInMinutes,
          maximumUnblockCount: maximumUnblockCount,
          allowanceResetIntervalInHours: allowanceResetIntervalInHours
        )
      )
      dismiss()
    }
  }

  private var durationBinding: Binding<Double> {
    Binding(
      get: { Double(accessDurationInMinutes) },
      set: { accessDurationInMinutes = Int($0) }
    )
  }

  private var formattedDuration: String {
    accessDurationInMinutes == 60 ? "1 hour" : "\(accessDurationInMinutes) minutes"
  }

  private var resetDescription: String {
    guard let allowanceResetIntervalInHours else {
      return "Your opens do not reset during this session."
    }

    return "You get all your opens back every \(allowanceResetIntervalInHours) hours."
  }
}

#Preview {
  SoftUnblockConfigurationView(
    profileName: "Deep Work",
    initialConfiguration: SoftUnblockStrategyData(
      accessDurationInMinutes: 15,
      maximumUnblockCount: 3,
      allowanceResetIntervalInHours: 6
    ),
    onStart: { _ in }
  )
  .environmentObject(ThemeManager.shared)
}
