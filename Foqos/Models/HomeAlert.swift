import Foundation

struct HomeAlert: Identifiable {
  enum AlertType {
    case screenTimeAccess
    case scheduleOutOfSync(profileId: UUID)
  }

  let type: AlertType
  let title: String
  let message: String
  let detailMessage: String
  let primaryActionTitle: String
  let iconName: String

  var id: String {
    switch type {
    case .screenTimeAccess:
      return "screen-time-access"
    case .scheduleOutOfSync(let profileId):
      return "schedule-out-of-sync-\(profileId.uuidString)"
    }
  }
}
