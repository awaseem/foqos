import Foundation

struct DashboardProfileActivity: Identifiable {
  let id = UUID()
  let profile: BlockedProfiles
  let totalTime: TimeInterval
  let sessionCount: Int
}
