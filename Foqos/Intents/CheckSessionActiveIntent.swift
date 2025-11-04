import AppIntents
import SwiftData

struct CheckSessionActiveIntent: AppIntent {
  @Dependency(key: "ModelContainer")
  private var modelContainer: ModelContainer

  @MainActor
  private var modelContext: ModelContext {
    return modelContainer.mainContext
  }

  static var title: LocalizedStringResource = "Check if Foqos Session is Active"
  static var description = IntentDescription(
    "Check if any Foqos blocking session is currently active and return true or false. Useful for automation and shortcuts."
  )

  static var openAppWhenRun: Bool = false

  @MainActor
  func perform() async throws -> some IntentResult & ReturnsValue<Bool> & ProvidesDialog {
    let strategyManager = StrategyManager.shared

    // Load the active session (this syncs scheduled sessions)
    strategyManager.loadActiveSession(context: modelContext)

    // Check if there's any active session using the isBlocking property
    let isActive = strategyManager.isBlocking

    let dialogMessage =
      isActive
      ? "A Foqos session is currently active."
      : "No Foqos session is active."

    return .result(
      value: isActive,
      dialog: .init(stringLiteral: dialogMessage)
    )
  }
}
