import Foundation
import SwiftUI

struct WeeklyDayAggregate: Identifiable, Equatable {
  let id = UUID()
  let dayOfWeek: Int
  let dayName: String
  let displayLabel: String
  let totalSessionTime: TimeInterval
  let sessionCount: Int
  let date: Date
}

struct WeeklySummary {
  let days: [WeeklyDayAggregate]
  let totalSessions: Int
  let averageSessionDuration: TimeInterval
  let totalFocusTime: TimeInterval
  let weekStartDate: Date
  let weekEndDate: Date
}

class WeeklyProfileInsightsUtil: ObservableObject {
  let profile: BlockedProfiles
  
  @Published var selectedDate: Date = Date()
  
  var weeklySummary: WeeklySummary {
    computeWeeklySummary(for: selectedDate)
  }
  
  init(profile: BlockedProfiles) {
    self.profile = profile
  }
  
  func setWeek(for date: Date) {
    selectedDate = date
  }
  
  func moveToPreviousWeek() {
    let calendar = Calendar.current
    if let previousWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: selectedDate) {
      selectedDate = previousWeek
    }
  }
  
  func moveToNextWeek() {
    let calendar = Calendar.current
    if let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: selectedDate) {
      selectedDate = nextWeek
    }
  }
  
  func refresh() {
    objectWillChange.send()
  }
  
  private func computeWeeklySummary(for date: Date) -> WeeklySummary {
    let calendar = Calendar.current
    
    let weekStart = WeeklySessionAggregator.startOfWeek(for: date, calendar: calendar)
    let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!
    let completedSessions: [WeeklySessionInterval] = profile.sessions.compactMap { session in
      guard let endTime = session.endTime else { return nil }
      return WeeklySessionInterval(startTime: session.startTime, endTime: endTime)
    }
    let aggregation = WeeklySessionAggregator.aggregate(
      sessions: completedSessions,
      weekStart: weekStart,
      calendar: calendar
    )
    
    var dayAggregates: [WeeklyDayAggregate] = []
    let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    for dayOffset in 0..<7 {
      guard let currentDay = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else { continue }
      let dayNumber = calendar.component(.day, from: currentDay)
      dayAggregates.append(WeeklyDayAggregate(
        dayOfWeek: dayOffset + 1,
        dayName: dayNames[dayOffset],
        displayLabel: "\(dayNames[dayOffset]) \(dayNumber)",
        totalSessionTime: aggregation.dailyDurations[dayOffset],
        sessionCount: aggregation.dailySessionCounts[dayOffset],
        date: currentDay
      ))
    }
    
    let totalSessions = aggregation.overlappingSessionCount
    let totalFocusTime = aggregation.totalFocusTime
    let averageSessionDuration = totalSessions > 0 ? totalFocusTime / Double(totalSessions) : 0
    
    return WeeklySummary(
      days: dayAggregates,
      totalSessions: totalSessions,
      averageSessionDuration: averageSessionDuration,
      totalFocusTime: totalFocusTime,
      weekStartDate: weekStart,
      weekEndDate: weekEnd
    )
  }
  
}
