//
//  InsightsView.swift
//  foqos
//
//  Dashboard view for focus insights and analytics
//

import Charts
import SwiftData
import SwiftUI

struct InsightsView: View {
  @Environment(\.modelContext) private var context
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject var themeManager: ThemeManager

  @Query(sort: \BlockedProfileSession.startTime, order: .reverse)
  private var allSessions: [BlockedProfileSession]

  @State private var selectedTimeRange: TimeRange = .week

  private var focusStreak: FocusStreak {
    FocusStreak.fetchOrCreate(in: context)
  }

  // Filter sessions by time range
  private var filteredSessions: [BlockedProfileSession] {
    let calendar = Calendar.current
    let now = Date()

    let startDate: Date = {
      switch selectedTimeRange {
      case .week:
        return calendar.date(byAdding: .day, value: -7, to: now) ?? now
      case .month:
        return calendar.date(byAdding: .month, value: -1, to: now) ?? now
      case .year:
        return calendar.date(byAdding: .year, value: -1, to: now) ?? now
      }
    }()

    return allSessions.filter { session in
      guard let endTime = session.endTime else { return false }
      return session.startTime >= startDate && endTime <= now
    }
  }

  // Calculate daily focus data for chart
  private var dailyFocusData: [DailyFocusData] {
    let calendar = Calendar.current
    var dataByDay: [Date: TimeInterval] = [:]

    // Initialize last 7 days with 0
    for dayOffset in 0..<7 {
      if let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) {
        let startOfDay = calendar.startOfDay(for: date)
        dataByDay[startOfDay] = 0
      }
    }

    // Sum up session durations per day
    for session in filteredSessions {
      guard let endTime = session.endTime else { continue }
      let duration = endTime.timeIntervalSince(session.startTime)
      let startOfDay = calendar.startOfDay(for: session.startTime)

      dataByDay[startOfDay, default: 0] += duration
    }

    return dataByDay.map { date, seconds in
      DailyFocusData(date: date, hours: seconds / 3600)
    }.sorted { $0.date < $1.date }
  }

  // Calculate total focus time
  private var totalFocusTime: TimeInterval {
    filteredSessions.reduce(0) { total, session in
      guard let endTime = session.endTime else { return total }
      return total + endTime.timeIntervalSince(session.startTime)
    }
  }

  // Calculate average session length
  private var averageSessionLength: TimeInterval {
    guard !filteredSessions.isEmpty else { return 0 }
    return totalFocusTime / Double(filteredSessions.count)
  }

  // Count sessions
  private var sessionCount: Int {
    filteredSessions.count
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: Spacing.lg) {
          // Time range picker
          Picker("Time Range", selection: $selectedTimeRange) {
            ForEach(TimeRange.allCases, id: \.self) { range in
              Text(range.title).tag(range)
            }
          }
          .pickerStyle(.segmented)
          .padding(.horizontal, Spacing.md)

          // Streak Card
          StreakCard(
            currentStreak: focusStreak.currentStreak,
            longestStreak: focusStreak.longestStreak,
            weeklyProgress: focusStreak.weeklyProgress,
            weeklyGoalHours: focusStreak.weeklyGoalHours,
            weeklyFocusHours: focusStreak.weeklyFocusHours
          )
          .padding(.horizontal, Spacing.md)

          // Focus Chart
          VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Daily Focus")
              .font(.headline)
              .padding(.horizontal, Spacing.md)

            if dailyFocusData.isEmpty {
              Text("No focus data yet")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(height: 200)
                .frame(maxWidth: .infinity)
            } else {
              Chart(dailyFocusData) { data in
                BarMark(
                  x: .value("Day", data.date, unit: .day),
                  y: .value("Hours", data.hours)
                )
                .foregroundStyle(themeManager.themeColor.gradient)
                .cornerRadius(CornerRadius.xs)
              }
              .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                  AxisGridLine()
                  AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                }
              }
              .chartYAxis {
                AxisMarks { value in
                  AxisGridLine()
                  AxisValueLabel("\(value.as(Double.self) ?? 0, specifier: "%.0f")h")
                }
              }
              .frame(height: 200)
              .padding(.horizontal, Spacing.md)
            }
          }
          .padding(.vertical, Spacing.sm)
          .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
              .fill(Color(.secondarySystemBackground))
          )
          .padding(.horizontal, Spacing.md)

          // Stats Grid
          LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.md) {
            StatCard(
              title: "Total Focus",
              value: formatDuration(totalFocusTime),
              icon: "clock.fill",
              color: themeManager.themeColor
            )

            StatCard(
              title: "Sessions",
              value: "\(sessionCount)",
              icon: "bolt.fill",
              color: .orange
            )

            StatCard(
              title: "Avg Session",
              value: formatDuration(averageSessionLength),
              icon: "timer",
              color: .blue
            )

            StatCard(
              title: "Current Streak",
              value: "\(focusStreak.currentStreak) days",
              icon: "flame.fill",
              color: Color(hex: StreakLevel.level(for: focusStreak.currentStreak).color)
            )
          }
          .padding(.horizontal, Spacing.md)

          // Recent Sessions
          if !filteredSessions.prefix(5).isEmpty {
            VStack(alignment: .leading, spacing: Spacing.sm) {
              Text("Recent Sessions")
                .font(.headline)
                .padding(.horizontal, Spacing.md)

              ForEach(Array(filteredSessions.prefix(5))) { session in
                SessionRow(session: session)
              }
            }
            .padding(.vertical, Spacing.sm)
            .background(
              RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Color(.secondarySystemBackground))
            )
            .padding(.horizontal, Spacing.md)
          }
        }
        .padding(.vertical, Spacing.md)
      }
      .background(Color(.systemGroupedBackground))
      .navigationTitle("Insights")
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Done") {
            dismiss()
          }
        }
      }
    }
  }

  private func formatDuration(_ interval: TimeInterval) -> String {
    let hours = Int(interval) / 3600
    let minutes = Int(interval) / 60 % 60

    if hours > 0 {
      return "\(hours)h \(minutes)m"
    } else {
      return "\(minutes)m"
    }
  }
}

