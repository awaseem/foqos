import AppIntents
import SwiftData

struct GetActiveSessionInfoIntent: AppIntent {
  @Dependency(key: "ModelContainer")
  private var modelContainer: ModelContainer

  @MainActor
  private var modelContext: ModelContext {
    return modelContainer.mainContext
  }

  static var title: LocalizedStringResource = "Get Active Session Info"
  static var description = IntentDescription(
    "Get the profile name, start date, and optional end date for the active Foqos session."
  )

  static var openAppWhenRun: Bool = false

  @MainActor
  func perform() async throws
    -> some IntentResult & ReturnsValue<ActiveSessionInfoEntity?> & ProvidesDialog
  {
    let strategyManager = StrategyManager.shared
    strategyManager.loadActiveSession(context: modelContext)

    guard let activeSession = strategyManager.activeSession, activeSession.isActive else {
      return .result(
        value: Optional<ActiveSessionInfoEntity>.none,
        dialog: "No Foqos session is active."
      )
    }

    let sessionInfo = ActiveSessionInfoEntity(session: activeSession)
    return .result(
      value: Optional(sessionInfo),
      dialog: "\(activeSession.blockedProfile.name) is active."
    )
  }
}
