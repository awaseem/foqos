import SwiftUI

struct MonthlySessionChart: View {
  @ObservedObject var viewModel: MonthlyProfileInsightsUtil
  @EnvironmentObject private var themeManager: ThemeManager
  @Binding var selectedDay: MonthlyDayAggregate?
  @State private var dragDay: MonthlyDayAggregate?
  @State private var previousDragDay: MonthlyDayAggregate?
  @State private var isDragging = false

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
  }

  private func clearSelection() {
    selectedDay = nil
    dragDay = nil
    previousDragDay = nil
    isDragging = false
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

  private func handleDrag(at location: CGPoint, in geometry: GeometryProxy) {
    guard isDragging else { return }

    let cellWidth = geometry.size.width / 7
    let cellHeight = cellWidth  // Square cells

    let column = Int(location.x / cellWidth)
    let row = Int(location.y / cellHeight)

    guard column >= 0, column < 7, row >= 0, row < weeksInMonth.count else { return }

    let week = weeksInMonth[row]
    guard column < week.count else { return }

    let day = week[column]
    guard day.dayOfMonth != 0 else { return }

    if dragDay?.date != day.date {
      previousDragDay = dragDay
      dragDay = day
      selectedDay = day
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
              Text(DateFormatters.formatDurationHoursSeconds(selectedDay.totalSessionTime))
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

          Text(DateFormatters.formatDurationHoursSeconds(monthlySummary.averageSessionDuration))
            .font(.system(size: 40, weight: .bold, design: .rounded))
            .fontWeight(.bold)
            .foregroundStyle(.primary)
            .contentTransition(.numericText())
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.85), value: selectedDay)
      }

      // Legend
      legendView()

      // Grid with drag support
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
        .gesture(
          DragGesture(minimumDistance: 0, coordinateSpace: .named("grid"))
            .onChanged { value in
              isDragging = true
              handleDrag(at: value.location, in: geometry)
            }
            .onEnded { _ in
              isDragging = false
              dragDay = nil
              previousDragDay = nil
            }
        )
      }
      .frame(
        height: CGFloat(weeksInMonth.count) * (UIScreen.main.bounds.width - 32) / 7 + CGFloat(
          weeksInMonth.count - 1) * 4)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.7), trigger: dragDay) { old, new in
      old == nil && new != nil
    }
    .sensoryFeedback(.selection, trigger: previousDragDay) { old, new in
      guard let oldDay = old, let newDay = new else { return false }
      return oldDay.date != newDay.date
    }
  }
}

// MARK: - Preference Key for Day Frames

struct DayFrame: Equatable {
  let day: MonthlyDayAggregate
  let frame: CGRect
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
    let viewModel: MonthlyProfileInsightsUtil

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

      viewModel = MonthlyProfileInsightsUtil(profile: profile)
    }

    var body: some View {
      MonthlySessionChart(viewModel: viewModel, selectedDay: $selectedDay)
        .environmentObject(ThemeManager.shared)
        .padding()
    }
  }

  return PreviewWrapper()
}
