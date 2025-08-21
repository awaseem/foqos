import FamilyControls
import Foundation

enum SharedData {
  private static let suite = UserDefaults(
    suiteName: "group.dev.ambitionsoftware.foqos"
  )!

  // MARK: – Keys
  private enum Key: String {
    case profiles
  }

  // MARK: – Profiles map (profileID → options)
  struct ProfileOptions: Codable, Equatable {
    var selection: FamilyActivitySelection?
    var strict: Bool?
    var allowOnly: Bool?
  }

  static var profiles: [String: ProfileOptions] {
    get {
      guard let data = suite.data(forKey: Key.profiles.rawValue) else { return [:] }
      return (try? JSONDecoder().decode([String: ProfileOptions].self, from: data)) ?? [:]
    }
    set {
      if let data = try? JSONEncoder().encode(newValue) {
        suite.set(data, forKey: Key.profiles.rawValue)
      } else {
        suite.removeObject(forKey: Key.profiles.rawValue)
      }
    }
  }

  static func options(for profileID: String) -> ProfileOptions? {
    profiles[profileID]
  }

  static func setOptions(_ options: ProfileOptions, for profileID: String) {
    var all = profiles
    all[profileID] = options
    profiles = all
  }

  static func removeOptions(for profileID: String) {
    var all = profiles
    all.removeValue(forKey: profileID)
    profiles = all
  }
}
