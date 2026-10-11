import FamilyControls
import SwiftData
import SwiftUI

/// Each control owns only the exact session it created, persisted across app restarts.
@MainActor
final class ProfileSessionControl: ObservableObject {
  @Published var profileID: UUID? {
    didSet { defaults.set(profileID?.uuidString, forKey: "\(key).profile") }
  }
  @Published var errorMessage: String?

  private let context: ModelContext
  private let manager: StrategyManager
  private let defaults: UserDefaults
  private let key: String
  private let isAuthorized: () -> Bool
  private var ownedSessionID: String?

  init(
    context: ModelContext, key: String, defaults: UserDefaults = .standard,
    manager: StrategyManager = .shared,
    isAuthorized: @escaping () -> Bool = {
      AuthorizationCenter.shared.authorizationStatus == .approved
    }
  ) {
    self.context = context
    self.key = key
    self.defaults = defaults
    self.manager = manager
    self.isAuthorized = isAuthorized
    profileID = defaults.string(forKey: "\(key).profile").flatMap(UUID.init(uuidString:))
    ownedSessionID = defaults.string(forKey: "\(key).session")
  }

  @discardableResult
  func setActive(_ active: Bool) -> Bool {
    errorMessage = nil
    do {
      guard let profileID,
        let profile = try BlockedProfiles.findProfile(byID: profileID, in: context),
        let strategyID = profile.blockingStrategyId,
        StrategyManager.getStrategyFromId(id: strategyID).supportsSessionControls
      else { throw ProfileSessionControlError.manualProfileRequired }
      let current = BlockedProfileSession.mostRecentActiveSession(in: context)
      if active {
        guard isAuthorized() else { throw ProfileSessionControlError.screenTimeRequired }
        if let current {
          if current.blockedProfile.id != profileID { throw FoqosControlError.anotherProfileActive }
          return false
        }
      } else {
        guard let current, current.id == ownedSessionID else { return false }
      }
      let changed = try manager.setProfileActiveFromControl(
        active, profileID: profileID, context: context,
        expectedSessionID: active ? nil : ownedSessionID)
      guard changed else { return false }
      ownedSessionID = active ? BlockedProfileSession.mostRecentActiveSession(in: context)?.id : nil
      defaults.set(ownedSessionID, forKey: "\(key).session")
      return true
    } catch {
      errorMessage = error.localizedDescription
      return false
    }
  }
}

enum ProfileSessionControlError: LocalizedError {
  case manualProfileRequired, screenTimeRequired

  var errorDescription: String? {
    switch self {
    case .manualProfileRequired: return "Choose a profile that supports session controls."
    case .screenTimeRequired: return "Grant Screen Time access in Foqos first."
    }
  }
}
