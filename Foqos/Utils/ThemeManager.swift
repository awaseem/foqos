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
    ("San Diego Merlot", Color(hex: "#7a1e3a")),
    ("Forest Green", Color(hex: "#0b6e4f")),
    ("Miami Vice", Color(hex: "#ff6ec7")),
    ("Electric Lemonade", Color(hex: "#ccff00")),
    ("Neon Grape", Color(hex: "#b026ff")),
    ("Slate Stone", Color(hex: "#708090")),
    ("Warm Sandstone", Color(hex: "#c4a77d")),
  ]

  private static let defaultColorName = "Grimace Purple"
  private static let fallbackColor = Color(hex: "#894fa3")  // Grimace Purple

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
      ?? Self.availableColors.first?.color
      ?? Self.fallbackColor
  }

  func setTheme(named name: String) {
    selectedColorName = name
  }
}

extension Color {
  init(hex: String) {
    let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&int)
    let a: UInt64
    let r: UInt64
    let g: UInt64
    let b: UInt64
    switch hex.count {
    case 3:  // RGB (12-bit)
      (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
    case 6:  // RGB (24-bit)
      (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
    case 8:  // ARGB (32-bit)
      (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
    default:
      (a, r, g, b) = (1, 1, 1, 0)
    }

    self.init(
      .sRGB,
      red: Double(r) / 255,
      green: Double(g) / 255,
      blue: Double(b) / 255,
      opacity: Double(a) / 255
    )
  }

  func toHex() -> String? {
    let uiColor = UIColor(self)
    var r: CGFloat = 0
    var g: CGFloat = 0
    var b: CGFloat = 0
    var a: CGFloat = 0

    guard uiColor.getRed(&r, green: &g, blue: &b, alpha: &a) else {
      return nil
    }

    let rgb: Int = (Int)(r * 255) << 16 | (Int)(g * 255) << 8 | (Int)(b * 255) << 0

    return String(format: "#%06x", rgb)
  }
}
