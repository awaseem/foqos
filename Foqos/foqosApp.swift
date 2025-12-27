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
import UIKit

private let container: ModelContainer = {
  do {
    return try ModelContainer(
      for: BlockedProfileSession.self,
      BlockedProfiles.self,
      FocusStreak.self,
      PomodoroSession.self
    )
  } catch {
    fatalError("Couldn't create ModelContainer: \(error)")
  }
}()

// MARK: - App Delegate for Quick Actions
class AppDelegate: NSObject, UIApplicationDelegate {
  static var navigationManager: NavigationManager?

  func application(
    _ application: UIApplication,
    configurationForConnecting connectingSceneSession: UISceneSession,
    options: UIScene.ConnectionOptions
  ) -> UISceneConfiguration {
    // Handle quick action if app was launched from one
    if let shortcutItem = options.shortcutItem {
      AppDelegate.navigationManager?.handleQuickAction(shortcutItem)
    }
    let configuration = UISceneConfiguration(
      name: connectingSceneSession.configuration.name,
      sessionRole: connectingSceneSession.role
    )
    configuration.delegateClass = SceneDelegate.self
    return configuration
  }
}

// MARK: - Scene Delegate for Quick Actions when app is running
class SceneDelegate: NSObject, UIWindowSceneDelegate {
  func windowScene(
    _ windowScene: UIWindowScene,
    performActionFor shortcutItem: UIApplicationShortcutItem,
    completionHandler: @escaping (Bool) -> Void
  ) {
    AppDelegate.navigationManager?.handleQuickAction(shortcutItem)
    completionHandler(true)
  }
}

@main
struct foqosApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

  @StateObject private var requestAuthorizer = RequestAuthorizer()
  @StateObject private var donationManager = TipManager()
  @StateObject private var navigationManager = NavigationManager()
  @StateObject private var nfcWriter = NFCWriter()
  @StateObject private var ratingManager = RatingManager()

  // Singletons for shared functionality
  @StateObject private var startegyManager = StrategyManager.shared
  @StateObject private var liveActivityManager = LiveActivityManager.shared
  @StateObject private var themeManager = ThemeManager.shared

  init() {
    TimersUtil.registerBackgroundTasks()
  }

  var body: some Scene {
    WindowGroup {
      HomeView()
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
        .onAppear {
          // Connect navigation manager to app delegate for quick actions
          AppDelegate.navigationManager = navigationManager
        }
        .environmentObject(requestAuthorizer)
        .environmentObject(donationManager)
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
