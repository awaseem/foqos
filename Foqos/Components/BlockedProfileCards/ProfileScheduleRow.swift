import SwiftUI

struct ProfileScheduleRow: View {
  let profile: BlockedProfiles
  let isActive: Bool

  private var hasSchedule: Bool { profile.schedule?.isActive == true }

  private var isTimerStrategy: Bool {
    profile.blockingStrategyId == NFCTimerBlockingStrategy.id
      || profile.blockingStrategyId == QRTimerBlockingStrategy.id
  }

  private var timerDuration: Int? {
    guard let strategyData = profile.strategyData else { return nil }
    let timerData = StrategyTimerData.toStrategyTimerData(from: strategyData)
    return timerData.durationInMinutes
  }

  private var daysLine: String {
    guard let schedule = profile.schedule, schedule.isActive else {
      return ""
    }
    return schedule.days
      .sorted { $0.rawValue < $1.rawValue }
      .map { $0.shortLabel }
      .joined(separator: " ")
  }

  private var timeLine: String? {
    guard let schedule = profile.schedule, schedule.isActive else { return nil }
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
    HStack(spacing: 4) {
      // Icon
      Group {
        if profile.scheduleIsOutOfSync || (hasSchedule && isTimerStrategy) {
          Image(systemName: "exclamationmark.triangle.fill")
            .foregroundColor(.red)
        }
      }
      .font(.body)

      VStack(alignment: .leading, spacing: 2) {
        if profile.scheduleIsOutOfSync {
          Text("Schedule is Out of Sync")
            .font(.caption2)
        } else if !hasSchedule && isActive && isTimerStrategy {
          Text("Duration")
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.primary)

          if let duration = timerDuration {
            Text("\(DateFormatters.formatMinutes(duration))")
              .font(.caption2)
              .foregroundColor(.secondary)
          }
        } else if hasSchedule && isTimerStrategy {
          Text("Unstable Profile with Schedule")
            .font(.caption2)
        } else if !hasSchedule {
          Text("No Schedule Set")
            .font(.caption)
            .foregroundColor(.secondary)
        } else if hasSchedule {
          Text(daysLine)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.primary)

          if let timeLine = timeLine {
            Text(timeLine)
              .font(.caption2)
              .foregroundColor(.secondary)
          }
        }
      }

      Spacer(minLength: 0)
    }
  }
}

#Preview {
  VStack(spacing: 20) {
    ProfileScheduleRow(
      profile: BlockedProfiles(
        name: "Test",
        blockingStrategyId: NFCBlockingStrategy.id,
        schedule: .init(
          days: [.monday, .wednesday, .friday],
          startHour: 9,
          startMinute: 0,
          endHour: 17,
          endMinute: 0,
          updatedAt: Date()
        )
      ),
      isActive: false
    )
  }
  .padding()
  .background(Color(.systemGroupedBackground))
}
