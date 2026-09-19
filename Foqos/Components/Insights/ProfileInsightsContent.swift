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

struct ProfileInsightsContent: View {
  @Environment(\.modelContext) private var modelContext

  @StateObject private var weeklyViewModel: WeeklyInsightsUtil
  @StateObject private var monthlyViewModel: MonthlyInsightsUtil
  @StateObject private var profileInsightsViewModel: ProfileInsightsUtil
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

  @State private var initialViewMode: InsightsViewMode?
  @State private var initialSelectedDate: Date?
  @State private var hasAppliedInitialState = false
  private let profileName: String

  init(
    profile: BlockedProfiles,
    initialViewMode: InsightsViewMode? = nil,
    initialSelectedDate: Date? = nil
  ) {
    _weeklyViewModel = StateObject(wrappedValue: WeeklyInsightsUtil(profiles: [profile]))
    _monthlyViewModel = StateObject(wrappedValue: MonthlyInsightsUtil(profiles: [profile]))
    _profileInsightsViewModel = StateObject(wrappedValue: ProfileInsightsUtil(profile: profile))
    _initialViewMode = State(wrappedValue: initialViewMode)
    _initialSelectedDate = State(wrappedValue: initialSelectedDate)
    self.profileName = profile.name
  }

  private var weekSummary: WeeklySummary {
    weeklyViewModel.weeklySummary
  }

  private var monthSummary: MonthlySummary {
    monthlyViewModel.monthlySummary
  }

  private var profileId: UUID {
    weeklyViewModel.profiles.first?.id ?? UUID()
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
    List {
      ProfileInsightsSections(
        weeklyViewModel: weeklyViewModel,
        monthlyViewModel: monthlyViewModel,
        selectedWeekDay: $selectedWeekDay,
        selectedMonthDay: $selectedMonthDay,
        viewMode: viewMode,
        sessions: filteredSessions,
        sessionsSectionTitle: sessionsSectionTitle,
        showsSummary: selectedDay == nil,
        totalFocusTime: profileInsightsViewModel.metrics.totalFocusTime,
        totalBreakTime: profileInsightsViewModel.metrics.totalBreakTime,
        profileId: profileId,
        onSelectSession: { selectedSession = $0 },
        onDeleteSession: {
          alertIdentifier = InsightsAlertIdentifier(id: .deleteSession, session: $0)
        }
      )
    }
    .navigationTitle("\(profileName) Insights")
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        ProfileInsightsFilterMenu(
          selectedFilter: selectedFilter,
          viewMode: viewMode,
          weekSummary: weekSummary,
          monthSummary: monthSummary,
          onSelectFilter: selectFilter,
          onSelectDate: presentDatePicker,
          onDeleteAll: { showDeleteAllConfirmation = true }
        )
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
      .presentationDetents([.medium, .large])
    }
    .sheet(isPresented: $showingMonthPicker) {
      InsightsMonthPickerView(selectedDate: monthlyViewModel.selectedDate) { date in
        selectedFilter = .specificMonth
        monthlyViewModel.setMonth(for: date)
        clearDaySelection()
      }
      .presentationDetents([.medium, .large])
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
    .task {
      await applyInitialState()
    }
  }

  private func applyInitialState() async {
    guard !hasAppliedInitialState,
      let viewMode = initialViewMode,
      let date = initialSelectedDate
    else { return }

    hasAppliedInitialState = true

    switch viewMode {
    case .week:
      selectedFilter = .specificWeek
      weeklyViewModel.setWeek(for: date)
      // Wait a moment for the view model to update
      try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1 seconds
      // Find and select the matching day
      if let matchingDay = weeklyViewModel.weeklySummary.days.first(where: {
        Calendar.current.isDate($0.date, inSameDayAs: date)
      }) {
        selectedWeekDay = matchingDay
      }
    case .month:
      selectedFilter = .specificMonth
      monthlyViewModel.setMonth(for: date)
      // Wait a moment for the view model to update
      try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1 seconds
      // Find and select the matching day
      if let matchingDay = monthlyViewModel.monthlySummary.days.first(where: {
        Calendar.current.isDate($0.date, inSameDayAs: date)
      }) {
        selectedMonthDay = matchingDay
      }
    case .allSessions:
      selectedFilter = .allSessions
    }
  }

  private func selectFilter(_ filter: InsightsFilter) {
    selectedFilter = filter
    clearDaySelection()

    switch filter {
    case .thisWeek:
      weeklyViewModel.setWeek(for: Date())
    case .lastWeek:
      if let date = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date()) {
        weeklyViewModel.setWeek(for: date)
      }
    case .thisMonth:
      monthlyViewModel.setMonth(for: Date())
    case .lastMonth:
      if let date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) {
        monthlyViewModel.setMonth(for: date)
      }
    case .specificWeek, .specificMonth, .allSessions:
      break
    }
  }

  private func presentDatePicker() {
    switch viewMode {
    case .week:
      showingWeekPicker = true
    case .month:
      showingMonthPicker = true
    case .allSessions:
      break
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
