import SwiftUI
import UIKit

// MARK: - Quick Action Types
enum QuickActionType: String {
  case startFocus = "com.foqos.quickaction.startfocus"
  case viewInsights = "com.foqos.quickaction.insights"
  case newProfile = "com.foqos.quickaction.newprofile"
}

class NavigationManager: ObservableObject {
  @Published var profileId: String? = nil
  @Published var link: URL? = nil
  @Published var navigateToProfileId: String? = nil

  // Quick Action navigation states
  @Published var showInsights: Bool = false
  @Published var showNewProfile: Bool = false
  @Published var triggerStartFocus: Bool = false

  // Handle Home Screen Quick Actions
  func handleQuickAction(_ shortcutItem: UIApplicationShortcutItem) {
    guard let actionType = QuickActionType(rawValue: shortcutItem.type) else { return }

    DispatchQueue.main.async {
      switch actionType {
      case .startFocus:
        self.triggerStartFocus = true
      case .viewInsights:
        self.showInsights = true
      case .newProfile:
        self.showNewProfile = true
      }
    }
  }

  func clearQuickAction() {
    showInsights = false
    showNewProfile = false
    triggerStartFocus = false
  }

  func handleLink(_ url: URL) {
    let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
    guard let path = components?.path else { return }

    let parts = path.split(separator: "/")
    if let basePath = parts[safe: 0], let profileId = parts[safe: 1] {
      switch String(basePath) {
      case "profile":
        self.profileId = String(profileId)
        self.link = url
      case "navigate":
        self.navigateToProfileId = String(profileId)
        self.link = url
      default:
        break
      }
    }
  }

  func clearNavigation() {
    profileId = nil
    link = nil
    navigateToProfileId = nil
  }
}
