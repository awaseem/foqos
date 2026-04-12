import FamilyControls
import SwiftData
import SwiftUI

enum HabitChartType: String, CaseIterable {
  case fourWeek = "4 Week Activity"
  case weekly = "Weekly View"
  case monthly = "Monthly View"

  var icon: String {
    switch self {
    case .fourWeek:
      return "calendar.day.timeline.left"
    case .weekly:
      return "calendar.badge.clock"
    case .monthly:
      return "calendar"
    }
  }

  var description: String {
    switch self {
    case .fourWeek:
      return "View your last 28 days of focus time in a heatmap calendar"
    case .weekly:
      return "See your week-by-week focus patterns with bar charts"
    case .monthly:
      return "Track your monthly progress with a calendar grid"
    }
  }
}

struct BlockedSessionsHabitTracker: View {
  @EnvironmentObject var themeManager: ThemeManager

  let sessions: [BlockedProfileSession]
  let profiles: [BlockedProfiles]
  let onInsightsTapped: (DashboardInsightsContext) -> Void

  @State private var selectedDate: Date?
  @State private var selectedDateProfiles: [DashboardProfileActivity] = []

  @StateObject private var weeklyViewModel: WeeklyInsightsUtil
  @State private var selectedWeekDay: WeeklyDayAggregate?

  @StateObject private var monthlyViewModel: MonthlyInsightsUtil
  @State private var selectedMonthDay: MonthlyDayAggregate?

  @AppStorage("showHabitTracker") private var showHabitTracker = true
  @AppStorage("habitChartType") private var chartTypeRaw = HabitChartType.fourWeek.rawValue
  @State private var showingConfiguration = false

  private var chartType: HabitChartType {
    get { HabitChartType(rawValue: chartTypeRaw) ?? .fourWeek }
    set { chartTypeRaw = newValue.rawValue }
  }

  private var chartTypeBinding: Binding<HabitChartType> {
    Binding(
      get: { chartType },
      set: { chartTypeRaw = $0.rawValue }
    )
  }

  init(
    sessions: [BlockedProfileSession],
    profiles: [BlockedProfiles],
    onInsightsTapped: @escaping (DashboardInsightsContext) -> Void
  ) {
    self.sessions = sessions
    self.profiles = profiles
    self.onInsightsTapped = onInsightsTapped
    _weeklyViewModel = StateObject(wrappedValue: WeeklyInsightsUtil(profiles: profiles))
    _monthlyViewModel = StateObject(wrappedValue: MonthlyInsightsUtil(profiles: profiles))
  }

  private func handleDateSelection(_ date: Date) {
    let isCurrentlySelected = selectedDate == date

    if isCurrentlySelected {
      clearAllSelections()
    } else {
      selectedDate = date
      selectedDateProfiles = DashboardActivityUtil.computeProfileActivities(
        for: date, profiles: profiles)
    }
  }

  private func handleWeeklyDateSelection(_ date: Date?) {
    if let date = date {
      selectedDate = date
      selectedDateProfiles = DashboardActivityUtil.computeProfileActivities(
        for: date, profiles: profiles)
    } else {
      clearDashboardState()
    }
  }

  private func handleMonthlyDateSelection(_ date: Date?) {
    if let date = date {
      selectedDate = date
      selectedDateProfiles = DashboardActivityUtil.computeProfileActivities(
        for: date, profiles: profiles)
    } else {
      clearDashboardState()
    }
  }

  private func clearDashboardState() {
    selectedDate = nil
    selectedDateProfiles = []
  }

  private func clearAllSelections() {
    selectedDate = nil
    selectedWeekDay = nil
    selectedMonthDay = nil
    selectedDateProfiles = []
  }

