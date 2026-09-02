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
  var askForStartSettings: Bool = true
  var order: Int = 0

  var enableLiveActivity: Bool = false
  var reminderTimeInSeconds: UInt32?
  var enableBreaks: Bool = false
  var breakTimeInMinutes: Int = 15
  var allowMultipleBreaks: Bool = false
  var breakAllowanceModeRawValue: String?
  var breakCountLimit: Int = 1
  var isBreakCountUnlimited: Bool = false
  var breakResetHour: Int = 0
  var breakResetMinute: Int = 0
  var breakResetPolicyRawValue: String?
  var enableStrictMode: Bool = false
  var enableBlockAppInstallation: Bool = false
  var enableAllowMode: Bool = false
  var enableAllowModeDomains: Bool = false
  var enableSafariBlocking: Bool = true
  var enableAdultContentBlocking: Bool = false
  var enableMacSync: Bool = false

  @available(
    *, deprecated, message: "Use physicalUnblockItems instead - supports multiple NFC/QR codes"
  )
  var physicalUnblockNFCTagId: String?

  @available(
    *, deprecated, message: "Use physicalUnblockItems instead - supports multiple NFC/QR codes"
  )
  var physicalUnblockQRCodeId: String?

  /// Array of physical unblock items (NFC tags and QR codes) that can unblock this profile
  /// Supports multiple NFC tags and/or QR codes per profile
  var physicalUnblockItems: [PhysicalUnblockItem]?

  var domains: [String]? = nil

  var schedule: BlockedProfileSchedule? = nil

  var disableBackgroundStops: Bool = false

  var enableEmergencyUnblock: Bool = true

  var customReminderMessage: String?

  @Relationship var sessions: [BlockedProfileSession] = []

  var activeScheduleTimerActivity: DeviceActivityName? {
    return DeviceActivityCenterUtil.getActiveScheduleTimerActivity(for: self)
  }

  var scheduleIsOutOfSync: Bool {
    return self.schedule?.isActive == true
      && DeviceActivityCenterUtil.getActiveScheduleTimerActivity(for: self) == nil
  }

  var allowsTimedBreaks: Bool {
    let strategyId = blockingStrategyId ?? NFCBlockingStrategy.id
    return StrategyManager.getStrategyFromId(id: strategyId).allowsTimedBreaks
  }

  var breakAllowanceMode: BreakAllowanceMode {
    get {
      guard let breakAllowanceModeRawValue,
        let mode = BreakAllowanceMode(rawValue: breakAllowanceModeRawValue)
      else {
        return allowMultipleBreaks ? .cumulative : .perBreak
      }
      return mode
    }
    set {
      breakAllowanceModeRawValue = newValue.rawValue
      allowMultipleBreaks = newValue == .cumulative || permitsMultipleBreaksPerPeriod
    }
  }

  var resolvedBreakCountLimit: Int? {
    isBreakCountUnlimited ? nil : max(1, breakCountLimit)
  }

  var permitsMultipleBreaksPerPeriod: Bool {
    switch breakAllowanceMode {
    case .perBreak:
      return resolvedBreakCountLimit.map { $0 > 1 } ?? true
    case .cumulative:
      return true
    }
  }

  var breakResetPolicy: BreakResetPolicy {
    get {
      guard let breakResetPolicyRawValue,
        let policy = BreakResetPolicy(rawValue: breakResetPolicyRawValue)
      else {
        return .daily
      }
      return policy
    }
    set {
      breakResetPolicyRawValue = newValue.rawValue
    }
  }

  var shouldAskForStartSettings: Bool {
    askForStartSettings || strategyData == nil
  }

  // MARK: - Physical Unblock Helpers

  /// Checks if a specific NFC tag or QR code can unblock this profile
  /// - Parameters:
  ///   - codeValue: The NFC tag ID or QR code value to check
  ///   - type: The type of code (NFC or QR)
  /// - Returns: True if the code is in the allowed list, false otherwise
  func canUnblock(withCode codeValue: String, type: PhysicalUnblockItem.PhysicalUnblockType) -> Bool
  {
    guard let items = physicalUnblockItems else { return false }
    let normalizedCodeValue = PhysicalUnblockItem.normalizedCodeValue(codeValue, type: type)

    return items.contains {
      let itemCodeValue = PhysicalUnblockItem.normalizedCodeValue($0.codeValue, type: $0.type)

      return $0.type == type
        && itemCodeValue == normalizedCodeValue
    }
  }

  func hasPhysicalUnblockItem(ofType type: PhysicalUnblockItem.PhysicalUnblockType) -> Bool {
    guard let items = physicalUnblockItems else { return false }
    return items.contains { $0.type == type }
  }

  init(
    id: UUID = UUID(),
    name: String,
    selectedActivity: FamilyActivitySelection = FamilyActivitySelection(),
    createdAt: Date = Date(),
    updatedAt: Date = Date(),
    blockingStrategyId: String = NFCBlockingStrategy.id,
    strategyData: Data? = nil,
    askForStartSettings: Bool = true,
    enableLiveActivity: Bool = false,
    reminderTimeInSeconds: UInt32? = nil,
    customReminderMessage: String? = nil,
    enableBreaks: Bool = false,
    breakTimeInMinutes: Int = 15,
    allowMultipleBreaks: Bool = false,
    breakAllowanceMode: BreakAllowanceMode? = nil,
    breakCountLimit: Int = 1,
    isBreakCountUnlimited: Bool = false,
    breakResetHour: Int = 0,
    breakResetMinute: Int = 0,
    breakResetPolicy: BreakResetPolicy = .daily,
    enableStrictMode: Bool = false,
    enableBlockAppInstallation: Bool = false,
    enableAllowMode: Bool = false,
    enableAllowModeDomains: Bool = false,
    enableSafariBlocking: Bool = true,
    enableAdultContentBlocking: Bool = false,
    enableMacSync: Bool = false,
    order: Int = 0,
    domains: [String]? = nil,
    physicalUnblockItems: [PhysicalUnblockItem]? = nil,
    schedule: BlockedProfileSchedule? = nil,
    disableBackgroundStops: Bool = false,
    enableEmergencyUnblock: Bool = true
  ) {
    self.id = id
    self.name = name
    self.selectedActivity = selectedActivity
    self.createdAt = createdAt
    self.updatedAt = updatedAt
    self.blockingStrategyId = blockingStrategyId
    self.strategyData = strategyData
    self.askForStartSettings = askForStartSettings
    self.order = order

    self.enableLiveActivity = enableLiveActivity
    self.reminderTimeInSeconds = reminderTimeInSeconds
    self.customReminderMessage = customReminderMessage
    self.enableLiveActivity = enableLiveActivity
    self.enableBreaks = enableBreaks
    self.breakTimeInMinutes = breakTimeInMinutes
    self.allowMultipleBreaks = allowMultipleBreaks
    self.breakAllowanceModeRawValue = breakAllowanceMode?.rawValue
    self.breakCountLimit = max(1, breakCountLimit)
    self.isBreakCountUnlimited = isBreakCountUnlimited
    self.breakResetHour = min(max(breakResetHour, 0), 23)
    self.breakResetMinute = min(max(breakResetMinute, 0), 59)
    self.breakResetPolicyRawValue = breakResetPolicy.rawValue
    if let breakAllowanceMode {
      self.allowMultipleBreaks =
        breakAllowanceMode == .cumulative || isBreakCountUnlimited || breakCountLimit > 1
    }
    self.enableStrictMode = enableStrictMode
    self.enableBlockAppInstallation = enableBlockAppInstallation
    self.enableAllowMode = enableAllowMode
    self.enableAllowModeDomains = enableMacSync ? false : enableAllowModeDomains
    self.enableSafariBlocking = enableSafariBlocking
    self.enableAdultContentBlocking = enableMacSync ? false : enableAdultContentBlocking
    self.enableMacSync = enableMacSync
    self.domains = domains

    self.physicalUnblockItems = PhysicalUnblockItem.normalizedItems(physicalUnblockItems)
    self.schedule = schedule

    self.disableBackgroundStops = disableBackgroundStops
    self.enableEmergencyUnblock = enableEmergencyUnblock
  }

  func showStopButton(elapsedTime: TimeInterval) -> Bool {
    guard let strategyData = self.strategyData else { return true }
    let timerData = StrategyTimerData.toStrategyTimerData(from: strategyData)

    // If hideStopButton is false, always show the stop button
    if !timerData.hideStopButton {
      return true
    }

    let durationInSeconds = Double(timerData.durationInMinutes * 60)
    return elapsedTime >= durationInSeconds
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
    strategyData: Data?? = nil,
    askForStartSettings: Bool? = nil,
    enableLiveActivity: Bool? = nil,
    reminderTime: UInt32? = nil,
    customReminderMessage: String? = nil,
    enableBreaks: Bool? = nil,
    breakTimeInMinutes: Int? = nil,
    allowMultipleBreaks: Bool? = nil,
    breakAllowanceMode: BreakAllowanceMode? = nil,
    breakCountLimit: Int? = nil,
    isBreakCountUnlimited: Bool? = nil,
    breakResetHour: Int? = nil,
    breakResetMinute: Int? = nil,
    breakResetPolicy: BreakResetPolicy? = nil,
    enableStrictMode: Bool? = nil,
    enableBlockAppInstallation: Bool? = nil,
    enableAllowMode: Bool? = nil,
    enableAllowModeDomains: Bool? = nil,
    enableSafariBlocking: Bool? = nil,
    enableAdultContentBlocking: Bool? = nil,
    enableMacSync: Bool? = nil,
    order: Int? = nil,
    domains: [String]? = nil,
    physicalUnblockItems: [PhysicalUnblockItem]?? = nil,
    schedule: BlockedProfileSchedule? = nil,
    disableBackgroundStops: Bool? = nil,
    enableEmergencyUnblock: Bool? = nil
  ) throws -> BlockedProfiles {
    if let newName = name {
      profile.name = newName
    }

    if let newSelection = selection {
      profile.selectedActivity = newSelection
    }

    if let newStrategyId = blockingStrategyId {
      let oldStrategyId = profile.blockingStrategyId
      let timerStrategyIds = [
        QRTimerBlockingStrategy.id,
        NFCTimerBlockingStrategy.id,
        ShortcutTimerBlockingStrategy.id,
      ]

      // Check if switching FROM timer TO non-timer strategy
      let wasTimer = oldStrategyId != nil && timerStrategyIds.contains(oldStrategyId!)
      let isTimer = timerStrategyIds.contains(newStrategyId)

      if wasTimer && !isTimer {
        profile.strategyData = nil
      }

      profile.blockingStrategyId = newStrategyId
    }

    if let strategyData {
      profile.strategyData = strategyData
    }

    if let newAskForStartSettings = askForStartSettings {
      profile.askForStartSettings = newAskForStartSettings
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

    if let newAllowMultipleBreaks = allowMultipleBreaks {
      profile.allowMultipleBreaks = newAllowMultipleBreaks
    }

    if let newBreakAllowanceMode = breakAllowanceMode {
      profile.breakAllowanceMode = newBreakAllowanceMode
    }

    if let newBreakCountLimit = breakCountLimit {
      profile.breakCountLimit = max(1, newBreakCountLimit)
    }

    if let newIsBreakCountUnlimited = isBreakCountUnlimited {
      profile.isBreakCountUnlimited = newIsBreakCountUnlimited
    }

    if let newBreakResetHour = breakResetHour {
      profile.breakResetHour = min(max(newBreakResetHour, 0), 23)
    }

    if let newBreakResetMinute = breakResetMinute {
      profile.breakResetMinute = min(max(newBreakResetMinute, 0), 59)
    }

    if let newBreakResetPolicy = breakResetPolicy {
      profile.breakResetPolicy = newBreakResetPolicy
    }

    profile.allowMultipleBreaks =
      profile.breakAllowanceMode == .cumulative || profile.permitsMultipleBreaksPerPeriod

    if let newEnableStrictMode = enableStrictMode {
      profile.enableStrictMode = newEnableStrictMode
    }

    if let newEnableBlockAppInstallation = enableBlockAppInstallation {
      profile.enableBlockAppInstallation = newEnableBlockAppInstallation
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

    if let newEnableAdultContentBlocking = enableAdultContentBlocking {
      profile.enableAdultContentBlocking = newEnableAdultContentBlocking
    }

    if let newEnableMacSync = enableMacSync {
      profile.enableMacSync = newEnableMacSync
    }

    if profile.enableMacSync {
      profile.enableAllowModeDomains = false
      profile.enableAdultContentBlocking = false
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

    if let newEnableEmergencyUnblock = enableEmergencyUnblock {
      profile.enableEmergencyUnblock = newEnableEmergencyUnblock
    }

    if let physicalUnblockItems {
      profile.physicalUnblockItems = PhysicalUnblockItem.normalizedItems(physicalUnblockItems)
    }

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
    SharedData.resetBreakAllowanceUsage(for: profile.id)

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
      allowMultipleBreaks: profile.allowMultipleBreaks,
      breakAllowanceModeRawValue: profile.breakAllowanceMode.rawValue,
      breakCountLimit: profile.breakCountLimit,
      isBreakCountUnlimited: profile.isBreakCountUnlimited,
      breakResetHour: profile.breakResetHour,
      breakResetMinute: profile.breakResetMinute,
      breakResetPolicyRawValue: profile.breakResetPolicy.rawValue,
      enableStrictMode: profile.enableStrictMode,
      enableBlockAppInstallation: profile.enableBlockAppInstallation,
      enableAllowMode: profile.enableAllowMode,
      enableAllowModeDomains: profile.enableAllowModeDomains,
      enableSafariBlocking: profile.enableSafariBlocking,
      enableAdultContentBlocking: profile.enableAdultContentBlocking,
      enableMacSync: profile.enableMacSync,
      domains: profile.domains,
      physicalUnblockNFCTagId: nil,
      physicalUnblockQRCodeId: nil,
      physicalUnblockItems: profile.physicalUnblockItems,
      schedule: profile.schedule,
      disableBackgroundStops: profile.disableBackgroundStops,
      enableEmergencyUnblock: profile.enableEmergencyUnblock
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
    askForStartSettings: Bool = true,
    enableLiveActivity: Bool = false,
    reminderTimeInSeconds: UInt32? = nil,
    customReminderMessage: String = "",
    enableBreaks: Bool = false,
    breakTimeInMinutes: Int = 15,
    allowMultipleBreaks: Bool = false,
    breakAllowanceMode: BreakAllowanceMode? = nil,
    breakCountLimit: Int = 1,
    isBreakCountUnlimited: Bool = false,
    breakResetHour: Int = 0,
    breakResetMinute: Int = 0,
    breakResetPolicy: BreakResetPolicy = .daily,
    enableStrictMode: Bool = false,
    enableBlockAppInstallation: Bool = false,
    enableAllowMode: Bool = false,
    enableAllowModeDomains: Bool = false,
    enableSafariBlocking: Bool = true,
    enableAdultContentBlocking: Bool = false,
    enableMacSync: Bool = false,
    domains: [String]? = nil,
    physicalUnblockItems: [PhysicalUnblockItem]? = nil,
    schedule: BlockedProfileSchedule? = nil,
    disableBackgroundStops: Bool = false,
    enableEmergencyUnblock: Bool = true
  ) throws -> BlockedProfiles {
    let profileOrder = getNextOrder(in: context)

    let profile = BlockedProfiles(
      name: name,
      selectedActivity: selection,
      blockingStrategyId: blockingStrategyId,
      strategyData: strategyData,
      askForStartSettings: askForStartSettings,
      enableLiveActivity: enableLiveActivity,
      reminderTimeInSeconds: reminderTimeInSeconds,
      customReminderMessage: customReminderMessage,
      enableBreaks: enableBreaks,
      breakTimeInMinutes: breakTimeInMinutes,
      allowMultipleBreaks: allowMultipleBreaks,
      breakAllowanceMode: breakAllowanceMode,
      breakCountLimit: breakCountLimit,
      isBreakCountUnlimited: isBreakCountUnlimited,
      breakResetHour: breakResetHour,
      breakResetMinute: breakResetMinute,
      breakResetPolicy: breakResetPolicy,
      enableStrictMode: enableStrictMode,
      enableBlockAppInstallation: enableBlockAppInstallation,
      enableAllowMode: enableAllowMode,
      enableAllowModeDomains: enableAllowModeDomains,
      enableSafariBlocking: enableSafariBlocking,
      enableAdultContentBlocking: enableAdultContentBlocking,
      enableMacSync: enableMacSync,
      order: profileOrder,
      domains: domains,
      physicalUnblockItems: physicalUnblockItems,
      disableBackgroundStops: disableBackgroundStops,
      enableEmergencyUnblock: enableEmergencyUnblock
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
      askForStartSettings: source.askForStartSettings,
      enableLiveActivity: source.enableLiveActivity,
      reminderTimeInSeconds: source.reminderTimeInSeconds,
      customReminderMessage: source.customReminderMessage,
      enableBreaks: source.enableBreaks,
      breakTimeInMinutes: source.breakTimeInMinutes,
      allowMultipleBreaks: source.allowMultipleBreaks,
      breakAllowanceMode: source.breakAllowanceMode,
      breakCountLimit: source.breakCountLimit,
      isBreakCountUnlimited: source.isBreakCountUnlimited,
      breakResetHour: source.breakResetHour,
      breakResetMinute: source.breakResetMinute,
      breakResetPolicy: source.breakResetPolicy,
      enableStrictMode: source.enableStrictMode,
      enableBlockAppInstallation: source.enableBlockAppInstallation,
      enableAllowMode: source.enableAllowMode,
      enableAllowModeDomains: source.enableAllowModeDomains,
      enableSafariBlocking: source.enableSafariBlocking,
      enableAdultContentBlocking: source.enableAdultContentBlocking,
      enableMacSync: source.enableMacSync,
      order: nextOrder,
      domains: source.domains,
      physicalUnblockItems: source.physicalUnblockItems,
      schedule: source.schedule,
      enableEmergencyUnblock: source.enableEmergencyUnblock
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
    _ = try updateProfile(profile, in: context, domains: newDomains)
  }

  static func removeDomain(from profile: BlockedProfiles, context: ModelContext, domain: String)
    throws
  {
    guard let domains = profile.domains else {
      return
    }

    let newDomains = domains.filter { $0 != domain }
    _ = try updateProfile(profile, in: context, domains: newDomains)
  }
}
