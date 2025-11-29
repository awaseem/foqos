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
}
