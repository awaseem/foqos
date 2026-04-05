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

struct InsightsSummaryCard: View {
  let totalFocusTime: TimeInterval
  let totalBreakTime: TimeInterval
  let profileId: UUID

  private var truncatedProfileId: String {
    profileId.uuidString.prefix(8) + "..."
  }

  var body: some View {
    VStack(spacing: 12) {
      SummaryCardRow(
        icon: "clock.fill",
        label: "Total Focus Time",
        value: DateFormatters.formatDurationHoursMinutes(totalFocusTime)
      )

      Divider()

      SummaryCardRow(
        icon: "cup.and.saucer.fill",
        label: "Total Break Time",
        value: DateFormatters.formatDurationHoursMinutes(totalBreakTime)
      )

      Divider()

      SummaryCardRow(
        icon: "tag.fill",
        label: "Profile ID",
        value: truncatedProfileId
      )
    }
    .padding()
    .background(Color(.secondarySystemGroupedBackground))
    .clipShape(RoundedRectangle(cornerRadius: 12))
  }
}

private struct SummaryCardRow: View {
  let icon: String
  let label: String
  let value: String

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: icon)
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(.secondary)
        .frame(width: 24)

      Text(label)
        .font(.subheadline)
        .foregroundStyle(.secondary)

      Spacer()

      Text(value)
        .font(.subheadline)
        .fontWeight(.medium)
        .foregroundStyle(.primary)
    }
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

#Preview("Card") {
  InsightsSummaryCard(
    totalFocusTime: 19800,
    totalBreakTime: 2700,
    profileId: UUID()
  )
  .padding()
  .background(Color(.systemGroupedBackground))
}
