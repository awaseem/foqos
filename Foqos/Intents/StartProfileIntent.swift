import AppIntents
import SwiftData

struct StartProfileIntent: AppIntent {
  @Dependency(key: "ModelContainer")
  private var modelContainer: ModelContainer

  @MainActor
  private var modelContext: ModelContext {
    return modelContainer.mainContext
  }

  @Parameter(title: "Profile") var profile: BlockedProfileEntity

  @Parameter(title: "Duration minutes (Optional)") var durationInMinutes: Int?

  static var title: LocalizedStringResource = "Start Foqos Profile"

  static var description = IntentDescription(
    "Start a Foqos blocking profile. Optionally specify a timer duration in minutes (15-1440)."
  )

  @MainActor
  func perform() async throws -> some IntentResult {
    StrategyManager.shared.startSessionFromBackground(
      profile.id,
      context: modelContext,
      durationInMinutes: durationInMinutes
    )

    return .result()
  }
}
