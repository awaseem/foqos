//
//  ProfileControlWidget.swift
//  FoqosWidget
//
//  Created by Ali Waseem on 2025-03-11.
//

import AppIntents
import SwiftUI
import WidgetKit

// MARK: - Widget Configuration
struct ProfileControlWidget: Widget {
  let kind: String = "ProfileControlWidget"

  var body: some WidgetConfiguration {
    AppIntentConfiguration(
      kind: kind, intent: ProfileSelectionIntent.self, provider: ProfileControlProvider()
    ) { entry in
      if #available(iOS 17.0, *) {
        ProfileWidgetEntryView(entry: entry)
          .containerBackground(.fill.tertiary, for: .widget)
      } else {
        ProfileWidgetEntryView(entry: entry)
          .padding()
          .background()
      }
    }
    .configurationDisplayName("Foqos Profile")
    .description("Monitor and control your selected focus profile")
    .supportedFamilies([.systemSmall])
  }
}
