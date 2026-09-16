import AppIntents

struct FoqosShortcutsProvider: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: StartProfileIntent(),
      phrases: [
        "Start a profile in \(.applicationName)",
        "Start \(\.$profile) in \(.applicationName)",
        "Start blocking with \(.applicationName)",
      ],
      shortTitle: "Start Profile",
      systemImageName: "play.circle"
    )
    AppShortcut(
      intent: StopActiveSessionIntent(),
      phrases: [
        "Stop my session in \(.applicationName)",
        "Stop blocking with \(.applicationName)",
      ],
      shortTitle: "Stop Session",
      systemImageName: "stop.circle"
    )
    AppShortcut(
      intent: PauseActiveSessionIntent(),
      phrases: [
        "Pause my session in \(.applicationName)",
        "Pause blocking with \(.applicationName)",
      ],
      shortTitle: "Pause Session",
      systemImageName: "pause.circle"
    )
    AppShortcut(
      intent: CheckSessionActiveIntent(),
      phrases: [
        "Am I blocking apps with \(.applicationName)",
        "Is my session active in \(.applicationName)",
      ],
      shortTitle: "Check Session",
      systemImageName: "checkmark.circle"
    )
    AppShortcut(
      intent: GetActiveSessionInfoIntent(),
      phrases: [
        "What profile is active in \(.applicationName)",
        "Get my session info in \(.applicationName)",
      ],
      shortTitle: "Session Info",
      systemImageName: "info.circle"
    )
  }
}
