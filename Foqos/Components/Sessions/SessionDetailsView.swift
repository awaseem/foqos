import SwiftData
import SwiftUI

struct SessionDetailsView: View {
  @Environment(\.dismiss) private var dismiss

  let session: BlockedProfileSession

  var body: some View {
    NavigationStack {
      Form {
        SessionInfoSection(session: session)
        TimingSection(session: session)

        if session.breakStartTime != nil && session.breakEndTime != nil {
          BreakSection(session: session)
        }

        if session.pauseStartTime != nil && session.pauseEndTime != nil {
          PauseSection(session: session)
        }
      }
      .navigationTitle("Session Details")
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button(action: { dismiss() }) {
            Image(systemName: "xmark")
          }
          .accessibilityLabel("Close")
        }
      }
    }
  }
}

// MARK: - Session Info Section

private struct SessionInfoSection: View {
  let session: BlockedProfileSession

  var body: some View {
    Section("Session Info") {
      InfoRow(label: "Tag", value: session.tag)
      InfoRow(label: "Profile", value: session.blockedProfile.name)
      InfoRow(label: "Force Started", value: session.forceStarted ? "Yes" : "No")
    }
  }
}

// MARK: - Timing Section

private struct TimingSection: View {
  let session: BlockedProfileSession

  var body: some View {
    Section("Timing") {
      InfoRow(
        label: "Started",
        value: DateFormatters.formatDate(session.startTime)
      )

      if let endTime = session.endTime {
        InfoRow(
          label: "Ended",
          value: DateFormatters.formatDate(endTime)
        )
      } else {
        InfoRow(label: "Ended", value: "In Progress")
          .foregroundStyle(.secondary)
      }

      InfoRow(
        label: "Duration",
        value: DateFormatters.formatDurationHoursSeconds(session.duration)
      )
    }
  }
}

// MARK: - Break Section

private struct BreakSection: View {
  let session: BlockedProfileSession

  var breakDuration: TimeInterval? {
    guard let breakStartTime = session.breakStartTime,
          let breakEndTime = session.breakEndTime else {
      return nil
    }
    return breakEndTime.timeIntervalSince(breakStartTime)
  }

  var body: some View {
    Section("Break") {
      if let breakStartTime = session.breakStartTime {
        InfoRow(
          label: "Started",
          value: DateFormatters.formatDate(breakStartTime)
        )
      }

      if let breakEndTime = session.breakEndTime {
        InfoRow(
          label: "Ended",
          value: DateFormatters.formatDate(breakEndTime)
        )
      }

      if let breakDuration = breakDuration {
        InfoRow(
          label: "Duration",
          value: "\(Int(breakDuration / 60))m"
        )
      }
    }
  }
}

// MARK: - Pause Section

private struct PauseSection: View {
  let session: BlockedProfileSession

  var pauseDuration: TimeInterval? {
    guard let pauseStartTime = session.pauseStartTime,
          let pauseEndTime = session.pauseEndTime else {
      return nil
    }
    return pauseEndTime.timeIntervalSince(pauseStartTime)
  }

  var body: some View {
    Section("Pause") {
      if let pauseStartTime = session.pauseStartTime {
        InfoRow(
          label: "Started",
          value: DateFormatters.formatDate(pauseStartTime)
        )
      }

      if let pauseEndTime = session.pauseEndTime {
        InfoRow(
          label: "Ended",
          value: DateFormatters.formatDate(pauseEndTime)
        )
      }

      if let pauseDuration = pauseDuration {
        InfoRow(
          label: "Duration",
          value: DateFormatters.formatDurationShort(pauseDuration)
        )
      }
    }
  }
}

// MARK: - Info Row Component

private struct InfoRow: View {
  let label: String
  let value: String

  var body: some View {
    HStack {
      Text(label)
        .foregroundStyle(.primary)
      Spacer()
      Text(value)
        .foregroundStyle(.secondary)
    }
  }
}

// MARK: - Previews

#Preview("Active Session") {
  struct PreviewWrapper: View {
    let profile: BlockedProfiles
    let session: BlockedProfileSession

    init() {
      let profile = BlockedProfiles(name: "Work Focus")
      let session = BlockedProfileSession(
        tag: "Morning Session",
        blockedProfile: profile,
        forceStarted: false
      )
      self.profile = profile
      self.session = session
    }

    var body: some View {
      SessionDetailsView(session: session)
    }
  }

  return PreviewWrapper()
    .modelContainer(for: [BlockedProfiles.self, BlockedProfileSession.self])
}

#Preview("Active Session with Break") {
  struct PreviewWrapper: View {
    let profile: BlockedProfiles
    let session: BlockedProfileSession

    init() {
      let profile = BlockedProfiles(
        name: "Deep Work",
        enableBreaks: true
      )
      let session = BlockedProfileSession(
        tag: "Focus Time",
        blockedProfile: profile,
        forceStarted: false
      )
      session.startBreak()
      self.profile = profile
      self.session = session
    }

    var body: some View {
      SessionDetailsView(session: session)
    }
  }

  return PreviewWrapper()
    .modelContainer(for: [BlockedProfiles.self, BlockedProfileSession.self])
}

#Preview("Completed Session with Break and Pause") {
  struct PreviewWrapper: View {
    let profile: BlockedProfiles
    let session: BlockedProfileSession

    init() {
      let profile = BlockedProfiles(
        name: "Study Session",
        enableBreaks: true
      )
      let session = BlockedProfileSession(
        tag: "Exam Prep",
        blockedProfile: profile,
        forceStarted: true
      )

      // Simulate a completed session
      session.endTime = Date().addingTimeInterval(-3600)

      // Add a break
      session.breakStartTime = Date().addingTimeInterval(-2700)
      session.breakEndTime = Date().addingTimeInterval(-2400)

      // Add a pause
      session.pauseStartTime = Date().addingTimeInterval(-1800)
      session.pauseEndTime = Date().addingTimeInterval(-1500)

      self.profile = profile
      self.session = session
    }

    var body: some View {
      SessionDetailsView(session: session)
    }
  }

  return PreviewWrapper()
    .modelContainer(for: [BlockedProfiles.self, BlockedProfileSession.self])
}
