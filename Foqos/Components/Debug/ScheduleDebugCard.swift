import SwiftUI

struct ScheduleDebugCard: View {
  let schedule: BlockedProfileSchedule

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      // Status & Summary
      Group {
        DebugRow(label: "Is Active", value: "\(schedule.isActive)")
        DebugRow(label: "Summary", value: schedule.summaryText)
        DebugRow(label: "Updated At", value: DateFormatters.formatDate(schedule.updatedAt))
      }

      Divider()

      // Schedule Details
      Group {
        DebugRow(
          label: "Days",
          value: schedule.days.map { $0.name }.joined(separator: ", ")
        )
        DebugRow(
          label: "Start Time",
          value: "\(schedule.startHour):\(String(format: "%02d", schedule.startMinute))"
        )
        DebugRow(
          label: "End Time",
          value: "\(schedule.endHour):\(String(format: "%02d", schedule.endMinute))"
        )
        DebugRow(label: "Duration (seconds)", value: "\(schedule.totalDurationInSeconds)")
      }

      Divider()

      // Status Checks
      Group {
        DebugRow(label: "Is Today Scheduled", value: "\(schedule.isTodayScheduled())")
        DebugRow(label: "Older Than 15 Minutes", value: "\(schedule.olderThan15Minutes())")
      }
    }
  }
}

#Preview {
  ScheduleDebugCard(
    schedule: BlockedProfileSchedule(
      days: [.monday, .tuesday, .wednesday, .thursday, .friday],
      startHour: 9,
      startMinute: 0,
      endHour: 17,
      endMinute: 30,
      updatedAt: Date()
    )
  )
  .padding()
}

#Preview("Weekend Schedule") {
  ScheduleDebugCard(
    schedule: BlockedProfileSchedule(
      days: [.saturday, .sunday],
      startHour: 10,
      startMinute: 0,
      endHour: 14,
      endMinute: 0,
      updatedAt: Date().addingTimeInterval(-3600)
    )
  )
  .padding()
}

#Preview("No Schedule") {
  ScheduleDebugCard(
    schedule: BlockedProfileSchedule(
      days: [],
      startHour: 0,
      startMinute: 0,
      endHour: 0,
      endMinute: 0,
      updatedAt: Date()
    )
  )
  .padding()
}
