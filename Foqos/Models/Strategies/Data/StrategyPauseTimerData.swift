import SwiftUI

struct StrategyPauseTimerData: Codable {
  var pauseDurationInMinutes: Int

  static func toStrategyPauseTimerData(from data: Data) -> StrategyPauseTimerData {
    do {
      return try JSONDecoder().decode(StrategyPauseTimerData.self, from: data)
    } catch {
      return StrategyPauseTimerData(pauseDurationInMinutes: 15)
    }
  }

  static func toData(from data: StrategyPauseTimerData) -> Data? {
    return try? JSONEncoder().encode(data)
  }
}
