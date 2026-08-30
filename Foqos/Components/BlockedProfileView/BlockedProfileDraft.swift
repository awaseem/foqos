import FamilyControls
import Foundation
import SwiftData
import SwiftUI

final class BlockedProfileDraft: ObservableObject {
  @Published var name: String
  @Published var enableLiveActivity: Bool
  @Published var enableReminder: Bool
  @Published var enableBreaks: Bool
  @Published var breakTimeInMinutes: Int
  @Published var allowMultipleBreaks: Bool
  @Published var enableStrictMode: Bool
  @Published var enableBlockAppInstallation: Bool
  @Published var reminderTimeInMinutes: Int
  @Published var customReminderMessage: String
  @Published var enableAllowMode: Bool
  @Published var enableAllowModeDomain: Bool
  @Published var enableSafariBlocking: Bool
  @Published var enableAdultContentBlocking: Bool
  @Published var enableMacSync: Bool
  @Published var disableBackgroundStops: Bool
  @Published var enableEmergencyUnblock: Bool
  @Published var domains: [String]
  @Published var physicalUnblockItems: [PhysicalUnblockItem]
  @Published var schedule: BlockedProfileSchedule
  @Published var selectedActivity: FamilyActivitySelection
  @Published var strategyData: Data?
  @Published var askForStartSettings: Bool
  @Published var selectedStrategy: BlockingStrategy? {
    didSet {
      let oldSettingsKind = StrategyStartSettingsKind(strategy: oldValue)
      let newSettingsKind = StrategyStartSettingsKind(strategy: selectedStrategy)

      if newSettingsKind == nil || oldSettingsKind != newSettingsKind {
        strategyData = nil
        askForStartSettings = true
      }

      enforceStrategyPolicies()
    }
  }

  init(profile: BlockedProfiles? = nil) {
    let isMacSyncEnabled = profile?.enableMacSync ?? false

    name = profile?.name ?? ""
    selectedActivity = profile?.selectedActivity ?? FamilyActivitySelection()
    enableLiveActivity = profile?.enableLiveActivity ?? false
    enableBreaks = profile?.enableBreaks ?? false
    breakTimeInMinutes = profile?.breakTimeInMinutes ?? 15
    allowMultipleBreaks = profile?.allowMultipleBreaks ?? false
    enableStrictMode = profile?.enableStrictMode ?? false
    enableBlockAppInstallation = profile?.enableBlockAppInstallation ?? false
    enableAllowMode = profile?.enableAllowMode ?? false
    enableMacSync = isMacSyncEnabled
    enableAllowModeDomain = isMacSyncEnabled ? false : profile?.enableAllowModeDomains ?? false
    enableSafariBlocking = profile?.enableSafariBlocking ?? true
    enableAdultContentBlocking =
      isMacSyncEnabled ? false : profile?.enableAdultContentBlocking ?? false
    enableReminder = profile?.reminderTimeInSeconds != nil
    disableBackgroundStops = profile?.disableBackgroundStops ?? false
    enableEmergencyUnblock = profile?.enableEmergencyUnblock ?? true
    reminderTimeInMinutes = Int(profile?.reminderTimeInSeconds ?? 900) / 60
    customReminderMessage = profile?.customReminderMessage ?? ""
    domains = profile?.domains ?? []
    physicalUnblockItems = profile?.physicalUnblockItems ?? []
    strategyData = nil
    askForStartSettings = true
    schedule =
      profile?.schedule
      ?? BlockedProfileSchedule(
        days: [],
        startHour: 9,
        startMinute: 0,
        endHour: 17,
        endMinute: 0,
        updatedAt: Date()
      )

    if let profileStrategyId = profile?.blockingStrategyId {
      selectedStrategy = StrategyManager.getStrategyFromId(id: profileStrategyId)
    } else {
      selectedStrategy = NFCBlockingStrategy()
    }

    // Restore persisted settings after the strategy observer has handled initial selection.
    strategyData = profile?.strategyData
    askForStartSettings = profile?.askForStartSettings ?? true

    enforceStrategyPolicies()
  }

  var isValid: Bool {
    return !name.isEmpty
  }

  var selectedStrategyAllowsTimedBreaks: Bool {
    return selectedStrategy?.allowsTimedBreaks ?? true
  }

