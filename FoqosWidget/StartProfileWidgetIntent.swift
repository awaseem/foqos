//
//  StartProfileWidgetIntent.swift
//  FoqosWidget
//
//  Created by Ali Waseem on 2025-03-11.
//

import AppIntents
import Foundation
import WidgetKit

// MARK: - Widget Start Profile Intent
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
    let name = profileName ?? "Unknown Profile"

    // Find the profile by name from SharedData snapshots
    let profileSnapshots = SharedData.profileSnapshots
    guard let profileSnapshot = profileSnapshots.values.first(where: { $0.name == name }) else {
      return .result(
        dialog: IntentDialog("Profile '\(name)' not found.")
      )
    }

    print("Widget button pressed! Starting profile: \(name)")

    // If there is an existing active session, end it
    if SharedData.getActiveSharedSession() != nil {
      SharedData.endActiveSharedSession()
    }

    // Create a new active session for the profile
    SharedData.createSessionForSchedular(for: profileSnapshot.id)

    // Start restrictions using AppBlockerUtil
    let appBlocker = AppBlockerUtil()
    appBlocker.activateRestrictions(for: profileSnapshot)

    // Refresh widgets to show the active state
    WidgetCenter.shared.reloadTimelines(ofKind: "ProfileControlWidget")

    return .result(
      dialog: IntentDialog("Started \(name)!")
    )
  }
}
