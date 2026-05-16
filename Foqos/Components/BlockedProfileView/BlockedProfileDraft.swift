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
  @Published var enableStrictMode: Bool
  @Published var enableBlockAppInstallation: Bool
  @Published var reminderTimeInMinutes: Int
  @Published var customReminderMessage: String
  @Published var enableAllowMode: Bool
  @Published var enableAllowModeDomain: Bool
  @Published var enableSafariBlocking: Bool
  @Published var enableAdultContentBlocking: Bool
  @Published var disableBackgroundStops: Bool
  @Published var enableEmergencyUnblock: Bool
  @Published var domains: [String]
  @Published var physicalUnblockItems: [PhysicalUnblockItem]
  @Published var schedule: BlockedProfileSchedule
  @Published var selectedActivity: FamilyActivitySelection
  @Published var selectedStrategy: BlockingStrategy?

  init(profile: BlockedProfiles? = nil) {
    name = profile?.name ?? ""
    selectedActivity = profile?.selectedActivity ?? FamilyActivitySelection()
    enableLiveActivity = profile?.enableLiveActivity ?? false
    enableBreaks = profile?.enableBreaks ?? false
    breakTimeInMinutes = profile?.breakTimeInMinutes ?? 15
    enableStrictMode = profile?.enableStrictMode ?? false
    enableBlockAppInstallation = profile?.enableBlockAppInstallation ?? false
    enableAllowMode = profile?.enableAllowMode ?? false
    enableAllowModeDomain = profile?.enableAllowModeDomains ?? false
    enableSafariBlocking = profile?.enableSafariBlocking ?? true
    enableAdultContentBlocking = profile?.enableAdultContentBlocking ?? false
    enableReminder = profile?.reminderTimeInSeconds != nil
    disableBackgroundStops = profile?.disableBackgroundStops ?? false
    enableEmergencyUnblock = profile?.enableEmergencyUnblock ?? true
    reminderTimeInMinutes = Int(profile?.reminderTimeInSeconds ?? 900) / 60
    customReminderMessage = profile?.customReminderMessage ?? ""
    domains = profile?.domains ?? []
    physicalUnblockItems = profile?.physicalUnblockItems ?? []
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
  }

  var isValid: Bool {
    return !name.isEmpty
  }

  func save(
    existingProfile: BlockedProfiles?,
    in context: ModelContext
  ) throws -> BlockedProfiles {
    schedule.updatedAt = Date()

    let reminderTimeSeconds: UInt32? =
      enableReminder ? UInt32(reminderTimeInMinutes * 60) : nil
    let physicalUnblockItemsToSave: [PhysicalUnblockItem]? =
      physicalUnblockItems.isEmpty ? nil : physicalUnblockItems

    if let existingProfile {
      let updatedProfile = try BlockedProfiles.updateProfile(
        existingProfile,
        in: context,
        name: name,
        selection: selectedActivity,
        blockingStrategyId: selectedStrategy?.getIdentifier(),
        enableLiveActivity: enableLiveActivity,
        reminderTime: reminderTimeSeconds,
        customReminderMessage: customReminderMessage,
        enableBreaks: enableBreaks,
        breakTimeInMinutes: breakTimeInMinutes,
        enableStrictMode: enableStrictMode,
        enableBlockAppInstallation: enableBlockAppInstallation,
        enableAllowMode: enableAllowMode,
        enableAllowModeDomains: enableAllowModeDomain,
        enableSafariBlocking: enableSafariBlocking,
        enableAdultContentBlocking: enableAdultContentBlocking,
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
      enableLiveActivity: enableLiveActivity,
      reminderTimeInSeconds: reminderTimeSeconds,
      customReminderMessage: customReminderMessage,
      enableBreaks: enableBreaks,
      breakTimeInMinutes: breakTimeInMinutes,
      enableStrictMode: enableStrictMode,
      enableBlockAppInstallation: enableBlockAppInstallation,
      enableAllowMode: enableAllowMode,
      enableAllowModeDomains: enableAllowModeDomain,
      enableSafariBlocking: enableSafariBlocking,
      enableAdultContentBlocking: enableAdultContentBlocking,
      domains: domains,
      physicalUnblockItems: physicalUnblockItemsToSave,
      schedule: schedule,
      disableBackgroundStops: disableBackgroundStops,
      enableEmergencyUnblock: enableEmergencyUnblock
    )

    DeviceActivityCenterUtil.scheduleTimerActivity(for: newProfile)
    return newProfile
  }
}
