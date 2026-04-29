import Foundation

struct StrategyPauseDelayData: Codable {
  var delaySeconds: Int = 5

  static func toStrategyPauseDelayData(from data: Data) -> StrategyPauseDelayData {
    do {
      return try JSONDecoder().decode(StrategyPauseDelayData.self, from: data)
    } catch {
      return StrategyPauseDelayData(delaySeconds: 5)
    }
  }

  static func toData(from data: StrategyPauseDelayData) -> Data? {
    return try? JSONEncoder().encode(data)
  }
}
