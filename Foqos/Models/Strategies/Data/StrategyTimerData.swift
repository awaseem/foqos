import SwiftUI

struct StrategyTimerData: Codable {
  var durationInMinutes: Int

  static func toStrategyTimerData(from data: Data) -> StrategyTimerData {
    do {
      return try JSONDecoder().decode(StrategyTimerData.self, from: data)
    } catch {
      // If decoding fails, return a default with 15 minutes
      return StrategyTimerData(durationInMinutes: 15)
    }
  }

  static func toData(from data: StrategyTimerData) -> Data? {
    return try? JSONEncoder().encode(data)
  }
}
