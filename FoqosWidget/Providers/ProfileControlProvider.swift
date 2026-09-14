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
    let nextRefresh = current.date.addingTimeInterval(current.isSessionActive ? 5 * 60 : 15 * 60)
    return Timeline(entries: [current], policy: .after(nextRefresh))
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
