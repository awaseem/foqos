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

  @Relationship var sessions: [BlockedProfileSession] = []

  init(
    id: UUID = UUID(),
    name: String,
    selectedActivity: FamilyActivitySelection = FamilyActivitySelection(),
    createdAt: Date = Date(),
    updatedAt: Date = Date(),
    blockingStrategyId: String = NFCBlockingStrategy.id,
    enableLiveActivity: Bool = false,
    reminderTimeInSeconds: UInt32? = nil,
    enableBreaks: Bool = false,
    enableStrictMode: Bool = false,
    enableAllowMode: Bool = false,
    enableAllowModeDomains: Bool = false,
    order: Int = 0,
    domains: [String]? = nil,
    physicalUnblockNFCTagId: String? = nil,
    physicalUnblockQRCodeId: String? = nil
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
    self.enableLiveActivity = enableLiveActivity
    self.enableBreaks = enableBreaks
    self.enableStrictMode = enableStrictMode
    self.enableAllowMode = enableAllowMode
    self.enableAllowModeDomains = enableAllowModeDomains
    self.domains = domains

    self.physicalUnblockNFCTagId = physicalUnblockNFCTagId
    self.physicalUnblockQRCodeId = physicalUnblockQRCodeId
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
    enableBreaks: Bool? = nil,
    enableStrictMode: Bool? = nil,
    enableAllowMode: Bool? = nil,
    enableAllowModeDomains: Bool? = nil,
    order: Int? = nil,
    domains: [String]? = nil,
    physicalUnblockNFCTagId: String? = nil,
    physicalUnblockQRCodeId: String? = nil
  ) throws {
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

    // Values can be nil when removed
    profile.physicalUnblockNFCTagId = physicalUnblockNFCTagId
    profile.physicalUnblockQRCodeId = physicalUnblockQRCodeId

    profile.reminderTimeInSeconds = reminderTime

    profile.updatedAt = Date()

    try context.save()
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

    // Then delete the profile
    context.delete(profile)
    try context.save()
  }

  static func countSelectedActivities(_ selection: FamilyActivitySelection)
    -> Int
  {
    return selection.categories.count + selection.applications.count
      + selection.webDomains.count
  }

  static func getProfileDeepLink(_ profile: BlockedProfiles) -> String {
    return "https://foqos.app/profile/" + profile.id.uuidString
  }

  // Create a codable/equatable snapshot suitable for UserDefaults
  func toSnapshot() -> SharedData.ProfileSnapshot {
    return SharedData.ProfileSnapshot(
      id: self.id,
      name: self.name,
      selectedActivity: self.selectedActivity,
      createdAt: self.createdAt,
      updatedAt: self.updatedAt,
      blockingStrategyId: self.blockingStrategyId,
      order: self.order,
      enableLiveActivity: self.enableLiveActivity,
      reminderTimeInSeconds: self.reminderTimeInSeconds,
      enableBreaks: self.enableBreaks,
      enableStrictMode: self.enableStrictMode,
      enableAllowMode: self.enableAllowMode,
      enableAllowModeDomains: self.enableAllowModeDomains,
      domains: self.domains,
      physicalUnblockNFCTagId: self.physicalUnblockNFCTagId,
      physicalUnblockQRCodeId: self.physicalUnblockQRCodeId
    )
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
      enableBreaks: source.enableBreaks,
      enableStrictMode: source.enableStrictMode,
      enableAllowMode: source.enableAllowMode,
      enableAllowModeDomains: source.enableAllowModeDomains,
      order: nextOrder,
      domains: source.domains,
      physicalUnblockNFCTagId: source.physicalUnblockNFCTagId,
      physicalUnblockQRCodeId: source.physicalUnblockQRCodeId
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

  static func getWebDomains(from profile: BlockedProfiles) -> Set<WebDomain> {
    if let domains = profile.domains {
      return Set(domains.map { WebDomain(domain: $0) })
    }

    return []
  }
}
