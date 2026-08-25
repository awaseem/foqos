import SwiftUI

struct MonthlySessionChart: View {
  @ObservedObject var viewModel: MonthlyInsightsUtil
  @EnvironmentObject private var themeManager: ThemeManager
  @Binding var selectedDay: MonthlyDayAggregate?
  let onDateSelected: ((Date?) -> Void)?
  @State private var selectionFeedbackTrigger = 0

  private var monthlySummary: MonthlySummary {
    viewModel.monthlySummary
  }

  private func colorForHours(_ hours: Double) -> Color {
    switch hours {
    case 0:
      return Color.gray.opacity(0.15)
    case 0..<1:
      return themeManager.themeColor.opacity(0.3)
    case 1..<3:
      return themeManager.themeColor.opacity(0.5)
    case 3..<5:
      return themeManager.themeColor.opacity(0.7)
    default:
      return themeManager.themeColor.opacity(0.9)
    }
  }

  private var legendData: [(String, Double)] {
    [("<1h", 0.3), ("1-3h", 0.5), ("3-5h", 0.7), (">5h", 0.9)]
  }

  private var weeksInMonth: [[MonthlyDayAggregate]] {
    let days = monthlySummary.days
    var weeks: [[MonthlyDayAggregate]] = []
    var currentWeek: [MonthlyDayAggregate] = []

    // Pad the beginning of the first week with empty days if month doesn't start on Sunday
    if let firstDay = days.first {
      let calendar = Calendar.current
      let weekday = calendar.component(.weekday, from: firstDay.date)
      let paddingDays = weekday - 1  // Sunday = 1, so padding = 0
      for _ in 0..<paddingDays {
        // Add placeholder nil values for padding
        currentWeek.append(
          MonthlyDayAggregate(
            dayOfMonth: 0,
            dayName: "",
            totalSessionTime: 0,
            sessionCount: 0,
            date: Date.distantPast
          ))
      }
    }

    for day in days {
      currentWeek.append(day)
      if currentWeek.count == 7 {
        weeks.append(currentWeek)
        currentWeek = []
      }
    }

    // Add remaining days to last week and pad if needed
    if !currentWeek.isEmpty {
      while currentWeek.count < 7 {
        currentWeek.append(
          MonthlyDayAggregate(
            dayOfMonth: 0,
            dayName: "",
            totalSessionTime: 0,
            sessionCount: 0,
            date: Date.distantPast
          ))
      }
      weeks.append(currentWeek)
    }

    return weeks
  }

  private func selectDay(_ day: MonthlyDayAggregate?) {
    selectedDay = day
    if let selectedDay = day {
      onDateSelected?(selectedDay.date)
      selectionFeedbackTrigger += 1
    }
  }

  private func clearSelection() {
    selectedDay = nil
    onDateSelected?(nil)
  }

  private func legendView() -> some View {
    HStack(spacing: 12) {
      ForEach(legendData, id: \.0) { label, opacity in
        HStack(spacing: 4) {
          Rectangle()
            .fill(themeManager.themeColor.opacity(opacity))
            .frame(width: 10, height: 10)
            .cornerRadius(2)

          Text(label)
            .font(.caption2)
            .foregroundColor(.secondary)
        }
      }
    }
  }

  private func daySquareView(
    for day: MonthlyDayAggregate,
    weekIndex: Int,
    dayIndex: Int,
    geometry: GeometryProxy
  ) -> some View {
    let hours = day.totalSessionTime / 3600
    let isSelected = selectedDay?.date == day.date
    let isPlaceholder = day.dayOfMonth == 0

    return Rectangle()
      .fill(isPlaceholder ? Color.clear : colorForHours(hours))
      .aspectRatio(1, contentMode: .fit)
      .cornerRadius(4)
      .overlay(
        Group {
          if !isPlaceholder {
            Text("\(day.dayOfMonth)")
              .font(.system(size: 10, weight: .medium))
              .foregroundColor(hours > 3 ? .white : .primary)
          }
        }
      )
      .overlay(
        RoundedRectangle(cornerRadius: 4)
          .stroke(isSelected ? Color.primary : Color.clear, lineWidth: 2)
      )
      .opacity(isPlaceholder ? 0 : 1)
      .contentShape(Rectangle())
      .onTapGesture {
        guard !isPlaceholder else { return }
        selectDay(day)
      }
      .background(
        GeometryReader { dayGeometry in
          Color.clear
            .preference(
              key: DayFramePreferenceKey.self,
              value: [DayFrame(day: day, frame: dayGeometry.frame(in: .named("grid")))]
            )
        }
      )
  }

