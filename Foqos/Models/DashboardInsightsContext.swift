import Foundation

struct DashboardInsightsContext: Identifiable {
  let id = UUID()
  let profile: BlockedProfiles
  let viewMode: InsightsViewMode
  let selectedDate: Date
}

enum InsightsViewMode {
  case week
  case month
  case allSessions
}
