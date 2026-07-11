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
  var usedBreakDurationInSeconds: TimeInterval = 0

  var pauseStartTime: Date?
  var pauseEndTime: Date?

  var forceStarted: Bool = false

  var isActive: Bool {
    return endTime == nil
  }

  var isBreakAvailable: Bool {
    guard blockedProfile.enableBreaks == true,
      blockedProfile.allowsTimedBreaks
    else {
      return false
    }

    if blockedProfile.allowMultipleBreaks {
      return remainingBreakAllowance() > 0
    }

    return breakEndTime == nil
  }

  var isBreakActive: Bool {
    return blockedProfile.enableBreaks == true
      && blockedProfile.allowsTimedBreaks
      && breakStartTime != nil
      && breakEndTime == nil
  }

  var isPauseActive: Bool {
    return pauseStartTime != nil && pauseEndTime == nil
  }

  var duration: TimeInterval {
    let end = endTime ?? Date()
    return end.timeIntervalSince(startTime)
  }

  var totalBreakAllowanceInSeconds: TimeInterval {
    TimeInterval(blockedProfile.breakTimeInMinutes * 60)
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

  func activeBreakElapsedTime(at date: Date = Date()) -> TimeInterval {
    guard isBreakActive, let breakStartTime else {
      return 0
    }

    return max(0, date.timeIntervalSince(breakStartTime))
  }

  func usedBreakDurationIncludingActiveBreak(at date: Date = Date()) -> TimeInterval {
    if blockedProfile.allowMultipleBreaks {
      return min(
        totalBreakAllowanceInSeconds,
        usedBreakDurationInSeconds + activeBreakElapsedTime(at: date)
      )
    }

    return completedSingleBreakDuration(at: date)
  }

  func remainingBreakAllowance(at date: Date = Date()) -> TimeInterval {
    max(0, totalBreakAllowanceInSeconds - usedBreakDurationIncludingActiveBreak(at: date))
  }

  func startBreak(at date: Date = Date()) {
    let breakStartTime = date

    if blockedProfile.allowMultipleBreaks {
      SharedData.resetBreak()
      self.breakStartTime = nil
      self.breakEndTime = nil
    }

    SharedData.setBreakStartTime(date: breakStartTime)
    self.breakStartTime = breakStartTime
  }

  func endBreak(at date: Date = Date()) {
    let breakEndTime = date

    if blockedProfile.allowMultipleBreaks {
      let completedDuration = activeBreakElapsedTime(at: breakEndTime)
      let updatedUsedDuration = min(
        totalBreakAllowanceInSeconds,
        usedBreakDurationInSeconds + completedDuration
      )
      usedBreakDurationInSeconds = updatedUsedDuration
      SharedData.setUsedBreakDurationInSeconds(updatedUsedDuration)
    }

    SharedData.setBreakEndTime(date: breakEndTime)
    self.breakEndTime = breakEndTime
  }

  private func completedSingleBreakDuration(at date: Date) -> TimeInterval {
    guard let breakStartTime else {
      return 0
    }

    if let breakEndTime {
      return max(0, breakEndTime.timeIntervalSince(breakStartTime))
    }

    if isBreakActive {
      return max(0, date.timeIntervalSince(breakStartTime))
    }

    return 0
  }

  func startPause() {
    let pauseStartTime = Date()

    SharedData.setPauseStartTime(date: pauseStartTime)
    self.pauseStartTime = pauseStartTime
  }

  func endPause() {
    let pauseEndTime = Date()

    SharedData.setPauseEndTime(date: pauseEndTime)
    self.pauseEndTime = pauseEndTime
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
      usedBreakDurationInSeconds: usedBreakDurationInSeconds,
      pauseStartTime: pauseStartTime,
      pauseEndTime: pauseEndTime,
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
      existingSession.usedBreakDurationInSeconds = snapshot.usedBreakDurationInSeconds ?? 0
      existingSession.pauseStartTime = snapshot.pauseStartTime
      existingSession.pauseEndTime = snapshot.pauseEndTime
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
    newSession.usedBreakDurationInSeconds = snapshot.usedBreakDurationInSeconds ?? 0
    newSession.pauseStartTime = snapshot.pauseStartTime
    newSession.pauseEndTime = snapshot.pauseEndTime

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
