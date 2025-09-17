import Charts
import SwiftUI

struct ProfileInsightsView: View {
  @StateObject private var viewModel: ProfileInsightsUtil
  @Environment(\.dismiss) private var dismiss

  init(profile: BlockedProfiles) {
    _viewModel = StateObject(wrappedValue: ProfileInsightsUtil(profile: profile))
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 24) {
          VStack(alignment: .leading, spacing: 4) {
            Text(
              "A snapshot of your focus habits, sessions, and breaks. Use these insights to understand patterns and improve productivity."
            )
            .font(.subheadline)
            .foregroundColor(.secondary)
          }

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
              ],
              columns: 2
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

          VStack(alignment: .leading, spacing: 16) {
            SectionTitle("Daily Patterns")

            ChartCard(
              title: "Sessions per Day",
              subtitle: "Daily session count over the last 14 days"
            ) {
              let data = viewModel.dailyAggregates(days: 14)
              SelectableChartFactory.dailyChart(
                data: data,
                xValue: \.date,
                yValue: { Double($0.sessionsCount) }
              ) { item in
                BarMark(
                  x: .value("Date", item.date),
                  y: .value("Sessions", item.sessionsCount)
                )
                .foregroundStyle(.blue)
              } annotationValue: { selectedData in
                "\(selectedData?.sessionsCount ?? 0) sessions"
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

            ChartCard(
              title: "Focus Time Trend",
              subtitle:
                "Total minutes focused per day over 14 days"
            ) {
              let data = viewModel.dailyAggregates(days: 14)
              SelectableChartFactory.dailyChart(
                data: data,
                xValue: \.date,
                yValue: { $0.focusDuration / 60.0 }
              ) { item in
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
              } annotationValue: { selectedData in
                "\(Int(round((selectedData?.focusDuration ?? 0) / 60.0))) min"
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

          VStack(alignment: .leading, spacing: 16) {
            SectionTitle("Break Analysis")

            ChartCard(
              title: "Break Usage Over Time",
              subtitle: "Number of breaks taken daily over 14 days"
            ) {
              let data = viewModel.breakDailyAggregates(days: 14)
              SelectableChartFactory.dailyChart(
                data: data,
                xValue: \.date,
                yValue: { Double($0.breaksCount) }
              ) { item in
                LineMark(
                  x: .value("Date", item.date),
                  y: .value("Breaks", item.breaksCount)
                )
                .foregroundStyle(.purple)
                AreaMark(
                  x: .value("Date", item.date),
                  y: .value("Breaks", item.breaksCount)
                )
                .foregroundStyle(.purple.opacity(0.2))
              } annotationValue: { selectedData in
                "\(selectedData?.breaksCount ?? 0) breaks"
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

            ChartCard(
              title: "Average Break Duration",
              subtitle: "Mean break length in minutes per day over 14 days"
            ) {
              let data = viewModel.breakDailyAggregates(days: 14)
              SelectableChartFactory.dailyChart(
                data: data,
                xValue: \.date,
                yValue: { data in
                  guard data.breaksCount > 0 else { return 0 }
                  return data.totalBreakDuration / Double(data.breaksCount) / 60.0
                }
              ) { item in
                let avgDuration =
                  item.breaksCount > 0
                  ? item.totalBreakDuration / Double(item.breaksCount) / 60.0 : 0
                LineMark(
                  x: .value("Date", item.date),
                  y: .value("Minutes", avgDuration)
                )
                .foregroundStyle(.purple)
                AreaMark(
                  x: .value("Date", item.date),
                  y: .value("Minutes", avgDuration)
                )
                .foregroundStyle(.purple.opacity(0.2))
              } annotationValue: { selectedData in
                guard let data = selectedData, data.breaksCount > 0 else { return "0 min" }
                let avgDuration = data.totalBreakDuration / Double(data.breaksCount) / 60.0
                return "\(Int(round(avgDuration))) min avg"
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

            ChartCard(
              title: "Break Start Times",
              subtitle:
                "When you typically start breaks by hour of day over 14 days"
            ) {
              let data = viewModel.breakStartHourlyAggregates(days: 14)
              SelectableChartFactory.hourlyChart(
                data: data,
                xValue: \.hour,
                yValue: { Double($0.breaksStarted) }
              ) { item in
                BarMark(
                  x: .value("Hour", item.hour),
                  y: .value("Breaks", item.breaksStarted)
                )
                .foregroundStyle(.purple)
              } annotationValue: { selectedData in
                "\(selectedData?.breaksStarted ?? 0) breaks started"
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

            ChartCard(
              title: "Break End Times",
              subtitle:
                "When you typically end breaks by hour of day over 14 days"
            ) {
              let data = viewModel.breakEndHourlyAggregates(days: 14)
              SelectableChartFactory.hourlyChart(
                data: data,
                xValue: \.hour,
                yValue: { Double($0.breaksEnded) }
              ) { item in
                BarMark(
                  x: .value("Hour", item.hour),
                  y: .value("Breaks", item.breaksEnded)
                )
                .foregroundStyle(.purple.opacity(0.7))
              } annotationValue: { selectedData in
                "\(selectedData?.breaksEnded ?? 0) breaks ended"
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

          VStack(alignment: .leading, spacing: 16) {
            SectionTitle("Time of Day")

            ChartCard(
              title: "Sessions Started by Hour",
              subtitle:
                "When you typically begin focus sessions by hour over 14 days"
            ) {
              let data = viewModel.hourlyAggregates(days: 14)
              SelectableChartFactory.hourlyChart(
                data: data,
                xValue: \.hour,
                yValue: { Double($0.sessionsStarted) }
              ) { item in
                BarMark(
                  x: .value("Hour", item.hour),
                  y: .value("Sessions", item.sessionsStarted)
                )
                .foregroundStyle(.blue)
              } annotationValue: { selectedData in
                "\(selectedData?.sessionsStarted ?? 0) sessions"
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

            ChartCard(
              title: "Average Session by Hour",
              subtitle:
                "Mean session duration in minutes by hour over 14 days"
            ) {
              let data = viewModel.hourlyAggregates(days: 14)
              SelectableChartFactory.hourlyChart(
                data: data,
                xValue: \.hour,
                yValue: { ($0.averageSessionDuration ?? 0) / 60.0 }
              ) { item in
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
              } annotationValue: { selectedData in
                "\(Int(round(((selectedData?.averageSessionDuration ?? 0) / 60.0)))) min"
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

            ChartCard(
              title: "Session End Times",
              subtitle:
                "When you typically complete focus sessions by hour over 14 days"
            ) {
              let data = viewModel.sessionEndHourlyAggregates(days: 14)
              SelectableChartFactory.hourlyChart(
                data: data,
                xValue: \.hour,
                yValue: { Double($0.sessionsEnded) }
              ) { item in
                BarMark(
                  x: .value("Hour", item.hour),
                  y: .value("Sessions", item.sessionsEnded)
                )
                .foregroundStyle(.red)
              } annotationValue: { selectedData in
                "\(selectedData?.sessionsEnded ?? 0) sessions ended"
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
            SectionTitle("Details")

            MultiStatCard(
              stats: nerdStatsItems,
              columns: 2
            )
          }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
      }
      .background(Color(.systemGroupedBackground).ignoresSafeArea())
      .navigationTitle("Stats for Nerds")
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button {
            dismiss()
          } label: {
            Image(systemName: "xmark")
          }
          .accessibilityLabel("Close")
        }
      }
    }
  }
}

#Preview {
  let profile = BlockedProfiles(name: "Focus")
  ProfileInsightsView(profile: profile)
}

extension ProfileInsightsView {
  private func formatHourShort(_ hour: Int) -> String {
    var comps = DateComponents()
    comps.hour = max(0, min(23, hour))
    let calendar = Calendar.current
    let date = calendar.date(from: comps) ?? Date()
    let formatter = DateFormatter()
    formatter.dateFormat = "ha"
    return formatter.string(from: date).lowercased()
  }

  private var nerdStatsItems: [MultiStatCard.StatItem] {
    let profile = viewModel.profile
    let profileIdShort = String(profile.id.uuidString.prefix(8))

    var items: [MultiStatCard.StatItem] = [
      .init(
        title: "Profile ID", valueText: profileIdShort, systemImageName: "tag", iconColor: .gray),
      .init(
        title: "Created", valueText: profile.createdAt.formatted(), systemImageName: "calendar",
        iconColor: .gray),
      .init(
        title: "Last Modified", valueText: profile.updatedAt.formatted(), systemImageName: "clock",
        iconColor: .gray),
      .init(
        title: "Total Sessions", valueText: "\(profile.sessions.count)",
        systemImageName: "list.number", iconColor: .gray),
      .init(
        title: "Categories Blocked", valueText: "\(profile.selectedActivity.categories.count)",
        systemImageName: "square.grid.2x2", iconColor: .gray),
      .init(
        title: "Apps Blocked", valueText: "\(profile.selectedActivity.applications.count)",
        systemImageName: "app", iconColor: .gray),
    ]

    if let active = profile.activeDeviceActivity {
      items.append(
        .init(
          title: "Active Device Activity", valueText: String(active.rawValue.prefix(8)),
          systemImageName: "bolt.fill",
          iconColor: .gray))
    }

    return items
  }
}
