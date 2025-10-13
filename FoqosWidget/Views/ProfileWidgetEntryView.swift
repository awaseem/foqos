//
//  ProfileWidgetEntryView.swift
//  FoqosWidget
//
//  Created by Ali Waseem on 2025-03-11.
//

import FamilyControls
import SwiftUI
import WidgetKit

// MARK: - Widget View
struct ProfileWidgetEntryView: View {
  var entry: ProfileControlProvider.Entry

  var body: some View {
    Link(destination: entry.deepLinkURL ?? URL(string: "foqos://")!) {
      VStack(spacing: 0) {
        // Main content area with large profile name
        VStack(spacing: 8) {

          // Large profile name in center
          Text(entry.profileName ?? "No Profile")
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(.primary)
            .lineLimit(2)

          // Session timer if active
          if entry.isSessionActive {
            if let startTime = entry.sessionStartTime {
              Text(
                Date(
                  timeIntervalSinceNow: startTime.timeIntervalSince1970
                    - Date().timeIntervalSince1970
                ),
                style: .timer
              )
              .font(.caption)
              .fontWeight(.medium)
              .foregroundColor(.secondary)
            }
          }

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)

        // Bottom section with app/domain count and foqos logo
        HStack {
          // Apps and domains count (bottom left)
          VStack(alignment: .leading, spacing: 2) {
            if let profile = entry.profileSnapshot {
              let appCount = getAppCount(from: profile)
              let domainCount = getDomainCount(from: profile)

              if appCount > 0 || domainCount > 0 {
                Text("\(appCount + domainCount)")
                  .font(.caption)
                  .fontWeight(.semibold)
                  .foregroundColor(.primary)

                Text("blocked")
                  .font(.system(size: 8))
                  .foregroundColor(.secondary)
              } else {
                Text("Tap to Start")
                  .font(.system(size: 8))
                  .foregroundColor(.secondary)
              }
            } else {
              Text("Tap to Start")
                .font(.system(size: 8))
                .foregroundColor(.secondary)
            }
          }

          Spacer()

          // Foqos logo (bottom right)
          Image(systemName: "hourglass")
            .font(.caption)
            .foregroundColor(.purple)
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 8)
      }
      .padding(.top, 8)
    }
  }

  // Helper function to count apps from profile
  private func getAppCount(from profile: SharedData.ProfileSnapshot) -> Int {
    return profile.selectedActivity.categories.count + profile.selectedActivity.applications.count
  }

  // Helper function to count domains from profile
  private func getDomainCount(from profile: SharedData.ProfileSnapshot) -> Int {
    let webDomainCount = profile.selectedActivity.webDomains.count
    let customDomainCount = profile.domains?.count ?? 0
    return webDomainCount + customDomainCount
  }
}

#Preview(as: .systemSmall) {
  ProfileControlWidget()
} timeline: {
  ProfileWidgetEntry(
    date: .now,
    selectedProfileId: "test-id",
    profileName: "Focus Session",
    activeSession: nil,
    profileSnapshot: SharedData.ProfileSnapshot(
      id: UUID(),
      name: "Focus Session",
      selectedActivity: {
        var selection = FamilyActivitySelection()
        // Simulate some selected apps and domains for preview
        return selection
      }(),
      createdAt: Date(),
      updatedAt: Date(),
      blockingStrategyId: nil,
      order: 0,
      enableLiveActivity: true,
      reminderTimeInSeconds: nil,
      customReminderMessage: nil,
      enableBreaks: true,
      enableStrictMode: true,
      enableAllowMode: true,
      enableAllowModeDomains: true,
      domains: ["facebook.com", "twitter.com", "instagram.com"],
      physicalUnblockNFCTagId: nil,
      physicalUnblockQRCodeId: nil,
      schedule: nil,
      disableBackgroundStops: nil
    ),
    deepLinkURL: URL(string: "foqos://profile/test-id"),
    focusMessage: "Stay focused and avoid distractions"
  )
  ProfileWidgetEntry(
    date: .now,
    selectedProfileId: "test-id-2",
    profileName: "Deep Work Session",
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
    profileSnapshot: SharedData.ProfileSnapshot(
      id: UUID(),
      name: "Deep Work Session",
      selectedActivity: FamilyActivitySelection(),
      createdAt: Date(),
      updatedAt: Date(),
      blockingStrategyId: nil,
      order: 0,
      enableLiveActivity: true,
      reminderTimeInSeconds: nil,
      customReminderMessage: nil,
      enableBreaks: true,
      enableStrictMode: false,
      enableAllowMode: true,
      enableAllowModeDomains: true,
      domains: ["youtube.com", "reddit.com"],
      physicalUnblockNFCTagId: nil,
      physicalUnblockQRCodeId: nil,
      schedule: nil,
      disableBackgroundStops: nil
    ),
    deepLinkURL: URL(string: "foqos://profile/test-id-2"),
    focusMessage: "Deep focus time"
  )
  ProfileWidgetEntry(
    date: .now,
    selectedProfileId: "test-id-3",
    profileName: "No Profile Selected",
    activeSession: nil,
    profileSnapshot: nil,
    deepLinkURL: URL(string: "foqos://"),
    focusMessage: "Select a profile to get started"
  )
}
