import Foundation
import SwiftData

@MainActor
enum WidgetDataStore {
  static func profiles() throws -> [WidgetProfileEntity] {
    let container = try FoqosModelContainer.make()
    let context = ModelContext(container)
    let descriptor = FetchDescriptor<BlockedProfiles>(sortBy: [SortDescriptor(\.name)])
    return try context.fetch(descriptor).map {
      WidgetProfileEntity(id: $0.id.uuidString, name: $0.name)
    }
  }

  static func entry(for configuration: ProfileSelectionIntent, at date: Date) throws
    -> ProfileWidgetEntry
  {
    let container = try FoqosModelContainer.make()
    let context = ModelContext(container)
    context.autosaveEnabled = false

    var activeDescriptor = FetchDescriptor<BlockedProfileSession>(
      predicate: #Predicate { $0.endTime == nil },
      sortBy: [SortDescriptor(\.startTime, order: .reverse)]
    )
    activeDescriptor.fetchLimit = 1
    let activeSession = try context.fetch(activeDescriptor).first

    let profile: BlockedProfiles?
    if let selected = configuration.profile {
      if let id = UUID(uuidString: selected.id) {
        var descriptor = FetchDescriptor<BlockedProfiles>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        profile = try context.fetch(descriptor).first
      } else {
        profile = nil
      }
    } else if let activeSession {
      profile = activeSession.blockedProfile
    } else {
      var descriptor = FetchDescriptor<BlockedProfiles>(sortBy: [
        SortDescriptor(\.updatedAt, order: .reverse)
      ])
      descriptor.fetchLimit = 1
      profile = try context.fetch(descriptor).first
    }

    var intervals: [WidgetSessionInterval] = []
    if let profile {
      let profileID = profile.id
      let calendar = Calendar.current
      let start = min(
        calendar.dateInterval(of: .month, for: date)!.start,
        calendar.dateInterval(of: .weekOfYear, for: date)!.start
      )
      let descriptor = FetchDescriptor<BlockedProfileSession>(
        predicate: #Predicate { session in
          session.blockedProfile.id == profileID && session.startTime < date
            && (session.endTime ?? date) > start
        }
      )
      intervals = try context.fetch(descriptor).map {
        WidgetSessionInterval(start: $0.startTime, end: $0.endTime ?? date)
      }
    }

    let path = configuration.useProfileURL == true ? "profile" : "navigate"
    let url = profile.flatMap { URL(string: "https://foqos.app/\(path)/\($0.id.uuidString)") }
    return ProfileWidgetEntry(
      date: date,
      selectedProfileId: profile?.id.uuidString,
      profileName: profile?.name,
      activeSession: activeSession.map {
        WidgetSessionInfo(
          blockedProfileId: $0.blockedProfile.id, startTime: $0.startTime, endTime: $0.endTime,
          breakStartTime: $0.breakStartTime, breakEndTime: $0.breakEndTime,
          pauseStartTime: $0.pauseStartTime, pauseEndTime: $0.pauseEndTime
        )
      },
      profileInfo: profile.map {
        WidgetProfileInfo(
          enableStrictMode: $0.enableStrictMode, enableAllowMode: $0.enableAllowMode,
          selectedItemCount: $0.selectedActivity.applications.count
            + $0.selectedActivity.categories.count
            + $0.selectedActivity.webDomains.count + ($0.domains?.count ?? 0),
          strategyID: $0.blockingStrategyId
        )
      },
      deepLinkURL: url,
      focusMessage: profile?.customReminderMessage ?? "Make room for what matters.",
      useProfileURL: configuration.useProfileURL,
      activity: .make(sessions: intervals, at: date),
      activityPeriod: configuration.activityPeriod,
      themeColor: ThemeManager().themeColor
    )
  }
}
