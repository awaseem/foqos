import SwiftUI

struct InsightsEmptyStateView: View {
  let hasSelectedDay: Bool

  var body: some View {
    VStack(spacing: 10) {
      Image(systemName: "chart.bar.xaxis")
        .font(.system(size: 28))
        .foregroundStyle(.secondary)

      Text(hasSelectedDay ? "No sessions on this day" : "No sessions this week")
        .font(.headline)
        .foregroundStyle(.secondary)

      Text(
        hasSelectedDay
          ? "Try another day or clear the filter to see the full week."
          : "Completed sessions from this week will appear here."
      )
      .font(.subheadline)
      .foregroundStyle(.secondary)
      .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 40)
    .listRowBackground(Color.clear)
  }
}

#Preview("No Selected Day") {
  List {
    InsightsEmptyStateView(hasSelectedDay: false)
  }
}

#Preview("With Selected Day") {
  List {
    InsightsEmptyStateView(hasSelectedDay: true)
  }
}
