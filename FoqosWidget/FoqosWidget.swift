//
//  FoqosWidget.swift
//  FoqosWidget
//
//  Created by Ali Waseem on 2025-03-11.
//

import AppIntents
import SwiftUI
import WidgetKit

// MARK: - Widget Entry Model
struct ProfileWidgetEntry: TimelineEntry {
  let date: Date
  let selectedProfileId: String?
  let profileName: String?
  let activeSession: SharedData.SessionSnapshot?
  let profileSnapshot: SharedData.ProfileSnapshot?
  let deepLinkURL: URL?
  let focusMessage: String

  var isSessionActive: Bool {
    return activeSession?.endTime == nil
  }

  var isBreakActive: Bool {
    guard let session = activeSession else { return false }
    return session.breakStartTime != nil && session.breakEndTime == nil
  }

  var sessionStartTime: Date? {
    return activeSession?.startTime
  }
}

// MARK: - Timeline Provider
struct ProfileControlProvider: AppIntentTimelineProvider {
  typealias Entry = ProfileWidgetEntry
  typealias Intent = ProfileSelectionIntent

  func placeholder(in context: Context) -> ProfileWidgetEntry {
    ProfileWidgetEntry(
      date: Date(),
      selectedProfileId: "placeholder",
      profileName: "Focus Session",
      activeSession: nil,
      profileSnapshot: nil,
      deepLinkURL: URL(string: "foqos://profile/placeholder"),
      focusMessage: "Stay focused and avoid distractions"
    )
  }

  func snapshot(for configuration: ProfileSelectionIntent, in context: Context) async
    -> ProfileWidgetEntry
  {
    return createEntry(for: configuration)
  }

  func timeline(for configuration: ProfileSelectionIntent, in context: Context) async -> Timeline<
    ProfileWidgetEntry
  > {
    let currentEntry = createEntry(for: configuration)

    // Create multiple entries for smoother updates
    var entries: [ProfileWidgetEntry] = [currentEntry]

    // Add more frequent updates for the next hour if session is active
    if currentEntry.isSessionActive {
      for minuteOffset in 1...60 {
        let futureDate =
          Calendar.current.date(byAdding: .minute, value: minuteOffset, to: Date()) ?? Date()
        let futureEntry = ProfileWidgetEntry(
          date: futureDate,
          selectedProfileId: currentEntry.selectedProfileId,
          profileName: currentEntry.profileName,
          activeSession: currentEntry.activeSession,
          profileSnapshot: currentEntry.profileSnapshot,
          deepLinkURL: currentEntry.deepLinkURL,
          focusMessage: currentEntry.focusMessage
        )
        entries.append(futureEntry)
      }
    }

    // Use .atEnd policy so the widget will request a new timeline when entries are exhausted
    // This ensures the widget stays up-to-date even if the app doesn't trigger manual refreshes
    return Timeline(entries: entries, policy: .atEnd)
  }

  private func createEntry(for configuration: ProfileSelectionIntent) -> ProfileWidgetEntry {
    let activeSession = SharedData.getActiveSharedSession()
    let profileSnapshots = SharedData.profileSnapshots

    var targetProfileId: String?
    var profileSnapshot: SharedData.ProfileSnapshot?
    var profileName: String?

    // Use the selected profile from configuration if available
    if let selectedProfile = configuration.profile {
      targetProfileId = selectedProfile.id
      profileSnapshot = profileSnapshots[targetProfileId!]
      profileName = selectedProfile.name
    } else {
      // Fallback: Show active session profile or most recent profile
      if let activeSession = activeSession {
        targetProfileId = activeSession.blockedProfileId.uuidString
        profileSnapshot = profileSnapshots[targetProfileId!]
        profileName = profileSnapshot?.name
      } else {
        // Find most recently updated profile
        let sortedProfiles = profileSnapshots.values.sorted { $0.updatedAt > $1.updatedAt }
        if let mostRecent = sortedProfiles.first {
          targetProfileId = mostRecent.id.uuidString
          profileSnapshot = mostRecent
          profileName = mostRecent.name
        }
      }
    }

    // Create deep link URL
    var deepLinkURL: URL?
    if let profileId = targetProfileId {
      deepLinkURL = URL(string: "foqos://profile/\(profileId)")
    } else {
      deepLinkURL = URL(string: "foqos://")
    }

    // Get focus message
    let focusMessage =
      profileSnapshot?.customReminderMessage ?? "Stay focused and avoid distractions"

    return ProfileWidgetEntry(
      date: Date(),
      selectedProfileId: targetProfileId,
      profileName: profileName ?? "No Profile",
      activeSession: activeSession,
      profileSnapshot: profileSnapshot,
      deepLinkURL: deepLinkURL,
      focusMessage: focusMessage
    )
  }
}

// MARK: - Widget View
struct ProfileWidgetEntryView: View {
  var entry: ProfileControlProvider.Entry

