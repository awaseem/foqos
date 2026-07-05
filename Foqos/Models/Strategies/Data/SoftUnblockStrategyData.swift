import Foundation

struct SoftUnblockStrategyData: Codable, Equatable {
  static let defaultDurationInMinutes = 15
  static let defaultMaximumUnblockCount = 3
  static let defaultAllowanceResetIntervalInHours: Int? = nil
  static let durationRange = 5...60
  static let unblockCountRange = SoftUnblockSessionState.maximumUnblockCountRange
  static let allowanceResetIntervalsInHours =
    SoftUnblockSessionState.allowanceResetIntervalsInHours

  var accessDurationInMinutes: Int
  var maximumUnblockCount: Int
  var allowanceResetIntervalInHours: Int?

  static func decode(_ data: Data?) -> SoftUnblockStrategyData {
    guard let data,
      let configuration = try? JSONDecoder().decode(SoftUnblockStrategyData.self, from: data)
    else {
      return SoftUnblockStrategyData(
        accessDurationInMinutes: defaultDurationInMinutes,
        maximumUnblockCount: defaultMaximumUnblockCount,
        allowanceResetIntervalInHours: defaultAllowanceResetIntervalInHours
      )
    }

    return configuration.normalized
  }

  static func encode(_ configuration: SoftUnblockStrategyData) -> Data? {
    try? JSONEncoder().encode(configuration.normalized)
  }

  private var normalized: SoftUnblockStrategyData {
    SoftUnblockStrategyData(
      accessDurationInMinutes: min(
        max(accessDurationInMinutes, Self.durationRange.lowerBound),
        Self.durationRange.upperBound
      ),
      maximumUnblockCount: min(
        max(maximumUnblockCount, Self.unblockCountRange.lowerBound),
        Self.unblockCountRange.upperBound
      ),
      allowanceResetIntervalInHours: allowanceResetIntervalInHours.flatMap { interval in
        Self.allowanceResetIntervalsInHours.contains(interval) ? interval : nil
      }
    )
  }
}
