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
  @Environment(\.widgetFamily) var widgetFamily
  var entry: ProfileControlProvider.Entry

  // Computed property to determine if we should use white text
  private var shouldUseWhiteText: Bool {
    return entry.isBreakActive || entry.isSessionActive
  }

  // Computed property to determine if the widget should show as unavailable
  private var isUnavailable: Bool {
    guard let selectedProfileId = entry.selectedProfileId,
      let activeSession = entry.activeSession
    else {
      return false
    }

    // Check if the active session's profile ID matches the widget's selected profile ID
    return activeSession.blockedProfileId.uuidString != selectedProfileId
  }

  private var quickLaunchEnabled: Bool {
    return entry.useProfileURL == true
  }

  private var linkToOpen: URL {
    // Don't open the app via profile to stop the session
    if entry.isBreakActive || entry.isSessionActive {
      return URL(string: "https://foqos.app")!
    }

    return entry.deepLinkURL ?? URL(string: "foqos://")!
  }

  var body: some View {
    switch widgetFamily {
    case .systemSmall:
      smallWidgetView
    case .systemMedium:
      mediumWidgetView
    case .accessoryCircular:
      circularAccessoryView
    case .accessoryRectangular:
      rectangularAccessoryView
    default:
      smallWidgetView
    }
  }

  // MARK: - Small Widget View (Original)
  private var smallWidgetView: some View {
    ZStack {
      // Main content
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

        // Middle section: Blocked count + enabled options count
        HStack {
          VStack(alignment: .leading, spacing: 2) {
            if let profile = entry.profileSnapshot {
              let blockedCount = getBlockedCount(from: profile)
              let enabledOptionsCount = getEnabledOptionsCount(from: profile)

              Text("\(blockedCount) Blocked")
                .font(.system(size: 10))
                .fontWeight(.medium)
                .foregroundColor(shouldUseWhiteText ? .white : .secondary)

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
        }

        // Bottom section: Status message or timer (takes up most space)
        VStack {
          if entry.isBreakActive {
            HStack(spacing: 4) {
              Image(systemName: "cup.and.saucer.fill")
                .font(.body)
                .foregroundColor(.white)
              Text("On a Break")
                .font(.body)
                .fontWeight(.bold)
                .foregroundColor(.white)
            }
          } else if entry.isSessionActive {
            if let startTime = entry.sessionStartTime {
              HStack(spacing: 4) {
                Image(systemName: "clock.fill")
                  .font(.body)
                  .foregroundColor(.white)
                Text(
                  Date(
                    timeIntervalSinceNow: startTime.timeIntervalSince1970
                      - Date().timeIntervalSince1970
                  ),
                  style: .timer
                )
                .font(.system(size: 22))
                .fontWeight(.bold)
                .foregroundColor(.white)
              }
            }
          } else {
            Link(destination: linkToOpen) {
              Text(quickLaunchEnabled ? "Tap to launch" : "Tap to open")
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(shouldUseWhiteText ? .white : .secondary)
            }
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 8)
      }
      .blur(radius: isUnavailable ? 3 : 0)

      // Unavailable overlay
      if isUnavailable {
        unavailableOverlay
      }
    }
  }

  // MARK: - Medium Widget View
  private var mediumWidgetView: some View {
    ZStack {
      HStack(spacing: 16) {
        // Left side: Profile info
        VStack(alignment: .leading, spacing: 8) {
          Text(entry.profileName ?? "No Profile")
            .font(.headline)
            .fontWeight(.bold)
            .foregroundColor(shouldUseWhiteText ? .white : .primary)
            .lineLimit(1)

          if let profile = entry.profileSnapshot {
            let blockedCount = getBlockedCount(from: profile)
            Text("\(blockedCount) apps blocked")
              .font(.subheadline)
              .foregroundColor(shouldUseWhiteText ? .white.opacity(0.8) : .secondary)
          }

          Spacer()

          // Status indicator
          HStack(spacing: 6) {
            Circle()
              .fill(entry.isSessionActive ? (entry.isBreakActive ? Color.orange : Color.green) : Color.gray)
              .frame(width: 8, height: 8)
            Text(entry.isSessionActive ? (entry.isBreakActive ? "On Break" : "Active") : "Inactive")
              .font(.caption)
              .foregroundColor(shouldUseWhiteText ? .white : .secondary)
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        // Right side: Timer or action
        VStack(alignment: .trailing, spacing: 8) {
          Image(systemName: entry.isSessionActive ? "shield.fill" : "shield")
            .font(.title)
            .foregroundColor(shouldUseWhiteText ? .white : .purple)

          Spacer()

          if entry.isSessionActive, let startTime = entry.sessionStartTime {
            Text(
              Date(
                timeIntervalSinceNow: startTime.timeIntervalSince1970
                  - Date().timeIntervalSince1970
              ),
              style: .timer
            )
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(shouldUseWhiteText ? .white : .primary)
            .monospacedDigit()
          } else {
            Link(destination: linkToOpen) {
              Text("Start")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.purple)
                .cornerRadius(8)
            }
          }
        }
      }
      .padding()
      .blur(radius: isUnavailable ? 3 : 0)

      if isUnavailable {
        unavailableOverlay
      }
    }
  }

  // MARK: - Circular Lock Screen Widget
  private var circularAccessoryView: some View {
    ZStack {
      AccessoryWidgetBackground()

      VStack(spacing: 2) {
        Image(systemName: entry.isSessionActive ? "shield.fill" : "shield")
          .font(.title2)
          .foregroundColor(entry.isSessionActive ? .green : .secondary)

        if entry.isSessionActive, !entry.isBreakActive {
          Text(elapsedTimeShort)
            .font(.caption2)
            .monospacedDigit()
        } else if entry.isBreakActive {
          Image(systemName: "cup.and.saucer.fill")
            .font(.caption2)
        }
      }
    }
  }

  // MARK: - Rectangular Lock Screen Widget
  private var rectangularAccessoryView: some View {
    HStack(spacing: 8) {
      Image(systemName: entry.isSessionActive ? "shield.fill" : "shield")
        .font(.title3)
        .foregroundColor(entry.isSessionActive ? .green : .secondary)

      VStack(alignment: .leading, spacing: 2) {
        Text(entry.profileName ?? "Foqos")
          .font(.headline)
          .lineLimit(1)

        if entry.isSessionActive {
          if entry.isBreakActive {
            Text("On Break")
              .font(.caption)
              .foregroundColor(.orange)
          } else if let startTime = entry.sessionStartTime {
            Text(
              Date(
                timeIntervalSinceNow: startTime.timeIntervalSince1970
                  - Date().timeIntervalSince1970
              ),
              style: .timer
            )
            .font(.caption)
            .monospacedDigit()
          }
        } else {
          Text("Tap to start")
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }

      Spacer()
    }
  }

  // MARK: - Unavailable Overlay
  private var unavailableOverlay: some View {
    VStack(spacing: 4) {
      Image(systemName: "exclamationmark.triangle.fill")
        .font(.title2)
        .foregroundColor(.orange)

      Text("Unavailable")
        .font(.system(size: 16))
        .fontWeight(.bold)
        .foregroundColor(.primary)

      Text("Different profile active")
        .font(.system(size: 10))
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(UIColor.systemBackground).opacity(0.9))
    .cornerRadius(8)
  }

  // MARK: - Elapsed Time Short Format
  private var elapsedTimeShort: String {
    guard let startTime = entry.sessionStartTime else { return "0:00" }
    let elapsed = Date().timeIntervalSince(startTime)
    let minutes = Int(elapsed) / 60
    let hours = minutes / 60
    if hours > 0 {
      return "\(hours)h"
    } else {
      return "\(minutes)m"
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
  // Preview 1: No active session
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
      enableSafariBlocking: true,
      domains: ["facebook.com", "twitter.com", "instagram.com"],
      physicalUnblockNFCTagId: nil,
      physicalUnblockQRCodeId: nil,
      schedule: nil,
      disableBackgroundStops: nil
    ),
    deepLinkURL: URL(string: "https://foqos.app/profile/test-id"),
    focusMessage: "Stay focused and avoid distractions",
    useProfileURL: true
  )

  // Preview 2: Active session matching widget profile
  let activeProfileId = UUID()
  ProfileWidgetEntry(
    date: .now,
    selectedProfileId: activeProfileId.uuidString,
    profileName: "Deep Work Session",
    activeSession: SharedData.SessionSnapshot(
      id: "test-session",
      tag: "test-tag",
      blockedProfileId: activeProfileId,  // Matches selectedProfileId
      startTime: Date(timeIntervalSinceNow: -300),  // Started 5 minutes ago
      endTime: nil,
      breakStartTime: nil,  // No break active
      breakEndTime: nil,
      forceStarted: true
    ),
    profileSnapshot: SharedData.ProfileSnapshot(
      id: activeProfileId,
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
      enableSafariBlocking: true,
      domains: ["youtube.com", "reddit.com"],
      physicalUnblockNFCTagId: nil,
      physicalUnblockQRCodeId: nil,
      schedule: nil,
      disableBackgroundStops: nil
    ),
    deepLinkURL: URL(string: "https://foqos.app/profile/\(activeProfileId.uuidString)"),
    focusMessage: "Deep focus time",
    useProfileURL: true
  )

  // Preview 3: Active session with break matching widget profile
  let breakProfileId = UUID()
  ProfileWidgetEntry(
    date: .now,
    selectedProfileId: breakProfileId.uuidString,
    profileName: "Study Session",
    activeSession: SharedData.SessionSnapshot(
      id: "test-session-break",
      tag: "test-tag-break",
      blockedProfileId: breakProfileId,  // Matches selectedProfileId
      startTime: Date(timeIntervalSinceNow: -600),  // Started 10 minutes ago
      endTime: nil,
      breakStartTime: Date(timeIntervalSinceNow: -60),  // Break started 1 minute ago
      breakEndTime: nil,
      forceStarted: true
    ),
    profileSnapshot: SharedData.ProfileSnapshot(
      id: breakProfileId,
      name: "Study Session",
      selectedActivity: FamilyActivitySelection(),
      createdAt: Date(),
      updatedAt: Date(),
      blockingStrategyId: nil,
      order: 0,
      enableLiveActivity: true,
      reminderTimeInSeconds: nil,
      customReminderMessage: nil,
      enableBreaks: true,
      enableStrictMode: true,
      enableAllowMode: false,
      enableAllowModeDomains: false,
      enableSafariBlocking: true,
      domains: ["tiktok.com", "instagram.com", "snapchat.com"],
      physicalUnblockNFCTagId: nil,
      physicalUnblockQRCodeId: nil,
      schedule: nil,
      disableBackgroundStops: nil
    ),
    deepLinkURL: URL(string: "https://foqos.app/profile/\(breakProfileId.uuidString)"),
    focusMessage: "Take a well-deserved break",
    useProfileURL: true
  )
  // Preview 4: No profile selected
  ProfileWidgetEntry(
    date: .now,
    selectedProfileId: nil,
    profileName: "No Profile Selected",
    activeSession: nil,
    profileSnapshot: nil,
    deepLinkURL: URL(string: "foqos://"),
    focusMessage: "Select a profile to get started",
    useProfileURL: false
  )

  // Preview 5: Unavailable state - different profile active
  let unavailableProfileId = UUID()
  let differentActiveProfileId = UUID()  // Different from unavailableProfileId
  ProfileWidgetEntry(
    date: .now,
    selectedProfileId: unavailableProfileId.uuidString,
    profileName: "Work Focus",
    activeSession: SharedData.SessionSnapshot(
      id: "different-session",
      tag: "different-tag",
      blockedProfileId: differentActiveProfileId,  // Different UUID than selectedProfileId
      startTime: Date(timeIntervalSinceNow: -180),  // Started 3 minutes ago
      endTime: nil,
      breakStartTime: nil,
      breakEndTime: nil,
      forceStarted: true
    ),
    profileSnapshot: SharedData.ProfileSnapshot(
      id: unavailableProfileId,
      name: "Work Focus",
      selectedActivity: FamilyActivitySelection(),
      createdAt: Date(),
      updatedAt: Date(),
      blockingStrategyId: nil,
      order: 0,
      enableLiveActivity: true,
      reminderTimeInSeconds: nil,
      customReminderMessage: nil,
      enableBreaks: true,
      enableStrictMode: true,
      enableAllowMode: false,
      enableAllowModeDomains: false,
      enableSafariBlocking: true,
      domains: ["linkedin.com", "slack.com"],
      physicalUnblockNFCTagId: nil,
      physicalUnblockQRCodeId: nil,
      schedule: nil,
      disableBackgroundStops: nil
    ),
    deepLinkURL: URL(string: "https://foqos.app/profile/\(unavailableProfileId.uuidString)"),
    focusMessage: "Different profile is currently active",
    useProfileURL: true
  )
}
