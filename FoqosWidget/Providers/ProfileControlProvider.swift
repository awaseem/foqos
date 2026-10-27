import AppIntents
import Foundation
import OSLog
import WidgetKit

struct ProfileControlProvider: AppIntentTimelineProvider {
  typealias Entry = ProfileWidgetEntry
  typealias Intent = ProfileSelectionIntent
  private let logger = Logger(subsystem: "dev.ambitionsoftware.foqos", category: "Widget")

  func placeholder(in context: Context) -> Entry {
    WidgetPreviewData.entry()
  }

  func snapshot(for configuration: Intent, in context: Context) async -> Entry {
    if context.isPreview { return WidgetPreviewData.entry(period: configuration.activityPeriod) }
    return await entry(for: configuration)
  }

  func timeline(for configuration: Intent, in context: Context) async -> Timeline<Entry> {
    let current = await entry(for: configuration)
    var nextRefresh = current.date.addingTimeInterval(current.isSessionActive ? 5 * 60 : 15 * 60)
    var entries = [current]
    if let end = current.sessionEndTime { nextRefresh = min(nextRefresh, end) }
    if let start = current.sessionStartTime, !current.isBreakActive, !current.isPauseActive {
      // The circular family shows "1h 15m" past an hour, so add an entry on each session minute
      // until the next reload.
      let elapsedMinutes = (current.date.timeIntervalSince(start) / 60).rounded(.down)
      var stepDate = start.addingTimeInterval((elapsedMinutes + 1) * 60)
      while stepDate < nextRefresh {
        var step = current
        step.date = stepDate
        entries.append(step)
        stepDate.addTimeInterval(60)
      }
    }
    return Timeline(entries: entries, policy: .after(nextRefresh))
  }

  private func entry(for configuration: Intent) async -> Entry {
    let now = Date()
    do {
      return try await WidgetDataStore.entry(for: configuration, at: now)
    } catch {
      logger.error("Unable to read widget data: \(error.localizedDescription, privacy: .public)")
      return Entry(
        date: now, selectedProfileId: nil, profileName: "Foqos", activeSession: nil,
        profileInfo: nil, deepLinkURL: URL(string: "foqos://"), focusMessage: "",
        useProfileURL: false, isDataUnavailable: true, activityPeriod: configuration.activityPeriod
      )
    }
  }
}
