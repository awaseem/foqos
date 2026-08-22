import SwiftUI

struct StrategyTimerData: Codable {
  static let defaultDurationInMinutes = 60

  var durationInMinutes: Int
  var hideStopButton: Bool

  static var defaultConfiguration: StrategyTimerData {
    StrategyTimerData(
      durationInMinutes: defaultDurationInMinutes,
      hideStopButton: false
    )
  }

  static func decode(_ data: Data?) -> StrategyTimerData {
    guard let data else {
      return defaultConfiguration
    }

    return toStrategyTimerData(from: data)
  }

  static func toStrategyTimerData(from data: Data) -> StrategyTimerData {
    do {
      return try JSONDecoder().decode(StrategyTimerData.self, from: data)
    } catch {
      // If decoding fails, return a default with 15 minutes
      return StrategyTimerData(durationInMinutes: 15, hideStopButton: false)
    }
  }

  static func toData(from data: StrategyTimerData) -> Data? {
    return try? JSONEncoder().encode(data)
  }
}
