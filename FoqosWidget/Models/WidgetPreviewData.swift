import Foundation
import SwiftUI

// Gallery and SwiftUI previews only; never persisted into the user's activity.
enum WidgetPreviewData {
  static func entry(period: WidgetActivityPeriod = .week) -> ProfileWidgetEntry {
    let calendar = Calendar.current
    let date = calendar.date(from: DateComponents(year: 2026, month: 9, day: 24, hour: 16))!
    let monthStart = calendar.dateInterval(of: .month, for: date)!.start
    let profileID = UUID(uuidString: "FEABBD23-D979-412D-ADE0-788B352E96FD")!
    let hours: [Double] = [
      2, 3.5, 0, 1.2, 4, 0, 0.8, 3, 2.3, 4.2, 1, 0, 2, 0, 3.1, 2.8, 4.5, 0, 2, 1, 3.5, 2.2, 4.8,
      2.7,
    ]
    let sessions = hours.enumerated().compactMap { offset, hours -> WidgetSessionInterval? in
      guard hours > 0 else { return nil }
      let start = calendar.date(byAdding: .hour, value: offset * 24 + 9, to: monthStart)!
      return WidgetSessionInterval(start: start, end: start.addingTimeInterval(hours * 3600))
    }
    return ProfileWidgetEntry(
      date: date,
      selectedProfileId: profileID.uuidString,
      profileName: "Deep work",
      activeSession: nil,
      profileInfo: WidgetProfileInfo(
        enableStrictMode: true, enableAllowMode: false, selectedItemCount: 8,
        strategyID: "NFCBlockingStrategy"),
      deepLinkURL: URL(string: "foqos://"), focusMessage: "Make room for what matters.",
      useProfileURL: false,
      activity: .make(sessions: sessions, at: date), activityPeriod: period,
      themeColor: ThemeManager().themeColor
    )
  }
}
