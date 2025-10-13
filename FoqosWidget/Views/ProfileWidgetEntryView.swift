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
        // Top section - Profile name and hourglass
        HStack {
          Text(entry.profileName ?? "No Profile")
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.primary)
            .lineLimit(1)

          Spacer()

          Image(systemName: "hourglass")
            .font(.caption)
            .foregroundColor(.purple)
        }
        .padding(.horizontal, 4)
        .padding(.top, 8)

        // Content section
        VStack(spacing: 4) {
          if entry.isSessionActive {
            // Active session view
            if let startTime = entry.sessionStartTime {
              Text(
                Date(
                  timeIntervalSinceNow: startTime.timeIntervalSince1970
                    - Date().timeIntervalSince1970
                ),
                style: .timer
              )
              .font(.caption)
              .fontWeight(.semibold)
              .foregroundColor(.primary)
              .multilineTextAlignment(.center)
            }
          } else {
            // Inactive session - show profile indicators
            ProfileIndicatorsView(profileSnapshot: entry.profileSnapshot)
          }
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    }
  }
}

// MARK: - Profile Indicators View
struct ProfileIndicatorsView: View {
  let profileSnapshot: SharedData.ProfileSnapshot?

  var body: some View {
    if let profile = profileSnapshot {
      let indicators = getIndicators(for: profile)

      if indicators.isEmpty {
        Text("Tap to Start")
          .font(.caption2)
          .foregroundColor(.secondary)
      } else {
        LazyVGrid(
          columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
          ], spacing: 4
        ) {
          ForEach(indicators, id: \.text) { indicator in
            IndicatorChip(
              icon: indicator.icon,
              text: indicator.text,
              color: indicator.color
            )
          }
        }
      }
    } else {
      Text("Tap to Start")
        .font(.caption2)
        .foregroundColor(.secondary)
    }
  }

  private func getIndicators(for profile: SharedData.ProfileSnapshot) -> [(
    icon: String, text: String, color: Color
  )] {
    var indicators: [(icon: String, text: String, color: Color)] = []

    if profile.enableBreaks {
      indicators.append((icon: "cup.and.heat.waves.fill", text: "Breaks", color: .orange))
    }

    if profile.enableStrictMode {
      indicators.append((icon: "lock.shield.fill", text: "Strict", color: .red))
    }

    if profile.enableAllowMode {
      indicators.append((icon: "checkmark.shield.fill", text: "Allow", color: .green))
    }

    if profile.enableAllowModeDomains {
      indicators.append((icon: "globe", text: "Domains", color: .blue))
    }

    return indicators
  }
}

// MARK: - Indicator Chip
struct IndicatorChip: View {
  let icon: String
  let text: String
  let color: Color

  var body: some View {
    HStack(spacing: 2) {
      Image(systemName: icon)
        .font(.system(size: 9, weight: .medium))
        .foregroundColor(color)

      Text(text)
        .font(.system(size: 9, weight: .medium))
        .foregroundColor(color)
    }
    .padding(.horizontal, 6)
    .padding(.vertical, 3)
    .background(color.opacity(0.15))
    .cornerRadius(6)
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
      domains: nil,
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
    profileSnapshot: SharedData.ProfileSnapshot(
      id: UUID(),
      name: "Deep Work",
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
      domains: nil,
      physicalUnblockNFCTagId: nil,
      physicalUnblockQRCodeId: nil,
      schedule: nil,
      disableBackgroundStops: nil
    ),
    deepLinkURL: URL(string: "foqos://profile/test-id"),
    focusMessage: "Deep focus time"
  )
  ProfileWidgetEntry(
    date: .now,
    selectedProfileId: "test-id",
    profileName: "Break Time",
    activeSession: SharedData.SessionSnapshot(
      id: "test-session",
      tag: "test-tag",
      blockedProfileId: UUID(),
      startTime: Date(timeIntervalSinceNow: -600),
      endTime: nil,
      breakStartTime: Date(timeIntervalSinceNow: -60),
      breakEndTime: nil,
      forceStarted: true
    ),
    profileSnapshot: nil,
    deepLinkURL: URL(string: "foqos://profile/test-id"),
    focusMessage: "Taking a break"
  )
}
