import AppIntents
import SwiftData

struct EndBreakIntent: AppIntent {
  @Dependency(key: "ModelContainer")
  private var modelContainer: ModelContainer

  static var title: LocalizedStringResource = "End Foqos Break"
  static var description = IntentDescription(
    "End the current Foqos break and resume blocking. Unused break time remains available when multiple breaks are enabled. Does nothing if no break is active."
  )
  static var openAppWhenRun: Bool = false

  @MainActor
  func perform() async throws -> some IntentResult & ProvidesDialog {
    guard
      let profileName = try StrategyManager.shared.endBreakFromBackground(
        context: modelContainer.mainContext
      )
    else {
      return .result(dialog: "No Foqos break is active.")
    }

    return .result(dialog: "Ended the break. \(profileName) is blocking again.")
  }
}
