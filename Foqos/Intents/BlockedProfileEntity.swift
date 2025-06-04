import AppIntents
import SwiftData

struct BlockedProfileEntity: AppEntity, Identifiable {
    let profile: BlockedProfiles

    var id: UUID { profile.id }
    var name: String { profile.name }

    static var typeDisplayRepresentation = TypeDisplayRepresentation(
        name: "Profile"
    )

    static var defaultQuery = BlockedProfilesQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(profile.name)")
    }
}

struct BlockedProfilesQuery: EntityQuery {
    @Dependency(key: "ModelContainer")
    private var modelContainer: ModelContainer
    
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

    func defaultResult() async -> BlockedProfileEntity? {
        try? await suggestedEntities().first
    }
}
