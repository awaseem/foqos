import SwiftUI

class ThemeManager: ObservableObject {
  static let shared = ThemeManager()

  @AppStorage(
    "foqosThemeColorHex", store: UserDefaults(suiteName: "group.dev.ambitionsoftware.foqos"))
  private var themeColorHex: String = ""

  var themeColor: Color {
    get {
      if themeColorHex.isEmpty {
        return .purple  // Default to iOS system purple
      }
      return Color(hex: themeColorHex)
    }
    set {
      if let hex = newValue.toHex() {
        themeColorHex = hex
        objectWillChange.send()
      }
    }
  }

  func setTheme(_ color: Color) {
    self.themeColor = color
  }
}
