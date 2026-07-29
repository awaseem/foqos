import SwiftUI

struct StrategyPauseTimerData: Codable {
  static let defaultPauseDurationInMinutes = 15

  var pauseDurationInMinutes: Int

  static func toStrategyPauseTimerData(from data: Data?) -> StrategyPauseTimerData {
    guard let data else {
      return StrategyPauseTimerData(
        pauseDurationInMinutes: defaultPauseDurationInMinutes
      )
    }

    do {
      return try JSONDecoder().decode(StrategyPauseTimerData.self, from: data)
    } catch {
      return StrategyPauseTimerData(
        pauseDurationInMinutes: defaultPauseDurationInMinutes
      )
    }
  }

  static func toData(from data: StrategyPauseTimerData) -> Data? {
    return try? JSONEncoder().encode(data)
  }
}
