import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings
import SwiftData

@Model
class BlockedProfiles {
  @Attribute(.unique) var id: UUID
  var name: String
  var selectedActivity: FamilyActivitySelection
  var createdAt: Date
  var updatedAt: Date
  var blockingStrategyId: String?
  var order: Int = 0

  var enableLiveActivity: Bool = false
  var reminderTimeInSeconds: UInt32?
  var enableBreaks: Bool = false
  var enableStrictMode: Bool = false
  var enableAllowMode: Bool = false
  var enableAllowModeDomains: Bool = false

  var physicalUnblockNFCTagId: String?
  var physicalUnblockQRCodeId: String?

  var domains: [String]? = nil

  var schedule: BlockedProfileSchedule? = nil

  var disableBackgroundStops: Bool = false

  var customReminderMessage: String?

  @Relationship var sessions: [BlockedProfileSession] = []

  var activeDeviceActivity: DeviceActivityName? {
    return DeviceActivityCenterUtil.getActiveDeviceActivity(for: self)
  }

  init(
    id: UUID = UUID(),
    name: String,
    selectedActivity: FamilyActivitySelection = FamilyActivitySelection(),
    createdAt: Date = Date(),
    updatedAt: Date = Date(),
    blockingStrategyId: String = NFCBlockingStrategy.id,
    enableLiveActivity: Bool = false,
    reminderTimeInSeconds: UInt32? = nil,
    customReminderMessage: String? = nil,
    enableBreaks: Bool = false,
    enableStrictMode: Bool = false,
    enableAllowMode: Bool = false,
    enableAllowModeDomains: Bool = false,
    order: Int = 0,
    domains: [String]? = nil,
    physicalUnblockNFCTagId: String? = nil,
    physicalUnblockQRCodeId: String? = nil,
    schedule: BlockedProfileSchedule? = nil,
    disableBackgroundStops: Bool = false
  ) {
    self.id = id
    self.name = name
    self.selectedActivity = selectedActivity
    self.createdAt = createdAt
    self.updatedAt = updatedAt
    self.blockingStrategyId = blockingStrategyId
    self.order = order

    self.enableLiveActivity = enableLiveActivity
    self.reminderTimeInSeconds = reminderTimeInSeconds
    self.customReminderMessage = customReminderMessage
    self.enableLiveActivity = enableLiveActivity
    self.enableBreaks = enableBreaks
    self.enableStrictMode = enableStrictMode
    self.enableAllowMode = enableAllowMode
    self.enableAllowModeDomains = enableAllowModeDomains
    self.domains = domains

    self.physicalUnblockNFCTagId = physicalUnblockNFCTagId
    self.physicalUnblockQRCodeId = physicalUnblockQRCodeId
    self.schedule = schedule

    self.disableBackgroundStops = disableBackgroundStops
  }

  static func fetchProfiles(in context: ModelContext) throws
    -> [BlockedProfiles]
  {
    let descriptor = FetchDescriptor<BlockedProfiles>(
      sortBy: [
        SortDescriptor(\.order, order: .forward), SortDescriptor(\.createdAt, order: .reverse),
      ]
    )
    return try context.fetch(descriptor)
  }

  static func findProfile(byID id: UUID, in context: ModelContext) throws
    -> BlockedProfiles?
  {
    let descriptor = FetchDescriptor<BlockedProfiles>(
      predicate: #Predicate { $0.id == id }
    )
    return try context.fetch(descriptor).first
  }

  static func fetchMostRecentlyUpdatedProfile(in context: ModelContext) throws
    -> BlockedProfiles?
  {
    let descriptor = FetchDescriptor<BlockedProfiles>(
      sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
    )
    return try context.fetch(descriptor).first
  }

