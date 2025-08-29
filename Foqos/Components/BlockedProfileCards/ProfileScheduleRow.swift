import SwiftUI

struct ProfileScheduleRow: View {
  let schedule: BlockedProfileSchedule?

  private var isActive: Bool { schedule?.isActive == true }

  private var daysLine: String {
    guard let schedule = schedule, schedule.isActive else {
      return "No schedule set"
    }
    return schedule.days
      .sorted { $0.rawValue < $1.rawValue }
      .map { $0.shortLabel }
      .joined(separator: " ")
  }

  private var timeLine: String? {
    guard let schedule = schedule, schedule.isActive else { return nil }
    let start = formattedTimeString(hour24: schedule.startHour, minute: schedule.startMinute)
    let end = formattedTimeString(hour24: schedule.endHour, minute: schedule.endMinute)
    return "\(start) - \(end)"
  }

  private func formattedTimeString(hour24: Int, minute: Int) -> String {
    var hour = hour24 % 12
    if hour == 0 { hour = 12 }
    let isPM = hour24 >= 12
    return "\(hour):\(String(format: "%02d", minute)) \(isPM ? "PM" : "AM")"
  }

  var body: some View {
    HStack(spacing: 16) {
      VStack(alignment: .leading, spacing: 2) {
        if isActive {
          Text(daysLine)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.primary)

          if let timeLine = timeLine {
            Text(timeLine)
              .font(.caption2)
              .foregroundColor(.secondary)
          }
        } else {
          Text(daysLine)
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }

      Spacer(minLength: 0)
    }
  }
}

#Preview {
  VStack(spacing: 20) {
    ProfileScheduleRow(
      schedule: .init(
        days: [.monday, .wednesday, .friday],
        startHour: 9,
        startMinute: 0,
        endHour: 17,
        endMinute: 0,
        updatedAt: Date()
      )
    )

    ProfileScheduleRow(schedule: nil)
    ProfileScheduleRow(
      schedule: .init(
        days: [],
        startHour: 9,
        startMinute: 0,
        endHour: 17,
        endMinute: 0,
        updatedAt: Date()
      )
    )
  }
  .padding()
  .background(Color(.systemGroupedBackground))
}
