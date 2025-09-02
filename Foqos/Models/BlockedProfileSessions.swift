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
    let breakStartTime = Date()

    SharedData.setBreakStartTime(date: breakStartTime)
    self.breakStartTime = breakStartTime
  }

  func endBreak() {
    let breakEndTime = Date()

    SharedData.setBreakEndTime(date: breakEndTime)
    self.breakEndTime = breakEndTime
  }

  func endSession() {
    let endTime = Date()

    // Set the end time in shared data in case its being saved
    SharedData.setEndTime(date: endTime)
    self.endTime = endTime

    SharedData.flushActiveSession()
  }

  func toSnapshot() -> SharedData.SessionSnapshot {
    return SharedData.SessionSnapshot(
      id: id,
      tag: tag,
      blockedProfileId: blockedProfile.id,
      startTime: startTime,
      endTime: endTime,
      breakStartTime: breakStartTime,
      breakEndTime: breakEndTime,
      forceStarted: forceStarted
    )
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

    SharedData.createActiveSharedSession(for: newSession.toSnapshot())

    context.insert(newSession)
    return newSession
  }

  static func upsertSessionFromSnapshot(
    in context: ModelContext,
    withSnapshot snapshot: SharedData.SessionSnapshot
  ) {
    let profileID = snapshot.blockedProfileId

    guard let existingProfile = try? BlockedProfiles.findProfile(byID: profileID, in: context)
    else {
      print("Profile not found when creating session from snapshot")
      return
    }

    // Try to find an existing session by id
    if let existingSession = try? findSession(byID: snapshot.id, in: context) {
      existingSession.tag = snapshot.tag
      existingSession.startTime = snapshot.startTime
      existingSession.endTime = snapshot.endTime
      existingSession.breakStartTime = snapshot.breakStartTime
      existingSession.breakEndTime = snapshot.breakEndTime
      existingSession.forceStarted = snapshot.forceStarted

      // manually save to ensure changes are persisted
      try? context.save()
      return
    }

    // Create new session from snapshot
    let newSession = BlockedProfileSession(
      tag: snapshot.tag,
      blockedProfile: existingProfile,
      forceStarted: snapshot.forceStarted
    )
    // Override auto-generated values with snapshot-provided ones
    newSession.id = snapshot.id
    newSession.startTime = snapshot.startTime
    newSession.endTime = snapshot.endTime
    newSession.breakStartTime = snapshot.breakStartTime
    newSession.breakEndTime = snapshot.breakEndTime

    // Let auto-save handle inserts
    context.insert(newSession)
  }

  static func findSession(
    byID id: String,
    in context: ModelContext
  ) throws -> BlockedProfileSession? {
    let descriptor = FetchDescriptor<BlockedProfileSession>(
      predicate: #Predicate { $0.id == id }
    )
    return try context.fetch(descriptor).first
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
