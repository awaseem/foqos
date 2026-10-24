import SwiftUI
import UIKit

/// Bridges Home Screen quick actions (long-press on the app icon) into SwiftUI.
final class QuickActionManager: ObservableObject {
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

  func updateShortcutItems(for profiles: [BlockedProfiles]) {
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

final class FoqosAppDelegate: NSObject, UIApplicationDelegate {
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
