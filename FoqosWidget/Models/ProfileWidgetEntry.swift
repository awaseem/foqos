import Foundation
import SwiftUI
import WidgetKit

struct ProfileWidgetEntry: TimelineEntry {
  var date: Date
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

  var sessionEndTime: Date? {
    guard isSessionActive, !isBreakActive, !isPauseActive
    else { return nil }
    return activeSession?.expectedEndTime
  }

  var breakOrPauseRange: ClosedRange<Date>? {
    guard isBreakActive || isPauseActive,
      let start = isPauseActive ? activeSession?.pauseStartTime : activeSession?.breakStartTime,
      let end = activeSession?.breakOrPauseEndTime
    else { return nil }
    return start...max(start, end)
  }

  var timer: SessionTimer? {
    guard isSessionActive else { return nil }
    if isBreakActive || isPauseActive {
      guard let range = breakOrPauseRange else { return nil }
      return SessionTimer(startTime: range.lowerBound, endTime: range.upperBound)
    }
    return activeSession?.focusTimer
  }

  func timeline() -> Timeline<ProfileWidgetEntry> {
    var nextRefresh = date.addingTimeInterval(isSessionActive ? 5 * 60 : 15 * 60)
    var entries = [self]
    if let end = timer?.endTime, end > date {
      nextRefresh = min(nextRefresh, end)
    }
    if let timer {
      var stepDate = timer.nextMinuteUpdate(after: date)
      while let step = stepDate, step < nextRefresh {
        var entry = self
        entry.date = step
        entries.append(entry)
        stepDate = timer.nextMinuteUpdate(after: step)
      }
      // Widget reloads can be delayed. Include the zero state in the existing timeline.
      if let end = timer.endTime, end > date, end <= nextRefresh {
        var entry = self
        entry.date = end
        entries.append(entry)
      }
    }
    return Timeline(entries: entries, policy: .after(nextRefresh))
  }

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
