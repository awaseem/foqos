import SwiftUI

struct BlockedProfileHardModeFields: View {
  @EnvironmentObject private var themeManager: ThemeManager
  @ObservedObject var draft: BlockedProfileDraft
  var disabled: Bool

  var body: some View {
    CustomToggle(
      title: "Hard Mode",
      description: draft.selectedStrategyAllowsHardMode
        ? "Hide the Stop button for a set time."
        : "Unavailable for timers. Hide the Stop button instead.",
      isOn: $draft.enableHardMode,
      isDisabled: disabled || !draft.selectedStrategyAllowsHardMode
    )

    if draft.enableHardMode && draft.selectedStrategyAllowsHardMode {
      VStack(alignment: .leading, spacing: 10) {
        HStack {
          Text("Lock Duration")
          Spacer()
          Text(DateFormatters.formatMinutes(draft.hardModeDurationInMinutes))
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .contentTransition(.numericText())
        }

        Slider(
          value: Binding(
            get: { Double(draft.hardModeDurationInMinutes) },
            set: { draft.hardModeDurationInMinutes = Int($0) }
          ),
          in: 30...720,
          step: 30
        )
        .tint(themeManager.themeColor)
        .accessibilityLabel("Hard Mode lock duration")
        .accessibilityValue(DateFormatters.formatMinutes(draft.hardModeDurationInMinutes))

        HStack {
          Text("30m")
          Spacer()
          Text("12h")
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
      }
      .disabled(disabled)
    }
  }
}

#Preview {
  Form {
    BlockedProfileHardModeFields(
      draft: BlockedProfileDraft(
        profile: BlockedProfiles(name: "Work", enableHardMode: true, hardModeDurationInMinutes: 90)
      ),
      disabled: false
    )
  }
  .environmentObject(ThemeManager())
}
