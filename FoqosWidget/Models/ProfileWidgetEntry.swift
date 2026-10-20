import Foundation
import SwiftUI
import WidgetKit

struct ProfileWidgetEntry: TimelineEntry {
  let date: Date
  let selectedProfileId: String?
  let profileName: String?
  let activeSession: WidgetSessionInfo?
  let profileInfo: WidgetProfileInfo?
  let deepLinkURL: URL?
  let focusMessage: String
  let useProfileURL: Bool?
  var isDataUnavailable = false
  var activity: WidgetActivitySummary = .make(sessions: [], at: .now)
  var activityPeriod: WidgetActivityPeriod = .week
  var themeColor: Color = Color(red: 0.537, green: 0.310, blue: 0.639)

  var isSessionActive: Bool {
    activeSession?.endTime == nil && activeSession != nil
      && activeSession?.blockedProfileId.uuidString == selectedProfileId
  }

  var hasOtherActiveProfile: Bool {
    activeSession != nil && activeSession?.endTime == nil && !isSessionActive
  }

  var isBreakActive: Bool {
    isSessionActive && activeSession?.breakStartTime != nil && activeSession?.breakEndTime == nil
  }

  var isPauseActive: Bool {
    isSessionActive && activeSession?.pauseStartTime != nil && activeSession?.pauseEndTime == nil
  }

  var sessionStartTime: Date? { isSessionActive ? activeSession?.startTime : nil }

  var destination: URL {
    if isSessionActive || hasOtherActiveProfile { return URL(string: "https://foqos.app")! }
    return deepLinkURL ?? URL(string: "foqos://")!
  }

  var statusLabel: String {
    if isDataUnavailable { return "Open Foqos to refresh" }
    if isPauseActive { return "Paused" }
    if isBreakActive { return "On a break" }
    if isSessionActive { return "Focusing" }
    if hasOtherActiveProfile { return "Another profile active" }
    if selectedProfileId == nil { return "Create a profile" }
    return useProfileURL == true ? "Start focusing" : "Open profile"
  }
}
