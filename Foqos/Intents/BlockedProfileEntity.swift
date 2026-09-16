import AppIntents
import SwiftData

struct BlockedProfileEntity: AppEntity, Identifiable {
  let id: UUID
  @Property(title: "Name") var name: String

  static var typeDisplayRepresentation = TypeDisplayRepresentation(
    name: "Profile"
  )

  static var defaultQuery = BlockedProfilesQuery()

  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(title: "\(name)")
  }

  init(profile: BlockedProfiles) {
    id = profile.id
    name = profile.name
  }
}

struct BlockedProfilesQuery: EntityStringQuery {
  @Dependency(key: "ModelContainer")
  private var modelContainer: ModelContainer

  init() {}

  init(modelContainer: ModelContainer) {
    self.modelContainer = modelContainer
  }

  @MainActor
  private var modelContext: ModelContext {
    return modelContainer.mainContext
  }

  @MainActor
  func entities(for identifiers: [UUID]) async throws
    -> [BlockedProfileEntity]
  {
    let results = try modelContext.fetch(
      FetchDescriptor<BlockedProfiles>(
        predicate: #Predicate { identifiers.contains($0.id) }
      )
    )
    return results.map { BlockedProfileEntity(profile: $0) }
  }

  @MainActor
  func suggestedEntities() async throws -> [BlockedProfileEntity] {
    let results = try modelContext.fetch(
      FetchDescriptor<BlockedProfiles>(sortBy: [.init(\.name)])
    )
    return results.map { BlockedProfileEntity(profile: $0) }
  }

  @MainActor
  func entities(matching string: String) async throws -> [BlockedProfileEntity] {
    let name = string.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !name.isEmpty else { return [] }

    let profiles = try await suggestedEntities()
    let exactMatches = profiles.filter {
      $0.name.compare(name, options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        == .orderedSame
    }
    if !exactMatches.isEmpty {
      return exactMatches
    }

    return profiles.filter { $0.name.localizedStandardContains(name) }
  }
}
