//
//  ProfileSelectionIntent.swift
//  FoqosWidget
//
//  Created by Ali Waseem on 2025-03-11.
//

import AppIntents
import Foundation

// MARK: - Profile Entity for Widget Configuration
struct WidgetProfileEntity: AppEntity {
  let id: String
  let name: String

  init(id: String, name: String) {
    self.id = id
    self.name = name
  }

  static var typeDisplayRepresentation = TypeDisplayRepresentation(
    name: "Profile"
  )

  static var defaultQuery = WidgetProfileQuery()

  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(title: "\(name)")
  }
}

// MARK: - Profile Query for Widget Configuration
struct WidgetProfileQuery: EntityQuery {
  func entities(for identifiers: [WidgetProfileEntity.ID]) async throws -> [WidgetProfileEntity] {
    let profiles = try await WidgetDataStore.profiles()
    return identifiers.compactMap { id in profiles.first { $0.id == id } }
  }

  func suggestedEntities() async throws -> [WidgetProfileEntity] {
    try await WidgetDataStore.profiles()
  }

  func defaultResult() async -> WidgetProfileEntity? {
    return try? await suggestedEntities().first
  }
}

enum WidgetActivityPeriod: String, AppEnum {
  case week
  case month

  static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Activity view")
  static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
    .week: "Weekly chart",
    .month: "Monthly grid",
  ]
}

// MARK: - Widget Configuration Intent
struct ProfileSelectionIntent: WidgetConfigurationIntent {
  static var title: LocalizedStringResource = "Select Profile"
  static var description = IntentDescription("Choose which profile to display in the widget")

  @Parameter(title: "Activity view", default: .week)
  var activityPeriod: WidgetActivityPeriod

  @Parameter(title: "Profile", description: "The profile to monitor in the widget")
  var profile: WidgetProfileEntity?

  @Parameter(
    title: "Quick Launch",
    description: "Launch the profile directly without navigating to the app")
  var useProfileURL: Bool?

  init() {
    self.useProfileURL = false
  }

  init(profile: WidgetProfileEntity?, useProfileURL: Bool = false) {
    self.profile = profile
    self.useProfileURL = useProfileURL
  }
}
