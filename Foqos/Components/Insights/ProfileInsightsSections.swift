import SwiftUI

struct ProfileInsightsSections: View {
  @ObservedObject var weeklyViewModel: WeeklyInsightsUtil
  @ObservedObject var monthlyViewModel: MonthlyInsightsUtil
  @Binding var selectedWeekDay: WeeklyDayAggregate?
  @Binding var selectedMonthDay: MonthlyDayAggregate?

  let viewMode: InsightsViewMode
  let sessions: [BlockedProfileSession]
  let sessionsSectionTitle: String
  let showsSummary: Bool
  let totalFocusTime: TimeInterval
  let totalBreakTime: TimeInterval
  let profileId: UUID
  let onSelectSession: (BlockedProfileSession) -> Void
  let onDeleteSession: (BlockedProfileSession) -> Void

  var body: some View {
    if viewMode != .allSessions {
      Section {
        if viewMode == .week {
          WeeklySessionChart(
            viewModel: weeklyViewModel, selectedDay: $selectedWeekDay, onDateSelected: nil
          )
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.vertical, 8)
          .listRowInsets(EdgeInsets(top: 12, leading: 4, bottom: 0, trailing: 4))
          .listRowBackground(Color.clear)
        } else {
          MonthlySessionChart(
            viewModel: monthlyViewModel, selectedDay: $selectedMonthDay, onDateSelected: nil
          )
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.vertical, 8)
          .listRowInsets(EdgeInsets(top: 12, leading: 4, bottom: 0, trailing: 4))
          .listRowBackground(Color.clear)
        }
      }
    }

    if !sessions.isEmpty {
      Section(sessionsSectionTitle) {
        ForEach(sessions) { session in
          Button {
            onSelectSession(session)
          } label: {
            SessionRow(session: session)
          }
          .buttonStyle(.plain)
          .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
              onDeleteSession(session)
            } label: {
              Label("Delete", systemImage: "trash")
            }
          }
        }
      }
    }

    if showsSummary {
      Section("Summary") {
        InsightsSummaryRow(
          icon: "clock.fill",
          label: "Total Focus Time",
          value: DateFormatters.formatDurationHoursMinutes(
            totalFocusTime)
        )

        InsightsSummaryRow(
          icon: "cup.and.saucer.fill",
          label: "Total Break Time",
          value: DateFormatters.formatDurationHoursMinutes(
            totalBreakTime)
        )

        InsightsSummaryRow(
          icon: "tag.fill",
          label: "Profile ID",
          value: String(profileId.uuidString.prefix(8)) + "..."
        )
      }
    }
  }
}
