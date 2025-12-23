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
  var strategyData: Data?
  var order: Int = 0

  var enableLiveActivity: Bool = false
  var reminderTimeInSeconds: UInt32?
  var enableBreaks: Bool = false
  var breakTimeInMinutes: Int = 15
  var enableStrictMode: Bool = false
  var enableAllowMode: Bool = false
  var enableAllowModeDomains: Bool = false
  var enableSafariBlocking: Bool = true

  var physicalUnblockNFCTagId: String?
  var physicalUnblockQRCodeId: String?

  @Relationship var nfcWhitelist: [NFCTagWhitelist] = []

  var domains: [String]? = nil

  var schedule: BlockedProfileSchedule? = nil

  var disableBackgroundStops: Bool = false

  var customReminderMessage: String?

  @Relationship var sessions: [BlockedProfileSession] = []

  var activeScheduleTimerActivity: DeviceActivityName? {
    return DeviceActivityCenterUtil.getActiveScheduleTimerActivity(for: self)
  }

  var scheduleIsOutOfSync: Bool {
    return self.schedule?.isActive == true
      && DeviceActivityCenterUtil.getActiveScheduleTimerActivity(for: self) == nil
  }

  init(
    id: UUID = UUID(),
    name: String,
    selectedActivity: FamilyActivitySelection = FamilyActivitySelection(),
    createdAt: Date = Date(),
    updatedAt: Date = Date(),
    blockingStrategyId: String = NFCBlockingStrategy.id,
    strategyData: Data? = nil,
    enableLiveActivity: Bool = false,
    reminderTimeInSeconds: UInt32? = nil,
    customReminderMessage: String? = nil,
    enableBreaks: Bool = false,
    breakTimeInMinutes: Int = 15,
    enableStrictMode: Bool = false,
    enableAllowMode: Bool = false,
    enableAllowModeDomains: Bool = false,
    enableSafariBlocking: Bool = true,
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
    self.strategyData = strategyData
    self.order = order

    self.enableLiveActivity = enableLiveActivity
    self.reminderTimeInSeconds = reminderTimeInSeconds
    self.customReminderMessage = customReminderMessage
    self.enableLiveActivity = enableLiveActivity
    self.enableBreaks = enableBreaks
    self.breakTimeInMinutes = breakTimeInMinutes
    self.enableStrictMode = enableStrictMode
    self.enableAllowMode = enableAllowMode
    self.enableAllowModeDomains = enableAllowModeDomains
    self.enableSafariBlocking = enableSafariBlocking
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
    strategyData: Data? = nil,
    enableLiveActivity: Bool? = nil,
    reminderTime: UInt32? = nil,
    customReminderMessage: String? = nil,
    enableBreaks: Bool? = nil,
    breakTimeInMinutes: Int? = nil,
    enableStrictMode: Bool? = nil,
    enableAllowMode: Bool? = nil,
    enableAllowModeDomains: Bool? = nil,
    enableSafariBlocking: Bool? = nil,
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

    if let newStrategyData = strategyData {
      profile.strategyData = newStrategyData
    }

    if let newEnableLiveActivity = enableLiveActivity {
      profile.enableLiveActivity = newEnableLiveActivity
    }

    if let newEnableBreaks = enableBreaks {
      profile.enableBreaks = newEnableBreaks
    }

    if let newBreakTimeInMinutes = breakTimeInMinutes {
      profile.breakTimeInMinutes = newBreakTimeInMinutes
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

    if let newEnableSafariBlocking = enableSafariBlocking {
      profile.enableSafariBlocking = newEnableSafariBlocking
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
    DeviceActivityCenterUtil.removeScheduleTimerActivities(for: profile)

    // Then delete the profile
    context.delete(profile)
    // Defer context saving as the reference to the profile might be used
  }

  static func getProfileDeepLink(_ profile: BlockedProfiles) -> String {
    return "https://foqos.app/profile/" + profile.id.uuidString
  }

  static func getSnapshot(for profile: BlockedProfiles) -> SharedData.ProfileSnapshot {
    return SharedData.ProfileSnapshot(
      id: profile.id,
      name: profile.name,
      selectedActivity: profile.selectedActivity,
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt,
      blockingStrategyId: profile.blockingStrategyId,
      strategyData: profile.strategyData,
      order: profile.order,
      enableLiveActivity: profile.enableLiveActivity,
      reminderTimeInSeconds: profile.reminderTimeInSeconds,
      customReminderMessage: profile.customReminderMessage,
      enableBreaks: profile.enableBreaks,
      breakTimeInMinutes: profile.breakTimeInMinutes,
      enableStrictMode: profile.enableStrictMode,
      enableAllowMode: profile.enableAllowMode,
      enableAllowModeDomains: profile.enableAllowModeDomains,
      enableSafariBlocking: profile.enableSafariBlocking,
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
    strategyData: Data? = nil,
    enableLiveActivity: Bool = false,
    reminderTimeInSeconds: UInt32? = nil,
    customReminderMessage: String = "",
    enableBreaks: Bool = false,
    breakTimeInMinutes: Int = 15,
    enableStrictMode: Bool = false,
    enableAllowMode: Bool = false,
    enableAllowModeDomains: Bool = false,
    enableSafariBlocking: Bool = true,
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
      strategyData: strategyData,
      enableLiveActivity: enableLiveActivity,
      reminderTimeInSeconds: reminderTimeInSeconds,
      customReminderMessage: customReminderMessage,
      enableBreaks: enableBreaks,
      breakTimeInMinutes: breakTimeInMinutes,
      enableStrictMode: enableStrictMode,
      enableAllowMode: enableAllowMode,
      enableAllowModeDomains: enableAllowModeDomains,
      enableSafariBlocking: enableSafariBlocking,
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
      strategyData: source.strategyData,
      enableLiveActivity: source.enableLiveActivity,
      reminderTimeInSeconds: source.reminderTimeInSeconds,
      customReminderMessage: source.customReminderMessage,
      enableBreaks: source.enableBreaks,
      breakTimeInMinutes: source.breakTimeInMinutes,
      enableStrictMode: source.enableStrictMode,
      enableAllowMode: source.enableAllowMode,
      enableAllowModeDomains: source.enableAllowModeDomains,
      enableSafariBlocking: source.enableSafariBlocking,
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

  // MARK: - NFC Whitelist Management


  /**
   Migrates an existing single NFC tag to the new whitelist system.

   This method safely converts legacy single-tag configurations to the new
   multi-tag whitelist format while preserving data integrity.

   - Parameters:
     - profile: The profile to migrate
     - context: SwiftData model context for database operations
   - Throws: Database errors if migration fails
   */
  static func migrateToNFCWhitelist(_ profile: BlockedProfiles, context: ModelContext) throws {
    if let singleTagId = profile.physicalUnblockNFCTagId,
       profile.nfcWhitelist.isEmpty {

        let whitelistTag = NFCTagWhitelist(
            tagId: singleTagId,
            name: "Legacy Tag",
            dateAdded: profile.updatedAt
        )

        // Set all relationships before saving to maintain consistency
        whitelistTag.profile = profile
        context.insert(whitelistTag)
        profile.nfcWhitelist.append(whitelistTag)
        profile.physicalUnblockNFCTagId = nil

        // Single transaction to prevent inconsistent state
        try context.save()
    }
  }

  /**
   Adds an NFC tag to the profile's whitelist with validation.

   - Parameters:
     - profile: The profile to add the tag to
     - context: SwiftData model context for database operations
     - tagId: Unique identifier for the NFC tag (will be normalized)
     - tagUrl: Optional URL from NDEF data
     - name: Optional display name (auto-generated if nil)
   - Throws:
     - `NFCWhitelistError.invalidTagId` if tag ID is empty or invalid
     - `NFCWhitelistError.tagAlreadyExists` if tag already exists
     - `NFCWhitelistError.tagLimitReached` if maximum tags exceeded
     - `NFCWhitelistError.invalidTagName` if name is too long
   */
  static func addNFCTag(
    to profile: BlockedProfiles,
    context: ModelContext,
    tagId: String,
    tagUrl: String? = nil,
    name: String? = nil
  ) throws {

    // Input validation
    let normalizedTagId = tagId.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !normalizedTagId.isEmpty else {
        throw NFCWhitelistError.invalidTagId
    }

    guard normalizedTagId.count <= 100 else {
        throw NFCWhitelistError.invalidTagId
    }

    if let name = name, name.count > 50 {
        throw NFCWhitelistError.invalidTagName
    }

    // Check for duplicates (case-insensitive)
    let duplicateCheck = profile.nfcWhitelist.first {
        $0.tagId.caseInsensitiveCompare(normalizedTagId) == .orderedSame
    }

    guard duplicateCheck == nil else {
        throw NFCWhitelistError.tagAlreadyExists
    }

    // Check tag limit
    guard profile.nfcWhitelist.count < 15 else {
        throw NFCWhitelistError.tagLimitReached
    }

    // Generate safe default name using timestamp to avoid race conditions
    let defaultName = name ?? "NFC Tag \(Int(Date().timeIntervalSince1970))"

    let newTag = NFCTagWhitelist(
        tagId: normalizedTagId,
        tagUrl: tagUrl,
        name: defaultName
    )

    newTag.profile = profile
    context.insert(newTag)
    profile.nfcWhitelist.append(newTag)

    try updateProfile(profile, in: context)
  }

  /**
   Removes an NFC tag from the profile's whitelist.

   - Parameters:
     - profile: The profile to remove the tag from
     - context: SwiftData model context for database operations
     - tagId: Identifier of the tag to remove
   - Throws:
     - `NFCWhitelistError.tagNotFound` if tag doesn't exist
     - Database errors if removal fails
   */
  static func removeNFCTag(
    from profile: BlockedProfiles,
    context: ModelContext,
    tagId: String
  ) throws {
    let normalizedTagId = tagId.trimmingCharacters(in: .whitespacesAndNewlines)

    guard let tagIndex = profile.nfcWhitelist.firstIndex(where: {
        $0.tagId.caseInsensitiveCompare(normalizedTagId) == .orderedSame
    }) else {
        throw NFCWhitelistError.tagNotFound
    }

    let tag = profile.nfcWhitelist.remove(at: tagIndex)
    context.delete(tag)

    try updateProfile(profile, in: context)
  }

  /**
   Simple migration to move legacy single NFC tags to whitelist.
   Call this once when the app starts up.
   */
  static func migrateLegacyNFCTags(context: ModelContext) {
    do {
      let profiles = try context.fetch(FetchDescriptor<BlockedProfiles>())

      for profile in profiles {
        // If profile has legacy tag but no whitelist entries, migrate it
        if let legacyTagId = profile.physicalUnblockNFCTagId,
           !legacyTagId.isEmpty,
           profile.nfcWhitelist.isEmpty {

          let tag = NFCTagWhitelist(tagId: legacyTagId, name: "Legacy NFC Tag")
          tag.profile = profile
          context.insert(tag)

          // Keep the legacy field for now as backup
          // profile.physicalUnblockNFCTagId = nil // Uncomment to remove legacy field
        }
      }

      try context.save()
    } catch {
      print("Migration failed: \(error)")
    }
  }
}

/// Errors that can occur during NFC whitelist operations
enum NFCWhitelistError: LocalizedError {
    case tagAlreadyExists
    case tagLimitReached
    case tagNotFound
    case invalidTagId
    case invalidTagName

    var errorDescription: String? {
        switch self {
        case .tagAlreadyExists:
            return "This NFC tag is already in the whitelist"
        case .tagLimitReached:
            return "Maximum of 15 NFC tags allowed"
        case .tagNotFound:
            return "NFC tag not found in whitelist"
        case .invalidTagId:
            return "Invalid NFC tag identifier"
        case .invalidTagName:
            return "Tag name must be 50 characters or less"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .tagAlreadyExists:
            return "This tag is already configured. You can rename it or remove it first."
        case .tagLimitReached:
            return "Remove some existing tags before adding new ones."
        case .invalidTagId:
            return "Ensure the NFC tag was scanned properly and try again."
        case .invalidTagName:
            return "Use a shorter name for this tag."
        case .tagNotFound:
            return "Check that the tag exists in the whitelist."
        }
    }
}
