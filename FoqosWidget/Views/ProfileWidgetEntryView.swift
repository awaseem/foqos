//
//  ProfileWidgetEntryView.swift
//  FoqosWidget
//
//  Created by Ali Waseem on 2025-03-11.
//

import AppIntents
import FamilyControls
import SwiftUI
import WidgetKit

// MARK: - Widget View
struct ProfileWidgetEntryView: View {
  var entry: ProfileControlProvider.Entry

  // Computed property to determine if we should use white text
  private var shouldUseWhiteText: Bool {
    return entry.isBreakActive || entry.isSessionActive
  }

  var body: some View {
    VStack(spacing: 8) {
      // Top section: Profile name (left) and hourglass (right)
      HStack {
        Text(entry.profileName ?? "No Profile")
          .font(.system(size: 14))
          .fontWeight(.bold)
          .foregroundColor(shouldUseWhiteText ? .white : .primary)
          .lineLimit(1)

        Spacer()

        Image(systemName: "hourglass")
          .font(.body)
          .foregroundColor(shouldUseWhiteText ? .white : .purple)
      }
      .padding(.top, 8)

      // Middle section: Status message or timer
      VStack {
        if entry.isBreakActive {
          Text("On a Break")
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(shouldUseWhiteText ? .white : .secondary)
        } else if entry.isSessionActive {
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
            .foregroundColor(shouldUseWhiteText ? .white : .secondary)
          }
        } else {
          Link(destination: entry.deepLinkURL ?? URL(string: "foqos://")!) {
            Text("Tap to open")
              .font(.caption)
              .fontWeight(.medium)
              .foregroundColor(shouldUseWhiteText ? .white : .secondary)
          }
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)

      // Bottom section: Blocked count + enabled options count + launch button
      HStack {
        VStack(alignment: .leading, spacing: 2) {
          if let profile = entry.profileSnapshot {
            let blockedCount = getBlockedCount(from: profile)
            let enabledOptionsCount = getEnabledOptionsCount(from: profile)

            Text("\(blockedCount) Blocked")
              .font(.system(size: 10))
              .fontWeight(.medium)
              .foregroundColor(shouldUseWhiteText ? .white : .orange)

            Text("with \(enabledOptionsCount) Options")
              .font(.system(size: 8))
              .fontWeight(.regular)
              .foregroundColor(shouldUseWhiteText ? .white : .green)
          } else {
            Text("No profile selected")
              .font(.system(size: 8))
              .foregroundColor(shouldUseWhiteText ? .white : .secondary)
          }
        }

        Spacer()

        // Launch button in bottom right when quick launch is enabled and no active session
        if entry.enableQuickLaunch && !entry.isSessionActive && !entry.isBreakActive {
          Button(
            intent: StartProfileWidgetIntent(profileName: entry.profileName)
          ) {
            HStack(spacing: 4) {
              Image(systemName: "play.fill")
                .font(.system(size: 10))
              Text("Start")
                .font(.system(size: 10))
                .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
          }
          .background(Color.purple)
          .cornerRadius(8)
          .buttonStyle(.plain)
        }
      }
      .padding(.bottom, 8)
    }
  }

  // Helper function to count total blocked items
  private func getBlockedCount(from profile: SharedData.ProfileSnapshot) -> Int {
    let appCount =
      profile.selectedActivity.categories.count + profile.selectedActivity.applications.count
    let webDomainCount = profile.selectedActivity.webDomains.count
    let customDomainCount = profile.domains?.count ?? 0
    return appCount + webDomainCount + customDomainCount
  }

  // Helper function to count enabled options
  private func getEnabledOptionsCount(from profile: SharedData.ProfileSnapshot) -> Int {
    var count = 0
    if profile.enableLiveActivity { count += 1 }
    if profile.enableBreaks { count += 1 }
    if profile.enableStrictMode { count += 1 }
    if profile.enableAllowMode { count += 1 }
    if profile.enableAllowModeDomains { count += 1 }
    if profile.reminderTimeInSeconds != nil { count += 1 }
    if profile.physicalUnblockNFCTagId != nil { count += 1 }
    if profile.physicalUnblockQRCodeId != nil { count += 1 }
    if profile.schedule != nil { count += 1 }
    if profile.disableBackgroundStops == true { count += 1 }
    return count
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
    focusMessage: "Stay focused and avoid distractions",
    enableQuickLaunch: false
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
      breakStartTime: Date(timeIntervalSinceNow: -60),
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
    focusMessage: "Deep focus time",
    enableQuickLaunch: true
  )
  ProfileWidgetEntry(
    date: .now,
    selectedProfileId: "test-id-3",
    profileName: "No Profile Selected",
    activeSession: nil,
    profileSnapshot: nil,
    deepLinkURL: URL(string: "foqos://"),
    focusMessage: "Select a profile to get started",
    enableQuickLaunch: true
  )
}
