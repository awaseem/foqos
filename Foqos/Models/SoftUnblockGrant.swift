import Foundation
import ManagedSettings

enum SoftUnblockResource: Codable, Equatable {
  case application(ApplicationToken)
  case category(ActivityCategoryToken)

  var applicationToken: ApplicationToken? {
    guard case .application(let token) = self else { return nil }
    return token
  }

  var categoryToken: ActivityCategoryToken? {
    guard case .category(let token) = self else { return nil }
    return token
  }
}

struct SoftUnblockGrant: Codable, Equatable, Identifiable {
  let id: UUID
  let sessionId: String
  let profileId: UUID
  let resource: SoftUnblockResource
  let createdAt: Date
  let expiresAt: Date

  func isExpired(at date: Date = Date()) -> Bool {
    expiresAt <= date
  }
}

struct SoftUnblockSessionState: Codable, Equatable {
  let sessionId: String
  let profileId: UUID
  let maximumUnblockCount: Int
  var usedUnblockCount: Int

  var remainingUnblockCount: Int {
    max(maximumUnblockCount - usedUnblockCount, 0)
  }
}
