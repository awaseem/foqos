import AppIntents
import SwiftData

struct CheckProfileStatusIntent: AppIntent {
  @Dependency(key: "ModelContainer")
  private var modelContainer: ModelContainer

  @MainActor
  private var modelContext: ModelContext {
    return modelContainer.mainContext
  }

  @Parameter(title: "Profile") var profile: BlockedProfileEntity

  static var title: LocalizedStringResource = "Foqos Profile Status"
  static var description = IntentDescription(
    "Check if a Foqos profile is currently active and return the status as a boolean value.")

  @MainActor
  func perform() async throws -> some IntentResult & ReturnsValue<Bool> & ProvidesDialog {
    // Get the active session using the same method as StrategyManager
    let activeSession = BlockedProfileSession.mostRecentActiveSession(in: modelContext)

    // Check if there's an active session and if it belongs to the specified profile
    let isActive = activeSession?.blockedProfile.id == profile.id

    let dialogMessage =
      isActive
      ? "\(profile.name) is currently active."
      : "\(profile.name) is not active."

    return .result(
      value: isActive,
      dialog: .init(stringLiteral: dialogMessage)
    )
  }
}
