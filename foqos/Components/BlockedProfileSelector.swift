import SwiftUI

struct BlockedProfileSelector: View {
    let profile: BlockedProfiles
    var onSwipeLeft: () -> Void
    var onSwipeRight: () -> Void
    var onTap: () -> Void
    var onLongPress: () -> Void
    
    @State private var offset: CGFloat = 0
    @State private var isLongPressing = false
    @State private var isDragging = false
    
    private let swipeThreshold: CGFloat = 60  // Reduced from 75
    
    private var cardOpacity: Double {
        let progress = abs(offset) / swipeThreshold
        return max(1 - progress * 0.6, 0.4)
    }
    
    private var backgroundColor: Color {
        isLongPressing ? Color.green.opacity(0.3) : Color(.secondarySystemBackground)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(profile.name)
                .font(.headline)
            Text("\(BlockedProfiles.countSelectedActivities(profile.selectedActivity)) items blocked")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
            if !isDragging {  // Only allow color change if not dragging
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    isLongPressing = isPressing
                }
            }
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    isDragging = true
                    isLongPressing = false  // Reset long press state when dragging
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
