import UIKit

enum DeviceLayoutUtil {
  static let compactEffectiveWidthThreshold: CGFloat = 375

  static var effectiveScreenWidth: CGFloat {
    min(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
  }

  static var hasCompactEffectiveWidth: Bool {
    effectiveScreenWidth <= compactEffectiveWidthThreshold
  }
}
