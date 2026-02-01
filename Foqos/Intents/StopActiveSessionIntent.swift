import AppIntents
import SwiftData

struct StopActiveSessionIntent: AppIntent {
  @Dependency(key: "ModelContainer")
  private var modelContainer: ModelContainer

  @MainActor
  private var modelContext: ModelContext {
    return modelContainer.mainContext
  }

  static var title: LocalizedStringResource = "Stop Active Foqos Session"
  static var description = IntentDescription(
    "Attempts to stop any currently active Foqos session."
  )

  static var openAppWhenRun: Bool = false

  @MainActor
  func perform() async throws -> some IntentResult & ReturnsValue<Bool> & ProvidesDialog {
    let strategyManager = StrategyManager.shared

    // Load the active session
    strategyManager.loadActiveSession(context: modelContext)
      
    // Check if there's an active session
    guard let blockedProfile = strategyManager.activeSession?.blockedProfile, strategyManager.isBlocking else {
      return .result(value: true, dialog: "No active Foqos session to stop")
    }

    let profileName = blockedProfile.name

    // Check if the profile has background stops disabled
    if blockedProfile.disableBackgroundStops {
      return .result(value: false, dialog: "Background stop disabled for profile: \(profileName)")
    }

    // Stop the session using the manual strategy
    strategyManager.stopSessionFromBackground(
      blockedProfile.id,
      context: modelContext
    )

    return .result(value: true, dialog: "Stopped profile: \(profileName)")
  }
}
