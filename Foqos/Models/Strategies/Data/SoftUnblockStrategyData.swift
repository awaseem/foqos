import Foundation

struct SoftUnblockStrategyData: Codable, Equatable {
  static let defaultDurationInMinutes = 15
  static let defaultMaximumUnblockCount = 3
  static let durationRange = 5...60
  static let unblockCountRange = 1...10

  var accessDurationInMinutes: Int
  var maximumUnblockCount: Int

  static func decode(_ data: Data?) -> SoftUnblockStrategyData {
    guard let data,
      let configuration = try? JSONDecoder().decode(SoftUnblockStrategyData.self, from: data)
    else {
      return SoftUnblockStrategyData(
        accessDurationInMinutes: defaultDurationInMinutes,
        maximumUnblockCount: defaultMaximumUnblockCount
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
      )
    )
  }
}
