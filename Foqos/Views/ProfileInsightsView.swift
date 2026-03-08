import SwiftData
import SwiftUI

private struct InsightsAlertIdentifier: Identifiable {
  enum AlertType {
    case deleteSession
    case error
  }

  let id: AlertType
  var session: BlockedProfileSession?
  var errorMessage: String?
}

private enum InsightsFilter: Equatable {
  case thisWeek
  case lastWeek
  case thisMonth
  case lastMonth
  case specificWeek
  case specificMonth
  case allSessions
}

private enum InsightsViewMode {
  case week
  case month
  case allSessions
}

struct ProfileInsightsView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext
  @EnvironmentObject private var themeManager: ThemeManager

  @StateObject private var weeklyViewModel: WeeklyInsightsUtil
  @StateObject private var monthlyViewModel: MonthlyInsightsUtil
  @State private var selectedWeekDay: WeeklyDayAggregate?
  @State private var selectedMonthDay: MonthlyDayAggregate?
  @State private var selectedSession: BlockedProfileSession?
  @State private var alertIdentifier: InsightsAlertIdentifier?
  @State private var showingWeekPicker = false
  @State private var showingMonthPicker = false
  @State private var showDeleteAllConfirmation = false
  @State private var selectedFilter: InsightsFilter = .thisWeek

  @Query(sort: \BlockedProfileSession.startTime, order: .reverse)
  private var allSessions: [BlockedProfileSession]

  private var viewMode: InsightsViewMode {
    switch selectedFilter {
    case .thisWeek, .lastWeek, .specificWeek:
      return .week
    case .thisMonth, .lastMonth, .specificMonth:
      return .month
    case .allSessions:
      return .allSessions
    }
  }

  private var selectedDay: Any? {
    switch viewMode {
    case .week:
      return selectedWeekDay
    case .month:
      return selectedMonthDay
    case .allSessions:
      return nil
    }
  }

  private var isSpecificFilter: Bool {
    switch selectedFilter {
    case .specificWeek, .specificMonth:
      return true
    default:
      return false
    }
  }

  init(profile: BlockedProfiles) {
    _weeklyViewModel = StateObject(wrappedValue: WeeklyInsightsUtil(profiles: [profile]))
    _monthlyViewModel = StateObject(wrappedValue: MonthlyInsightsUtil(profiles: [profile]))
  }

  private var weekSummary: WeeklySummary {
    weeklyViewModel.weeklySummary
  }

  private var monthSummary: MonthlySummary {
    monthlyViewModel.monthlySummary
  }

  private var weekSessions: [BlockedProfileSession] {
    allSessions.filter { session in
      guard let profileId = weeklyViewModel.profiles.first?.id,
            session.blockedProfile.id == profileId,
            let endTime = session.endTime
      else {
        return false
      }
      return session.startTime < weekEndExclusive && endTime > weekStart
    }
  }

  private var monthSessions: [BlockedProfileSession] {
    allSessions.filter { session in
      guard let profileId = monthlyViewModel.profiles.first?.id,
            session.blockedProfile.id == profileId,
            let endTime = session.endTime
      else {
        return false
      }
      return session.startTime < monthEndExclusive && endTime > monthStart
    }
  }

  private var allProfileSessions: [BlockedProfileSession] {
    allSessions.filter { session in
      guard let profileId = weeklyViewModel.profiles.first?.id else { return false }
      return session.blockedProfile.id == profileId && session.endTime != nil
    }
  }

  private var filteredSessions: [BlockedProfileSession] {
    switch viewMode {
    case .week:
      return filteredWeekSessions
    case .month:
      return filteredMonthSessions
    case .allSessions:
      return allProfileSessions
    }
  }

  private var filteredWeekSessions: [BlockedProfileSession] {
    guard let selectedWeekDay else {
      return weekSessions
    }

    let dayStart = Calendar.current.startOfDay(for: selectedWeekDay.date)
    let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart

    return weekSessions.filter { session in
      guard let endTime = session.endTime else { return false }
      return session.startTime < dayEnd && endTime > dayStart
    }
  }

  private var filteredMonthSessions: [BlockedProfileSession] {
    guard let selectedMonthDay else {
      return monthSessions
    }

    let dayStart = Calendar.current.startOfDay(for: selectedMonthDay.date)
    let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart

    return monthSessions.filter { session in
      guard let endTime = session.endTime else { return false }
      return session.startTime < dayEnd && endTime > dayStart
    }
  }

  private var weekStart: Date {
    weekSummary.weekStartDate
  }

  private var weekEndExclusive: Date {
    Calendar.current.date(byAdding: .day, value: 1, to: weekSummary.weekEndDate)
      ?? weekSummary.weekEndDate
  }

  private var monthStart: Date {
    monthSummary.monthStartDate
  }

  private var monthEndExclusive: Date {
    Calendar.current.date(byAdding: .day, value: 1, to: monthSummary.monthEndDate)
      ?? monthSummary.monthEndDate
  }

  private var sessionsSectionTitle: String {
    switch viewMode {
    case .week:
      if let selectedWeekDay {
        return "Sessions for \(DateFormatters.formatSelectedDayHeader(selectedWeekDay.date))"
      }
      return "Sessions"
    case .month:
      if let selectedMonthDay {
        return "Sessions for \(DateFormatters.formatSelectedDayHeader(selectedMonthDay.date))"
      }
      return "Sessions"
    case .allSessions:
      return "All Sessions"
    }
  }

  var body: some View {
    NavigationStack {
      List {
        if viewMode != .allSessions {
          Section {
            if viewMode == .week {
              WeeklySessionChart(viewModel: weeklyViewModel, selectedDay: $selectedWeekDay, onDateSelected: nil)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
                .listRowInsets(EdgeInsets(top: 12, leading: 4, bottom: 0, trailing: 4))
                .listRowBackground(Color.clear)
            } else {
              MonthlySessionChart(viewModel: monthlyViewModel, selectedDay: $selectedMonthDay, onDateSelected: nil)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
                .listRowInsets(EdgeInsets(top: 12, leading: 4, bottom: 0, trailing: 4))
                .listRowBackground(Color.clear)
            }
          }
        }

        if filteredSessions.isEmpty {
          InsightsEmptyStateView(hasSelectedDay: selectedDay != nil)
        } else {
          Section(sessionsSectionTitle) {
            ForEach(filteredSessions) { session in
              Button {
                selectedSession = session
              } label: {
                SessionRow(session: session)
              }
              .buttonStyle(.plain)
              .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                  alertIdentifier = InsightsAlertIdentifier(id: .deleteSession, session: session)
                } label: {
                  Label("Delete", systemImage: "trash")
                }
              }
            }
          }
        }
      }
      .navigationTitle("Insights")
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button {
            dismiss()
          } label: {
            Image(systemName: "xmark")
          }
          .accessibilityLabel("Close")
        }

        ToolbarItem(placement: .topBarTrailing) {
          Menu {
            // Week options
            Button {
              selectedFilter = .thisWeek
              clearDaySelection()
              weeklyViewModel.setWeek(for: Date())
            } label: {
              Label(
                "This Week",
                systemImage: selectedFilter == .thisWeek
                  ? "checkmark" : "calendar.day.timeline.left")
            }

            Button {
              selectedFilter = .lastWeek
              clearDaySelection()
              if let lastWeek = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date())
              {
                weeklyViewModel.setWeek(for: lastWeek)
              }
            } label: {
              Label(
                "Last Week",
                systemImage: selectedFilter == .lastWeek
                  ? "checkmark" : "calendar.day.timeline.right")
            }

            Divider()

            // Month options
            Button {
              selectedFilter = .thisMonth
              clearDaySelection()
              monthlyViewModel.setMonth(for: Date())
            } label: {
              Label(
                "This Month", systemImage: selectedFilter == .thisMonth ? "checkmark" : "calendar")
            }

            Button {
              selectedFilter = .lastMonth
              clearDaySelection()
              if let lastMonth = Calendar.current.date(byAdding: .month, value: -1, to: Date()) {
                monthlyViewModel.setMonth(for: lastMonth)
              }
            } label: {
              Label(
                "Last Month", systemImage: selectedFilter == .lastMonth ? "checkmark" : "arrow.left"
              )
            }

            Divider()

            // Specific date picker
            Button {
              if viewMode == .week {
                showingWeekPicker = true
              } else if viewMode == .month {
                showingMonthPicker = true
              }
            } label: {
              Label(
                viewMode == .week ? "Select Week..." : "Select Month...",
                systemImage: isSpecificFilter ? "checkmark" : "calendar.view.day"
              )
            }

            Divider()

            // All sessions option
            Button {
              selectedFilter = .allSessions
              clearDaySelection()
            } label: {
              Label(
                "All Sessions",
                systemImage: selectedFilter == .allSessions ? "checkmark" : "list.bullet")
            }

            // Delete all sessions
            Button(role: .destructive) {
              showDeleteAllConfirmation = true
            } label: {
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
      }
      .sheet(item: $selectedSession) { session in
        SessionDetailsView(session: session)
      }
      .sheet(isPresented: $showingWeekPicker) {
        InsightsWeekPickerView(selectedDate: weeklyViewModel.selectedDate) { date in
          selectedFilter = .specificWeek
          weeklyViewModel.setWeek(for: date)
          clearDaySelection()
        }
        .presentationDetents([.medium])
      }
      .sheet(isPresented: $showingMonthPicker) {
        InsightsMonthPickerView(selectedDate: monthlyViewModel.selectedDate) { date in
          selectedFilter = .specificMonth
          monthlyViewModel.setMonth(for: date)
          clearDaySelection()
        }
        .presentationDetents([.medium])
      }
      .alert(item: $alertIdentifier) { alert in
        switch alert.id {
        case .deleteSession:
          guard let session = alert.session else {
            return Alert(title: Text("Error"))
          }

          return Alert(
            title: Text("Delete Session"),
            message: Text(
              "Are you sure you want to delete this session? This action cannot be undone."),
            primaryButton: .cancel(),
            secondaryButton: .destructive(Text("Delete")) {
              deleteSession(session)
            }
          )
        case .error:
          return Alert(
            title: Text("Error"),
            message: Text(alert.errorMessage ?? "An unknown error occurred"),
            dismissButton: .default(Text("OK"))
          )
        }
      }
      .alert("Delete All Sessions", isPresented: $showDeleteAllConfirmation) {
        Button("Cancel", role: .cancel) {}
        Button("Delete All", role: .destructive) {
          deleteAllSessions()
        }
      } message: {
        Text(
          "Are you sure you want to delete all completed sessions? This action cannot be undone.")
      }
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

  private func clearDaySelection() {
    selectedWeekDay = nil
    selectedMonthDay = nil
  }

  private func deleteSession(_ session: BlockedProfileSession) {
    modelContext.delete(session)

    do {
      try modelContext.save()
      if selectedSession?.id == session.id {
        selectedSession = nil
      }
    } catch {
      alertIdentifier = InsightsAlertIdentifier(
        id: .error, errorMessage: error.localizedDescription)
    }
  }

  private func deleteAllSessions() {
    for session in allProfileSessions {
      modelContext.delete(session)
    }
    do {
      try modelContext.save()
      selectedSession = nil
    } catch {
      alertIdentifier = InsightsAlertIdentifier(
        id: .error, errorMessage: error.localizedDescription)
    }
  }
}

#Preview {
  struct PreviewWrapper: View {
    let container: ModelContainer
    let profile: BlockedProfiles

    init() {
      do {
        container = try ModelContainer(for: BlockedProfiles.self, BlockedProfileSession.self)
      } catch {
        fatalError("Failed to create preview container: \(error)")
      }

      let context = container.mainContext
      let profile = BlockedProfiles(name: "Work Focus")
      context.insert(profile)

      let calendar = Calendar.current
      let weekStart = WeeklySessionAggregator.startOfWeek(for: Date(), calendar: calendar)

      for dayOffset in 0..<6 {
        let day = calendar.date(byAdding: .day, value: dayOffset, to: weekStart)!
        let session = BlockedProfileSession(
          tag: "Focus Block \(dayOffset + 1)", blockedProfile: profile)
        session.startTime = calendar.date(byAdding: .hour, value: 9 + dayOffset, to: day)!
        session.endTime = calendar.date(
          byAdding: .minute, value: 50 + dayOffset * 5, to: session.startTime)!
        context.insert(session)
      }

      self.profile = profile
    }

    var body: some View {
      ProfileInsightsView(profile: profile)
        .environmentObject(ThemeManager.shared)
        .modelContainer(container)
    }
  }

  return PreviewWrapper()
}