  @ViewBuilder
  private var chartContent: some View {
    switch chartType {
    case .fourWeek:
      FourWeekHeatmapView(
        sessions: sessions,
        selectedDate: selectedDate,
        onDateSelected: handleDateSelection
      )
    case .weekly:
      WeeklySessionChart(
        viewModel: weeklyViewModel,
        selectedDay: $selectedWeekDay,
        onDateSelected: handleWeeklyDateSelection
      )
    case .monthly:
      MonthlySessionChart(
        viewModel: monthlyViewModel,
        selectedDay: $selectedMonthDay,
        onDateSelected: handleMonthlyDateSelection
      )
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(alignment: .center) {
        SectionTitle(
          "Activity",
          buttonText: "Manage",
          buttonAction: { showingConfiguration = true },
          buttonIcon: "chart.line.uptrend.xyaxis"
        )
      }

      ZStack {
        if showHabitTracker {
          RoundedRectangle(cornerRadius: 24)
            .fill(Color(.systemBackground))

          VStack(alignment: .leading, spacing: 0) {
            chartContent
              .padding(chartType == .fourWeek ? 0 : 16)

            if !selectedDateProfiles.isEmpty, let date = selectedDate {
              let viewMode: InsightsViewMode = {
                switch chartType {
                case .weekly, .fourWeek:
                  return .week
                case .monthly:
                  return .month
                }
              }()

              ProfileActivityView(
                selectedDate: date,
                activities: selectedDateProfiles,
                viewMode: viewMode,
                onInsightsTapped: onInsightsTapped
              )
            }
          }
        }
      }
      .overlay(
        RoundedRectangle(cornerRadius: 24)
          .stroke(Color.gray.opacity(0.3), lineWidth: 1)
      )
      .animation(.easeInOut(duration: 0.3), value: showHabitTracker)
      .animation(.easeInOut(duration: 0.3), value: chartType)
      .frame(height: showHabitTracker ? nil : 0, alignment: .top)
      .clipped()
      .sheet(isPresented: $showingConfiguration) {
        ChartConfigurationSheet(
          showHabitTracker: $showHabitTracker,
          chartType: chartTypeBinding,
          onDismiss: { showingConfiguration = false }
        )
        .presentationDetents([.medium])
      }
    }
  }
}

#Preview {
  let profile1 = BlockedProfiles(name: "Deep Work", selectedActivity: FamilyActivitySelection())
  let profile2 = BlockedProfiles(
    name: "Social Media Block", selectedActivity: FamilyActivitySelection())
  let profile3 = BlockedProfiles(name: "Gaming Focus", selectedActivity: FamilyActivitySelection())

  let calendar = Calendar.current
  let now = Date()

  let session1 = BlockedProfileSession(tag: "morning-focus", blockedProfile: profile1)
  session1.startTime = calendar.date(byAdding: .day, value: -3, to: now)!
  session1.endTime = calendar.date(byAdding: .hour, value: 2, to: session1.startTime)

  let session2 = BlockedProfileSession(tag: "weekend-detox", blockedProfile: profile2)
  session2.startTime = calendar.date(byAdding: .day, value: -2, to: calendar.startOfDay(for: now))!
  session2.startTime = calendar.date(byAdding: .hour, value: 22, to: session2.startTime)!
  session2.endTime = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: now))!
  session2.endTime = calendar.date(byAdding: .hour, value: 8, to: session2.endTime!)

  let session3 = BlockedProfileSession(tag: "afternoon-work", blockedProfile: profile3)
  session3.startTime = calendar.date(byAdding: .day, value: -1, to: now)!
  session3.startTime = calendar.date(byAdding: .hour, value: -10, to: session3.startTime)!
  session3.endTime = calendar.date(byAdding: .hour, value: 4, to: session3.startTime)

  let exampleSessions = [session1, session2, session3]
  let exampleProfiles = [profile1, profile2, profile3]

  return BlockedSessionsHabitTracker(
    sessions: exampleSessions,
    profiles: exampleProfiles,
    onInsightsTapped: { _ in }
  )
  .environmentObject(ThemeManager.shared)
}
