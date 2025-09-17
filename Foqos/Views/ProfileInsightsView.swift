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
          SectionTitle("Focus Habits")

          MultiStatCard(
            stats: [
              .init(
                title: "Current Streak",
                valueText: String(viewModel.currentStreakDays()) + " days",
                systemImageName: "flame",
                iconColor: .red
              ),
              .init(
                title: "Longest Streak",
                valueText: String(viewModel.longestStreakDays()) + " days",
                systemImageName: "crown",
                iconColor: .yellow
              ),
              .init(
                title: "Days Since Last Session",
                valueText: {
                  if let days = viewModel.daysSinceLastSession() { return String(days) }
                  return "—"
                }(),
                systemImageName: "calendar.badge.exclamationmark",
                iconColor: .orange
              ),
            ],
            columns: 3
          )
        }

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
          SectionTitle("Highlights")

          let best = viewModel.bestFocusWeekday(in: 60)
          let avgDaily = viewModel.averageDailyFocusTime(days: 14)
          let mostProductive = viewModel.mostProductiveHours(count: 3, days: 30)
          let peakFocus = viewModel.peakFocusHours(count: 3, days: 30)
          MultiStatCard(
            stats: [
              .init(
                title: "Best Focus Day",
                valueText: {
                  if let best = best {
                    let day = weekdayName(for: best.weekday, short: true)
                    return day + " · " + viewModel.formattedDuration(best.totalFocus)
                  } else {
                    return "—"
                  }
                }(),
                systemImageName: "calendar",
                iconColor: .purple
              ),
              .init(
                title: "Avg Daily Focus (14d)",
                valueText: viewModel.formattedDuration(avgDaily),
                systemImageName: "clock.badge.checkmark",
                iconColor: .teal
              ),
              .init(
                title: "Most Productive Hours",
                valueText: mostProductive.isEmpty ? "—" : listHoursShort(mostProductive),
                systemImageName: "clock",
                iconColor: .indigo
              ),
              .init(
                title: "Peak Focus Hours",
                valueText: peakFocus.isEmpty ? "—" : listHoursShort(peakFocus),
                systemImageName: "chart.line.uptrend.xyaxis",
                iconColor: .pink
              ),
            ],
            columns: 1
          )
        }

        VStack(alignment: .leading, spacing: 8) {
          SectionTitle("Time of Day")

          ChartCard(title: "Sessions Started by Hour", subtitle: "Last 14 days") {
            let data = viewModel.hourlyAggregates(days: 14)
            Chart(data) { item in
              BarMark(
                x: .value("Hour", item.hour),
                y: .value("Sessions", item.sessionsStarted)
              )
              .foregroundStyle(.blue)
            }
            .chartXAxis {
              AxisMarks(values: .automatic(desiredCount: 6)) { value in
                AxisGridLine()
                AxisTick()
                if let hour = value.as(Int.self) {
                  AxisValueLabel(formatHourShort(hour))
                }
              }
            }
            .chartYAxis {
              AxisMarks(position: .leading)
            }
          }

          ChartCard(title: "Average Session by Hour", subtitle: "Last 14 days") {
            let data = viewModel.hourlyAggregates(days: 14)
            Chart(data) { item in
              LineMark(
                x: .value("Hour", item.hour),
                y: .value("Minutes", (item.averageSessionDuration ?? 0) / 60.0)
              )
              .foregroundStyle(.green)
              AreaMark(
                x: .value("Hour", item.hour),
                y: .value("Minutes", (item.averageSessionDuration ?? 0) / 60.0)
              )
              .foregroundStyle(.green.opacity(0.2))
            }
            .chartXAxis {
              AxisMarks(values: .automatic(desiredCount: 6)) { value in
                AxisGridLine()
                AxisTick()
                if let hour = value.as(Int.self) {
                  AxisValueLabel(formatHourShort(hour))
                }
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

extension ProfileInsightsView {
  private func weekdayName(for weekdayIndex: Int, short: Bool = true) -> String {
    let symbols = short ? Calendar.current.shortWeekdaySymbols : Calendar.current.weekdaySymbols
    let safeIndex = max(1, min(7, weekdayIndex)) - 1
    return symbols[safeIndex]
  }

  private func formatHourShort(_ hour: Int) -> String {
    var comps = DateComponents()
    comps.hour = max(0, min(23, hour))
    let calendar = Calendar.current
    let date = calendar.date(from: comps) ?? Date()
    let formatter = DateFormatter()
    formatter.dateFormat = "ha"
    return formatter.string(from: date).lowercased()
  }

  private func listHoursShort(_ hours: [Int]) -> String {
    let labels = hours.map { formatHourShort($0) }
    return labels.joined(separator: ", ")
  }
}
