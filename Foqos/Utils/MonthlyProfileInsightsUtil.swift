import Foundation
import SwiftUI

struct MonthlyDayAggregate: Identifiable, Equatable {
  let id = UUID()
  let dayOfMonth: Int
  let dayName: String
  let totalSessionTime: TimeInterval
  let sessionCount: Int
  let date: Date

  var averageSessionDuration: TimeInterval {
    sessionCount > 0 ? totalSessionTime / Double(sessionCount) : 0
  }
}

struct MonthlySummary {
  let days: [MonthlyDayAggregate]
  let totalSessions: Int
  let averageSessionDuration: TimeInterval
  let totalFocusTime: TimeInterval
  let monthStartDate: Date
  let monthEndDate: Date
  let daysInMonth: Int
}

class MonthlyProfileInsightsUtil: ObservableObject {
  let profile: BlockedProfiles

  @Published var selectedDate: Date = Date()

  var monthlySummary: MonthlySummary {
    computeMonthlySummary(for: selectedDate)
  }

  init(profile: BlockedProfiles) {
    self.profile = profile
  }

  func setMonth(for date: Date) {
    selectedDate = date
  }

  func moveToPreviousMonth() {
    let calendar = Calendar.current
    if let previousMonth = calendar.date(byAdding: .month, value: -1, to: selectedDate) {
      selectedDate = previousMonth
    }
  }

  func moveToNextMonth() {
    let calendar = Calendar.current
    if let nextMonth = calendar.date(byAdding: .month, value: 1, to: selectedDate) {
      selectedDate = nextMonth
    }
  }

  func refresh() {
    objectWillChange.send()
  }

  func sessionsForDate(_ date: Date) -> [BlockedProfileSession] {
    let calendar = Calendar.current
    let dayStart = calendar.startOfDay(for: date)
    guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { return [] }

    return profile.sessions.filter { session in
      let sessionStart = session.startTime
      let sessionEnd = session.endTime ?? Date()
      return sessionStart < dayEnd && sessionEnd > dayStart
    }.sorted { $0.duration > $1.duration }
  }

  private func computeMonthlySummary(for date: Date) -> MonthlySummary {
    let calendar = Calendar.current

    let monthStart = MonthlySessionAggregator.startOfMonth(for: date, calendar: calendar)
    let daysInMonth = MonthlySessionAggregator.daysInMonth(for: date, calendar: calendar)
    let monthEnd = calendar.date(byAdding: .day, value: daysInMonth - 1, to: monthStart)!

    let completedSessions: [MonthlySessionInterval] = profile.sessions.compactMap { session in
      guard let endTime = session.endTime else { return nil }
      return MonthlySessionInterval(startTime: session.startTime, endTime: endTime)
    }

    let aggregation = MonthlySessionAggregator.aggregate(
      sessions: completedSessions,
      monthStart: monthStart,
      calendar: calendar
    )

    var dayAggregates: [MonthlyDayAggregate] = []
    let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    for dayOffset in 0..<daysInMonth {
      guard let currentDay = calendar.date(byAdding: .day, value: dayOffset, to: monthStart) else {
        continue
      }
      let weekday = calendar.component(.weekday, from: currentDay)
      let dayOfMonth = calendar.component(.day, from: currentDay)

      dayAggregates.append(
        MonthlyDayAggregate(
          dayOfMonth: dayOfMonth,
          dayName: dayNames[weekday - 1],
          totalSessionTime: aggregation.dailyDurations[dayOffset],
          sessionCount: aggregation.dailySessionCounts[dayOffset],
          date: currentDay
        ))
    }

    let totalSessions = aggregation.overlappingSessionCount
    let totalFocusTime = aggregation.totalFocusTime
    let averageSessionDuration = totalSessions > 0 ? totalFocusTime / Double(totalSessions) : 0

    return MonthlySummary(
      days: dayAggregates,
      totalSessions: totalSessions,
      averageSessionDuration: averageSessionDuration,
      totalFocusTime: totalFocusTime,
      monthStartDate: monthStart,
      monthEndDate: monthEnd,
      daysInMonth: daysInMonth
    )
  }
}
