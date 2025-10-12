import SwiftUI

struct BlockedProfileSelector: View {
  let profile: BlockedProfiles

  var isActive: Bool?

  var onSwipeLeft: () -> Void
  var onSwipeRight: () -> Void
  var onTap: () -> Void
  var onLongPress: () -> Void

  @State private var offset: CGFloat = 0
  @State private var isLongPressing = false
  @State private var isDragging = false

  private let swipeThreshold: CGFloat = 60

  private var cardOpacity: Double {
    let progress = abs(offset) / swipeThreshold
    return max(1 - progress * 0.6, 0.4)
  }

  private var backgroundColor: Color {
    if isActive == true {
      return Color.green.opacity(0.6)
    }
    return isLongPressing ? Color.green.opacity(0.3) : Color(.secondarySystemBackground)
  }

  var body: some View {
    HStack(alignment: .center, spacing: 12) {
      // Main Content
      VStack(alignment: .leading, spacing: 4) {
        Text(profile.name)
          .font(.headline)
        Text(
          "\(FamilyActivityUtil.countSelectedActivities(profile.selectedActivity)) items blocked"
        )
        .font(.subheadline)
        .foregroundColor(.secondary)
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      // Gesture Hints
      HStack(alignment: .center, spacing: 8) {
        Image(systemName: "hand.tap.fill")
          .font(.caption)
        Image(systemName: "chevron.left")
          .font(.caption)
        Image(systemName: "chevron.right")
          .font(.caption)
      }
      .foregroundColor(.secondary)
      .opacity(0.4)
      .frame(width: 20)
      .padding(.horizontal)
    }
    .padding()
    .background(backgroundColor)
    .cornerRadius(10)
    .offset(x: offset)
    .opacity(cardOpacity)
    .scaleEffect(isLongPressing ? 0.95 : 1.0)
    .onLongPressGesture(minimumDuration: 0.5) {
      if !isDragging {
        onLongPress()
      }
    } onPressingChanged: { isPressing in
      if !isDragging {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
          isLongPressing = isPressing
        }
      }
    }
    .gesture(
      DragGesture()
        .onChanged { value in
          isDragging = true
          isLongPressing = false
          withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.7)) {
            offset = value.translation.width
          }
        }
        .onEnded { value in
          isDragging = false
          let velocity = value.predictedEndLocation.x - value.location.x

          withAnimation(.spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0.2)) {
            if value.translation.width < -swipeThreshold || velocity < -500 {
              onSwipeLeft()
            } else if value.translation.width > swipeThreshold || velocity > 500 {
              onSwipeRight()
            }
            offset = 0
          }
        }
    )
    .simultaneousGesture(
      TapGesture()
        .onEnded {
          if !isDragging && !isLongPressing {
            onTap()
          }
        }
    )
  }
}
