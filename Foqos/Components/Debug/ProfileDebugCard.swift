import SwiftData
import SwiftUI

struct ProfileDebugCard: View {
  let profile: BlockedProfiles

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      // Basic Info
      Group {
        DebugRow(label: "ID", value: profile.id.uuidString)
        DebugRow(label: "Name", value: profile.name)
        DebugRow(label: "Created At", value: DateFormatters.formatDate(profile.createdAt))
        DebugRow(label: "Updated At", value: DateFormatters.formatDate(profile.updatedAt))
        DebugRow(label: "Order", value: "\(profile.order)")
      }

      Divider()

      // Strategy & Features
      Group {
        DebugRow(label: "Strategy ID", value: profile.blockingStrategyId ?? "nil")
        DebugRow(label: "Enable Live Activity", value: "\(profile.enableLiveActivity)")
        DebugRow(label: "Enable Breaks", value: "\(profile.enableBreaks)")
        DebugRow(label: "Enable Strict Mode", value: "\(profile.enableStrictMode)")
        DebugRow(label: "Enable Allow Mode", value: "\(profile.enableAllowMode)")
        DebugRow(
          label: "Enable Allow Mode Domains",
          value: "\(profile.enableAllowModeDomains)"
        )
        DebugRow(
          label: "Disable Background Stops",
          value: "\(profile.disableBackgroundStops)"
        )
      }

      Divider()

      // Reminders
      Group {
        DebugRow(
          label: "Reminder Time (seconds)",
          value: profile.reminderTimeInSeconds.map { "\($0)" } ?? "nil"
        )
        DebugRow(
          label: "Custom Reminder Message",
          value: profile.customReminderMessage ?? "nil"
        )
      }

      Divider()

      // Physical Unlock
      Group {
        DebugRow(label: "NFC Tag ID", value: profile.physicalUnblockNFCTagId ?? "nil")
        DebugRow(label: "QR Code ID", value: profile.physicalUnblockQRCodeId ?? "nil")
      }

      Divider()

      // Sessions & Activity
      Group {
        DebugRow(label: "Total Sessions", value: "\(profile.sessions.count)")
        DebugRow(
          label: "Active Schedule Timer Activity",
          value: profile.activeScheduleTimerActivity?.rawValue ?? "nil"
        )
      }
    }
  }
}

#Preview {
  let profile = BlockedProfiles(
    name: "Work Focus",
    blockingStrategyId: NFCBlockingStrategy.id,
    enableLiveActivity: true,
    reminderTimeInSeconds: 3600,
    customReminderMessage: "Time to focus!",
    enableBreaks: true,
    enableStrictMode: false,
    enableAllowMode: false,
    order: 0
  )

  return ProfileDebugCard(profile: profile)
    .padding()
    .modelContainer(for: [BlockedProfiles.self, BlockedProfileSession.self])
}

#Preview("Profile with NFC Tag") {
  let profile = BlockedProfiles(
    name: "Deep Work",
    blockingStrategyId: NFCBlockingStrategy.id,
    enableLiveActivity: false,
    enableBreaks: false,
    enableStrictMode: true,
    order: 1,
    physicalUnblockNFCTagId: "ABC123DEF456"
  )

  return ProfileDebugCard(profile: profile)
    .padding()
    .modelContainer(for: [BlockedProfiles.self, BlockedProfileSession.self])
}

#Preview("Profile with Schedule") {
  let schedule = BlockedProfileSchedule(
    days: [.monday, .tuesday, .wednesday, .thursday, .friday],
    startHour: 9,
    startMinute: 0,
    endHour: 17,
    endMinute: 0
  )

  let profile = BlockedProfiles(
    name: "Scheduled Focus",
    blockingStrategyId: ManualBlockingStrategy.id,
    enableLiveActivity: true,
    enableBreaks: true,
    order: 2,
    schedule: schedule,
    disableBackgroundStops: true
  )

  return ProfileDebugCard(profile: profile)
    .padding()
    .modelContainer(for: [BlockedProfiles.self, BlockedProfileSession.self])
}
