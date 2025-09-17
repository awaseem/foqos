import SwiftUI

struct ProfileInsightsView: View {
  @StateObject private var viewModel: ProfileInsightsUtil

  init(profile: BlockedProfiles) {
    _viewModel = StateObject(wrappedValue: ProfileInsightsUtil(profile: profile))
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        SectionTitle("Insights")

        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 16) {
            StatCard(
              title: "Total Focus Time",
              valueText: viewModel.formattedDuration(viewModel.metrics.totalFocusTime),
              subtitleText: "All time",
              systemImageName: "clock",
              iconColor: .blue
            )
            .frame(width: 260)

            StatCard(
              title: "Average Session",
              valueText: viewModel.formattedDuration(viewModel.metrics.averageSessionDuration),
              systemImageName: "chart.bar",
              iconColor: .purple
            )
            .frame(width: 260)

            StatCard(
              title: "Longest Session",
              valueText: viewModel.formattedDuration(viewModel.metrics.longestSessionDuration),
              systemImageName: "timer",
              iconColor: .green
            )
            .frame(width: 260)

            StatCard(
              title: "Shortest Session",
              valueText: viewModel.formattedDuration(viewModel.metrics.shortestSessionDuration),
              systemImageName: "hourglass",
              iconColor: .orange
            )
            .frame(width: 260)

            StatCard(
              title: "Total Sessions",
              valueText: String(viewModel.metrics.totalCompletedSessions),
              systemImageName: "list.number",
              iconColor: .blue
            )
            .frame(width: 260)
          }
          .padding(.vertical, 4)
        }
      }
      .padding(.horizontal)
      .padding(.top, 16)
    }
    .background(Color(.systemGroupedBackground).ignoresSafeArea())
    .navigationTitle("\(viewModel.profile.name) Insights")
  }
}

#Preview {
  let profile = BlockedProfiles(name: "Focus")
  ProfileInsightsView(profile: profile)
}
