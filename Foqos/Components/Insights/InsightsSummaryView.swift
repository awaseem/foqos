import SwiftUI

struct InsightsSummaryRow: View {
  let icon: String
  let label: String
  let value: String

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: icon)
        .font(.body)
        .foregroundStyle(.secondary)
        .frame(width: 20)

      Text(label)
        .font(.body)
        .foregroundStyle(.secondary)

      Spacer()

      Text(value)
        .font(.body)
        .fontWeight(.medium)
        .foregroundStyle(.primary)
    }
    .padding(.vertical, 4)
  }
}

#Preview("Row") {
  List {
    Section("Summary") {
      InsightsSummaryRow(
        icon: "clock.fill",
        label: "Total Focus Time",
        value: "5h 30m"
      )
      InsightsSummaryRow(
        icon: "cup.and.saucer.fill",
        label: "Total Break Time",
        value: "45m"
      )
      InsightsSummaryRow(
        icon: "tag.fill",
        label: "Profile ID",
        value: "abc12345..."
      )
    }
  }
}
