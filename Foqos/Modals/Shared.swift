import FamilyControls
import Foundation

enum SharedData {
    private static let suite = UserDefaults(
        suiteName: "group.dev.ambitionsoftware.foqos"
    )!

    // MARK: – Keys
    private enum Key: String {
        case strict
        case selection
        case allowOnly
    }

    // MARK: – FamilyActivitySelection
    static var selection: FamilyActivitySelection? {
        get {
            guard let data = suite.data(forKey: Key.selection.rawValue) else {
                return nil
            }
            return try? JSONDecoder().decode(
                FamilyActivitySelection.self,
                from: data
            )
        }
        set {
            if let newValue = newValue,
                let data = try? JSONEncoder().encode(newValue)
            {
                suite.set(data, forKey: Key.selection.rawValue)
            } else {
                suite.removeObject(forKey: Key.selection.rawValue)
            }
        }
    }

    // MARK: – Strict flag
    static var strict: Bool? {
        get { suite.bool(forKey: Key.strict.rawValue) }
        set { suite.set(newValue, forKey: Key.strict.rawValue) }
    }
    
    static var allowOnly: Bool? {
        get { suite.bool(forKey: Key.allowOnly.rawValue) }
        set { suite.set(newValue, forKey: Key.allowOnly.rawValue) }
    }
}
