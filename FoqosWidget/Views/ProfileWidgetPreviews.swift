//
//  ProfileWidgetPreviews.swift
//  FoqosWidget
//
//  Created by Ali Waseem on 2025-03-11.
//

import SwiftUI
import WidgetKit

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
