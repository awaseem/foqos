import SwiftUI

struct ScheduleWarningPrompt: View {
  @EnvironmentObject var themeManager: ThemeManager

  let onApply: () -> Void
  let disabled: Bool

  var body: some View {
    Section {
      VStack(spacing: 16) {
        HStack(alignment: .top, spacing: 12) {
          Image(systemName: "exclamationmark.triangle.fill")
            .font(.title2)
            .foregroundColor(.yellow)

          Text(
            "We found an issue where the schedule got destroyed, press apply to setup the schedule again. Alternatively setup a new schedule below."
          )
          .font(.subheadline)
          .foregroundColor(.primary)
          .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        Button(action: onApply) {
          Text("Fix Schedule")
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(themeManager.themeColor)
            .cornerRadius(10)
        }
        .disabled(disabled)
        .opacity(disabled ? 0.5 : 1.0)
      }
      .padding(.vertical, 8)
    }
  }
}

#Preview {
  Form {
    ScheduleWarningPrompt(
      onApply: { print("Apply tapped") },
      disabled: false
    )
  }
}

#Preview("Disabled") {
  Form {
    ScheduleWarningPrompt(
      onApply: { print("Apply tapped") },
      disabled: true
    )
  }
}
