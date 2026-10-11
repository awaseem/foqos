import SwiftData

// SwiftData's default configuration uses the primary App Group in both targets.
// Keep the existing configuration so the app continues opening the same store.
enum FoqosModelContainer {
  static func make() throws -> ModelContainer {
    // Partner sharing uses separate CloudKit records; never sync the existing local models.
    let configuration = ModelConfiguration(cloudKitDatabase: .none)
    return try ModelContainer(
      for: BlockedProfileSession.self, BlockedProfiles.self, configurations: configuration)
  }
}
