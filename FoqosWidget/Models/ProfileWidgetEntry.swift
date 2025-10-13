//
//  ProfileWidgetEntry.swift
//  FoqosWidget
//
//  Created by Ali Waseem on 2025-03-11.
//

import Foundation
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
  let useProfileURL: Bool?

  var isSessionActive: Bool {
    if let active = activeSession {
      return active.endTime == nil
    } else {
      return false
    }
  }

  var isBreakActive: Bool {
    guard let session = activeSession else { return false }
    return session.breakStartTime != nil && session.breakEndTime == nil
  }

  var sessionStartTime: Date? {
    return activeSession?.startTime
  }
}
