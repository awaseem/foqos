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
    
    // Select a color based on the profile ID
    private var cardColor: Color {
        // Use the UUID to select a color
        let idString = profile.id.uuidString
        
        // Convert first 8 characters to an integer and use it to select a color
        guard let firstPart = idString.split(separator: "-").first,
              let intValue = UInt64(firstPart, radix: 16) else {
            // Fallback to the first color
            return predefinedColors[0]
        }
        
        // Use modulo to get an index within the array bounds
        let index = Int(intValue % UInt64(predefinedColors.count))
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
                        // Multiple soft blurred shapes with the profile color
                        Circle()
                            .fill(cardColor.opacity(0.7))
                            .frame(width: 100, height: 100)
                            .offset(x: -80, y: -40)
                            .blur(radius: 20)
                        
                        Circle()
                            .fill(cardColor.opacity(0.6))
                            .frame(width: 120, height: 120)
                            .offset(x: 70, y: 60)
                            .blur(radius: 25)
                        
                        Capsule()
                            .fill(cardColor.opacity(0.5))
                            .frame(width: 160, height: 80)
                            .offset(x: -30, y: 40)
                            .blur(radius: 15)
                    }
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
                    id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F") ?? UUID(),
                    name: "Social Media Block",
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
