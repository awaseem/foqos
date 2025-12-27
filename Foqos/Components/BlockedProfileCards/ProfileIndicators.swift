import SwiftUI

struct ProfileIndicators: View {
  let enableLiveActivity: Bool
  let hasReminders: Bool
  let enableBreaks: Bool
  let enableStrictMode: Bool

  // Build accessibility summary
  private var accessibilitySummary: String {
    var features: [String] = []
    if enableBreaks { features.append("Breaks enabled") }
    if enableStrictMode { features.append("Strict mode enabled") }
    if enableLiveActivity { features.append("Live Activity enabled") }
    if hasReminders { features.append("Reminders enabled") }

    if features.isEmpty {
      return "No special features enabled"
    }
    return "Profile features: " + features.joined(separator: ", ")
  }

  var body: some View {
    HStack(spacing: Spacing.md) {
      if enableBreaks {
        indicatorView(label: "Breaks", hint: "Short breaks are enabled during focus sessions")
      }
      if enableStrictMode {
        indicatorView(label: "Strict", hint: "Strict mode prevents easy exit from focus sessions")
      }
      if enableLiveActivity {
        indicatorView(label: "Live Activity", hint: "Shows focus timer on lock screen")
      }
      if hasReminders {
        indicatorView(label: "Reminders", hint: "Scheduled reminders are set for this profile")
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(accessibilitySummary)
  }

  private func indicatorView(label: String, hint: String) -> some View {
    HStack(spacing: Spacing.xxs + 2) {
      Circle()
        .fill(Color.primary.opacity(Opacity.secondary))
        .frame(width: 6, height: 6)

      Text(label)
        .font(.caption2)
        .foregroundColor(.secondary)
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel(label)
    .accessibilityHint(hint)
  }
}

#Preview {
  VStack(spacing: 20) {
    ProfileIndicators(
      enableLiveActivity: true,
      hasReminders: true,
      enableBreaks: false,
      enableStrictMode: false,
    )
    ProfileIndicators(
      enableLiveActivity: false,
      hasReminders: false,
      enableBreaks: true,
      enableStrictMode: true,
    )
  }
  .padding()
  .background(Color(.systemGroupedBackground))
}
