import AppIntents
import SwiftData

struct BreakControlIntent: SetValueIntent, LiveActivityIntent {
  static var title: LocalizedStringResource = "Set Foqos Break State"
  static var isDiscoverable = false

  @Parameter(title: "Session ID") var sessionID: String
  @Parameter(title: "On Break") var value: Bool

  #if !FOQOS_WIDGET_EXTENSION
    @Dependency(key: "ModelContainer") private var modelContainer: ModelContainer
  #endif

  init() {}

  init(sessionID: String) {
    self.sessionID = sessionID
  }

  @MainActor
  func perform() async throws -> some IntentResult {
    try FoqosControlError.requireAppProcess()
    #if !FOQOS_WIDGET_EXTENSION
      try StrategyManager.shared.setBreakActiveFromControl(
        value, sessionID: sessionID, context: modelContainer.mainContext
      )
    #endif
    return .result()
  }
}
