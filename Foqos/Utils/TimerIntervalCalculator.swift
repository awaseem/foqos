import Foundation

/// Builds the `DateComponents` pair behind every one-off `DeviceActivitySchedule` Foqos registers
/// for breaks, pauses and timer strategies.
///
/// Two framework constraints drive the math:
/// - `DeviceActivityCenter.startMonitoring` rejects intervals shorter than 15 minutes.
/// - An interval that does not start safely in the past is unreliable, because the system may not
///   consider the device to already be inside it, and `intervalDidEnd` can then be missed.
///
/// Every interval returned here satisfies both, including the ones that end tomorrow: when a timer
/// runs past midnight the start lands later in the day than the end, which the framework reads as
/// an interval spanning midnight, the same shape profile schedules already use.
enum TimerIntervalCalculator {
  /// Shortest interval `DeviceActivityCenter` accepts.
  static let minimumMonitoringWindow: TimeInterval = 15 * 60

  /// Longest timer that can be expressed. The interval can be as long as the duration plus
  /// `minimumMonitoringWindow`, and that total has to stay below 24 hours, otherwise the start
  /// would wrap past the end and invert the interval.
  static let maximumDuration: TimeInterval = (23 * 60 * 60) + (30 * 60)

  static func interval(
    durationInSeconds: TimeInterval,
    now: Date = Date(),
    calendar: Calendar = .current
  ) -> (intervalStart: DateComponents, intervalEnd: DateComponents) {
    let safeDuration = min(max(1, durationInSeconds), maximumDuration)
    let endDate = now.addingTimeInterval(safeDuration)
    let intervalEnd = calendar.dateComponents([.hour, .minute, .second], from: endDate)

    // Midnight keeps the start in the past, but only yields a long enough interval when the timer
    // ends well into the same day, and only when the timer did not start at midnight itself.
    let startOfDay = calendar.startOfDay(for: now)
    let secondsIntoEndDay = endDate.timeIntervalSince(calendar.startOfDay(for: endDate))
    if calendar.isDate(endDate, inSameDayAs: now), secondsIntoEndDay >= minimumMonitoringWindow,
      now > startOfDay
    {
      return (
        intervalStart: DateComponents(hour: 0, minute: 0, second: 0), intervalEnd: intervalEnd
      )
    }

    // Otherwise back the start up by the minimum interval: it stays in the past, the interval
    // clears the 15 minute floor, and it spans midnight whenever the timer ends tomorrow.
    let startDate = now.addingTimeInterval(-minimumMonitoringWindow)
    let intervalStart = calendar.dateComponents([.hour, .minute, .second], from: startDate)
    return (intervalStart: intervalStart, intervalEnd: intervalEnd)
  }
}
