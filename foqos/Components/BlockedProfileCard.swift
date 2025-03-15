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
        Color.teal,
        Color.green,
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
                        ForEach(0..<6, id: \.self) { index in
                            let seed = getPositionFromName(name: profile.name, index: index)
                            
                            Group {
                                if index % 3 == 0 {
                                    Circle()
                                        .fill(cardColor.opacity(0.4 + Double(index) * 0.04))
                                        .frame(width: 80 + CGFloat(seed.size), height: 80 + CGFloat(seed.size))
                                } else if index % 3 == 1 {
                                    Capsule()
                                        .fill(cardColor.opacity(0.4 + Double(index) * 0.04))
                                        .frame(width: 120 + CGFloat(seed.size), height: 60 + CGFloat(seed.size * 0.5))
                                } else {
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(cardColor.opacity(0.4 + Double(index) * 0.04))
                                        .frame(width: 70 + CGFloat(seed.size), height: 70 + CGFloat(seed.size))
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
            VStack(alignment: .leading, spacing: 12) {
                // Header info
                VStack(alignment: .leading, spacing: 8) {
                    Text(profile.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Last updated: \(profile.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Profile stats
                VStack(alignment: .leading, spacing: 10) {
                    // Strategy with icon
                    HStack {
                        Label {
                            Text("Strategy:")
                                .foregroundColor(.secondary)
                        } icon: {
                            Image(systemName: "shield.fill")
                                .foregroundColor(cardColor.opacity(0.8))
                        }
                        .font(.subheadline)
                        
                        Spacer()
                        
                        Text(blockingStrategyName)
                            .foregroundColor(.primary)
                            .fontWeight(.semibold)
                            .font(.subheadline)
                    }
                    
                    // Apps count with icon
                    HStack {
                        Label {
                            Text("Apps & Categories:")
                                .foregroundColor(.secondary)
                        } icon: {
                            Image(systemName: "app.badge.fill")
                                .foregroundColor(cardColor.opacity(0.8))
                        }
                        .font(.subheadline)
                        
                        Spacer()
                        
                        Text("\(BlockedProfiles.countSelectedActivities(profile.selectedActivity))")
                            .foregroundColor(.primary)
                            .fontWeight(.semibold)
                            .font(.subheadline)
                    }
                    
                    // Live Activity with icon
                    HStack {
                        Label {
                            Text("Live Activity:")
                                .foregroundColor(.secondary)
                        } icon: {
                            Image(systemName: "bell.fill")
                                .foregroundColor(cardColor.opacity(0.8))
                        }
                        .font(.subheadline)
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Circle()
                                .fill(profile.enableLiveActivity ? Color.green : Color.red)
                                .frame(width: 8, height: 8)
                            
                            Text(profile.enableLiveActivity ? "Enabled" : "Disabled")
                                .foregroundColor(.primary)
                                .fontWeight(.semibold)
                                .font(.subheadline)
                        }
                    }
                    
                    // Reminders with icon
                    HStack {
                        Label {
                            Text("Reminders:")
                                .foregroundColor(.secondary)
                        } icon: {
                            Image(systemName: "alarm.fill")
                                .foregroundColor(cardColor.opacity(0.8))
                        }
                        .font(.subheadline)
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Circle()
                                .fill(profile.reminderTimeInSeconds != nil ? Color.green : Color.red)
                                .frame(width: 8, height: 8)
                            
                            Text(profile.reminderTimeInSeconds != nil ? "Enabled" : "Disabled")
                                .foregroundColor(.primary)
                                .fontWeight(.semibold)
                                .font(.subheadline)
                        }
                    }
                }
                
                Spacer()
                
                // Glass pane buttons
                HStack(spacing: 12) {
                    GlassButton(title: "Start", icon: "play.fill") {
                        // Start action
                    }
                    
                    GlassButton(title: "Edit", icon: "pencil") {
                        // Edit action
                    }
                }
            }
            .padding(18)
        }
        .frame(height: 200)
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
        
        VStack(spacing: 20) {
            BlockedProfileCard(
                profile: BlockedProfiles(
                    id: UUID(),
                    name: "Work",
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
