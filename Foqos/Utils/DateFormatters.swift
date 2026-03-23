import Foundation

enum DateFormatters {
  static func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter.string(from: date)
  }

  static func formatDuration(_ duration: TimeInterval) -> String {
    let hours = Int(duration) / 3600
    let minutes = (Int(duration) % 3600) / 60
    let seconds = Int(duration) % 60

    if hours > 0 {
      return String(format: "%dh %dm %ds", hours, minutes, seconds)
    } else if minutes > 0 {
      return String(format: "%dm %ds", minutes, seconds)
    } else {
      return String(format: "%ds", seconds)
    }
  }

  static func formatMinutes(_ durationInMinutes: Int) -> String {
    if durationInMinutes <= 60 {
      return "\(durationInMinutes) min"
    } else {
      let hours = durationInMinutes / 60
      let minutes = durationInMinutes % 60
      if minutes == 0 {
        return "\(hours)h"
      } else {
        return "\(hours)h \(minutes)m"
      }
    }
  }

  static func formatDurationHoursMinutes(_ interval: TimeInterval) -> String {
    guard interval > 0 else { return "0m" }
    let totalSeconds = Int(interval)
    let hours = totalSeconds / 3600
    let minutes = (totalSeconds % 3600) / 60

    if hours > 0 {
      return "\(hours)h \(minutes)m"
    }
    return "\(minutes)m"
  }

  static func formatDurationShort(_ interval: TimeInterval) -> String {
    guard interval > 0 else { return "0m" }
    let totalSeconds = Int(interval)
    let hours = totalSeconds / 3600
    let minutes = (totalSeconds % 3600) / 60

    if hours > 0 {
      return "\(hours)h"
    }
    return "\(minutes)m"
  }

  static func formatSelectedDayHeader(_ date: Date) -> String {
    return date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
  }

  static func formatSessionDate(_ date: Date) -> String {
    let calendar = Calendar.current
    if calendar.isDateInToday(date) {
      return "Today"
    } else if calendar.isDateInYesterday(date) {
      return "Yesterday"
    }

    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter.string(from: date)
  }

  static func formatWeekRange(start: Date, end: Date) -> String {
    let calendar = Calendar.current
    let sameMonth = calendar.component(.month, from: start) == calendar.component(.month, from: end)
    let sameYear = calendar.component(.year, from: start) == calendar.component(.year, from: end)

    if sameMonth && sameYear {
      let month = start.formatted(.dateTime.month(.abbreviated))
      let startDay = calendar.component(.day, from: start)
      let endDay = calendar.component(.day, from: end)
      return "\(month) \(startDay) - \(endDay)"
    }

    if sameYear {
      return start.formatted(.dateTime.month(.abbreviated).day()) + " - "
        + end.formatted(.dateTime.month(.abbreviated).day().year())
    }

    return start.formatted(.dateTime.month(.abbreviated).day().year()) + " - "
      + end.formatted(.dateTime.month(.abbreviated).day().year())
  }

  static func formatMonthRange(start: Date, end: Date) -> String {
    let calendar = Calendar.current
    let sameYear = calendar.component(.year, from: start) == calendar.component(.year, from: end)

    if sameYear {
      return start.formatted(.dateTime.month(.abbreviated)) + " - "
        + end.formatted(.dateTime.month(.abbreviated))
    }

    return start.formatted(.dateTime.month(.abbreviated).year()) + " - "
      + end.formatted(.dateTime.month(.abbreviated).year())
  }

  static func formatDashboardDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d, yyyy"
    return formatter.string(from: date)
  }

  static func formatDayNumber(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "d"
    return formatter.string(from: date)
  }
}
