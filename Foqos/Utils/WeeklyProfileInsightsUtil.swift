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
    
    let weekStart = startOfWeek(for: date)
    let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!
    
    let completedSessions = profile.sessions.filter { session in
      guard let endTime = session.endTime else { return false }
      return endTime >= weekStart && endTime <= calendar.date(byAdding: .day, value: 1, to: weekEnd)!
    }
    
    var dayAggregates: [WeeklyDayAggregate] = []
    let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    for dayOffset in 0..<7 {
      guard let currentDay = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else { continue }
      let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDay)!
      
      let daySessions = completedSessions.filter { session in
        guard let endTime = session.endTime else { return false }
        return endTime >= currentDay && endTime < nextDay
      }
      
      let totalTime = daySessions.reduce(0) { $0 + $1.duration }
      
      let dayNumber = calendar.component(.day, from: currentDay)
      dayAggregates.append(WeeklyDayAggregate(
        dayOfWeek: dayOffset + 1,
        dayName: dayNames[dayOffset],
        displayLabel: "\(dayNames[dayOffset]) \(dayNumber)",
        totalSessionTime: totalTime,
        sessionCount: daySessions.count,
        date: currentDay
      ))
    }
    
    let totalSessions = completedSessions.count
    let totalFocusTime = completedSessions.reduce(0) { $0 + $1.duration }
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
  
  private func startOfWeek(for date: Date) -> Date {
    let calendar = Calendar.current
    var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
    components.weekday = 1
    return calendar.date(from: components)!
  }
  
  func formattedDuration(_ interval: TimeInterval) -> String {
    guard interval > 0 else { return "0m" }
    let totalSeconds = Int(interval)
    let hours = totalSeconds / 3600
    let minutes = (totalSeconds % 3600) / 60
    
    if hours > 0 {
      return "\(hours)h \(minutes)m"
    }
    return "\(minutes)m"
  }
  
  func formattedDurationShort(_ interval: TimeInterval) -> String {
    guard interval > 0 else { return "0m" }
    let totalSeconds = Int(interval)
    let hours = totalSeconds / 3600
    let minutes = (totalSeconds % 3600) / 60
    
    if hours > 0 {
      return "\(hours)h"
    }
    return "\(minutes)m"
  }
  
  func formattedDurationHHMMSS(_ interval: TimeInterval) -> String {
    guard interval > 0 else { return "0h 0s" }
    let totalSeconds = Int(interval)
    let hours = totalSeconds / 3600
    let seconds = totalSeconds % 60
    return "\(hours)h \(seconds)s"
  }
}