// MARK: - Time Range Enum
enum TimeRange: CaseIterable {
  case week, month, year

  var title: String {
    switch self {
    case .week: return "Week"
    case .month: return "Month"
    case .year: return "Year"
    }
  }
}

// MARK: - Daily Focus Data
struct DailyFocusData: Identifiable {
  let id = UUID()
  let date: Date
  let hours: Double
}

// MARK: - Stat Card
private struct StatCard: View {
  let title: String
  let value: String
  let icon: String
  let color: Color

  var body: some View {
    VStack(alignment: .leading, spacing: Spacing.sm) {
      HStack {
        Image(systemName: icon)
          .font(.title3)
          .foregroundColor(color)

        Spacer()
      }

      VStack(alignment: .leading, spacing: Spacing.xxs) {
        Text(value)
          .font(.title2)
          .fontWeight(.bold)

        Text(title)
          .font(.caption)
          .foregroundColor(.secondary)
      }
    }
    .padding(Spacing.md)
    .background(
      RoundedRectangle(cornerRadius: CornerRadius.lg)
        .fill(Color(.secondarySystemBackground))
    )
  }
}

// MARK: - Session Row
private struct SessionRow: View {
  let session: BlockedProfileSession

  private var duration: TimeInterval {
    guard let endTime = session.endTime else { return 0 }
    return endTime.timeIntervalSince(session.startTime)
  }

  private var formattedDuration: String {
    let hours = Int(duration) / 3600
    let minutes = Int(duration) / 60 % 60

    if hours > 0 {
      return "\(hours)h \(minutes)m"
    } else {
      return "\(minutes)m"
    }
  }

  var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: Spacing.xxs) {
        Text(session.blockedProfile.name)
          .font(.subheadline)
          .fontWeight(.medium)

        Text(session.startTime, style: .date)
          .font(.caption)
          .foregroundColor(.secondary)
      }

      Spacer()

      VStack(alignment: .trailing, spacing: Spacing.xxs) {
        Text(formattedDuration)
          .font(.subheadline)
          .fontWeight(.medium)

        Text(session.startTime, style: .time)
          .font(.caption)
          .foregroundColor(.secondary)
      }
    }
    .padding(.horizontal, Spacing.md)
    .padding(.vertical, Spacing.sm)
  }
}

#Preview {
  InsightsView()
    .environmentObject(ThemeManager.shared)
}
