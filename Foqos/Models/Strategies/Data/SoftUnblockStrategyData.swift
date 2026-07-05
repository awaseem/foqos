import Foundation

struct SoftUnblockStrategyData: Codable, Equatable {
  static let defaultDurationInMinutes = 15

  var accessDurationInMinutes: Int

  static func decode(_ data: Data?) -> SoftUnblockStrategyData {
    guard let data,
      let configuration = try? JSONDecoder().decode(SoftUnblockStrategyData.self, from: data)
    else {
      return SoftUnblockStrategyData(
        accessDurationInMinutes: SoftUnblockStrategyData.defaultDurationInMinutes
      )
    }

    return configuration
  }

  static func encode(_ configuration: SoftUnblockStrategyData) -> Data? {
    try? JSONEncoder().encode(configuration)
  }
}
