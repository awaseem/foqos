import AppIntents
import SwiftUI
import WidgetKit

struct BreakSessionControl: ControlWidget {
  var body: some ControlWidgetConfiguration {
    StaticControlConfiguration(
      kind: "FoqosBreakSessionControl", provider: BreakSessionControlProvider()
    ) { state in
      ControlWidgetToggle(
        "Foqos Break", isOn: state.isBreakActive,
        action: BreakControlIntent(sessionID: state.session?.id ?? "")
      ) { isOnBreak in
        Label(
          isOnBreak ? "On Break" : (state.session == nil ? "No Session" : "Start Break"),
          systemImage: "cup.and.saucer.fill"
        )
        .controlWidgetActionHint(isOnBreak ? "End break" : "Start break")
      }
      .tint(.orange)
    }
    .displayName("Foqos Break")
    .description("Start or end a break in your active session using its remaining break allowance.")
  }
}

struct BreakSessionControlProvider: ControlValueProvider {
  var previewValue: FoqosControlState { FoqosControlState(session: nil) }

  func currentValue() async throws -> FoqosControlState {
    FoqosControlState(session: SharedData.getActiveSharedSession())
  }
}
