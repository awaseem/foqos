import SwiftUI

class ThemeManager: ObservableObject {
  static let shared = ThemeManager()

  // Single source of truth for all theme colors
  static let availableColors: [(name: String, color: Color)] = [
    ("Grimace Purple", Color(hex: "#894fa3")),
    ("Ocean Blue", Color(hex: "#007aff")),
    ("Mint Fresh", Color(hex: "#00c6bf")),
    ("Lime Zest", Color(hex: "#7fd800")),
    ("Sunset Coral", Color(hex: "#ff5966")),
    ("Hot Pink", Color(hex: "#ff2da5")),
    ("Tangerine", Color(hex: "#ff9300")),
    ("Lavender Dream", Color(hex: "#ba8eff")),
    // 80s Neon Collection
    ("Miami Vice", Color(hex: "#ff6ec7")),
    ("Electric Lemonade", Color(hex: "#ccff00")),
    ("Neon Grape", Color(hex: "#b026ff")),
    // Calm & Earthy
    ("Slate Stone", Color(hex: "#708090")),
    ("Warm Sandstone", Color(hex: "#c4a77d")),
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
