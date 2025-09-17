import Foundation

struct ProfileInsightsMetrics {
  let totalCompletedSessions: Int
  let totalFocusTime: TimeInterval
  let averageSessionDuration: TimeInterval?
  let longestSessionDuration: TimeInterval?
  let shortestSessionDuration: TimeInterval?
}

class ProfileInsightsUtil: ObservableObject {
  @Published var metrics: ProfileInsightsMetrics

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

    let total = durations.reduce(0, +)
    let count = durations.count
    let average = count > 0 ? total / Double(count) : nil
    let longest = durations.max()
    let shortest = durations.min()

    return ProfileInsightsMetrics(
      totalCompletedSessions: count,
      totalFocusTime: total,
      averageSessionDuration: average,
      longestSessionDuration: longest,
      shortestSessionDuration: shortest
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
}
