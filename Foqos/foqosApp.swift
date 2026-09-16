//
//  foqosApp.swift
//  foqos
//
//  Created by Ali Waseem on 2024-10-06.
//

import AppIntents
import BackgroundTasks
import SwiftData
import SwiftUI

@MainActor private let container: ModelContainer = {
  do {
    let container = try FoqosModelContainer.make()
    // Temporary backfill for users upgrading from the legacy NFC/QR fields.
    // Remove this in the next app version once the installed base has migrated.
    try PhysicalUnblockMigrationHelper.migrateOldPhysicalUnblockFields(
      in: container.mainContext
    )
    return container
  } catch {
    fatalError("Couldn't create ModelContainer: \(error)")
  }
}()

@main
struct foqosApp: App {
  @StateObject private var requestAuthorizer = RequestAuthorizer()
  @StateObject private var donationManager = TipManager()
  @StateObject private var navigationManager = NavigationManager()
  @StateObject private var nfcWriter = NFCWriter()
  @StateObject private var ratingManager = RatingManager()

  // Singletons for shared functionality
  @StateObject private var startegyManager = StrategyManager.shared
  @StateObject private var liveActivityManager = LiveActivityManager.shared
  @StateObject private var themeManager = ThemeManager.shared
  @StateObject private var alertsManager = AlertsManager.shared

  init() {
    TimersUtil.registerBackgroundTasks()

    let asyncDependency: @Sendable () async -> (ModelContainer) = {
      @MainActor in
      return container
    }
    AppDependencyManager.shared.add(
      key: "ModelContainer",
      dependency: asyncDependency
    )
    FoqosShortcutsProvider.updateAppShortcutParameters()
  }

  var body: some Scene {
    WindowGroup {
      HomeView()
        .onReceive(NotificationCenter.default.publisher(for: ModelContext.didSave)) {
          notification in
          guard let context = notification.object as? ModelContext,
            context === container.mainContext
          else { return }
          FoqosShortcutsProvider.updateAppShortcutParameters()
        }
        .onOpenURL { url in
          handleUniversalLink(url)
        }
        .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) {
          userActivity in
          guard let url = userActivity.webpageURL else {
            return
          }
          handleUniversalLink(url)

        }
        .environmentObject(requestAuthorizer)
        .environmentObject(donationManager)
        .environmentObject(alertsManager)
        .environmentObject(startegyManager)
        .environmentObject(navigationManager)
        .environmentObject(nfcWriter)
        .environmentObject(ratingManager)
        .environmentObject(liveActivityManager)
        .environmentObject(themeManager)
    }
    .modelContainer(container)
  }

  private func handleUniversalLink(_ url: URL) {
    navigationManager.handleLink(url)
  }
}
