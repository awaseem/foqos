import SwiftUI

struct BlockedProfileStats: View {
    var profile: BlockedProfiles
    
    var body: some View {
        Section("Stats for Nerds") {
            // Profile ID
            HStack {
                Text("Profile ID")
                    .foregroundStyle(.gray)
                Spacer()
                Text(profile.id.uuidString)
                    .truncationMode(.tail)
                    .foregroundStyle(.gray)
            }
            
            // Created Date
            HStack {
                Text("Created")
                    .foregroundStyle(.gray)
                Spacer()
                Text(profile.createdAt.formatted())
                    .foregroundStyle(.gray)
            }
            
            // Last Modified
            HStack {
                Text("Last Modified")
                    .foregroundStyle(.gray)
                Spacer()
                Text(profile.updatedAt.formatted())
                    .foregroundStyle(.gray)
            }
            
            // Total Sessions
            HStack {
                Text("Total Sessions")
                    .foregroundStyle(.gray)
                Spacer()
                Text("\(profile.sessions.count)")
                    .foregroundStyle(.gray)
            }
            
            
            // Selected Restrictions Details
            HStack {
                Text("Categories Blocked")
                    .foregroundStyle(.gray)
                Spacer()
                Text("\(profile.selectedActivity.categories.count)")
                    .foregroundStyle(.gray)
            }
            
            HStack {
                Text("Apps Blocked")
                    .foregroundStyle(.gray)
                Spacer()
                Text("\(profile.selectedActivity.applications.count)")
                    .foregroundStyle(.gray)
            }
        }
    }
}
