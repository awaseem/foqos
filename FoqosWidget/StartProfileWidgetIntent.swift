//
//  StartProfileWidgetIntent.swift
//  FoqosWidget
//
//  Created by Ali Waseem on 2025-03-11.
//

import AppIntents
import Foundation

// MARK: - Dummy Widget Start Profile Intent
struct StartProfileWidgetIntent: AppIntent {
  static var title: LocalizedStringResource = "Start Profile"
  static var description = IntentDescription("Start a focus profile from the widget")

  @Parameter(title: "Profile Name")
  var profileName: String?

  init() {}

  init(profileName: String?) {
    self.profileName = profileName
  }

  func perform() async throws -> some IntentResult {
    // Dummy implementation - just show a confirmation
    let name = profileName ?? "Unknown Profile"

    // In a real implementation, this would start the actual profile
    print("Widget button pressed! Starting profile: \(name)")

    return .result(
      dialog: IntentDialog("Started \(name)! This is a dummy action.")
    )
  }
}
