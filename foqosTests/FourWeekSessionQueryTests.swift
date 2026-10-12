import SwiftData
import XCTest

@testable import foqos

final class FourWeekSessionQueryTests: ModelRegressionTestCase {
  func testCompletedSessionsDescriptorKeepsOnlySessionsEndingAfterWindowStart() throws {
    let windowStart = Calendar.current.startOfDay(for: referenceDate)
    let history = try makeHistory(windowStart: windowStart)

    let reader = freshContext()
    let sessions = try reader.fetch(
      BlockedProfileSession.completedSessionsDescriptor(after: windowStart))

    XCTAssertEqual(sessions.map(\.id), history.expected.map(\.id))
  }

  func testCompletedSessionsDescriptorPreservesEveryDisplayedDayTotal() throws {
    let calendar = Calendar.current
    let windowStart = calendar.startOfDay(for: referenceDate)
    let history = try makeHistory(windowStart: windowStart)
    let reader = freshContext()
    let sessions = try reader.fetch(
      BlockedProfileSession.completedSessionsDescriptor(after: windowStart))

    for day in 0..<28 {
      let date = try XCTUnwrap(calendar.date(byAdding: .day, value: day, to: windowStart))
      XCTAssertEqual(
        DashboardActivityUtil.sessionHoursForDate(date, sessions: sessions),
        DashboardActivityUtil.sessionHoursForDate(date, sessions: history.completed),
        accuracy: 0.001,
        "Daily total changed for day \(day)"
      )
    }
  }

  private func makeHistory(windowStart: Date) throws -> (
    completed: [BlockedProfileSession], expected: [BlockedProfileSession]
  ) {
    let profile = BlockedProfiles(name: "Focus")
    context.insert(profile)

    let old = insertSession(
      profile: profile,
      start: windowStart.addingTimeInterval(-7200),
      end: windowStart.addingTimeInterval(-3600)
    )
    let boundary = insertSession(
      profile: profile,
      start: windowStart.addingTimeInterval(-3600),
      end: windowStart
    )
    let crossing = insertSession(
      profile: profile,
      start: try XCTUnwrap(Calendar.current.date(byAdding: .day, value: -40, to: windowStart)),
      end: windowStart.addingTimeInterval(3600)
    )
    let lastDay = try XCTUnwrap(
      Calendar.current.date(byAdding: .day, value: 27, to: windowStart))
    let recent = insertSession(
      profile: profile,
      start: lastDay.addingTimeInterval(3600),
      end: lastDay.addingTimeInterval(7200)
    )
    _ = insertSession(
      profile: profile,
      start: lastDay.addingTimeInterval(10800),
      end: nil
    )
    try context.save()

    return ([old, boundary, crossing, recent], [recent, crossing])
  }

  private func insertSession(
    profile: BlockedProfiles, start: Date, end: Date?
  ) -> BlockedProfileSession {
    let session = BlockedProfileSession(tag: "focus", blockedProfile: profile)
    session.startTime = start
    session.endTime = end
    context.insert(session)
    return session
  }
}
