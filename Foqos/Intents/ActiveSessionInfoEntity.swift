import AppIntents
import Foundation
import SwiftData

struct ActiveSessionInfoEntity: AppEntity, Identifiable {
  var id: String

  @Property(title: "Profile Name") var profileName: String
  @Property(title: "Started At") var startedAt: Date
  @Property(title: "Ends At") var endsAt: Date?

  static var typeDisplayRepresentation = TypeDisplayRepresentation(
    name: "Active Session Info"
  )

  static var defaultQuery = ActiveSessionInfoQuery()

  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(title: "\(profileName)")
  }

  init(session: BlockedProfileSession) {
    id = session.id
    profileName = session.blockedProfile.name
    startedAt = session.startTime
    endsAt = session.endTime ?? SessionTimeCalculator.expectedSessionEndTime(for: session)
  }
}

struct ActiveSessionInfoQuery: EntityQuery {
  @Dependency(key: "ModelContainer")
  private var modelContainer: ModelContainer

  @MainActor
  private var modelContext: ModelContext {
    return modelContainer.mainContext
  }

  @MainActor
  func entities(for identifiers: [String]) async throws -> [ActiveSessionInfoEntity] {
    let results = try modelContext.fetch(
      FetchDescriptor<BlockedProfileSession>(
        predicate: #Predicate { identifiers.contains($0.id) }
      )
    )
    return results.map { ActiveSessionInfoEntity(session: $0) }
  }
}
