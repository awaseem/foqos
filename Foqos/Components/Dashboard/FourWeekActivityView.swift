import SwiftData
import SwiftUI
import UIKit

struct FourWeekActivityView: View {
  @Environment(\.scenePhase) private var scenePhase

  let selectedDate: Date?
  let onDateSelected: (Date) -> Void

  @State private var dates = DashboardActivityUtil.dates(forDays: 28)

  var body: some View {
    Group {
      if let windowStart = dates.first {
        FourWeekSessionsView(
          windowStart: windowStart,
          dates: dates,
          selectedDate: selectedDate,
          onDateSelected: onDateSelected
        )
      }
    }
    .onAppear(perform: refreshDates)
    .onChange(of: scenePhase) { _, phase in
      if phase == .active {
        refreshDates()
      }
    }
    .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
      refreshDates()
    }
    .onReceive(NotificationCenter.default.publisher(for: .NSSystemTimeZoneDidChange)) { _ in
      refreshDates()
    }
    .onReceive(
      NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)
    ) { _ in
      refreshDates()
    }
  }

  private func refreshDates() {
    let updatedDates = DashboardActivityUtil.dates(forDays: 28)
    if dates != updatedDates {
      dates = updatedDates
    }
  }
}

private struct FourWeekSessionsView: View {
  @Query private var sessions: [BlockedProfileSession]

  let dates: [Date]
  let selectedDate: Date?
  let onDateSelected: (Date) -> Void

  init(
    windowStart: Date,
    dates: [Date],
    selectedDate: Date?,
    onDateSelected: @escaping (Date) -> Void
  ) {
    _sessions = Query(BlockedProfileSession.completedSessionsDescriptor(after: windowStart))
    self.dates = dates
    self.selectedDate = selectedDate
    self.onDateSelected = onDateSelected
  }

  var body: some View {
    FourWeekHeatmapView(
      sessions: sessions,
      dates: dates,
      selectedDate: selectedDate,
      onDateSelected: onDateSelected
    )
  }
}
