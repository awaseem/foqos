import Foundation
import SwiftData

struct CompanionStats: Equatable {
  var streakDays: Int
  var todayFocusSeconds: Int
  var weekMinutes: [Int]  // oldest first, [6] = today

  static let zero = CompanionStats(
    streakDays: 0,
    todayFocusSeconds: 0,
    weekMinutes: Array(repeating: 0, count: 7)
  )
}

// Computes the stats shown on companion devices. Reuses
// WeeklySessionAggregator so the device always matches the app's insights,
// and mirrors ProfileInsightsUtil.currentStreakDays semantics (the streak is
// anchored to today).
enum CompanionStatsCalculator {
  static func stats(
    for intervals: [WeeklySessionInterval],
    now: Date = Date(),
    calendar: Calendar = .current,
    streakLookbackDays: Int = 365
  ) -> CompanionStats {
    guard !intervals.isEmpty else { return .zero }

    let todayStart = calendar.startOfDay(for: now)
    guard let windowStart = calendar.date(byAdding: .day, value: -6, to: todayStart) else {
      return .zero
    }

    let week = WeeklySessionAggregator.aggregate(
      sessions: intervals,
      weekStart: windowStart,
      calendar: calendar
    )

    // Pre-bucket every day each interval touches, so the streak walk is a
    // set lookup instead of scanning all intervals per day.
    var focusDays = Set<Date>()
    for interval in intervals {
      var day = calendar.startOfDay(for: interval.startTime)
      while day < interval.endTime {
        focusDays.insert(day)
        guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
        day = next
      }
    }

    var streak = 0
    var day = todayStart
    while streak < streakLookbackDays, focusDays.contains(day) {
      streak += 1
      guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
      day = previous
    }

    return CompanionStats(
      streakDays: streak,
      todayFocusSeconds: Int(week.dailyDurations[6]),
      weekMinutes: week.dailyDurations.map { Int($0 / 60) }
    )
  }

  // Fetches recent sessions and computes stats; active sessions count up to
  // "now" so today's total includes the in-progress session.
  static func stats(in context: ModelContext, now: Date = Date()) -> CompanionStats {
    guard let lookbackStart = Calendar.current.date(byAdding: .day, value: -365, to: now) else {
      return .zero
    }

    let descriptor = FetchDescriptor<BlockedProfileSession>(
      predicate: #Predicate { $0.startTime >= lookbackStart }
    )
    guard let sessions = try? context.fetch(descriptor) else { return .zero }

    let intervals = sessions.compactMap { session -> WeeklySessionInterval? in
      let end = session.endTime ?? now
      guard end > session.startTime else { return nil }
      return WeeklySessionInterval(startTime: session.startTime, endTime: end)
    }
    return stats(for: intervals, now: now)
  }
}
