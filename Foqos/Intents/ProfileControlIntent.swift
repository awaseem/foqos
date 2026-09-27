import AppIntents
import SwiftData

struct ProfileControlIntent: SetValueIntent, LiveActivityIntent {
  static var title: LocalizedStringResource = "Set Foqos Profile State"
  static var isDiscoverable = false

  @Parameter(title: "Profile ID") var profileID: String
  @Parameter(title: "Active") var value: Bool

  #if !FOQOS_WIDGET_EXTENSION
    @Dependency(key: "ModelContainer") private var modelContainer: ModelContainer
  #endif

  init() {}

  init(profileID: String) {
    self.profileID = profileID
  }

  @MainActor
  func perform() async throws -> some IntentResult {
    // LiveActivityIntent runs in the app, where the blocking services are available.
    try FoqosControlError.requireAppProcess()
    #if !FOQOS_WIDGET_EXTENSION
      guard let id = UUID(uuidString: profileID) else {
        throw FoqosControlError.profileUnavailable
      }
      try StrategyManager.shared.setProfileActiveFromControl(
        value, profileID: id, context: modelContainer.mainContext
      )
    #endif
    return .result()
  }
}
