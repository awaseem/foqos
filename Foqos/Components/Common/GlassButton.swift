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
    .contentShape(Rectangle())  // Improve tap area
    .frame(minWidth: 0, maxWidth: equalWidth ? .infinity : nil)
  }

  @State private var isPressed = false
  @State private var progress: CGFloat = 0.0
  @State private var touchLocation: CGPoint = .zero

  private var longPressButton: some View {
    buttonContent
      .contentShape(Rectangle())
      .frame(minWidth: 0, maxWidth: equalWidth ? .infinity : nil)
      .scaleEffect(isPressed ? 0.9 : 1.0)
      .animation(.spring(response: 0.4), value: isPressed)
      .simultaneousGesture(
        LongPressGesture(minimumDuration: longPressDuration)
          .onEnded { _ in
            UIImpactFeedbackGenerator(style: .medium)
              .impactOccurred()
            action()
            isPressed = false
            progress = 0
          }
      )
      .simultaneousGesture(
        DragGesture(minimumDistance: 0)
          .onChanged { value in
            if !isPressed {
              isPressed = true
              touchLocation = value.startLocation
              progress = 0
              withAnimation(.linear(duration: longPressDuration)) {
                progress = 1.0
              }
            }
          }
          .onEnded { _ in
            isPressed = false
            progress = 0
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
                  x: touchLocation.x,
                  y: touchLocation.y
                )
            }
          }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .scaleEffect(0.9)
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
