import Charts
import SwiftUI

struct WeeklySessionChart: View {
  @ObservedObject var viewModel: WeeklyInsightsUtil
  @EnvironmentObject private var themeManager: ThemeManager
  @Binding var selectedDay: WeeklyDayAggregate?
  let onDateSelected: ((Date?) -> Void)?
  @State private var dragLabel: String?
  @State private var previousLabel: String?

  private var chartView: some View {
    Chart {
      ForEach(viewModel.weeklySummary.days) { day in
        BarMark(
          x: .value("Day", day.displayLabel),
          y: .value("Duration", day.totalSessionTime)
        )
        .foregroundStyle(
          selectedDay?.displayLabel == day.displayLabel
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

  private func selectDay(_ label: String) {
    selectedDay = viewModel.weeklySummary.days.first { $0.displayLabel == label }
    if let day = selectedDay {
      onDateSelected?(day.date)
    }
  }

  private func clearSelection() {
    selectedDay = nil
    dragLabel = nil
    previousLabel = nil
    onDateSelected?(nil)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      if let selectedDay = selectedDay {
        HStack {
          VStack(alignment: .leading, spacing: 2) {
            Text(DateFormatters.formatSelectedDayHeader(selectedDay.date))
              .font(.caption)
              .fontWeight(.semibold)
              .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
              Text(DateFormatters.formatDurationHoursMinutes(selectedDay.totalSessionTime))
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .fontWeight(.bold)
                .foregroundStyle(.primary)
                .contentTransition(.numericText())

              Text("total")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            }
          }

          Spacer()

          Button {
            clearSelection()
          } label: {
            Image(systemName: "arrow.counterclockwise")
              .font(.title3)
              .foregroundStyle(.secondary)
          }
          .buttonStyle(.plain)
          .padding(.trailing, 8)
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.85), value: selectedDay)
      } else {
        VStack(alignment: .leading, spacing: 2) {
          Text("Avg Focus Session")
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)

          Text(
            DateFormatters.formatDurationHoursMinutes(
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
        .chartXSelection(value: $dragLabel)
        .onChange(of: dragLabel) { oldValue, newValue in
          // Track previous for haptic feedback
          if let old = oldValue, let new = newValue, old != new {
            previousLabel = old
          }

          // Update selection in real-time during drag
          if let label = newValue {
            selectDay(label)
          }
        }
        .onChange(of: viewModel.selectedDate) { _, _ in
          clearSelection()
        }
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.7), trigger: dragLabel) {
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
    let viewModel: WeeklyInsightsUtil

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

      viewModel = WeeklyInsightsUtil(profiles: [profile])
    }

    var body: some View {
      WeeklySessionChart(
        viewModel: viewModel,
        selectedDay: $selectedDay,
        onDateSelected: nil
      )
      .environmentObject(ThemeManager.shared)
      .padding()
    }
  }

  return PreviewWrapper()
}
