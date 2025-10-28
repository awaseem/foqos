import SwiftData
import SwiftUI

struct SessionDebugCard: View {
  let session: BlockedProfileSession

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      // Basic Info
      Group {
        DebugRow(label: "Session ID", value: session.id)
        DebugRow(label: "Tag", value: session.tag)
        DebugRow(label: "Start Time", value: DateFormatters.formatDate(session.startTime))
        DebugRow(
          label: "End Time",
          value: session.endTime.map { DateFormatters.formatDate($0) } ?? "nil (active)"
        )
        DebugRow(label: "Force Started", value: "\(session.forceStarted)")
      }

      Divider()

      // Status Flags
      Group {
        DebugRow(label: "Is Active", value: "\(session.isActive)")
        DebugRow(label: "Is Break Available", value: "\(session.isBreakAvailable)")
        DebugRow(label: "Is Break Active", value: "\(session.isBreakActive)")
      }

      Divider()

      // Break Times
      Group {
        DebugRow(
          label: "Break Start Time",
          value: session.breakStartTime.map { DateFormatters.formatDate($0) } ?? "nil"
        )
        DebugRow(
          label: "Break End Time",
          value: session.breakEndTime.map { DateFormatters.formatDate($0) } ?? "nil"
        )
      }

      Divider()

      // Duration
      DebugRow(label: "Duration", value: DateFormatters.formatDuration(session.duration))
    }
  }
}

#Preview {
  let profile = BlockedProfiles(name: "Work Focus")
  let session = BlockedProfileSession(
    tag: "manual-start",
    blockedProfile: profile,
    forceStarted: false
  )

  return SessionDebugCard(session: session)
    .padding()
    .modelContainer(for: [BlockedProfiles.self, BlockedProfileSession.self])
}

#Preview("Active Session with Break") {
  let profile = BlockedProfiles(
    name: "Deep Work",
    enableBreaks: true
  )
  let session = BlockedProfileSession(
    tag: "nfc-scan",
    blockedProfile: profile,
    forceStarted: false
  )
  session.startBreak()

  return SessionDebugCard(session: session)
    .padding()
    .modelContainer(for: [BlockedProfiles.self, BlockedProfileSession.self])
}

#Preview("Completed Session") {
  let profile = BlockedProfiles(name: "Study Time")
  let session = BlockedProfileSession(
    tag: "scheduled",
    blockedProfile: profile,
    forceStarted: true
  )
  session.endSession()

  return SessionDebugCard(session: session)
    .padding()
    .modelContainer(for: [BlockedProfiles.self, BlockedProfileSession.self])
}
