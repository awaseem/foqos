import Foundation

struct WeeklySessionInterval: Equatable {
  let startTime: Date
  let endTime: Date
}

struct WeeklySessionAggregation: Equatable {
  let dailyDurations: [TimeInterval]
  let dailySessionCounts: [Int]
  let overlappingSessionCount: Int
  let totalFocusTime: TimeInterval
}

enum WeeklySessionAggregator {
  static func aggregate(
    sessions: [WeeklySessionInterval],
    weekStart: Date,
    calendar: Calendar = .current
  ) -> WeeklySessionAggregation {
    let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!
    let overlappingSessions = sessions.filter { session in
      session.startTime < weekEnd && session.endTime > weekStart
    }

    var dailyDurations = Array(repeating: TimeInterval.zero, count: 7)
    var dailySessionCounts = Array(repeating: 0, count: 7)

    for dayOffset in 0..<7 {
      let currentDay = calendar.date(byAdding: .day, value: dayOffset, to: weekStart)!
      let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDay)!

      for session in overlappingSessions {
        let overlapStart = max(session.startTime, currentDay)
        let overlapEnd = min(session.endTime, nextDay)

        guard overlapStart < overlapEnd else { continue }

        dailyDurations[dayOffset] += overlapEnd.timeIntervalSince(overlapStart)
        dailySessionCounts[dayOffset] += 1
      }
    }

    return WeeklySessionAggregation(
      dailyDurations: dailyDurations,
      dailySessionCounts: dailySessionCounts,
      overlappingSessionCount: overlappingSessions.count,
      totalFocusTime: dailyDurations.reduce(0, +)
    )
  }

  static func startOfWeek(for date: Date, calendar: Calendar = .current) -> Date {
    var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
    components.weekday = 1
    return calendar.date(from: components)!
  }
}
