import SwiftUI
import UIKit

struct RoundedButton: View {
  let text: String
  let action: () -> Void
  let backgroundColor: Color
  let textColor: Color
  let font: Font
  let fontWeight: Font.Weight
  let iconName: String?

  init(
    _ text: String,
    action: @escaping () -> Void,
    backgroundColor: Color = Color.secondary.opacity(0.2),
    textColor: Color = .gray,
    font: Font = .subheadline,
    fontWeight: Font.Weight = .medium,
    iconName: String? = nil
  ) {
    self.text = text
    self.action = action
    self.backgroundColor = backgroundColor
    self.textColor = textColor
    self.font = font
    self.fontWeight = fontWeight
    self.iconName = iconName
  }

  var body: some View {
    Button(action: {
      HapticFeedback.light.trigger()
      action()
    }) {
      HStack(spacing: 6) {
        if let iconName = iconName {
          Image(systemName: iconName)
            .font(font)
            .fontWeight(fontWeight)
        }

        if !text.isEmpty {
          Text(text)
            .font(font)
            .fontWeight(fontWeight)
        }
      }
      .foregroundColor(textColor)
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
      .glassButtonBackground(cornerRadius: 16)
      .overlay(
        RoundedRectangle(cornerRadius: 16, style: .continuous)
          .strokeBorder(.white.opacity(0.15))
      )
    }
    .buttonStyle(PressableButtonStyle())
    .accessibilityLabel(text.isEmpty ? (iconName ?? "Button") : text)
  }
}

// MARK: - Pressable Button Style
struct PressableButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
      .opacity(configuration.isPressed ? 0.9 : 1.0)
      .animation(.micro, value: configuration.isPressed)
  }
}

extension View {
  @ViewBuilder
  fileprivate func glassButtonBackground(cornerRadius: CGFloat) -> some View {
    if #available(iOS 26.0, *) {
      self.modifier(GlassBackgroundModifier(cornerRadius: cornerRadius))
    } else {
      self
        .background(
          .ultraThinMaterial,
          in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        )
    }
  }
}

@available(iOS 26.0, *)
private struct GlassBackgroundModifier: ViewModifier {
  let cornerRadius: CGFloat

  func body(content: Content) -> some View {
    content
      .glassEffect(in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
  }
}

// Preview
#Preview {
  VStack(spacing: 16) {
    RoundedButton("See All") {
      print("See All tapped")
    }

    RoundedButton(
      "View Report",
      action: { print("View Report tapped") },
      iconName: "chart.bar")

    RoundedButton(
      "Custom Style",
      action: { print("Custom tapped") },
      backgroundColor: .blue,
      textColor: .white,
      iconName: "star.fill")

    RoundedButton(
      "Large Button",
      action: { print("Large tapped") },
      backgroundColor: .green.opacity(0.2),
      textColor: .green,
      font: .title3,
      fontWeight: .semibold,
      iconName: "checkmark.circle")

    RoundedButton(
      "Settings",
      action: { print("Settings tapped") },
      iconName: "gear")
  }
  .padding(20)
}
