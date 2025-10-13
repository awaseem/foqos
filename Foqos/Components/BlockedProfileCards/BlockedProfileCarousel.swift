import FamilyControls
import SwiftUI

struct BlockedProfileCarousel: View {
  let profiles: [BlockedProfiles]
  let isBlocking: Bool
  let isBreakAvailable: Bool
  let isBreakActive: Bool
  let activeSessionProfileId: UUID?
  let elapsedTime: TimeInterval
  let startingProfileId: UUID?

  var onStartTapped: (BlockedProfiles) -> Void
  var onStopTapped: (BlockedProfiles) -> Void
  var onEditTapped: (BlockedProfiles) -> Void
  var onStatsTapped: (BlockedProfiles) -> Void
  var onBreakTapped: (BlockedProfiles) -> Void
  var onManageTapped: () -> Void
  var onEmergencyTapped: () -> Void

  // State for tracking current profile index and drag gesture
  @State private var currentIndex: Int = 0
  @State private var dragOffset: CGFloat = 0
  @State private var animatingOffset: CGFloat = 0

  // Constants for the carousel
  private let cardSpacing: CGFloat = 12
  private let dragThreshold: CGFloat = 50

  private var cardHeight: CGFloat = 240

  private var titleMessage: String {
    return isBlocking ? "Active Profile" : "Profile"
  }

  private var actionButtonText: String {
    return isBlocking ? "Emergency" : "Manage"
  }

  private var actionButtonIcon: String {
    return isBlocking ? "exclamationmark.triangle.fill" : "person.crop.circle"
  }

  private var actionButtonAction: () -> Void {
    return isBlocking ? onEmergencyTapped : onManageTapped
  }

  init(
    profiles: [BlockedProfiles],
    isBlocking: Bool,
    isBreakAvailable: Bool,
    isBreakActive: Bool,
    activeSessionProfileId: UUID?,
    elapsedTime: TimeInterval,
    startingProfileId: UUID? = nil,
    onStartTapped: @escaping (BlockedProfiles) -> Void,
    onStopTapped: @escaping (BlockedProfiles) -> Void,
    onEditTapped: @escaping (BlockedProfiles) -> Void,
    onStatsTapped: @escaping (BlockedProfiles) -> Void,
    onBreakTapped: @escaping (BlockedProfiles) -> Void,
    onManageTapped: @escaping () -> Void,
    onEmergencyTapped: @escaping () -> Void
  ) {
    self.profiles = profiles
    self.isBlocking = isBlocking
    self.isBreakAvailable = isBreakAvailable
    self.isBreakActive = isBreakActive
    self.activeSessionProfileId = activeSessionProfileId
    self.elapsedTime = elapsedTime
    self.startingProfileId = startingProfileId
    self.onStartTapped = onStartTapped
    self.onStopTapped = onStopTapped
    self.onEditTapped = onEditTapped
    self.onStatsTapped = onStatsTapped
    self.onBreakTapped = onBreakTapped
    self.onManageTapped = onManageTapped
    self.onEmergencyTapped = onEmergencyTapped
  }

  // Initialize current index based on active profile or starting profile
  private func initialSetup() {
    // First priority: active session profile
    if let activeId = activeSessionProfileId,
      let index = profiles.firstIndex(where: { $0.id == activeId })
    {
      currentIndex = index
      return
    }

    // Second priority: starting profile
    if let startingId = startingProfileId,
      let index = profiles.firstIndex(where: { $0.id == startingId })
    {
      currentIndex = index
      return
    }

    // Default: first profile if available
    if profiles.first != nil {
      currentIndex = 0
      return
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {

      SectionTitle(
        titleMessage,
        buttonText: actionButtonText,
        buttonAction: {
          actionButtonAction()
        },
        buttonIcon: actionButtonIcon
      )
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
                  isBreakAvailable: isBreakAvailable,
                  isBreakActive: isBreakActive,
                  elapsedTime: elapsedTime,
                  onStartTapped: {
                    onStartTapped(profiles[index])
                  },
                  onStopTapped: {
                    onStopTapped(profiles[index])
                  },
                  onEditTapped: {
                    onEditTapped(profiles[index])
                  },
                  onStatsTapped: {
                    onStatsTapped(profiles[index])
                  },
                  onBreakTapped: {
                    onBreakTapped(profiles[index])
                  }
                )
                .frame(width: cardWidth)
              }
            }
            .offset(
              x: calculateOffset(
                geometry: geometry,
                cardWidth: cardWidth
              )
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
        .padding(.bottom, 10)

        // Page indicator dots
        HStack(spacing: 8) {
          if !isBlocking && profiles.count > 1 {
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
          }
        }
        .frame(height: 8)
        .opacity(!isBlocking && profiles.count > 1 ? 1 : 0)
        .animation(.easeInOut, value: isBlocking)
      }
    }
    .onAppear {
      initialSetup()
    }
    .onChange(of: activeSessionProfileId) { _, _ in
      initialSetup()
    }
    .onChange(of: profiles) { _, _ in
      initialSetup()
    }
    .onChange(of: startingProfileId) { _, _ in
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

// Active preview
#Preview {
  let activeId = UUID()

  ZStack {
    Color(.systemGroupedBackground).ignoresSafeArea()

    BlockedProfileCarousel(
      profiles: [
        BlockedProfiles(
          id: activeId,
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
      isBreakAvailable: true,
      isBreakActive: false,
      activeSessionProfileId: activeId,
      elapsedTime: 1234,
      onStartTapped: { _ in },
      onStopTapped: { _ in },
      onEditTapped: { _ in },
      onStatsTapped: { _ in },
      onBreakTapped: { _ in },
      onManageTapped: {},
      onEmergencyTapped: {}
    )
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
      isBlocking: false,
      isBreakAvailable: false,
      isBreakActive: false,
      activeSessionProfileId: nil,
      elapsedTime: 1234,
      onStartTapped: { _ in },
      onStopTapped: { _ in },
      onEditTapped: { _ in },
      onStatsTapped: { _ in },
      onBreakTapped: { _ in },
      onManageTapped: {},
      onEmergencyTapped: {}
    )
  }
}

// Preview with startingProfileId set to "Gaming" (second profile)
#Preview("Starting Profile - Gaming") {
  let gamingProfileId = UUID()

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
          id: gamingProfileId,
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
      isBlocking: false,
      isBreakAvailable: false,
      isBreakActive: false,
      activeSessionProfileId: nil,
      elapsedTime: 1234,
      startingProfileId: gamingProfileId,
      onStartTapped: { _ in },
      onStopTapped: { _ in },
      onEditTapped: { _ in },
      onStatsTapped: { _ in },
      onBreakTapped: { _ in },
      onManageTapped: {},
      onEmergencyTapped: {}
    )
  }
}
