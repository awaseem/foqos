import Foundation

enum Weekday: Int, CaseIterable, Codable, Equatable {
  case sunday = 1
  case monday
  case tuesday
  case wednesday
  case thursday
  case friday
  case saturday

  var name: String {
    switch self {
    case .sunday: return "Sunday"
    case .monday: return "Monday"
    case .tuesday: return "Tuesday"
    case .wednesday: return "Wednesday"
    case .thursday: return "Thursday"
    case .friday: return "Friday"
    case .saturday: return "Saturday"
    }
  }
}

struct BlockedProfileSchedule: Codable, Equatable {
  var days: [Weekday]

  var startHour: Int
  var startMinute: Int
  var endHour: Int
  var endMinute: Int

  var updatedAt: Date

  var isActive: Bool {
    return !days.isEmpty
  }

  var totalDurationInSeconds: Int {
    return (endHour - startHour) * 3600 + (endMinute - startMinute) * 60
  }

  func isTodayScheduled(now: Date = Date(), calendar: Calendar = .current) -> Bool {
    guard isActive else { return false }
    let currentWeekdayRaw = calendar.component(.weekday, from: now)
    guard let today = Weekday(rawValue: currentWeekdayRaw) else { return false }
    return days.contains(today)
  }
}