  var selectedStrategySupportsAllowMode: Bool {
    return selectedStrategy?.supportsAllowMode ?? true
  }

  func save(
    existingProfile: BlockedProfiles?,
    in context: ModelContext
  ) throws -> BlockedProfiles {
    ensureSavedStartSettings()
    schedule.updatedAt = Date()

    let reminderTimeSeconds: UInt32? =
      enableReminder ? UInt32(reminderTimeInMinutes * 60) : nil
    let physicalUnblockItemsToSave: [PhysicalUnblockItem]? =
      physicalUnblockItems.isEmpty ? nil : physicalUnblockItems
    let enableTimedBreaksToSave = selectedStrategyAllowsTimedBreaks && enableBreaks

    if let existingProfile {
      let updatedProfile = try BlockedProfiles.updateProfile(
        existingProfile,
        in: context,
        name: name,
        selection: selectedActivity,
        blockingStrategyId: selectedStrategy?.getIdentifier(),
        strategyData: .some(strategyData),
        askForStartSettings: askForStartSettings,
        enableLiveActivity: enableLiveActivity,
        reminderTime: reminderTimeSeconds,
        customReminderMessage: customReminderMessage,
        enableBreaks: enableTimedBreaksToSave,
        breakTimeInMinutes: breakTimeInMinutes,
        allowMultipleBreaks: enableTimedBreaksToSave && allowMultipleBreaks,
        enableStrictMode: enableStrictMode,
        enableBlockAppInstallation: enableBlockAppInstallation,
        enableAllowMode: enableAllowMode,
        enableAllowModeDomains: enableAllowModeDomain,
        enableSafariBlocking: enableSafariBlocking,
        enableAdultContentBlocking: enableAdultContentBlocking,
        enableMacSync: enableMacSync,
        domains: domains,
        physicalUnblockItems: .some(physicalUnblockItemsToSave),
        schedule: schedule,
        disableBackgroundStops: disableBackgroundStops,
        enableEmergencyUnblock: enableEmergencyUnblock
      )

      DeviceActivityCenterUtil.scheduleTimerActivity(for: updatedProfile)
      return updatedProfile
    }

    let newProfile = try BlockedProfiles.createProfile(
      in: context,
      name: name,
      selection: selectedActivity,
      blockingStrategyId: selectedStrategy?.getIdentifier() ?? NFCBlockingStrategy.id,
      strategyData: strategyData,
      askForStartSettings: askForStartSettings,
      enableLiveActivity: enableLiveActivity,
      reminderTimeInSeconds: reminderTimeSeconds,
      customReminderMessage: customReminderMessage,
      enableBreaks: enableTimedBreaksToSave,
      breakTimeInMinutes: breakTimeInMinutes,
      allowMultipleBreaks: enableTimedBreaksToSave && allowMultipleBreaks,
      enableStrictMode: enableStrictMode,
      enableBlockAppInstallation: enableBlockAppInstallation,
      enableAllowMode: enableAllowMode,
      enableAllowModeDomains: enableAllowModeDomain,
      enableSafariBlocking: enableSafariBlocking,
      enableAdultContentBlocking: enableAdultContentBlocking,
      enableMacSync: enableMacSync,
      domains: domains,
      physicalUnblockItems: physicalUnblockItemsToSave,
      schedule: schedule,
      disableBackgroundStops: disableBackgroundStops,
      enableEmergencyUnblock: enableEmergencyUnblock
    )

    DeviceActivityCenterUtil.scheduleTimerActivity(for: newProfile)
    return newProfile
  }

  private func enforceStrategyPolicies() {
    if !selectedStrategyAllowsTimedBreaks {
      enableBreaks = false
      allowMultipleBreaks = false
    }

    if !selectedStrategySupportsAllowMode && enableAllowMode {
      enableAllowMode = false
      selectedActivity = FamilyActivitySelection()
    }
  }

  private func ensureSavedStartSettings() {
    guard !askForStartSettings, strategyData == nil,
      let settingsKind = StrategyStartSettingsKind(strategy: selectedStrategy)
    else {
      return
    }

    strategyData = settingsKind.defaultData
  }
}
