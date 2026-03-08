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
  let onInsightsTapped: (BlockedProfiles) -> Void

  // 4-week view state
  @State private var selectedDate: Date?

  // Weekly chart state
  @StateObject private var weeklyViewModel: WeeklyInsightsUtil
  @State private var selectedWeekDay: WeeklyDayAggregate?

  // Monthly chart state
  @StateObject private var monthlyViewModel: MonthlyInsightsUtil
  @State private var selectedMonthDay: MonthlyDayAggregate?

  // Profile activity state
  @State private var selectedDateProfiles: [DashboardProfileActivity] = []
  @State private var showingProfileActivity = false

  // Settings
  @AppStorage("showHabitTracker") private var showHabitTracker = true
  @AppStorage("habitChartType") private var chartTypeRaw = HabitChartType.fourWeek.rawValue
  @State private var showingConfiguration = false

  private var chartType: HabitChartType {
    get { HabitChartType(rawValue: chartTypeRaw) ?? .fourWeek }
    set { chartTypeRaw = newValue.rawValue }
  }

  // Number of days to show in the tracker
  private let daysToShow = 28  // 4 weeks (7 days x 4)

  init(
    sessions: [BlockedProfileSession],
    profiles: [BlockedProfiles],
    onInsightsTapped: @escaping (BlockedProfiles) -> Void
  ) {
    self.sessions = sessions
    self.profiles = profiles
    self.onInsightsTapped = onInsightsTapped
    _weeklyViewModel = StateObject(wrappedValue: WeeklyInsightsUtil(profiles: profiles))
    _monthlyViewModel = StateObject(wrappedValue: MonthlyInsightsUtil(profiles: profiles))
  }

  // MARK: - 4-Week View Helpers

  private func sessionHoursForDate(_ date: Date) -> Double {
    let calendar = Calendar.current
    let dayStart = calendar.startOfDay(for: date)
    guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { return 0 }

    let totalSeconds = sessions.reduce(0.0) { total, session in
      let sessionStart = session.startTime
      let sessionEnd = session.endTime ?? Date()
      let overlapStart = max(sessionStart, dayStart)
      let overlapEnd = min(sessionEnd, dayEnd)
      let overlapDuration = max(0, overlapEnd.timeIntervalSince(overlapStart))
      return total + overlapDuration
    }

    return totalSeconds / 3600
  }

  private func sessionsForDate(_ date: Date) -> [BlockedProfileSession] {
    let calendar = Calendar.current
    let dayStart = calendar.startOfDay(for: date)
    guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { return [] }

    return sessions.filter { session in
      let sessionStart = session.startTime
      let sessionEnd = session.endTime ?? Date()
      return sessionStart < dayEnd && sessionEnd > dayStart
    }.sorted { $0.duration > $1.duration }
  }

  private func dates() -> [Date] {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())

    return (0..<daysToShow).map { day in
      calendar.date(byAdding: .day, value: -day, to: today)!
    }.reversed()
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

  private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d, yyyy"
    return formatter.string(from: date)
  }

  private func formatDay(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "d"
    return formatter.string(from: date)
  }

  private var legendData: [(String, Double)] {
    [("<1h", 0.3), ("1-3h", 0.5), ("3-5h", 0.7), (">5h", 0.9)]
  }

  private var weeklyDates: [[Date]] {
    let allDates = dates()
    return stride(from: 0, to: allDates.count, by: 7).map { startIndex in
      let endIndex = min(startIndex + 7, allDates.count)
      return Array(allDates[startIndex..<endIndex])
    }
  }

  // MARK: - Profile Activity Computation

  private func computeProfileActivities(for date: Date) -> [DashboardProfileActivity] {
    let calendar = Calendar.current
    let dayStart = calendar.startOfDay(for: date)
    guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { return [] }

    var activities: [DashboardProfileActivity] = []

    for profile in profiles {
      let profileSessions = profile.sessions.filter { session in
        guard let endTime = session.endTime else { return false }
        return session.startTime < dayEnd && endTime > dayStart
      }

      guard !profileSessions.isEmpty else { continue }

      let totalTime = profileSessions.reduce(0.0) { total, session in
        let sessionStart = session.startTime
        let sessionEnd = session.endTime ?? Date()
        let overlapStart = max(sessionStart, dayStart)
        let overlapEnd = min(sessionEnd, dayEnd)
        return total + max(0, overlapEnd.timeIntervalSince(overlapStart))
      }

      activities.append(
        DashboardProfileActivity(
          profile: profile,
          totalTime: totalTime,
          sessionCount: profileSessions.count
        ))
    }

    return activities.sorted { $0.totalTime > $1.totalTime }
  }

  // MARK: - Date Selection Handlers

  private func handleDateSelection(_ date: Date) {
    let isCurrentlySelected = selectedDate == date

    if isCurrentlySelected {
      // Deselect if tapping the same date
      clearAllSelections()
    } else {
      // Select new date - only update dashboard state, not chart selections
      selectedDate = date
      selectedDateProfiles = computeProfileActivities(for: date)
      showingProfileActivity = !selectedDateProfiles.isEmpty
    }
  }

  private func handleWeeklyDateSelection(_ date: Date?) {
    if let date = date {
      selectedDate = date
      selectedDateProfiles = computeProfileActivities(for: date)
      showingProfileActivity = !selectedDateProfiles.isEmpty
    } else {
      // Chart was cleared - clear dashboard state too
      selectedDate = nil
      selectedDateProfiles = []
      showingProfileActivity = false
    }
  }

  private func handleMonthlyDateSelection(_ date: Date?) {
    if let date = date {
      selectedDate = date
      selectedDateProfiles = computeProfileActivities(for: date)
      showingProfileActivity = !selectedDateProfiles.isEmpty
    } else {
      // Chart was cleared - clear dashboard state too
      selectedDate = nil
      selectedDateProfiles = []
      showingProfileActivity = false
    }
  }

  private func clearAllSelections() {
    selectedDate = nil
    selectedWeekDay = nil
    selectedMonthDay = nil
    selectedDateProfiles = []
    showingProfileActivity = false
  }

  // MARK: - Chart Content Views

  @ViewBuilder
  private var chartContent: some View {
    switch chartType {
    case .fourWeek:
      fourWeekChartView
    case .weekly:
      WeeklySessionChart(
        viewModel: weeklyViewModel,
        selectedDay: $selectedWeekDay,
        onDateSelected: { date in
          handleWeeklyDateSelection(date)
        }
      )
    case .monthly:
      MonthlySessionChart(
        viewModel: monthlyViewModel,
        selectedDay: $selectedMonthDay,
        onDateSelected: { date in
          handleMonthlyDateSelection(date)
        }
      )
    }
  }

  private var fourWeekChartView: some View {
    VStack(alignment: .leading, spacing: 12) {
      legendView()

      LazyVStack(spacing: 8) {
        ForEach(weeklyDates.indices, id: \.self) { weekIndex in
          weekRowView(for: weeklyDates[weekIndex])
        }
      }
      .frame(maxWidth: .infinity)
    }
    .padding(16)
  }

  // MARK: - 4-Week Subviews

  private func legendView() -> some View {
    HStack {
      Spacer()
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
  }

  private func daySquareView(for date: Date) -> some View {
    let hours = sessionHoursForDate(date)
    let isSelected = selectedDate == date

    return VStack(spacing: 2) {
      Text(formatDay(date))
        .font(.system(size: 10))
        .foregroundColor(.secondary)

      Rectangle()
        .fill(colorForHours(hours))
        .aspectRatio(1, contentMode: .fit)
        .cornerRadius(4)
        .overlay(
          RoundedRectangle(cornerRadius: 4)
            .stroke(
              isSelected ? themeManager.themeColor : Color.clear,
              lineWidth: 2
            )
        )
        .onTapGesture {
          handleDateSelection(date)
        }
        .contentShape(Rectangle())
    }
  }

  private func weekRowView(for week: [Date]) -> some View {
    HStack(spacing: 4) {
      ForEach(week, id: \.timeIntervalSince1970) { date in
        daySquareView(for: date)
      }
    }
    .frame(maxWidth: .infinity)
  }

  // MARK: - Profile Activity View

  private var profileActivityView: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        if let date = selectedDate {
          Text(formatDate(date))
            .font(.subheadline)
            .fontWeight(.medium)
        }

        Spacer()

        Button {
          clearAllSelections()
        } label: {
          Image(systemName: "arrow.counterclockwise")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
      }

      if selectedDateProfiles.isEmpty {
        Text("No profiles active on this day")
          .font(.caption)
          .foregroundColor(.secondary)
      } else {
        VStack(alignment: .leading, spacing: 8) {
          ForEach(selectedDateProfiles) { activity in
            profileActivityRow(for: activity)

            if activity.id != selectedDateProfiles.last?.id {
              Divider()
            }
          }
        }
      }
    }
    .padding(.top, 8)
    .padding(.horizontal, 16)
    .padding(.bottom, 16)
    .transition(.move(edge: .bottom).combined(with: .opacity))
    .animation(.easeInOut, value: showingProfileActivity)
  }

  private func profileActivityRow(for activity: DashboardProfileActivity) -> some View {
    HStack(spacing: 12) {
      // Profile name
      Text(activity.profile.name)
        .font(.subheadline)
        .fontWeight(.medium)
        .foregroundColor(.primary)

      Spacer()

      // Time
      Text(DateFormatters.formatDurationShort(activity.totalTime))
        .font(.subheadline)
        .fontWeight(.medium)
        .foregroundColor(.secondary)

      // Insights button
      Button {
        onInsightsTapped(activity.profile)
      } label: {
        HStack(spacing: 4) {
          Text("Insights")
            .font(.caption)
            .fontWeight(.medium)
          Image(systemName: "chart.line.uptrend.xyaxis")
            .font(.caption)
        }
        .foregroundStyle(themeManager.themeColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
          Capsule()
            .fill(themeManager.themeColor.opacity(0.15))
        )
      }
      .buttonStyle(.plain)
    }
    .padding(.vertical, 4)
  }

  // MARK: - Configuration Sheet

  private var configurationSheet: some View {
    NavigationStack {
      List {
        Section("Visibility") {
          Toggle("Show Chart", isOn: $showHabitTracker)
            .tint(themeManager.themeColor)
        }

        Section("Chart Type") {
          ForEach(HabitChartType.allCases, id: \.self) { type in
            Button {
              chartTypeRaw = type.rawValue
            } label: {
              HStack(alignment: .top, spacing: 12) {
                // Radio button indicator
                ZStack {
                  Circle()
                    .stroke(chartType == type ? themeManager.themeColor : Color.gray.opacity(0.4), lineWidth: 2)
                    .frame(width: 22, height: 22)

                  if chartType == type {
                    Circle()
                      .fill(themeManager.themeColor)
                      .frame(width: 12, height: 12)
                  }
                }
                .padding(.top, 2)

                // Icon and text content
                VStack(alignment: .leading, spacing: 4) {
                  HStack(spacing: 8) {
                    Image(systemName: type.icon)
                      .foregroundStyle(themeManager.themeColor)
                      .font(.system(size: 16))

                    Text(type.rawValue)
                      .font(.system(size: 16, weight: .medium))
                      .foregroundStyle(.primary)
                  }

                  Text(type.description)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
              }
              .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
            .listRowSeparator(.hidden)
          }
        }
      }
      .navigationTitle("Dashboard Insights")
      .navigationBarTitleDisplayMode(.inline)
    }
  }

  // MARK: - Main Body

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
            if chartType == .fourWeek {
              fourWeekChartView
            } else {
              VStack(alignment: .leading, spacing: 12) {
                chartContent
                  .padding(16)
              }
            }

            if showingProfileActivity {
              profileActivityView
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
        configurationSheet
          .presentationDetents([.medium])
      }
    }
  }
}

