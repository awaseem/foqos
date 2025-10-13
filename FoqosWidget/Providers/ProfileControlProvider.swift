//
//  ProfileControlProvider.swift
//  FoqosWidget
//
//  Created by Ali Waseem on 2025-03-11.
//

import AppIntents
import Foundation
import WidgetKit

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
      focusMessage: "Stay focused and avoid distractions",
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
          focusMessage: currentEntry.focusMessage,
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
      deepLinkURL = URL(string: "https://foqos.app/navigate/\(profileId)")
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
