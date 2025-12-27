//
//  DesignSystem.swift
//  foqos
//
//  Design tokens for consistent UI across the app
//

import SwiftUI

// MARK: - Spacing Scale (8pt Grid)

enum Spacing {
  static let xxs: CGFloat = 4   // Tight spacing
  static let xs: CGFloat = 8    // Default padding
  static let sm: CGFloat = 12   // Component gaps
  static let md: CGFloat = 16   // Section padding
  static let lg: CGFloat = 24   // Large sections
  static let xl: CGFloat = 32   // Screen margins
  static let xxl: CGFloat = 48  // Hero spacing
}

// MARK: - Corner Radius

enum CornerRadius {
  static let xs: CGFloat = 6    // Pills, tags
  static let sm: CGFloat = 8    // Small buttons
  static let md: CGFloat = 12   // Standard buttons
  static let lg: CGFloat = 16   // Cards, inputs
  static let xl: CGFloat = 24   // Large cards
  static let full: CGFloat = 9999 // Circular
}

// MARK: - Shadows

enum Shadow {
  static let sm = ShadowStyle(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
  static let md = ShadowStyle(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
  static let lg = ShadowStyle(color: Color.black.opacity(0.16), radius: 16, x: 0, y: 8)
}

struct ShadowStyle {
  let color: Color
  let radius: CGFloat
  let x: CGFloat
  let y: CGFloat
}

// MARK: - Opacity

enum Opacity {
  static let disabled: Double = 0.4
  static let secondary: Double = 0.6
  static let tertiary: Double = 0.3
  static let overlay: Double = 0.15
  static let border: Double = 0.2
}

// MARK: - Typography Scale

enum Typography {
  static let largeTitle = Font.largeTitle
  static let title = Font.title
  static let title2 = Font.title2
  static let title3 = Font.title3
  static let headline = Font.headline
  static let body = Font.body
  static let callout = Font.callout
  static let subheadline = Font.subheadline
  static let footnote = Font.footnote
  static let caption = Font.caption
  static let caption2 = Font.caption2

  // Monospaced for timers
  static func timer(size: CGFloat = 16) -> Font {
    .system(size: size, weight: .semibold, design: .monospaced)
  }
}

// MARK: - Touch Target

enum TouchTarget {
  static let minimum: CGFloat = 44  // Apple HIG minimum
  static let comfortable: CGFloat = 48
  static let large: CGFloat = 56
}

// MARK: - View Modifiers

extension View {
  func cardStyle(isActive: Bool = false) -> some View {
    self
      .padding(Spacing.md)
      .background(
        RoundedRectangle(cornerRadius: CornerRadius.lg)
          .fill(isActive ? Color.accentColor.opacity(0.1) : Color(.systemBackground))
      )
      .shadow(
        color: Shadow.sm.color,
        radius: Shadow.sm.radius,
        x: Shadow.sm.x,
        y: Shadow.sm.y
      )
  }

  func standardPadding() -> some View {
    self.padding(.horizontal, Spacing.md)
  }

  func sectionSpacing() -> some View {
    self.padding(.vertical, Spacing.lg)
  }
}

// MARK: - Semantic Colors

extension Color {
  static let foqosPrimary = Color.accentColor
  static let foqosSecondary = Color.secondary
  static let foqosBackground = Color(.systemBackground)
  static let foqosGroupedBackground = Color(.systemGroupedBackground)
  static let foqosCardBackground = Color(.secondarySystemBackground)

  // Status colors
  static let foqosSuccess = Color.green
  static let foqosWarning = Color.orange
  static let foqosError = Color.red
  static let foqosInfo = Color.blue
}
