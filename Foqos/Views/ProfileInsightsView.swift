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

private enum InsightsWeekFilter: Equatable {
  case thisWeek
  case lastWeek
  case specific
}

struct ProfileInsightsView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext
  @EnvironmentObject private var themeManager: ThemeManager

  @StateObject private var viewModel: WeeklyProfileInsightsUtil
  @State private var selectedDay: WeeklyDayAggregate?
  @State private var selectedSession: BlockedProfileSession?
  @State private var alertIdentifier: InsightsAlertIdentifier?
  @State private var showingWeekPicker = false
  @State private var selectedWeekFilter: InsightsWeekFilter = .thisWeek

  @Query(sort: \BlockedProfileSession.startTime, order: .reverse)
  private var allSessions: [BlockedProfileSession]

  init(profile: BlockedProfiles) {
    _viewModel = StateObject(wrappedValue: WeeklyProfileInsightsUtil(profile: profile))
  }

  private var weekSummary: WeeklySummary {
    viewModel.weeklySummary
  }

  private var weekSessions: [BlockedProfileSession] {
    allSessions.filter { session in
      guard session.blockedProfile.id == viewModel.profile.id, let endTime = session.endTime else {
        return false
      }

      return session.startTime < weekEndExclusive && endTime > weekStart
    }
  }

  private var filteredSessions: [BlockedProfileSession] {
    guard let selectedDay else {
      return weekSessions
    }

    let dayStart = Calendar.current.startOfDay(for: selectedDay.date)
    let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart

    return weekSessions.filter { session in
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

  private var sessionsSectionTitle: String {
    if let selectedDay {
      return "Sessions for \(DateFormatters.formatSelectedDayHeader(selectedDay.date))"
    }

    return "Sessions"
  }

  var body: some View {
    NavigationStack {
      List {
        Section {
          WeeklySessionChart(viewModel: viewModel, selectedDay: $selectedDay)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
            .listRowInsets(EdgeInsets(top: 12, leading: 4, bottom: 0, trailing: 4))
            .listRowBackground(Color.clear)
        }

        if filteredSessions.isEmpty {
          emptyState
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
            Button {
              selectedWeekFilter = .thisWeek
              selectedDay = nil
              viewModel.setWeek(for: Date())
            } label: {
              Label("This Week", systemImage: selectedWeekFilter == .thisWeek ? "checkmark" : "")
            }
            
            Button {
              selectedWeekFilter = .lastWeek
              selectedDay = nil
              if let lastWeek = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date()) {
                viewModel.setWeek(for: lastWeek)
              }
            } label: {
              Label("Last Week", systemImage: selectedWeekFilter == .lastWeek ? "checkmark" : "")
            }
            
            Button {
              showingWeekPicker = true
            } label: {
              Label("Select Date...", systemImage: selectedWeekFilter == .specific ? "checkmark" : "")
            }
          } label: {
            HStack(spacing: 4) {
              Image(systemName: "calendar")
              Text(weekFilterMenuTitle)
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
        InsightsWeekPickerView(selectedDate: viewModel.selectedDate) { date in
          selectedWeekFilter = .specific
          viewModel.setWeek(for: date)
          selectedDay = nil
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
    }
  }

  private var emptyState: some View {
    VStack(spacing: 10) {
      Image(systemName: "chart.bar.xaxis")
        .font(.system(size: 28))
        .foregroundStyle(.secondary)

      Text(selectedDay == nil ? "No sessions this week" : "No sessions on this day")
        .font(.headline)
        .foregroundStyle(.secondary)

      Text(
        selectedDay == nil
          ? "Completed sessions from this week will appear here."
          : "Try another day or clear the filter to see the full week."
      )
      .font(.subheadline)
      .foregroundStyle(.secondary)
      .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 40)
    .listRowBackground(Color.clear)
  }

  private var weekFilterMenuTitle: String {
    switch selectedWeekFilter {
    case .thisWeek:
      return "This Week"
    case .lastWeek:
      return "Last Week"
    case .specific:
      return formatWeekRange(start: weekSummary.weekStartDate, end: weekSummary.weekEndDate)
    }
  }

  private func formatWeekRange(start: Date, end: Date) -> String {
    let calendar = Calendar.current
    let sameMonth = calendar.component(.month, from: start) == calendar.component(.month, from: end)
    let sameYear = calendar.component(.year, from: start) == calendar.component(.year, from: end)

    if sameMonth && sameYear {
      let month = start.formatted(.dateTime.month(.abbreviated))
      let startDay = calendar.component(.day, from: start)
      let endDay = calendar.component(.day, from: end)
      return "\(month) \(startDay) - \(endDay)"
    }

    if sameYear {
      return start.formatted(.dateTime.month(.abbreviated).day()) + " - "
        + end.formatted(.dateTime.month(.abbreviated).day().year())
    }

    return start.formatted(.dateTime.month(.abbreviated).day().year()) + " - "
      + end.formatted(.dateTime.month(.abbreviated).day().year())
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
}

private struct InsightsWeekPickerView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var draftDate: Date

  let onApply: (Date) -> Void

  init(selectedDate: Date, onApply: @escaping (Date) -> Void) {
    _draftDate = State(initialValue: selectedDate)
    self.onApply = onApply
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        DatePicker("", selection: $draftDate, displayedComponents: .date)
          .datePickerStyle(.graphical)
          .labelsHidden()
      }
      .onChange(of: draftDate) { _, newValue in
        onApply(newValue)
        dismiss()
      }
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
