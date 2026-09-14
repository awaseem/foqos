import Foundation

struct WidgetActivityDay: Identifiable {
  let date: Date
  let duration: TimeInterval
  var id: Date { date }
}

struct WidgetSessionInterval {
  let start: Date
  let end: Date
}

struct WidgetActivitySummary {
  let week: [WidgetActivityDay]
  let month: [WidgetActivityDay]
  let monthLeadingDays: Int
  let sessionCount: Int

  var weeklyDuration: TimeInterval { week.reduce(0) { $0 + $1.duration } }
  var monthlyDuration: TimeInterval { month.reduce(0) { $0 + $1.duration } }
  var activeDays: Int { month.filter { $0.duration > 0 }.count }

  static func make(
    sessions: [WidgetSessionInterval], at date: Date, calendar: Calendar = .current
  ) -> Self {
    let weekStart = calendar.dateInterval(of: .weekOfYear, for: date)!.start
    let monthStart = calendar.dateInterval(of: .month, for: date)!.start
    let monthDays = calendar.range(of: .day, in: .month, for: date)!.count
    // Match Insights: session elapsed time, split at local midnight (including DST).
    func days(from start: Date, count: Int) -> [WidgetActivityDay] {
      (0..<count).map { offset in
        let day = calendar.date(byAdding: .day, value: offset, to: start)!
        let nextDay = calendar.date(byAdding: .day, value: 1, to: day)!
        let duration = sessions.reduce(0.0) { total, session in
          let end = min(session.end, nextDay, date)
          let start = max(session.start, day)
          return total + max(0, end.timeIntervalSince(start))
        }
        return WidgetActivityDay(date: day, duration: duration)
      }
    }
    return Self(
      week: days(from: weekStart, count: 7),
      month: days(from: monthStart, count: monthDays),
      monthLeadingDays: (calendar.component(.weekday, from: monthStart) - calendar.firstWeekday + 7)
        % 7,
      sessionCount: sessions.filter { $0.start < date && $0.end > monthStart }.count
    )
  }

  static func durationLabel(_ duration: TimeInterval) -> String {
    let minutes = max(0, Int(duration / 60))
    if minutes < 60 { return "\(minutes)m" }
    let hours = minutes / 60
    return minutes % 60 == 0 ? "\(hours)h" : "\(hours)h \(minutes % 60)m"
  }
}
