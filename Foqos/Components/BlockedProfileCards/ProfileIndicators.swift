import SwiftUI

struct ProfileIndicators: View {
  let enableLiveActivity: Bool
  let hasReminders: Bool
  let enableBreaks: Bool
  let enableStrictMode: Bool

  var body: some View {
    HStack(spacing: 16) {
      if enableBreaks {
        indicatorView(label: "Breaks")
      }
      if enableStrictMode {
        indicatorView(label: "Strict")
      }
      if enableLiveActivity {
        indicatorView(label: "Live Activity")
      }
      if hasReminders {
        indicatorView(label: "Reminders")
      }
    }
  }

  private func indicatorView(label: String) -> some View {
    HStack(spacing: 6) {
      Circle()
        .fill(Color.green.opacity(0.85))
        .frame(width: 6, height: 6)

      Text(label)
        .font(.caption2)
        .foregroundColor(.secondary)
    }
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
