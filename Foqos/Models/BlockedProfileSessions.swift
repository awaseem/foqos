import Foundation
import SwiftData

@Model
class BlockedProfileSession {
  @Attribute(.unique) var id: String
  var tag: String

  @Relationship var blockedProfile: BlockedProfiles

  var startTime: Date
  var endTime: Date?

  var breakStartTime: Date?
  var breakEndTime: Date?

  var forceStarted: Bool = false

  var isActive: Bool {
    return endTime == nil
  }

  var isBreakAvailable: Bool {
    return blockedProfile.enableBreaks == true
      && breakEndTime == nil
  }

  var isBreakActive: Bool {
    return blockedProfile.enableBreaks == true
      && breakStartTime != nil
      && breakEndTime == nil
  }

  var duration: TimeInterval {
    let end = endTime ?? Date()
    return end.timeIntervalSince(startTime)
  }

  init(
    tag: String,
    blockedProfile: BlockedProfiles,
    forceStarted: Bool = false
  ) {
    self.id = UUID().uuidString
    self.tag = tag
    self.blockedProfile = blockedProfile
    self.startTime = Date()
    self.forceStarted = forceStarted

    // Add this session to the profile's sessions array
    blockedProfile.sessions.append(self)
  }

  func startBreak() {
    self.breakStartTime = Date()
  }

  func endBreak() {
    self.breakEndTime = Date()
  }

  func endSession() {
    self.endTime = Date()
  }

  static func mostRecentActiveSession(in context: ModelContext)
    -> BlockedProfileSession?
  {
    var descriptor = FetchDescriptor<BlockedProfileSession>(
      predicate: #Predicate { $0.endTime == nil },
      sortBy: [SortDescriptor(\.startTime, order: .reverse)]
    )
    descriptor.fetchLimit = 1

    return try? context.fetch(descriptor).first
  }

  static func createSession(
    in context: ModelContext,
    withTag tag: String,
    withProfile profile: BlockedProfiles,
    forceStart: Bool = false
  ) -> BlockedProfileSession {
    let newSession = BlockedProfileSession(
      tag: tag,
      blockedProfile: profile,
      forceStarted: forceStart
    )

    context.insert(newSession)
    return newSession
  }

  static func recentInactiveSessions(
    in context: ModelContext,
    limit: Int = 50
  ) -> [BlockedProfileSession] {
    var descriptor = FetchDescriptor<BlockedProfileSession>(
      predicate: #Predicate { $0.endTime != nil },
      sortBy: [SortDescriptor(\.endTime, order: .reverse)]
    )
    descriptor.fetchLimit = limit

    return (try? context.fetch(descriptor)) ?? []
  }
}
