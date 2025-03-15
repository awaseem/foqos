import FamilyControls
import SwiftUI

struct BlockedProfileCard: View {
    let profile: BlockedProfiles
    var onStartTapped: () -> Void
    var onEditTapped: () -> Void
    
    // Keep a reference to the CardBackground to access color
    private var cardBackground: CardBackground {
        CardBackground(name: profile.name)
    }

    // Get blocking strategy name
    private var blockingStrategyName: String {
        guard let strategyId = profile.blockingStrategyId else { return "None" }
        return StrategyManager.getStrategyFromId(id: strategyId).name
    }
    
    // Get blocking strategy description
    private var blockingStrategyDescription: String {
        guard let strategyId = profile.blockingStrategyId else { return "No strategy selected" }
        return StrategyManager.getStrategyFromId(id: strategyId).description
    }
    
    // Get blocking strategy icon
    private var blockingStrategyIcon: String {
        guard let strategyId = profile.blockingStrategyId else { return "questionmark.circle.fill" }
        return StrategyManager.getStrategyFromId(id: strategyId).iconType
    }

    var body: some View {
        ZStack {
            // Use the CardBackground component
            cardBackground
            
            // Content
            VStack(alignment: .leading, spacing: 16) {
                // Header section - Profile name, edit button, and indicators
                HStack {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(profile.name)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        // Notification indicators
                        HStack(spacing: 16) {
                            // Live Activity indicator
                            HStack(spacing: 6) {
                                // Simple dot with no border
                                Circle()
                                    .fill(
                                        profile.enableLiveActivity
                                            ? Color.green.opacity(0.85)
                                            : Color.gray.opacity(0.35)
                                    )
                                    .frame(width: 6, height: 6)

                                Text("Live Activity")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }

                            // Reminder indicator
                            HStack(spacing: 6) {
                                // Simple dot with no border
                                Circle()
                                    .fill(
                                        profile.reminderTimeInSeconds != nil
                                            ? Color.green.opacity(0.85)
                                            : Color.gray.opacity(0.35)
                                    )
                                    .frame(width: 6, height: 6)

                                Text("Reminders")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Edit button moved to top right
                    Button(action: onEditTapped) {
                        Image(systemName: "pencil")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(.thinMaterial)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                                    )
                            )
                    }
                }

                // Middle section - Strategy and apps info
                VStack(alignment: .leading, spacing: 16) {
                    // Strategy info with icon
                    HStack {
                        Image(systemName: blockingStrategyIcon)
                            .foregroundColor(cardBackground.getCardColor())
                            .font(.system(size: 16))
                            .frame(width: 28, height: 28)
                            .background(
                                Circle()
                                    .fill(cardBackground.getCardColor().opacity(0.15))
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(blockingStrategyName)
                                .foregroundColor(.primary)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }

                    // Apps and sessions info
                    HStack(spacing: 16) {
                        // Apps count
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Apps & Categories")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text(
                                "\(BlockedProfiles.countSelectedActivities(profile.selectedActivity))"
                            )
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        }

                        Divider()
                            .frame(height: 24)

                        // Active sessions
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Total Sessions")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text(
                                profile.sessions.count.description.localizedLowercase
                            )
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                    }
                }

                // Spacer to push buttons to bottom
                Spacer(minLength: 4)

                // Bottom section - Only start button
                GlassButton(title: "Start", icon: "play.fill") {
                    onStartTapped()
                }
            }
            .padding(16)
        }
        .frame(height: 190)
        .padding(.horizontal)
    }
}

// Glass button component
struct GlassButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                Text(title)
                    .fontWeight(.semibold)
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.thinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                    )
            )
            .foregroundColor(.primary)
        }
        .contentShape(Rectangle())  // Improve tap area
    }
}

#Preview {
    ZStack {
        Color(.systemGroupedBackground).ignoresSafeArea()

        VStack(spacing: 16) {
            BlockedProfileCard(
                profile: BlockedProfiles(
                    id: UUID(),
                    name: "Work",
                    selectedActivity: FamilyActivitySelection(),
                    blockingStrategyId: NFCBlockingStrategy.id,
                    enableLiveActivity: true,
                    reminderTimeInSeconds: 3600
                ),
                onStartTapped: {},
                onEditTapped: {}
            )
        }
        .padding(.vertical)
    }
}
