import Charts
import SwiftUI

struct ProfileInsightsView: View {
  @StateObject private var viewModel: ProfileInsightsUtil

  init(profile: BlockedProfiles) {
    _viewModel = StateObject(wrappedValue: ProfileInsightsUtil(profile: profile))
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        VStack(alignment: .leading, spacing: 8) {
          SectionTitle("Session")

          MultiStatCard(
            stats: [
              .init(
                title: "Total Focus Time",
                valueText: viewModel.formattedDuration(viewModel.metrics.totalFocusTime),
                systemImageName: "clock",
                iconColor: .orange
              ),
              .init(
                title: "Average Session",
                valueText: viewModel.formattedDuration(viewModel.metrics.averageSessionDuration),
                systemImageName: "chart.bar",
                iconColor: .orange
              ),
              .init(
                title: "Longest Session",
                valueText: viewModel.formattedDuration(viewModel.metrics.longestSessionDuration),
                systemImageName: "timer",
                iconColor: .orange
              ),
              .init(
                title: "Shortest Session",
                valueText: viewModel.formattedDuration(viewModel.metrics.shortestSessionDuration),
                systemImageName: "hourglass",
                iconColor: .orange
              ),
              .init(
                title: "Total Sessions",
                valueText: String(viewModel.metrics.totalCompletedSessions),
                systemImageName: "list.number",
                iconColor: .orange
              ),
            ],
            columns: 2
          )
        }

        VStack(alignment: .leading, spacing: 8) {
          SectionTitle("Daily Patterns")

          ChartCard(title: "Sessions per Day", subtitle: "Last 14 days") {
            let data = viewModel.dailyAggregates(days: 14)
            Chart(data) { item in
              BarMark(
                x: .value("Date", item.date),
                y: .value("Sessions", item.sessionsCount)
              )
              .foregroundStyle(.blue)
            }
            .chartXAxis {
              AxisMarks(values: .automatic(desiredCount: 4)) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.month().day())
              }
            }
            .chartYAxis {
              AxisMarks(position: .leading)
            }
          }

          ChartCard(title: "Focus Time Trend", subtitle: "Last 14 days") {
            let data = viewModel.dailyAggregates(days: 14)
            Chart(data) { item in
              LineMark(
                x: .value("Date", item.date),
                y: .value("Minutes", item.focusDuration / 60.0)
              )
              .foregroundStyle(.green)
              AreaMark(
                x: .value("Date", item.date),
                y: .value("Minutes", item.focusDuration / 60.0)
              )
              .foregroundStyle(.green.opacity(0.2))
            }
            .chartXAxis {
              AxisMarks(values: .automatic(desiredCount: 4)) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.month().day())
              }
            }
            .chartYAxis {
              AxisMarks(position: .leading)
            }
          }
        }

        VStack(alignment: .leading, spacing: 8) {
          SectionTitle("Break Behavior")

          MultiStatCard(
            stats: [
              .init(
                title: "Total Breaks Taken",
                valueText: String(viewModel.metrics.totalBreaksTaken),
                systemImageName: "pause.circle",
                iconColor: .blue
              ),
              .init(
                title: "Average Break Duration",
                valueText: viewModel.formattedDuration(viewModel.metrics.averageBreakDuration),
                systemImageName: "hourglass",
                iconColor: .blue
              ),
              .init(
                title: "Sessions With Breaks",
                valueText: String(viewModel.metrics.sessionsWithBreaks),
                systemImageName: "rectangle.badge.checkmark",
                iconColor: .blue
              ),
              .init(
                title: "Sessions Without Breaks",
                valueText: String(viewModel.metrics.sessionsWithoutBreaks),
                systemImageName: "rectangle.badge.xmark",
                iconColor: .blue
              ),
            ],
            columns: 2
          )
        }
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 16)
    }
    .background(Color(.systemGroupedBackground).ignoresSafeArea())
    .navigationTitle("\(viewModel.profile.name) Insights")
  }
}

#Preview {
  let profile = BlockedProfiles(name: "Focus")
  ProfileInsightsView(profile: profile)
}
