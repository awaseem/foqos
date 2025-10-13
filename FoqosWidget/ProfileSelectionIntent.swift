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
    let profileSnapshots = SharedData.profileSnapshots
    return identifiers.compactMap { id in
      guard let snapshot = profileSnapshots[id] else { return nil }
      return WidgetProfileEntity(id: id, name: snapshot.name)
    }
  }

  func suggestedEntities() async throws -> [WidgetProfileEntity] {
    let profileSnapshots = SharedData.profileSnapshots
    return profileSnapshots.map { (id, snapshot) in
      WidgetProfileEntity(id: id, name: snapshot.name)
    }.sorted { $0.name < $1.name }
  }

  func defaultResult() async -> WidgetProfileEntity? {
    return try? await suggestedEntities().first
  }
}

// MARK: - Widget Configuration Intent
struct ProfileSelectionIntent: WidgetConfigurationIntent {
  static var title: LocalizedStringResource = "Select Profile"
  static var description = IntentDescription("Choose which profile to display in the widget")

  @Parameter(title: "Profile", description: "The profile to monitor in the widget")
  var profile: WidgetProfileEntity?

  init() {}

  init(profile: WidgetProfileEntity?) {
    self.profile = profile
  }
}
