import SwiftUI
import UIKit
import UserNotifications

/// Bridges Home Screen quick actions (long-press on the app icon) into SwiftUI.
final class QuickActionManager: ObservableObject {
  struct ProfileSnapshot: Equatable {
    let id: UUID
    let name: String
  }

  static let shared = QuickActionManager()

  static let startProfileActionType = "com.foqos.quickaction.startProfile"
  static let profileIdUserInfoKey = "profileId"

  // iOS shows at most four quick actions in total
  private static let maxShortcutItems = 4

  @Published var pendingProfileId: UUID?

  @discardableResult
  func handle(_ shortcutItem: UIApplicationShortcutItem) -> Bool {
    guard shortcutItem.type == Self.startProfileActionType,
      let rawId = shortcutItem.userInfo?[Self.profileIdUserInfoKey] as? String,
      let profileId = UUID(uuidString: rawId)
    else { return false }

    pendingProfileId = profileId
    return true
  }

  func updateShortcutItems(for profiles: [ProfileSnapshot]) {
    UIApplication.shared.shortcutItems = profiles.prefix(Self.maxShortcutItems).map { profile in
      UIApplicationShortcutItem(
        type: Self.startProfileActionType,
        localizedTitle: "Start \(profile.name)",
        localizedSubtitle: nil,
        icon: UIApplicationShortcutIcon(type: .play),
        userInfo: [Self.profileIdUserInfoKey: profile.id.uuidString as NSString]
      )
    }
  }
}

final class FoqosAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    return true
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter, willPresent notification: UNNotification
  ) async -> UNNotificationPresentationOptions {
    notification.request.identifier.hasPrefix(BlockingWarning.identifierPrefix)
      ? [.banner, .sound] : []
  }

  func application(
    _ application: UIApplication,
    configurationForConnecting connectingSceneSession: UISceneSession,
    options: UIScene.ConnectionOptions
  ) -> UISceneConfiguration {
    // Cold launch from a quick action delivers the item here rather than to the scene delegate
    if let shortcutItem = options.shortcutItem {
      QuickActionManager.shared.handle(shortcutItem)
    }

    let configuration = UISceneConfiguration(
      name: nil,
      sessionRole: connectingSceneSession.role
    )
    configuration.delegateClass = FoqosSceneDelegate.self
    return configuration
  }
}

final class FoqosSceneDelegate: NSObject, UIWindowSceneDelegate {
  func windowScene(
    _ windowScene: UIWindowScene,
    performActionFor shortcutItem: UIApplicationShortcutItem,
    completionHandler: @escaping (Bool) -> Void
  ) {
    completionHandler(QuickActionManager.shared.handle(shortcutItem))
  }
}
