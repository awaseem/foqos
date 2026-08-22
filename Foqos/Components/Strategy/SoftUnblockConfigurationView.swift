import SwiftUI

struct SoftUnblockConfigurationView: View {
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var themeManager: ThemeManager

  let profileName: String
  let actionTitle: String
  let onStart: (SoftUnblockStrategyData) -> Void

  @State private var maximumUnblockCount: Int
  @State private var accessDurationInMinutes: Int
  @State private var allowanceResetIntervalInHours: Int?
  @State private var lastAllowanceResetIntervalInHours: Int

  init(
    profileName: String,
    initialConfiguration: SoftUnblockStrategyData,
    actionTitle: String = "Start Blocking",
    onStart: @escaping (SoftUnblockStrategyData) -> Void
  ) {
    self.profileName = profileName
    self.actionTitle = actionTitle
    self.onStart = onStart
    _maximumUnblockCount = State(initialValue: initialConfiguration.maximumUnblockCount)
    _accessDurationInMinutes = State(
      initialValue: initialConfiguration.accessDurationInMinutes
    )
    _allowanceResetIntervalInHours = State(
      initialValue: initialConfiguration.allowanceResetIntervalInHours
    )
    _lastAllowanceResetIntervalInHours = State(
      initialValue: initialConfiguration.allowanceResetIntervalInHours
        ?? SoftUnblockStrategyData.defaultEnabledAllowanceResetIntervalInHours
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

              Text("Each time you open a blocked app or category, it uses one.")
                .font(.caption)
                .foregroundColor(.secondary)

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
              HStack {
                Text("Reset Opens")
                  .font(.headline)

                Spacer()

                Toggle("Reset Opens", isOn: resetEnabledBinding)
                  .labelsHidden()
                  .tint(themeManager.themeColor)
              }

              Text(resetDescription)
                .font(.caption)
                .foregroundColor(.secondary)

              if allowanceResetIntervalInHours != nil {
                Text(formattedResetInterval)
                  .font(.system(size: 40, weight: .bold, design: .rounded))
                  .contentTransition(.numericText())

                Slider(
                  value: resetIntervalBinding,
                  in: resetIntervalRange,
                  step: 1
                )
                .tint(themeManager.themeColor)
                .sensoryFeedback(.selection, trigger: allowanceResetIntervalInHours)
                .accessibilityValue(formattedResetInterval)

                HStack {
                  Text("1h")
                  Spacer()
                  Text("24h")
                }
                .font(.caption2)
                .foregroundColor(.secondary)
              }
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
      title: actionTitle,
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

  private var resetEnabledBinding: Binding<Bool> {
    Binding(
      get: { allowanceResetIntervalInHours != nil },
      set: { isEnabled in
        allowanceResetIntervalInHours = isEnabled ? lastAllowanceResetIntervalInHours : nil
      }
    )
  }

  private var resetIntervalBinding: Binding<Double> {
    Binding(
      get: { Double(allowanceResetIntervalInHours ?? lastAllowanceResetIntervalInHours) },
      set: { value in
        let interval = Int(value)
        allowanceResetIntervalInHours = interval
        lastAllowanceResetIntervalInHours = interval
      }
    )
  }

  private var resetIntervalRange: ClosedRange<Double> {
    let range = SoftUnblockStrategyData.allowanceResetIntervalRangeInHours
    return Double(range.lowerBound)...Double(range.upperBound)
  }

  private var formattedDuration: String {
    accessDurationInMinutes == 60 ? "1 hour" : "\(accessDurationInMinutes) minutes"
  }

  private var formattedResetInterval: String {
    let interval = allowanceResetIntervalInHours ?? lastAllowanceResetIntervalInHours
    return interval == 1 ? "1 hour" : "\(interval) hours"
  }

  private var resetDescription: String {
    guard let allowanceResetIntervalInHours else {
      return "Your opens do not reset during this session."
    }

    if allowanceResetIntervalInHours == 1 {
      return "You get all your opens back every hour."
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