  static func updateProfile(
    _ profile: BlockedProfiles,
    in context: ModelContext,
    name: String? = nil,
    selection: FamilyActivitySelection? = nil,
    blockingStrategyId: String? = nil,
    enableLiveActivity: Bool? = nil,
    reminderTime: UInt32? = nil,
    customReminderMessage: String? = nil,
    enableBreaks: Bool? = nil,
    enableStrictMode: Bool? = nil,
    enableAllowMode: Bool? = nil,
    enableAllowModeDomains: Bool? = nil,
    order: Int? = nil,
    domains: [String]? = nil,
    physicalUnblockNFCTagId: String? = nil,
    physicalUnblockQRCodeId: String? = nil,
    schedule: BlockedProfileSchedule? = nil,
    disableBackgroundStops: Bool? = nil
  ) throws -> BlockedProfiles {
    if let newName = name {
      profile.name = newName
    }

    if let newSelection = selection {
      profile.selectedActivity = newSelection
    }

    if let newStrategyId = blockingStrategyId {
      profile.blockingStrategyId = newStrategyId
    }

    if let newEnableLiveActivity = enableLiveActivity {
      profile.enableLiveActivity = newEnableLiveActivity
    }

    if let newEnableBreaks = enableBreaks {
      profile.enableBreaks = newEnableBreaks
    }

    if let newEnableStrictMode = enableStrictMode {
      profile.enableStrictMode = newEnableStrictMode
    }

    if let newEnableAllowMode = enableAllowMode {
      profile.enableAllowMode = newEnableAllowMode
    }

    if let newEnableAllowModeDomains = enableAllowModeDomains {
      profile.enableAllowModeDomains = newEnableAllowModeDomains
    }

    if let newOrder = order {
      profile.order = newOrder
    }

    if let newDomains = domains {
      profile.domains = newDomains
    }

    if let newSchedule = schedule {
      profile.schedule = newSchedule
    }

    if let newDisableBackgroundStops = disableBackgroundStops {
      profile.disableBackgroundStops = newDisableBackgroundStops
    }

    // Values can be nil when removed
    profile.physicalUnblockNFCTagId = physicalUnblockNFCTagId
    profile.physicalUnblockQRCodeId = physicalUnblockQRCodeId

    profile.reminderTimeInSeconds = reminderTime
    profile.customReminderMessage = customReminderMessage
    profile.updatedAt = Date()

    // Update the snapshot
    updateSnapshot(for: profile)

    try context.save()

    return profile
  }

  static func deleteProfile(
    _ profile: BlockedProfiles,
    in context: ModelContext
  ) throws {
    // First end any active sessions
    for session in profile.sessions {
      if session.endTime == nil {
        session.endSession()
      }
    }

    // Remove all sessions first
    for session in profile.sessions {
      context.delete(session)
    }

    // Delete the snapshot
    deleteSnapshot(for: profile)

    // Remove the schedule restrictions
    DeviceActivityCenterUtil.removeScheduleRestrictions(for: profile)

    // Then delete the profile
    context.delete(profile)
    try context.save()
  }

  static func getProfileDeepLink(_ profile: BlockedProfiles) -> String {
    return "https://foqos.app/profile/" + profile.id.uuidString
  }

  // TODO: This should not be a static method, it should be a method on the profile object
  static func getSnapshot(for profile: BlockedProfiles) -> SharedData.ProfileSnapshot {
    return SharedData.ProfileSnapshot(
      id: profile.id,
      name: profile.name,
      selectedActivity: profile.selectedActivity,
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt,
      blockingStrategyId: profile.blockingStrategyId,
      order: profile.order,
      enableLiveActivity: profile.enableLiveActivity,
      reminderTimeInSeconds: profile.reminderTimeInSeconds,
      customReminderMessage: profile.customReminderMessage,
      enableBreaks: profile.enableBreaks,
      enableStrictMode: profile.enableStrictMode,
      enableAllowMode: profile.enableAllowMode,
      enableAllowModeDomains: profile.enableAllowModeDomains,
      domains: profile.domains,
      physicalUnblockNFCTagId: profile.physicalUnblockNFCTagId,
      physicalUnblockQRCodeId: profile.physicalUnblockQRCodeId,
      schedule: profile.schedule,
      disableBackgroundStops: profile.disableBackgroundStops
    )
  }

  // Create a codable/equatable snapshot suitable for UserDefaults
  static func updateSnapshot(for profile: BlockedProfiles) {
    let snapshot = getSnapshot(for: profile)
    SharedData.setSnapshot(snapshot, for: profile.id.uuidString)
  }

