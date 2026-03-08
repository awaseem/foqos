import Foundation

final class DashboardActivityUtil {
  static func sessionHoursForDate(_ date: Date, sessions: [BlockedProfileSession]) -> Double {
    let calendar = Calendar.current
    let dayStart = calendar.startOfDay(for: date)
    guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { return 0 }

    let totalSeconds = sessions.reduce(0.0) { total, session in
      let sessionStart = session.startTime
      let sessionEnd = session.endTime ?? Date()
      let overlapStart = max(sessionStart, dayStart)
      let overlapEnd = min(sessionEnd, dayEnd)
      let overlapDuration = max(0, overlapEnd.timeIntervalSince(overlapStart))
      return total + overlapDuration
    }

    return totalSeconds / 3600
  }

  static func sessionsForDate(_ date: Date, sessions: [BlockedProfileSession]) -> [BlockedProfileSession] {
    let calendar = Calendar.current
    let dayStart = calendar.startOfDay(for: date)
    guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { return [] }

    return sessions.filter { session in
      let sessionStart = session.startTime
      let sessionEnd = session.endTime ?? Date()
      return sessionStart < dayEnd && sessionEnd > dayStart
    }.sorted { $0.duration > $1.duration }
  }

  static func computeProfileActivities(for date: Date, profiles: [BlockedProfiles]) -> [DashboardProfileActivity] {
    let calendar = Calendar.current
    let dayStart = calendar.startOfDay(for: date)
    guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { return [] }

    var activities: [DashboardProfileActivity] = []

    for profile in profiles {
      let profileSessions = profile.sessions.filter { session in
        guard let endTime = session.endTime else { return false }
        return session.startTime < dayEnd && endTime > dayStart
      }

      guard !profileSessions.isEmpty else { continue }

      let totalTime = profileSessions.reduce(0.0) { total, session in
        let sessionStart = session.startTime
        let sessionEnd = session.endTime ?? Date()
        let overlapStart = max(sessionStart, dayStart)
        let overlapEnd = min(sessionEnd, dayEnd)
        return total + max(0, overlapEnd.timeIntervalSince(overlapStart))
      }

      activities.append(
        DashboardProfileActivity(
          profile: profile,
          totalTime: totalTime,
          sessionCount: profileSessions.count
        ))
    }

    return activities.sorted { $0.totalTime > $1.totalTime }
  }

  static func dates(forDays daysToShow: Int) -> [Date] {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())

    return (0..<daysToShow).map { day in
      calendar.date(byAdding: .day, value: -day, to: today)!
    }.reversed()
  }

  static func weeklyDates(from dates: [Date]) -> [[Date]] {
    stride(from: 0, to: dates.count, by: 7).map { startIndex in
      let endIndex = min(startIndex + 7, dates.count)
      return Array(dates[startIndex..<endIndex])
    }
  }
}
