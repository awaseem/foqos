import Foundation

struct SessionTimer: Equatable {
  let startTime: Date
  var endTime: Date? = nil

  var countsDown: Bool { endTime != nil }

  var countdownRange: ClosedRange<Date>? {
    endTime.map { startTime...max(startTime, $0) }
  }

  func displayedTime(at date: Date) -> TimeInterval {
    if let endTime {
      return max(0, endTime.timeIntervalSince(max(startTime, date)))
    }
    return max(0, date.timeIntervalSince(startTime))
  }

  func nextMinuteUpdate(after date: Date) -> Date? {
    if let endTime, endTime <= date { return nil }
    let anchor = endTime ?? startTime
    let minutes = (date.timeIntervalSince(anchor) / 60).rounded(.down)
    return anchor.addingTimeInterval((minutes + 1) * 60)
  }
}
