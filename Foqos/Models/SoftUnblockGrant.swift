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
  static let maximumUnblockCountRange = 1...10
  static let allowanceResetIntervalsInHours = [6, 12, 24]

  let sessionId: String
  let profileId: UUID
  let maximumUnblockCount: Int
  let allowanceResetIntervalInHours: Int?
  var allowanceWindowStartedAt: Date
  var nextAllowanceResetAt: Date?
  var usedUnblockCount: Int

  var remainingUnblockCount: Int {
    max(maximumUnblockCount - usedUnblockCount, 0)
  }

  @discardableResult
  mutating func resetAllowanceIfNeeded(at date: Date) -> Bool {
    guard let allowanceResetIntervalInHours,
      let nextAllowanceResetAt,
      date >= nextAllowanceResetAt
    else {
      return false
    }

    let interval = TimeInterval(allowanceResetIntervalInHours * 60 * 60)
    let elapsedIntervals = Int(date.timeIntervalSince(nextAllowanceResetAt) / interval) + 1
    allowanceWindowStartedAt = nextAllowanceResetAt.addingTimeInterval(
      TimeInterval(elapsedIntervals - 1) * interval
    )
    self.nextAllowanceResetAt = nextAllowanceResetAt.addingTimeInterval(
      TimeInterval(elapsedIntervals) * interval
    )
    usedUnblockCount = 0
    return true
  }

  func containsAllowanceUse(createdAt date: Date) -> Bool {
    guard date >= allowanceWindowStartedAt else { return false }
    guard let nextAllowanceResetAt else { return true }
    return date < nextAllowanceResetAt
  }
}
