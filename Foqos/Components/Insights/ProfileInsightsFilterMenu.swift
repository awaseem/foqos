import SwiftUI

enum InsightsFilter: Equatable {
  case thisWeek
  case lastWeek
  case thisMonth
  case lastMonth
  case specificWeek
  case specificMonth
  case allSessions
}

struct ProfileInsightsFilterMenu: View {
  let selectedFilter: InsightsFilter
  let viewMode: InsightsViewMode
  let weekSummary: WeeklySummary
  let monthSummary: MonthlySummary
  let onSelectFilter: (InsightsFilter) -> Void
  let onSelectDate: () -> Void
  let onDeleteAll: () -> Void

  private var isSpecificFilter: Bool {
    selectedFilter == .specificWeek || selectedFilter == .specificMonth
  }

  var body: some View {
    Menu {
      Button {
        onSelectFilter(.thisWeek)
      } label: {
        Label(
          "This Week",
          systemImage: selectedFilter == .thisWeek
            ? "checkmark" : "calendar.day.timeline.left")
      }
      Button {
        onSelectFilter(.lastWeek)
      } label: {
        Label(
          "Last Week",
          systemImage: selectedFilter == .lastWeek
            ? "checkmark" : "calendar.day.timeline.right")
      }

      Divider()

      Button {
        onSelectFilter(.thisMonth)
      } label: {
        Label("This Month", systemImage: selectedFilter == .thisMonth ? "checkmark" : "calendar")
      }
      Button {
        onSelectFilter(.lastMonth)
      } label: {
        Label("Last Month", systemImage: selectedFilter == .lastMonth ? "checkmark" : "arrow.left")
      }

      Divider()

      Button(action: onSelectDate) {
        Label(
          viewMode == .week ? "Select Week..." : "Select Month...",
          systemImage: isSpecificFilter ? "checkmark" : "calendar.view.day"
        )
      }

      Divider()

      Button {
        onSelectFilter(.allSessions)
      } label: {
        Label(
          "All Sessions", systemImage: selectedFilter == .allSessions ? "checkmark" : "list.bullet")
      }
      Button(role: .destructive, action: onDeleteAll) {
        Label("Delete All Sessions", systemImage: "trash")
      }
    } label: {
      HStack(spacing: 4) {
        Image(systemName: filterMenuIcon)
        Text(filterMenuTitle)
          .font(.subheadline.weight(.medium))
      }
      .foregroundStyle(.primary)
    }
  }

  private var filterMenuIcon: String {
    switch selectedFilter {
    case .thisWeek:
      return "calendar.day.timeline.left"
    case .lastWeek:
      return "calendar.day.timeline.right"
    case .thisMonth:
      return "calendar"
    case .lastMonth:
      return "arrow.left"
    case .specificWeek, .specificMonth:
      return "calendar.view.day"
    case .allSessions:
      return "list.bullet"
    }
  }

  private var filterMenuTitle: String {
    switch selectedFilter {
    case .thisWeek:
      return "This Week"
    case .lastWeek:
      return "Last Week"
    case .thisMonth:
      return "This Month"
    case .lastMonth:
      return "Last Month"
    case .specificWeek:
      return DateFormatters.formatWeekRange(
        start: weekSummary.weekStartDate, end: weekSummary.weekEndDate)
    case .specificMonth:
      return DateFormatters.formatMonthRange(
        start: monthSummary.monthStartDate, end: monthSummary.monthEndDate)
    case .allSessions:
      return "All Sessions"
    }
  }

}
