import Foundation
import SwiftUI

struct ProfileInsightsMetrics {
  let totalCompletedSessions: Int
  let totalFocusTime: TimeInterval
  let averageSessionDuration: TimeInterval?
  let longestSessionDuration: TimeInterval?
  let shortestSessionDuration: TimeInterval?
  // Break metrics
  let totalBreaksTaken: Int
  let averageBreakDuration: TimeInterval?
  let sessionsWithBreaks: Int
  let sessionsWithoutBreaks: Int
}

class ProfileInsightsUtil: ObservableObject {
  @Published var metrics: ProfileInsightsMetrics

  struct DayAggregate: Identifiable {
    let id = UUID()
    let date: Date
    let sessionsCount: Int
    let focusDuration: TimeInterval
  }

  let profile: BlockedProfiles
  private var startDate: Date? = nil
  private var endDate: Date? = nil

  init(profile: BlockedProfiles) {
    self.profile = profile
    self.metrics = Self.computeMetrics(for: profile)
  }

  func setDateRange(start: Date?, end: Date?) {
    self.startDate = start
    self.endDate = end
    refresh()
  }

  func refresh() {
    metrics = Self.computeMetrics(
      for: profile,
      from: startDate,
      to: endDate
    )
  }

  private static func computeMetrics(
    for profile: BlockedProfiles,
    from startDate: Date? = nil,
    to endDate: Date? = nil
  ) -> ProfileInsightsMetrics {
    let completed = profile.sessions.filter { session in
      guard let end = session.endTime else { return false }
      if let startDate = startDate, session.startTime < startDate { return false }
      if let endDate = endDate, end > endDate { return false }
      return true
    }

    let durations: [TimeInterval] = completed.map { session in
      guard let end = session.endTime else { return 0 }
      return end.timeIntervalSince(session.startTime)
    }

    // Breaks: assuming one optional break per session in current model
    let sessionsWithBreaksArray = completed.filter { $0.breakStartTime != nil }
    let sessionsWithBreaks = sessionsWithBreaksArray.count
    let sessionsWithoutBreaks = completed.count - sessionsWithBreaks

    let breakDurations: [TimeInterval] = sessionsWithBreaksArray.compactMap { session in
      guard let start = session.breakStartTime, let end = session.breakEndTime else { return nil }
      return end.timeIntervalSince(start)
    }

    let total = durations.reduce(0, +)
    let count = durations.count
    let average = count > 0 ? total / Double(count) : nil
    let longest = durations.max()
    let shortest = durations.min()
    let totalBreaksTaken = sessionsWithBreaks
    let avgBreak =
      breakDurations.isEmpty ? nil : (breakDurations.reduce(0, +) / Double(breakDurations.count))

    return ProfileInsightsMetrics(
      totalCompletedSessions: count,
      totalFocusTime: total,
      averageSessionDuration: average,
      longestSessionDuration: longest,
      shortestSessionDuration: shortest,
      totalBreaksTaken: totalBreaksTaken,
      averageBreakDuration: avgBreak,
      sessionsWithBreaks: sessionsWithBreaks,
      sessionsWithoutBreaks: sessionsWithoutBreaks
    )
  }

  func formattedDuration(_ interval: TimeInterval?) -> String {
    guard let interval = interval, interval > 0 else { return "—" }
    let totalSeconds = Int(interval)
    let hours = totalSeconds / 3600
    let minutes = (totalSeconds % 3600) / 60
    let seconds = totalSeconds % 60

    if hours > 0 {
      return "\(hours)h \(minutes)m"
    }
    if minutes > 0 {
      return "\(minutes)m"
    }
    return "\(seconds)s"
  }

  func formattedPercent(_ value: Double?) -> String {
    guard let value = value else { return "—" }
    let percent = max(0, min(1, value)) * 100
    return String(format: "%.0f%%", percent)
  }

  // MARK: - Aggregations
  func dailyAggregates(days: Int = 14, endingOn end: Date = Date()) -> [DayAggregate] {
    let calendar = Calendar.current
    let effectiveEnd = min(endDate ?? end, end)
    guard
      let windowStart = calendar.date(
        byAdding: .day, value: -(days - 1), to: calendar.startOfDay(for: effectiveEnd))
    else {
      return []
    }

    let effectiveStart = max(startDate ?? windowStart, windowStart)
    let startOfWindow = calendar.startOfDay(for: effectiveStart)
    let endOfWindow = calendar.startOfDay(for: effectiveEnd)

    let completed = profile.sessions.filter { session in
      guard let sessionEnd = session.endTime else { return false }
      return sessionEnd >= startOfWindow
        && sessionEnd <= calendar.date(byAdding: .day, value: 1, to: endOfWindow)!
    }

    var buckets: [Date: (count: Int, duration: TimeInterval)] = [:]
    for session in completed {
      guard let end = session.endTime else { continue }
      let day = calendar.startOfDay(for: end)
      let duration = end.timeIntervalSince(session.startTime)
      let prior = buckets[day] ?? (0, 0)
      buckets[day] = (prior.count + 1, prior.duration + max(0, duration))
    }

    var results: [DayAggregate] = []
    var current = startOfWindow
    while current <= endOfWindow {
      let values = buckets[current] ?? (0, 0)
      results.append(
        DayAggregate(date: current, sessionsCount: values.count, focusDuration: values.duration))
      guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
      current = next
    }

    return results
  }

  func bestFocusWeekday(in days: Int = 60) -> (weekday: Int, totalFocus: TimeInterval)? {
    let calendar = Calendar.current
    let end = calendar.startOfDay(for: Date())
    guard calendar.date(byAdding: .day, value: -days, to: end) != nil else { return nil }
    var totals: [Int: TimeInterval] = [:]
    for agg in dailyAggregates(days: days, endingOn: end) {
      let weekday = calendar.component(.weekday, from: agg.date)
      totals[weekday, default: 0] += agg.focusDuration
    }
    guard let best = totals.max(by: { $0.value < $1.value }) else { return nil }
    return (weekday: best.key, totalFocus: best.value)
  }

  func averageDailyFocusTime(days: Int = 14, endingOn end: Date = Date()) -> TimeInterval? {
    let aggs = dailyAggregates(days: days, endingOn: end)
    guard !aggs.isEmpty else { return nil }
    let total = aggs.reduce(0) { $0 + $1.focusDuration }
    return total / Double(aggs.count)
  }

  func currentStreakDays() -> Int {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let aggs = dailyAggregates(days: 365, endingOn: today).sorted { $0.date > $1.date }
    var streak = 0
    var expected = today
    for agg in aggs {
      if calendar.isDate(agg.date, inSameDayAs: expected) {
        if agg.sessionsCount > 0 { streak += 1 } else { break }
        guard let prev = calendar.date(byAdding: .day, value: -1, to: expected) else { break }
        expected = prev
      } else if agg.date < expected {
        break
      }
    }
    return streak
  }
}
