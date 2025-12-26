import SwiftUI

struct GlassButton: View {
  let title: String
  let icon: String
  var fullWidth: Bool = true
  var equalWidth: Bool = false
  var longPressEnabled: Bool = false
  var longPressDuration: Double = 0.8
  var color: Color? = nil
  var accessibilityHint: String? = nil
  let action: () -> Void

  @Environment(\.accessibilityReduceMotion) var reduceMotion

  var body: some View {
    if longPressEnabled {
      longPressButton
    } else {
      standardButton
    }
  }

  private var standardButton: some View {
    Button(action: {
      HapticFeedback.light.trigger()
      action()
    }) {
      buttonContent
    }
    .buttonStyle(PressableButtonStyle())
    .frame(minWidth: 0, maxWidth: equalWidth ? .infinity : nil)
    .accessibilityLabel(title)
    .accessibilityHint(accessibilityHint ?? "")
  }

  @State private var isPressed = false

  private var longPressButton: some View {
    buttonContent
      .contentShape(Rectangle())
      .frame(minWidth: 0, maxWidth: equalWidth ? .infinity : nil)
      .scaleEffect(isPressed ? 0.96 : 1.0)
      .animation(reduceMotion ? nil : .snappy, value: isPressed)
      .onLongPressGesture(
        minimumDuration: longPressDuration,
        pressing: { pressing in
          isPressed = pressing
          if pressing {
            HapticFeedback.light.trigger()
          }
        },
        perform: {
          HapticFeedback.medium.trigger()
          action()
          isPressed = false
        }
      )
      .accessibilityLabel(title)
      .accessibilityHint(accessibilityHint ?? "Hold to activate")
      .accessibilityAddTraits(.startsMediaSession)
  }

  private var buttonContent: some View {
    HStack(spacing: Spacing.xxs + 2) {
      Image(systemName: icon)
        .font(.system(size: 16, weight: .medium))
        .accessibilityHidden(true)
      Text(title)
        .fontWeight(.semibold)
        .font(.subheadline)
    }
    .frame(
      minWidth: 0,
      maxWidth: fullWidth ? .infinity : (equalWidth ? .infinity : nil)
    )
    .padding(.vertical, Spacing.sm)
    .padding(.horizontal, fullWidth ? nil : Spacing.lg)
    .background(
      RoundedRectangle(cornerRadius: CornerRadius.lg)
        .fill(.thinMaterial)
        .overlay(
          RoundedRectangle(cornerRadius: CornerRadius.lg)
            .stroke((color ?? Color.primary).opacity(Opacity.tertiary), lineWidth: 1)
        )
    )
    .foregroundColor(color ?? .primary)
  }
}

private struct PressableButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .contentShape(Rectangle())
      .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
      .animation(.spring(response: 0.3), value: configuration.isPressed)
  }
}

#Preview {
  VStack(spacing: 20) {
    GlassButton(
      title: "Regular Button",
      icon: "play.fill"
    ) {
      print("Regular button tapped")
    }

    GlassButton(
      title: "Blue Button",
      icon: "star.fill",
      color: .blue
    ) {
      print("Blue button tapped")
    }

    GlassButton(
      title: "Hold to Start",
      icon: "play.fill",
      longPressEnabled: true,
      color: .green
    ) {
      print("Long press completed")
    }
  }
  .padding()
  .background(Color(.systemGroupedBackground))
}
