import FamilyControls
import SwiftUI

struct BlockedProfileCarousel: View {
    let profiles: [BlockedProfiles]
    let isBlocking: Bool
    let activeSessionProfileId: UUID?
    let elapsedTime: TimeInterval

    var onStartTapped: (BlockedProfiles) -> Void
    var onStopTapped: (BlockedProfiles) -> Void
    var onEditTapped: (BlockedProfiles) -> Void

    // State for tracking current profile index and drag gesture
    @State private var currentIndex: Int = 0
    @State private var dragOffset: CGFloat = 0
    @State private var animatingOffset: CGFloat = 0

    // Constants for the carousel
    private let cardSpacing: CGFloat = 12
    private let cardHeight: CGFloat = 180
    private let dragThreshold: CGFloat = 50

    init(
        profiles: [BlockedProfiles], isBlocking: Bool,
        activeSessionProfileId: UUID?, elapsedTime: TimeInterval,
        onStartTapped: @escaping (BlockedProfiles) -> Void,
        onStopTapped: @escaping (BlockedProfiles) -> Void,
        onEditTapped: @escaping (BlockedProfiles) -> Void
    ) {
        self.profiles = profiles
        self.isBlocking = isBlocking
        self.activeSessionProfileId = activeSessionProfileId
        self.elapsedTime = elapsedTime
        self.onStartTapped = onStartTapped
        self.onStopTapped = onStopTapped
        self.onEditTapped = onEditTapped
    }

    // Initialize current index based on active profile
    private func initialSetup() {
        if let activeId = activeSessionProfileId,
            let index = profiles.firstIndex(where: { $0.id == activeId })
        {
            currentIndex = index
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 40) {
            // Title
            SectionTitle("Profiles")
                .padding(.horizontal, 16)

            VStack(spacing: 16) {
                // Card carousel
                ZStack {
                    // Carousel container
                    GeometryReader { geometry in
                        let cardWidth = geometry.size.width - 32  // Padding on sides

                        HStack(spacing: cardSpacing) {
                            ForEach(profiles.indices, id: \.self) { index in
                                BlockedProfileCard(
                                    profile: profiles[index],
                                    isActive: profiles[index].id
                                        == activeSessionProfileId,
                                    elapsedTime: elapsedTime,
                                    onStartTapped: {
                                        onStartTapped(profiles[index])
                                    },
                                    onStopTapped: {
                                        onStopTapped(profiles[index])
                                    },
                                    onEditTapped: {
                                        onEditTapped(profiles[index])
                                    }
                                )
                                .frame(width: cardWidth, height: cardHeight)
                            }
                        }
                        .offset(
                            x: calculateOffset(
                                geometry: geometry, cardWidth: cardWidth)
                        )
                        .animation(
                            .spring(response: 0.4, dampingFraction: 0.8),
                            value: currentIndex
                        )
                        .animation(
                            .spring(response: 0.4, dampingFraction: 0.8),
                            value: dragOffset
                        )
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    if !isBlocking {  // Only allow dragging when not blocking
                                        dragOffset = value.translation.width
                                    }
                                }
                                .onEnded { value in
                                    if !isBlocking {  // Only allow dragging when not blocking
                                        let offsetAmount = value.translation
                                            .width
                                        let swipedRight =
                                            offsetAmount > dragThreshold
                                        let swipedLeft =
                                            offsetAmount < -dragThreshold

                                        if swipedLeft
                                            && currentIndex < profiles.count - 1
                                        {
                                            currentIndex += 1
                                        } else if swipedRight
                                            && currentIndex > 0
                                        {
                                            currentIndex -= 1
                                        }

                                        dragOffset = 0
                                    }
                                }
                        )
                    }
                }
                .frame(height: cardHeight)

                // Page indicator dots
                if profiles.count > 1 {
                    HStack(spacing: 8) {
                        Spacer()
                        ForEach(0..<profiles.count, id: \.self) { index in
                            Circle()
                                .fill(
                                    index == currentIndex
                                        ? Color.primary
                                        : Color.secondary.opacity(0.3)
                                )
                                .frame(width: 8, height: 8)
                                .animation(.easeInOut, value: currentIndex)
                        }
                        Spacer()
                    }
                    .padding(.top, 30)
                }
            }
        }
        .onAppear {
            initialSetup()
        }
        .onChange(of: activeSessionProfileId) { _, _ in
            initialSetup()
        }
    }

    // Calculate the offset based on current index and drag
    private func calculateOffset(geometry: GeometryProxy, cardWidth: CGFloat)
        -> CGFloat
    {
        let totalWidth = cardWidth + cardSpacing
        let baseOffset = CGFloat(currentIndex) * -totalWidth
        let leadingPadding = (geometry.size.width - cardWidth) / 2
        return baseOffset + dragOffset + leadingPadding
    }
}

#Preview {
    ZStack {
        Color(.systemGroupedBackground).ignoresSafeArea()

        BlockedProfileCarousel(
            profiles: [
                BlockedProfiles(
                    id: UUID(),
                    name: "Work",
                    selectedActivity: FamilyActivitySelection(),
                    blockingStrategyId: NFCBlockingStrategy.id,
                    enableLiveActivity: true,
                    reminderTimeInSeconds: 3600
                ),
                BlockedProfiles(
                    id: UUID(),
                    name: "Gaming",
                    selectedActivity: FamilyActivitySelection(),
                    blockingStrategyId: QRCodeBlockingStrategy.id,
                    enableLiveActivity: false,
                    reminderTimeInSeconds: nil
                ),
                BlockedProfiles(
                    id: UUID(),
                    name: "Social Media",
                    selectedActivity: FamilyActivitySelection(),
                    blockingStrategyId: ManualBlockingStrategy.id,
                    enableLiveActivity: true,
                    reminderTimeInSeconds: 1800
                ),
            ],
            isBlocking: true,
            activeSessionProfileId: nil,
            elapsedTime: 1234,
            onStartTapped: { _ in },
            onStopTapped: { _ in },
            onEditTapped: { _ in }
        )
    }
}
