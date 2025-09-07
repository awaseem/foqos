import AppIntents
import SwiftData

struct StopProfileIntent: AppIntent {
  @Dependency(key: "ModelContainer")
  private var modelContainer: ModelContainer

  @MainActor
  private var modelContext: ModelContext {
    return modelContainer.mainContext
  }

  @Parameter(title: "Profile") var profile: BlockedProfileEntity

  static var title: LocalizedStringResource = "Stop Foqos Profile"

  @MainActor
  func perform() async throws -> some IntentResult {
    let strategyManager = StrategyManager.shared

    strategyManager
      .stopSessionFromBackground(
        profile.id,
        context: modelContext
      )

    return .result()
  }
}
