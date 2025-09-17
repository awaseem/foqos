import SwiftUI

struct BlockedProfileStats: View {
  var profile: BlockedProfiles

  private var profileIdShort: String {
    String(profile.id.uuidString.prefix(8))
  }

  private var statsItems: [MultiStatCard.StatItem] {
    var items: [MultiStatCard.StatItem] = [
      .init(
        title: "Profile ID", valueText: profileIdShort, systemImageName: "tag", iconColor: .gray),
      .init(
        title: "Created", valueText: profile.createdAt.formatted(), systemImageName: "calendar",
        iconColor: .blue),
      .init(
        title: "Last Modified", valueText: profile.updatedAt.formatted(), systemImageName: "clock",
        iconColor: .purple),
      .init(
        title: "Total Sessions", valueText: "\(profile.sessions.count)",
        systemImageName: "list.number", iconColor: .green),
      .init(
        title: "Categories Blocked", valueText: "\(profile.selectedActivity.categories.count)",
        systemImageName: "square.grid.2x2", iconColor: .orange),
      .init(
        title: "Apps Blocked", valueText: "\(profile.selectedActivity.applications.count)",
        systemImageName: "app", iconColor: .pink),
    ]
    if let active = profile.activeDeviceActivity {
      items.append(
        .init(
          title: "Active Device Activity", valueText: active.rawValue, systemImageName: "bolt.fill",
          iconColor: .yellow))
    }
    return items
  }

  var body: some View {
    Section("Stats for Nerds") {
      MultiStatCard(stats: statsItems, columns: 2)
    }
  }
}
