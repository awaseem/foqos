import Foundation

enum BlockingWarning {
  static let identifierPrefix = "blockingWarning."

  static func leadTime(
    for duration: TimeInterval, intervalEnd: DateComponents? = nil,
    now: Date = Date(), calendar: Calendar = .current
  ) -> DateComponents? {
    var remaining = duration
    if let intervalEnd {
      // One-shot Screen Time timers use a clamped wall-clock end, with second precision.
      guard let hour = intervalEnd.hour, let minute = intervalEnd.minute,
        let end = calendar.date(
          bySettingHour: hour, minute: minute, second: intervalEnd.second ?? 0, of: now)
      else { return nil }
      remaining = min(
        duration, end.timeIntervalSinceReferenceDate - floor(now.timeIntervalSinceReferenceDate))
    }
    guard remaining > 60 else { return nil }
    return DateComponents(minute: min(5, max(1, Int(remaining / 300))))
  }

  static func isEndWarningDue(
    at now: Date, end: Date, leadMinutes: Int, sessionEnd: Date?
  ) -> Bool {
    guard (1...5).contains(leadMinutes), end < (sessionEnd ?? .distantFuture) else { return false }
    let warningDate = end.addingTimeInterval(-TimeInterval(leadMinutes * 60))
    return (warningDate..<end).contains(now)
  }
}
