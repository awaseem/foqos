import Foundation

struct MonthlySessionInterval: Equatable {
  let startTime: Date
  let endTime: Date
}

struct MonthlySessionAggregation: Equatable {
  let dailyDurations: [TimeInterval]
  let dailySessionCounts: [Int]
  let overlappingSessionCount: Int
  let totalFocusTime: TimeInterval
  let daysInMonth: Int
}

enum MonthlySessionAggregator {
  static func aggregate(
    sessions: [MonthlySessionInterval],
    monthStart: Date,
    calendar: Calendar = .current
  ) -> MonthlySessionAggregation {
    let daysInMonth = daysInMonth(for: monthStart, calendar: calendar)
    let monthEnd = calendar.date(byAdding: .day, value: daysInMonth, to: monthStart)!

    let overlappingSessions = sessions.filter { session in
      session.startTime < monthEnd && session.endTime > monthStart
    }

    var dailyDurations = Array(repeating: TimeInterval.zero, count: daysInMonth)
    var dailySessionCounts = Array(repeating: 0, count: daysInMonth)

    for dayOffset in 0..<daysInMonth {
      let currentDay = calendar.date(byAdding: .day, value: dayOffset, to: monthStart)!
      let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDay)!

      for session in overlappingSessions {
        let overlapStart = max(session.startTime, currentDay)
        let overlapEnd = min(session.endTime, nextDay)

        guard overlapStart < overlapEnd else { continue }

        dailyDurations[dayOffset] += overlapEnd.timeIntervalSince(overlapStart)
        dailySessionCounts[dayOffset] += 1
      }
    }

    return MonthlySessionAggregation(
      dailyDurations: dailyDurations,
      dailySessionCounts: dailySessionCounts,
      overlappingSessionCount: overlappingSessions.count,
      totalFocusTime: dailyDurations.reduce(0, +),
      daysInMonth: daysInMonth
    )
  }

  static func startOfMonth(for date: Date, calendar: Calendar = .current) -> Date {
    let components = calendar.dateComponents([.year, .month], from: date)
    return calendar.date(from: components)!
  }

  static func daysInMonth(for date: Date, calendar: Calendar = .current) -> Int {
    return calendar.range(of: .day, in: .month, for: date)?.count ?? 30
  }

  static func sessionsForDate(
    date: Date,
    sessions: [BlockedProfileSession],
    calendar: Calendar = .current
  ) -> [BlockedProfileSession] {
    let dayStart = calendar.startOfDay(for: date)
    guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { return [] }

    return sessions.filter { session in
      let sessionStart = session.startTime
      let sessionEnd = session.endTime ?? Date()
      return sessionStart < dayEnd && sessionEnd > dayStart
    }.sorted { $0.duration > $1.duration }
  }
}