  static func deleteSnapshot(for profile: BlockedProfiles) {
    SharedData.removeSnapshot(for: profile.id.uuidString)
  }

  static func reorderProfiles(
    _ profiles: [BlockedProfiles],
    in context: ModelContext
  ) throws {
    for (index, profile) in profiles.enumerated() {
      profile.order = index
    }
    try context.save()
  }

  static func getNextOrder(in context: ModelContext) -> Int {
    let descriptor = FetchDescriptor<BlockedProfiles>(
      sortBy: [SortDescriptor(\.order, order: .reverse)]
    )
    guard let lastProfile = try? context.fetch(descriptor).first else {
      return 0
    }
    return lastProfile.order + 1
  }

  static func createProfile(
    in context: ModelContext,
    name: String,
    selection: FamilyActivitySelection = FamilyActivitySelection(),
    blockingStrategyId: String = NFCBlockingStrategy.id,
    enableLiveActivity: Bool = false,
    reminderTimeInSeconds: UInt32? = nil,
    customReminderMessage: String = "",
    enableBreaks: Bool = false,
    enableStrictMode: Bool = false,
    enableAllowMode: Bool = false,
    enableAllowModeDomains: Bool = false,
    domains: [String]? = nil,
    physicalUnblockNFCTagId: String? = nil,
    physicalUnblockQRCodeId: String? = nil,
    schedule: BlockedProfileSchedule? = nil,
    disableBackgroundStops: Bool = false
  ) throws -> BlockedProfiles {
    let profileOrder = getNextOrder(in: context)

    let profile = BlockedProfiles(
      name: name,
      selectedActivity: selection,
      blockingStrategyId: blockingStrategyId,
      enableLiveActivity: enableLiveActivity,
      reminderTimeInSeconds: reminderTimeInSeconds,
      customReminderMessage: customReminderMessage,
      enableBreaks: enableBreaks,
      enableStrictMode: enableStrictMode,
      enableAllowMode: enableAllowMode,
      enableAllowModeDomains: enableAllowModeDomains,
      order: profileOrder,
      domains: domains,
      physicalUnblockNFCTagId: physicalUnblockNFCTagId,
      physicalUnblockQRCodeId: physicalUnblockQRCodeId,
      disableBackgroundStops: disableBackgroundStops
    )

    if let schedule = schedule {
      profile.schedule = schedule
    }

    // Create the snapshot so extensions can read it immediately
    updateSnapshot(for: profile)

    context.insert(profile)
    try context.save()
    return profile
  }

  static func cloneProfile(
    _ source: BlockedProfiles,
    in context: ModelContext,
    newName: String
  ) throws -> BlockedProfiles {
    let nextOrder = getNextOrder(in: context)
    let cloned = BlockedProfiles(
      name: newName,
      selectedActivity: source.selectedActivity,
      blockingStrategyId: source.blockingStrategyId ?? NFCBlockingStrategy.id,
      enableLiveActivity: source.enableLiveActivity,
      reminderTimeInSeconds: source.reminderTimeInSeconds,
      customReminderMessage: source.customReminderMessage,
      enableBreaks: source.enableBreaks,
      enableStrictMode: source.enableStrictMode,
      enableAllowMode: source.enableAllowMode,
      enableAllowModeDomains: source.enableAllowModeDomains,
      order: nextOrder,
      domains: source.domains,
      physicalUnblockNFCTagId: source.physicalUnblockNFCTagId,
      physicalUnblockQRCodeId: source.physicalUnblockQRCodeId,
      schedule: source.schedule
    )

    context.insert(cloned)
    try context.save()
    return cloned
  }

  static func addDomain(to profile: BlockedProfiles, context: ModelContext, domain: String) throws {
    guard let domains = profile.domains else {
      return
    }

    if domains.contains(domain) {
      return
    }

    let newDomains = domains + [domain]
    try updateProfile(profile, in: context, domains: newDomains)
  }

  static func removeDomain(from profile: BlockedProfiles, context: ModelContext, domain: String)
    throws
  {
    guard let domains = profile.domains else {
      return
    }

    let newDomains = domains.filter { $0 != domain }
    try updateProfile(profile, in: context, domains: newDomains)
  }
}
