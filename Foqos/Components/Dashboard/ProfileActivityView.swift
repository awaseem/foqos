import SwiftUI

struct ProfileActivityView: View {
  @EnvironmentObject var themeManager: ThemeManager

  let selectedDate: Date
  let activities: [DashboardProfileActivity]
  let viewMode: InsightsViewMode
  let onInsightsTapped: (DashboardInsightsContext) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(DateFormatters.formatDashboardDate(selectedDate))
        .font(.subheadline)
        .fontWeight(.medium)

      VStack(alignment: .leading, spacing: 8) {
        ForEach(activities) { activity in
          profileActivityRow(for: activity)

          if activity.id != activities.last?.id {
            Divider()
          }
        }
      }
    }
    .padding(.top, 8)
    .padding(.horizontal, 16)
    .padding(.bottom, 16)
    .transition(.move(edge: .bottom).combined(with: .opacity))
  }

  private func profileActivityRow(for activity: DashboardProfileActivity) -> some View {
    HStack(spacing: 12) {
      Text(activity.profile.name)
        .font(.subheadline)
        .fontWeight(.medium)
        .foregroundColor(.primary)

      Spacer()

      Text(DateFormatters.formatDurationShort(activity.totalTime))
        .font(.subheadline)
        .fontWeight(.medium)
        .foregroundColor(.secondary)

      Button {
        let context = DashboardInsightsContext(
          profile: activity.profile,
          viewMode: viewMode,
          selectedDate: selectedDate
        )
        onInsightsTapped(context)
      } label: {
        HStack(spacing: 4) {
          Image(systemName: "chart.line.uptrend.xyaxis")
            .font(.caption)
          Text("View")
            .font(.caption)
            .fontWeight(.medium)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
        .background(
          Capsule()
            .fill(.tertiary)
        )
      }
      .buttonStyle(.plain)
    }
    .padding(.vertical, 4)
  }
}

#Preview {
  let profile1 = BlockedProfiles(name: "Deep Work")
  let profile2 = BlockedProfiles(name: "Social Media Block")

  let activities = [
    DashboardProfileActivity(profile: profile1, totalTime: 7200, sessionCount: 2),
    DashboardProfileActivity(profile: profile2, totalTime: 3600, sessionCount: 1),
  ]

  return ProfileActivityView(
    selectedDate: Date(),
    activities: activities,
    viewMode: .week,
    onInsightsTapped: { _ in }
  )
  .environmentObject(ThemeManager.shared)
  .padding()
}
