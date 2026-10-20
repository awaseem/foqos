import AppIntents
import SwiftUI
import WidgetKit

struct ProfileSessionControl: ControlWidget {
  var body: some ControlWidgetConfiguration {
    AppIntentControlConfiguration(
      kind: "FoqosProfileSessionControl", provider: ProfileSessionControlProvider()
    ) { state in
      ControlWidgetToggle(
        state.name,
        isOn: state.isActive,
        action: ProfileControlIntent(profileID: state.profileID)
      ) { isActive in
        Label(isActive ? "Active" : "Start", systemImage: state.icon.systemImage)
          .controlWidgetActionHint(isActive ? "Stop profile" : "Start profile")
      }
      .tint(.green)
    }
    .displayName("Foqos Profile")
    .description(
      "Start a profile like the Start Foqos Profile shortcut, or stop it when background stops are allowed."
    )
    .promptsForUserConfiguration()
  }
}

struct ProfileSessionControlConfiguration: ControlConfigurationIntent {
  static var title: LocalizedStringResource = "Choose Profile"

  @Parameter(title: "Profile") var profile: WidgetProfileEntity?
  @Parameter(title: "Icon", default: .hourglass) var icon: FoqosControlIcon
}

struct ProfileSessionControlProvider: AppIntentControlValueProvider {
  struct Value {
    var profileID: String
    var name: String
    var isActive: Bool
    var icon: FoqosControlIcon
  }

  func previewValue(configuration: ProfileSessionControlConfiguration) -> Value {
    Value(
      profileID: configuration.profile?.id ?? "",
      name: configuration.profile?.name ?? "Foqos Profile", isActive: false,
      icon: configuration.icon
    )
  }

  func currentValue(configuration: ProfileSessionControlConfiguration) async throws -> Value {
    let profiles = try await WidgetDataStore.profiles()
    let profile = profiles.first { $0.id == configuration.profile?.id }
    let state = FoqosControlState(session: SharedData.getActiveSharedSession())
    return Value(
      profileID: profile?.id ?? "", name: profile?.name ?? "Choose Profile",
      isActive: state.isProfileActive(profile?.id), icon: configuration.icon
    )
  }
}
