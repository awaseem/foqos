import Charts
import SwiftUI

struct WeeklySessionChart: View {
  @ObservedObject var viewModel: WeeklyProfileInsightsUtil
  @EnvironmentObject private var themeManager: ThemeManager
  @Binding var selectedDay: WeeklyDayAggregate?
  @State private var selectedLabel: String?
  @State private var previousLabel: String?

  private var chartView: some View {
    Chart {
      ForEach(viewModel.weeklySummary.days) { day in
        BarMark(
          x: .value("Day", day.displayLabel),
          y: .value("Duration", day.totalSessionTime)
        )
        .foregroundStyle(
          selectedLabel == day.displayLabel
            ? themeManager.themeColor.opacity(0.7)
            : themeManager.themeColor
        )
        .cornerRadius(6)
      }
    }
    .chartYAxis {
      AxisMarks(position: .trailing) { value in
        AxisValueLabel {
          if let duration = value.as(TimeInterval.self) {
            Text(DateFormatters.formatDurationShort(duration))
              .font(.caption2)
              .foregroundStyle(.secondary)
          }
        }
      }
    }
    .chartXAxis {
      AxisMarks { value in
        AxisValueLabel {
          if let label = value.as(String.self) {
            Text(label)
              .font(.caption)
              .fontWeight(.medium)
              .foregroundStyle(.secondary)
          }
        }
      }
    }
    .chartPlotStyle { plotArea in
      plotArea
        .padding(.trailing, 10)
    }
  }

  private func handleSelectionChange(newValue: String?) {
    if let label = newValue {
      selectedDay = viewModel.weeklySummary.days.first { $0.displayLabel == label }
    } else {
      selectedDay = nil
    }
    previousLabel = newValue
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      if let selectedDay {
        VStack(alignment: .leading, spacing: 2) {
          Text(DateFormatters.formatSelectedDayHeader(selectedDay.date))
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)

          Text(DateFormatters.formatDurationHoursSeconds(selectedDay.totalSessionTime))
                .font(.system(size: 40, weight: .bold, design: .rounded))
            .fontWeight(.bold)
            .foregroundStyle(.primary)
            .contentTransition(.numericText())
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.85), value: selectedDay)
      } else {
        VStack(alignment: .leading, spacing: 2) {
          Text("Avg Focus Session")
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)

          Text(
            DateFormatters.formatDurationHoursSeconds(
              viewModel.weeklySummary.averageSessionDuration)
          )
          .font(.system(size: 40, weight: .bold, design: .rounded))
          .fontWeight(.bold)
          .foregroundStyle(.primary)
          .contentTransition(.numericText())
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.85), value: selectedDay)
      }

      chartView
        .chartXSelection(value: $selectedLabel)
        .onChange(of: selectedLabel) { _, newValue in
          handleSelectionChange(newValue: newValue)
        }
        .onChange(of: viewModel.selectedDate) { _, _ in
          selectedLabel = nil
          selectedDay = nil
          previousLabel = nil
        }
        .onChange(of: selectedDay) { _, newValue in
          guard newValue == nil else { return }
          selectedLabel = nil
          previousLabel = nil
        }
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.7), trigger: selectedLabel) {
          old, new in
          old == nil && new != nil
        }
        .sensoryFeedback(.selection, trigger: previousLabel) { old, new in
          guard let oldLabel = old, let newLabel = new else { return false }
          return oldLabel != newLabel
        }
        .frame(maxWidth: .infinity)
        .frame(height: 210)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

#Preview {
  struct PreviewWrapper: View {
    @State private var selectedDay: WeeklyDayAggregate?
    let viewModel: WeeklyProfileInsightsUtil

    init() {
      let profile = BlockedProfiles(name: "Work Focus")
      let calendar = Calendar.current
      let today = Date()
      let weekStart = WeeklySessionAggregator.startOfWeek(for: today, calendar: calendar)

      for dayOffset in 0..<7 {
        let sessionsCount = [3, 5, 2, 4, 6, 1, 2][dayOffset]
        let day = calendar.date(byAdding: .day, value: dayOffset, to: weekStart)!

        for sessionIndex in 0..<sessionsCount {
          let session = BlockedProfileSession(
            tag: "Focus Session \(sessionIndex + 1)", blockedProfile: profile)
          let startTime = calendar.date(byAdding: .hour, value: 8 + sessionIndex, to: day)!
          session.startTime = startTime
          session.endTime = calendar.date(
            byAdding: .minute, value: 45 + sessionIndex * 10, to: startTime)!
        }
      }

      viewModel = WeeklyProfileInsightsUtil(profile: profile)
    }

    var body: some View {
      WeeklySessionChart(viewModel: viewModel, selectedDay: $selectedDay)
        .environmentObject(ThemeManager.shared)
        .padding()
    }
  }

  return PreviewWrapper()
}
