import SwiftUI

class NavigationManager: ObservableObject {
  @Published var profileId: String? = nil
  @Published var link: URL? = nil

  @Published var navigateToProfileId: String? = nil

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
