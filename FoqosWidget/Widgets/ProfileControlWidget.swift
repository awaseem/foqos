import AppIntents
import SwiftUI
import WidgetKit

struct ProfileControlWidget: Widget {
  let kind = "ProfileControlWidget"

  var body: some WidgetConfiguration {
    AppIntentConfiguration(
      kind: kind, intent: ProfileSelectionIntent.self, provider: ProfileControlProvider()
    ) { entry in
      ProfileWidgetEntryView(entry: entry)
        .containerBackground(for: .widget) {
          ProfileWidgetBackground()
        }
    }
    .configurationDisplayName("Foqos Profile")
    .description(
      "Your focus, at a glance. Weekly charts, a monthly activity grid, and your profile in your theme."
    )
    .supportedFamilies([
      .systemSmall, .systemMedium, .accessoryRectangular, .accessoryInline,
    ])
  }
}
