import AppIntents
import SwiftData

struct StartBreakIntent: AppIntent {
  @Dependency(key: "ModelContainer")
  private var modelContainer: ModelContainer

  static var title: LocalizedStringResource = "Start Foqos Break"
  static var description = IntentDescription(
    "Start a break from the active Foqos session using its remaining break allowance. Breaks must be enabled for the profile."
  )
  static var openAppWhenRun: Bool = false

  @MainActor
  func perform() async throws -> some IntentResult & ProvidesDialog {
    let result = try StrategyManager.shared.startBreakFromBackground(
      context: modelContainer.mainContext
    )

    if result.didChange {
      return .result(dialog: "Started a break from \(result.profileName).")
    }
    return .result(dialog: "A break is already active for \(result.profileName).")
  }
}