  private func weekRowView(
    for week: [MonthlyDayAggregate],
    weekIndex: Int,
    geometry: GeometryProxy
  ) -> some View {
    HStack(spacing: 4) {
      ForEach(Array(week.enumerated()), id: \.element.id) { dayIndex, day in
        daySquareView(
          for: day,
          weekIndex: weekIndex,
          dayIndex: dayIndex,
          geometry: geometry
        )
      }
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      // Header
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

          Text(DateFormatters.formatDurationHoursMinutes(monthlySummary.averageSessionDuration))
            .font(.system(size: 40, weight: .bold, design: .rounded))
            .fontWeight(.bold)
            .foregroundStyle(.primary)
            .contentTransition(.numericText())
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.85), value: selectedDay)
      }

      // Grid
      GeometryReader { geometry in
        LazyVStack(spacing: 4) {
          ForEach(weeksInMonth.indices, id: \.self) { weekIndex in
            weekRowView(
              for: weeksInMonth[weekIndex],
              weekIndex: weekIndex,
              geometry: geometry
            )
          }
        }
        .frame(maxWidth: .infinity)
        .coordinateSpace(name: "grid")
      }
      .frame(
        height: CGFloat(weeksInMonth.count) * (UIScreen.main.bounds.width - 32) / 7
          + CGFloat(
            weeksInMonth.count - 1))

      // Legend
      legendView()
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .sensoryFeedback(
      .impact(flexibility: .soft, intensity: 0.7),
      trigger: selectionFeedbackTrigger
    )
  }
}

// MARK: - Preference Key for Day Frames

struct DayFrame: Equatable {
  let day: MonthlyDayAggregate
  let frame: CGRect

  static func == (lhs: DayFrame, rhs: DayFrame) -> Bool {
    lhs.day.id == rhs.day.id && lhs.frame == rhs.frame
  }
}

struct DayFramePreferenceKey: PreferenceKey {
  static var defaultValue: [DayFrame] = []

  static func reduce(value: inout [DayFrame], nextValue: () -> [DayFrame]) {
    value.append(contentsOf: nextValue())
  }
}

#Preview {
  struct PreviewWrapper: View {
    @State private var selectedDay: MonthlyDayAggregate?
    let viewModel: MonthlyInsightsUtil

    init() {
      let profile = BlockedProfiles(name: "Work Focus")
      let calendar = Calendar.current
      let today = Date()
      let monthStart = MonthlySessionAggregator.startOfMonth(for: today, calendar: calendar)
      let daysInMonth = MonthlySessionAggregator.daysInMonth(for: today, calendar: calendar)

      // Create sample sessions across the month
      for dayOffset in 0..<daysInMonth {
        let sessionsCount = Int.random(in: 0...4)
        let day = calendar.date(byAdding: .day, value: dayOffset, to: monthStart)!

        for sessionIndex in 0..<sessionsCount {
          let session = BlockedProfileSession(
            tag: "Focus Session \(sessionIndex + 1)", blockedProfile: profile)
          let startTime = calendar.date(byAdding: .hour, value: 8 + sessionIndex * 2, to: day)!
          session.startTime = startTime
          session.endTime = calendar.date(
            byAdding: .minute, value: 30 + sessionIndex * 15, to: startTime)!
        }
      }

      viewModel = MonthlyInsightsUtil(profiles: [profile])
    }

    var body: some View {
      MonthlySessionChart(
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
