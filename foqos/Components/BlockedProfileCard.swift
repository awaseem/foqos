import SwiftUI
import FamilyControls

struct BlockedProfileCard: View {
    let profile: BlockedProfiles
    
    // Predefined bright iOS-friendly solid colors that work well with white text
    private let predefinedColors: [Color] = [
        Color.blue,
        Color.indigo,
        Color.purple,
        Color.pink,
        Color.orange,
        Color.red
    ]
    
    // Structure to hold position data for shapes
    private struct ShapePosition {
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
    }
    
    // Generate deterministic position based on profile name and index
    private func getPositionFromName(name: String, index: Int) -> ShapePosition {
        if name.isEmpty {
            // Fallback values if name is empty
            return ShapePosition(x: CGFloat(index * 20 - 60), y: CGFloat(index * 15 - 40), size: CGFloat(index * 5))
        }
        
        // Create a deterministic seed value from name and index
        let nameBytes = Array(name.utf8)
        let seedValue = nameBytes.count > 0 ? nameBytes.reduce(UInt64(index * 17)) { ($0 << 5) &+ UInt64($1) } : UInt64(index * 31)
        
        // Generate position values within appropriate ranges
        let xMultiplier = index % 2 == 0 ? -1.0 : 1.0 // Alternate sides
        let xRange: CGFloat = 100.0
        let yRange: CGFloat = 80.0
        
        let xOffset = CGFloat(seedValue % 100) / 100.0 * xRange * xMultiplier
        let yOffset = CGFloat((seedValue >> 8) % 100) / 100.0 * yRange - yRange/2
        let size = CGFloat((seedValue >> 16) % 40) // Size variation
        
        return ShapePosition(
            x: xOffset,
            y: yOffset,
            size: size
        )
    }
    
    // Select a color based on the profile name
    private var cardColor: Color {
        // Use the profile name to select a consistent color
        let name = profile.name
        
        if name.isEmpty {
            // Fallback to the first color if name is empty
            return predefinedColors[0]
        }
        
        // Sum the Unicode values of characters in the name for a deterministic result
        let nameSum = name.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        
        // Use modulo to get an index within the array bounds
        let index = nameSum % predefinedColors.count
        return predefinedColors[index]
    }
    
    // Get blocking strategy name
    private var blockingStrategyName: String {
        guard let strategyId = profile.blockingStrategyId else { return "None" }
        return StrategyManager.getStrategyFromId(id: strategyId).name
    }
    
    var body: some View {
        ZStack {
            // Blurred shapes background
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(UIColor.systemBackground))
                .overlay(
                    ZStack {
                        // Generate dynamic shapes based on profile name
                        ForEach(0..<5, id: \.self) { index in
                            let seed = getPositionFromName(name: profile.name, index: index)
                            
                            Group {
                                if index % 3 == 0 {
                                    Circle()
                                        .fill(cardColor.opacity(0.4 + Double(index) * 0.04))
                                        .frame(width: 70 + CGFloat(seed.size), height: 70 + CGFloat(seed.size))
                                } else if index % 3 == 1 {
                                    Capsule()
                                        .fill(cardColor.opacity(0.4 + Double(index) * 0.04))
                                        .frame(width: 100 + CGFloat(seed.size), height: 50 + CGFloat(seed.size * 0.5))
                                } else {
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(cardColor.opacity(0.4 + Double(index) * 0.04))
                                        .frame(width: 60 + CGFloat(seed.size), height: 60 + CGFloat(seed.size))
                                }
                            }
                            .offset(x: seed.x, y: seed.y)
                            .blur(radius: 15 + CGFloat(index * 3))
                        }
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.ultraThinMaterial.opacity(0.7))
                )
                .clipShape(RoundedRectangle(cornerRadius: 24))
            
            // Content
            VStack(alignment: .leading, spacing: 16) {
                // Header section - Profile name and indicators
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
                                .fill(profile.enableLiveActivity ? Color.green.opacity(0.85) : Color.gray.opacity(0.35))
                                .frame(width: 6, height: 6)
                            
                            Text("Live Activity")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        // Reminder indicator
                        HStack(spacing: 6) {
                            // Simple dot with no border
                            Circle()
                                .fill(profile.reminderTimeInSeconds != nil ? Color.green.opacity(0.85) : Color.gray.opacity(0.35))
                                .frame(width: 6, height: 6)
                            
                            Text("Reminders")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Middle section - Strategy and apps info
                VStack(alignment: .leading, spacing: 16) {
                    // Strategy info with icon
                    HStack {
                        Image(systemName: "shield.fill")
                            .foregroundColor(cardColor)
                            .font(.system(size: 16))
                            .frame(width: 28, height: 28)
                            .background(
                                Circle()
                                    .fill(cardColor.opacity(0.15))
                            )
                        
                        Text(blockingStrategyName)
                            .foregroundColor(.primary)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    // Apps and sessions info
                    HStack(spacing: 16) {
                        // Apps count
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Apps & Categories")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("\(BlockedProfiles.countSelectedActivities(profile.selectedActivity))")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        
                        Divider()
                            .frame(height: 24)
                        
                        // Active sessions
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Active Sessions")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("0") // Replace with actual sessions count
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                    }
                }
                
                // Spacer to push buttons to bottom
                Spacer(minLength: 4)
                
                // Bottom section - Only action buttons
                HStack(spacing: 8) {
                    GlassButton(title: "Start", icon: "play.fill") {
                        // Start action
                    }
                    
                    GlassButton(title: "Edit", icon: "pencil") {
                        // Edit action
                    }
                }
            }
            .padding(16)
        }
        .frame(height: 170)
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
        .contentShape(Rectangle()) // Improve tap area
    }
}

#Preview {
    ZStack {
        Color(.systemGroupedBackground).ignoresSafeArea()
        
        VStack(spacing: 16) {
            BlockedProfileCard(
                profile: BlockedProfiles(
                    id: UUID(),
                    name: "Work Focus",
                    selectedActivity: FamilyActivitySelection(),
                    blockingStrategyId: NFCBlockingStrategy.id,
                    enableLiveActivity: true,
                    reminderTimeInSeconds: 3600
                )
            )
        }
        .padding(.vertical)
    }
}
