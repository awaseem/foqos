import Foundation
import Sparkle

@MainActor
final class FoqosUpdaterController: ObservableObject {
  let isConfigured: Bool

  private let updaterController: SPUStandardUpdaterController

  init(bundle: Bundle = .main) {
    isConfigured = Self.hasUpdateConfiguration(in: bundle)
    updaterController = SPUStandardUpdaterController(
      startingUpdater: isConfigured,
      updaterDelegate: nil,
      userDriverDelegate: nil
    )
  }

  func checkForUpdates() {
    guard isConfigured else {
      return
    }

    updaterController.checkForUpdates(nil)
  }

  private static func hasUpdateConfiguration(in bundle: Bundle) -> Bool {
    guard
      let feedURL = bundle.object(forInfoDictionaryKey: "SUFeedURL") as? String,
      !feedURL.isEmpty,
      let publicKey = bundle.object(forInfoDictionaryKey: "SUPublicEDKey") as? String,
      !publicKey.isEmpty
    else {
      return false
    }

    return true
  }
}
