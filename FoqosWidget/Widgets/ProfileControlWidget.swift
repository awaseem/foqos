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
      ProfileWidgetEntryView(entry: entry)
        .containerBackground(for: .widget) {
          // Use the entry's background color or clear if inactive
          if entry.isSessionActive {
            if entry.isBreakActive {
              Color.orange
            } else {
              Color.green
            }
          } else {
            Color.clear
          }
        }
    }
    .configurationDisplayName("Foqos Profile")
    .description("Monitor and control your selected focus profile")
    .supportedFamilies([.systemSmall])
  }
}