#Preview {
  // Create example blocked profiles
  let profile1 = BlockedProfiles(
    name: "Deep Work",
    selectedActivity: FamilyActivitySelection()
  )

  let profile2 = BlockedProfiles(
    name: "Social Media Block",
    selectedActivity: FamilyActivitySelection()
  )

  let profile3 = BlockedProfiles(
    name: "Gaming Focus",
    selectedActivity: FamilyActivitySelection()
  )

  // Create example sessions with multi-day scenarios
  let calendar = Calendar.current
  let now = Date()

  // Session 1: Short session from 3 days ago
  let session1 = BlockedProfileSession(tag: "morning-focus", blockedProfile: profile1)
  session1.startTime = calendar.date(byAdding: .day, value: -3, to: now)!
  session1.endTime = calendar.date(byAdding: .hour, value: 2, to: session1.startTime)

  // Session 2: Multi-day session starting 2 days ago, ending yesterday
  let session2 = BlockedProfileSession(tag: "weekend-detox", blockedProfile: profile2)
  session2.startTime = calendar.date(byAdding: .day, value: -2, to: calendar.startOfDay(for: now))!
  session2.startTime = calendar.date(byAdding: .hour, value: 22, to: session2.startTime)!
  session2.endTime = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: now))!
  session2.endTime = calendar.date(byAdding: .hour, value: 8, to: session2.endTime!)

  // Session 3: Another session yesterday
  let session3 = BlockedProfileSession(tag: "afternoon-work", blockedProfile: profile3)
  session3.startTime = calendar.date(byAdding: .day, value: -1, to: now)!
  session3.startTime = calendar.date(byAdding: .hour, value: -10, to: session3.startTime)!
  session3.endTime = calendar.date(byAdding: .hour, value: 4, to: session3.startTime)

  // Session 4: Long multi-day session spanning 3 days (started 5 days ago, ended 2 days ago)
  let session4 = BlockedProfileSession(tag: "extended-focus", blockedProfile: profile1)
  session4.startTime = calendar.date(byAdding: .day, value: -5, to: calendar.startOfDay(for: now))!
  session4.startTime = calendar.date(byAdding: .hour, value: 14, to: session4.startTime)!
  session4.endTime = calendar.date(byAdding: .day, value: -2, to: calendar.startOfDay(for: now))!
  session4.endTime = calendar.date(byAdding: .hour, value: 10, to: session4.endTime!)

  // Session 5: Short session today
  let session5 = BlockedProfileSession(tag: "morning-routine", blockedProfile: profile2)
  session5.startTime = calendar.date(byAdding: .hour, value: -3, to: now)!
  session5.endTime = calendar.date(byAdding: .hour, value: 1, to: session5.startTime)

  // Session 6: Currently active session (no end time)
  let session6 = BlockedProfileSession(tag: "current-focus", blockedProfile: profile3)
  session6.startTime = calendar.date(byAdding: .hour, value: -1, to: now)!
  // No end time = currently active

  // Session 7: Another multi-day session from a week ago
  let session7 = BlockedProfileSession(tag: "weekly-detox", blockedProfile: profile2)
  session7.startTime = calendar.date(byAdding: .day, value: -7, to: calendar.startOfDay(for: now))!
  session7.startTime = calendar.date(byAdding: .hour, value: 20, to: session7.startTime)!
  session7.endTime = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: now))!
  session7.endTime = calendar.date(byAdding: .hour, value: 12, to: session7.endTime!)

  let exampleSessions = [session1, session2, session3, session4, session5, session6, session7]
  let exampleProfiles = [profile1, profile2, profile3]

  return BlockedSessionsHabitTracker(
    sessions: exampleSessions,
    profiles: exampleProfiles,
    onInsightsTapped: { _ in }
  )
  .environmentObject(ThemeManager.shared)
}
