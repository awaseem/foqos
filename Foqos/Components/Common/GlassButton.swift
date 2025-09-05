import SwiftUI

struct GlassButton: View {
  let title: String
  let icon: String
  var fullWidth: Bool = true
  var equalWidth: Bool = false
  var longPressEnabled: Bool = false
  var longPressDuration: Double = 0.8
  var color: Color? = nil
  let action: () -> Void

  var body: some View {
    if longPressEnabled {
      longPressButton
    } else {
      standardButton
    }
  }

  private var standardButton: some View {
    Button(action: action) {
      buttonContent
    }
    .buttonStyle(PressableButtonStyle())
    .frame(minWidth: 0, maxWidth: equalWidth ? .infinity : nil)
  }

  @State private var isPressed = false
  @State private var progress: CGFloat = 0.0
  @State private var touchStartLocation: CGPoint = .zero

  private var longPressButton: some View {
    buttonContent
      .contentShape(Rectangle())
      .frame(minWidth: 0, maxWidth: equalWidth ? .infinity : nil)
      .scaleEffect(isPressed ? 0.96 : 1.0)
      .animation(.spring(response: 0.3), value: isPressed)
      .simultaneousGesture(
        DragGesture(minimumDistance: 0)
          .onChanged { value in
            if progress == 0.0 {  // capture where the touch started
              touchStartLocation = value.startLocation
            }
          }
      )
      .onLongPressGesture(
        minimumDuration: longPressDuration,
        maximumDistance: 50,
        pressing: { pressing in
          if pressing {
            isPressed = true
            withAnimation(.linear(duration: longPressDuration)) {
              progress = 1.0
            }
          } else {
            isPressed = false
            withAnimation(.easeOut(duration: 0.2)) {
              progress = 0.0
            }
          }
        },
        perform: {
          UIImpactFeedbackGenerator(style: .medium).impactOccurred()
          action()
          isPressed = false
          progress = 0.0
        }
      )
      .overlay(
        ZStack {
          if isPressed {
            GeometryReader { geometry in
              Circle()
                .fill(Color.primary.opacity(0.1))
                .frame(
                  width: geometry.size.width * progress * 2,
                  height: geometry.size.width * progress * 2
                )
                .position(
                  x: touchStartLocation.x,
                  y: touchStartLocation.y
                )
            }
          }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .scaleEffect(0.95)
      )
  }

  private var buttonContent: some View {
    HStack(spacing: 6) {
      Image(systemName: icon)
        .font(.system(size: 16, weight: .medium))
      Text(title)
        .fontWeight(.semibold)
        .font(.subheadline)
    }
    .frame(
      minWidth: 0,
      maxWidth: fullWidth ? .infinity : (equalWidth ? .infinity : nil)
    )
    .padding(.vertical, 12)
    .padding(.horizontal, fullWidth ? nil : 24)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(.thinMaterial)
        .overlay(
          RoundedRectangle(cornerRadius: 16)
            .stroke((color ?? Color.primary).opacity(0.2), lineWidth: 1)
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
