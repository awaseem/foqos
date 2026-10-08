import Foundation

struct ManualMinimumDuration: Codable {
  static let presets = [0, 5, 10, 15, 30, 60]
  var minimumDurationInMinutes: Int

  var seconds: TimeInterval {
    TimeInterval(minimumDurationInMinutes) * 60
  }

  static func decode(_ data: Data?) -> ManualMinimumDuration {
    guard let data,
      let configuration = try? JSONDecoder().decode(Self.self, from: data),
      presets.contains(configuration.minimumDurationInMinutes)
    else {
      return Self(minimumDurationInMinutes: 0)
    }
    return configuration
  }

  func encode() -> Data? {
    try? JSONEncoder().encode(self)
  }

  static func remaining(startTime: Date, duration: TimeInterval, at date: Date) -> TimeInterval {
    guard duration > 0 else { return 0 }
    return max(0, startTime.addingTimeInterval(duration).timeIntervalSince(date))
  }
}