  var body: some View {
    Link(destination: entry.deepLinkURL ?? URL(string: "foqos://")!) {
      HStack(alignment: .center, spacing: 8) {
        // Left side - App info
        VStack(alignment: .leading, spacing: 4) {
          HStack(spacing: 2) {
            Text("Foqos")
              .font(.caption2)
              .fontWeight(.bold)
              .foregroundColor(.primary)
            Image(systemName: "hourglass")
              .font(.caption2)
              .foregroundColor(.purple)
          }

          Text(entry.profileName ?? "No Profile")
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.primary)
            .lineLimit(1)

          Text(entry.focusMessage)
            .font(.caption2)
            .foregroundColor(.secondary)
            .lineLimit(2)
        }

        Spacer()

        // Right side - Timer or status
        VStack(alignment: .trailing, spacing: 2) {
          if entry.isSessionActive {
            if entry.isBreakActive {
              VStack(spacing: 1) {
                Image(systemName: "cup.and.heat.waves.fill")
                  .font(.caption)
                  .foregroundColor(.orange)
                Text("Break")
                  .font(.caption2)
                  .fontWeight(.medium)
                  .foregroundColor(.orange)
              }
            } else if let startTime = entry.sessionStartTime {
              Text(
                Date(
                  timeIntervalSinceNow: startTime.timeIntervalSince1970
                    - Date().timeIntervalSince1970
                ),
                style: .timer
              )
              .font(.caption)
              .fontWeight(.semibold)
              .foregroundColor(.secondary)
              .multilineTextAlignment(.trailing)
            }
          } else {
            VStack(spacing: 1) {
              Image(systemName: "play.circle")
                .font(.caption)
                .foregroundColor(.green)
              Text("Tap to Start")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.green)
            }
          }
        }
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
    }
  }
}

// MARK: - Widget Configuration
struct ProfileControlWidget: Widget {
  let kind: String = "ProfileControlWidget"

  var body: some WidgetConfiguration {
    AppIntentConfiguration(
      kind: kind, intent: ProfileSelectionIntent.self, provider: ProfileControlProvider()
    ) { entry in
      if #available(iOS 17.0, *) {
        ProfileWidgetEntryView(entry: entry)
          .containerBackground(.fill.tertiary, for: .widget)
      } else {
        ProfileWidgetEntryView(entry: entry)
          .padding()
          .background()
      }
    }
    .configurationDisplayName("Foqos Profile")
    .description("Monitor and control your selected focus profile")
    .supportedFamilies([.systemSmall])
  }
}

// MARK: - Legacy Widget (keeping for compatibility)
struct Provider: TimelineProvider {
  func placeholder(in context: Context) -> SimpleEntry {
    SimpleEntry(date: Date(), emoji: "😀")
  }

  func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
    let entry = SimpleEntry(date: Date(), emoji: "😀")
    completion(entry)
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
    var entries: [SimpleEntry] = []

    let currentDate = Date()
    for hourOffset in 0..<5 {
      let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
      let entry = SimpleEntry(date: entryDate, emoji: "😀")
      entries.append(entry)
    }

    let timeline = Timeline(entries: entries, policy: .atEnd)
    completion(timeline)
  }
}

struct SimpleEntry: TimelineEntry {
  let date: Date
  let emoji: String
}

struct FoqosWidgetEntryView: View {
  var entry: Provider.Entry

  var body: some View {
    VStack {
      Text("Time:")
      Text(entry.date, style: .time)

      Text("Emoji:")
      Text(entry.emoji)
    }
  }
}

struct FoqosWidget: Widget {
  let kind: String = "FoqosWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: Provider()) { entry in
      if #available(iOS 17.0, *) {
        FoqosWidgetEntryView(entry: entry)
          .containerBackground(.fill.tertiary, for: .widget)
      } else {
        FoqosWidgetEntryView(entry: entry)
          .padding()
          .background()
      }
    }
    .configurationDisplayName("My Widget")
    .description("This is an example widget.")
  }
}

// MARK: - Previews
#Preview(as: .systemSmall) {
  ProfileControlWidget()
} timeline: {
  ProfileWidgetEntry(
    date: .now,
    selectedProfileId: "test-id",
    profileName: "Focus Session",
    activeSession: nil,
    profileSnapshot: nil,
    deepLinkURL: URL(string: "foqos://profile/test-id"),
    focusMessage: "Stay focused and avoid distractions"
  )
  ProfileWidgetEntry(
    date: .now,
    selectedProfileId: "test-id",
    profileName: "Deep Work",
    activeSession: SharedData.SessionSnapshot(
      id: "test-session",
      tag: "test-tag",
      blockedProfileId: UUID(),
      startTime: Date(timeIntervalSinceNow: -300),
      endTime: nil,
      breakStartTime: nil,
      breakEndTime: nil,
      forceStarted: true
    ),
    profileSnapshot: nil,
    deepLinkURL: URL(string: "foqos://profile/test-id"),
    focusMessage: "Deep focus time"
  )
}
