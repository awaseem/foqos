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
      deepLinkURL: URL(string: "https://foqos.app/profile/placeholder"),
      focusMessage: "Stay focused and avoid distractions",
      useProfileURL: false
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

    // Efficient timeline: use fewer entries with smart refresh policies
    var entries: [ProfileWidgetEntry] = [currentEntry]

    // Calculate next refresh time based on session state
    let refreshPolicy: TimelineReloadPolicy
    let now = Date()

    if currentEntry.isSessionActive {
      // When session is active, add entries at key intervals (5, 15, 30 min)
      // This reduces memory and CPU usage while keeping widget reasonably fresh
      let refreshIntervals = [5, 15, 30]  // minutes

      for minutes in refreshIntervals {
        if let futureDate = Calendar.current.date(byAdding: .minute, value: minutes, to: now) {
          let futureEntry = ProfileWidgetEntry(
            date: futureDate,
            selectedProfileId: currentEntry.selectedProfileId,
            profileName: currentEntry.profileName,
            activeSession: currentEntry.activeSession,
            profileSnapshot: currentEntry.profileSnapshot,
            deepLinkURL: currentEntry.deepLinkURL,
            focusMessage: currentEntry.focusMessage,
            useProfileURL: currentEntry.useProfileURL
          )
          entries.append(futureEntry)
        }
      }

      // Refresh after 30 minutes for active sessions
      refreshPolicy = .after(Calendar.current.date(byAdding: .minute, value: 30, to: now) ?? now)
    } else {
      // Inactive: refresh every 15 minutes to check for new sessions
      refreshPolicy = .after(Calendar.current.date(byAdding: .minute, value: 15, to: now) ?? now)
    }

    return Timeline(entries: entries, policy: refreshPolicy)
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

    // Create deep link URL based on configuration
    var deepLinkURL: URL?
    if let profileId = targetProfileId {
      if let useProfileURL = configuration.useProfileURL, useProfileURL == true {
        deepLinkURL = URL(string: "https://foqos.app/profile/\(profileId)")
      } else {
        deepLinkURL = URL(string: "https://foqos.app/navigate/\(profileId)")
      }
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
      focusMessage: focusMessage,
      useProfileURL: configuration.useProfileURL
    )
  }
}
