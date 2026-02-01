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
    "Stops the currently active Foqos session, if any. Useful for quickly ending a blocking session from Shortcuts or Siri."
  )

  static var openAppWhenRun: Bool = false

  @MainActor
  func perform() async throws -> some IntentResult & ProvidesDialog {
    let strategyManager = StrategyManager.shared

    // Load the active session
    strategyManager.loadActiveSession(context: modelContext)

    // Check if there's an active session
    guard let activeSession = strategyManager.activeSession, activeSession.isActive else {
      return .result(dialog: "No active session to stop.")
    }

    let profileName = activeSession.blockedProfile.name

    // Check if the profile has background stops disabled
    if activeSession.blockedProfile.disableBackgroundStops {
      return .result(
        dialog: "Cannot stop \(profileName) from a shortcut. Background stops are disabled for this profile."
      )
    }

    // Stop the session using the manual strategy
    strategyManager.stopSessionFromBackground(
      activeSession.blockedProfile.id,
      context: modelContext
    )

    return .result(dialog: "Stopped \(profileName) session.")
  }
}
