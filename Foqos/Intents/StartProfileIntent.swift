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
    let strategyManager = StrategyManager.shared

    if let duration = durationInMinutes {
      if duration < 15 || duration > 1440 {
        strategyManager.errorMessage = "Duration must be between 15 and 1440 minutes"
        return .result()
      }
      strategyManager.startSessionFromBackgroundWithTimer(
        profile.id,
        context: modelContext,
        durationInMinutes: duration
      )
    } else {
      strategyManager.startSessionFromBackground(
        profile.id,
        context: modelContext
      )
    }

    return .result()
  }
}
