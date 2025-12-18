import SwiftUI

class ThemeManager: ObservableObject {
  static let shared = ThemeManager()

  // Single source of truth for all theme colors
  static let availableColors: [(name: String, color: Color)] = [
    ("Grimace Purple", Color(hex: "#894fa3")),
    ("Electric Purple", Color(hex: "#9349f9")),
    ("Ocean Blue", Color(hex: "#007aff")),
    ("Mint Fresh", Color(hex: "#00c6bf")),
    ("Lime Zest", Color(hex: "#7fd800")),
    ("Sunset Coral", Color(hex: "#ff5966")),
    ("Hot Pink", Color(hex: "#ff2da5")),
    ("Tangerine", Color(hex: "#ff9300")),
    ("Lavender Dream", Color(hex: "#ba8eff")),
    ("Cyber Cyan", Color(hex: "#00e5ff")),
  ]

  private static let defaultColorName = "Grimace Purple"

  @AppStorage(
    "foqosThemeColorName", store: UserDefaults(suiteName: "group.dev.ambitionsoftware.foqos"))
  private var themeColorName: String = defaultColorName

  var selectedColorName: String {
    get { themeColorName }
    set {
      themeColorName = newValue
      objectWillChange.send()
    }
  }

  var themeColor: Color {
    Self.availableColors.first(where: { $0.name == themeColorName })?.color
      ?? Self.availableColors.first!.color
  }

  func setTheme(named name: String) {
    selectedColorName = name
  }
}
