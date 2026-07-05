import SwiftUI

struct SoftUnblockConfigurationView: View {
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var themeManager: ThemeManager

  let profileName: String
  let onStart: (SoftUnblockStrategyData) -> Void

  @State private var maximumUnblockCount: Int
  @State private var accessDurationInMinutes: Int

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
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 28) {
        VStack(alignment: .leading, spacing: 8) {
          Text("Soft Unblock Settings")
            .font(.title2.bold())

          Text("Choose how temporary access works while \(profileName) is active.")
            .font(.callout)
            .foregroundColor(.secondary)
        }

        VStack(alignment: .leading, spacing: 12) {
          Text("Allowed Unblocks")
            .font(.headline)

          Stepper(
            value: $maximumUnblockCount,
            in: SoftUnblockStrategyData.unblockCountRange
          ) {
            HStack(alignment: .firstTextBaseline) {
              Text("\(maximumUnblockCount)")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .contentTransition(.numericText())

              Text(maximumUnblockCount == 1 ? "unblock" : "unblocks")
                .foregroundColor(.secondary)
            }
          }
          .sensoryFeedback(.selection, trigger: maximumUnblockCount)

          Text("Each successful app or category request uses one unblock.")
            .font(.caption)
            .foregroundColor(.secondary)
        }

        VStack(alignment: .leading, spacing: 12) {
          Text("Access Duration")
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

        ActionButton(
          title: "Start Blocking",
          backgroundColor: themeManager.themeColor,
          iconName: "checkmark.circle.fill"
        ) {
          onStart(
            SoftUnblockStrategyData(
              accessDurationInMinutes: accessDurationInMinutes,
              maximumUnblockCount: maximumUnblockCount
            )
          )
          dismiss()
        }
      }
      .padding(24)
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
}

#Preview {
  SoftUnblockConfigurationView(
    profileName: "Deep Work",
    initialConfiguration: SoftUnblockStrategyData(
      accessDurationInMinutes: 15,
      maximumUnblockCount: 3
    ),
    onStart: { _ in }
  )
  .environmentObject(ThemeManager.shared)
}
