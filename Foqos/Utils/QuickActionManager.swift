import Combine
import UIKit

@MainActor
final class QuickActionManager: ObservableObject {
  static let shared = QuickActionManager()

  static let profileStartActionType = "dev.ambitionsoftware.foqos.start-profile"
  static let profileIDUserInfoKey = "profileID"

  @Published private(set) var pendingProfileID: UUID?

  static func shortcutItems(from profiles: [BlockedProfiles]) -> [UIApplicationShortcutItem] {
    let sortedProfiles = profiles.sorted { lhs, rhs in
      if lhs.order != rhs.order {
        return lhs.order < rhs.order
      }

      if lhs.createdAt != rhs.createdAt {
        return lhs.createdAt > rhs.createdAt
      }

      return lhs.id.uuidString < rhs.id.uuidString
    }

    return sortedProfiles.map { profile in
      UIApplicationShortcutItem(
        type: profileStartActionType,
        localizedTitle: "Start \(profile.name)",
        localizedSubtitle: nil,
        icon: nil,
        userInfo: [profileIDUserInfoKey: profile.id.uuidString as NSString]
      )
    }
  }

  static func profileID(from shortcutItem: UIApplicationShortcutItem) -> UUID? {
    guard shortcutItem.type == profileStartActionType,
      let rawProfileID = shortcutItem.userInfo?[profileIDUserInfoKey]
    else {
      return nil
    }

    if let profileIDString = rawProfileID as? String {
      return UUID(uuidString: profileIDString)
    }

    if let profileIDString = rawProfileID as? NSString {
      return UUID(uuidString: profileIDString as String)
    }

    return nil
  }

  func handle(_ shortcutItem: UIApplicationShortcutItem) {
    guard let profileID = Self.profileID(from: shortcutItem) else {
      return
    }

    pendingProfileID = profileID
  }

  func clearPendingProfileStart() {
    pendingProfileID = nil
  }

  func refreshActions(from profiles: [BlockedProfiles]) {
    UIApplication.shared.shortcutItems = Self.shortcutItems(from: profiles)
  }
}

final class FoqosAppDelegate: NSObject, UIApplicationDelegate {
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    if let shortcutItem = launchOptions?[.shortcutItem] as? UIApplicationShortcutItem {
      Task { @MainActor in
        QuickActionManager.shared.handle(shortcutItem)
      }
    }

    return true
  }

  func application(
    _ application: UIApplication,
    performActionFor shortcutItem: UIApplicationShortcutItem,
    completionHandler: @escaping (Bool) -> Void
  ) {
    Task { @MainActor in
      QuickActionManager.shared.handle(shortcutItem)
      completionHandler(true)
    }
  }

  func application(
    _ application: UIApplication,
    configurationForConnecting connectingSceneSession: UISceneSession,
    options: UIScene.ConnectionOptions
  ) -> UISceneConfiguration {
    if let shortcutItem = options.shortcutItem {
      Task { @MainActor in
        QuickActionManager.shared.handle(shortcutItem)
      }
    }

    let configuration = UISceneConfiguration(
      name: "Default Configuration",
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
    Task { @MainActor in
      QuickActionManager.shared.handle(shortcutItem)
      completionHandler(true)
    }
  }
}
