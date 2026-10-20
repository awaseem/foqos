import SwiftData

// SwiftData's default configuration uses the primary App Group in both targets.
// Keep the existing configuration so the app continues opening the same store.
enum FoqosModelContainer {
  static func make() throws -> ModelContainer {
    try ModelContainer(for: BlockedProfileSession.self, BlockedProfiles.self)
  }
}
