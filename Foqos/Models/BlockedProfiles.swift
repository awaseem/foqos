import FamilyControls
import Foundation
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

  init(
    id: UUID = UUID(),
    name: String,
    selectedActivity: FamilyActivitySelection = FamilyActivitySelection(),
    createdAt: Date = Date(),
    updatedAt: Date = Date(),
    blockingStrategyId: String = "NFCBlockingStrategy",
    strategyData: Data? = nil,
    askForStartSettings: Bool = true,
    enableLiveActivity: Bool = false,
    reminderTimeInSeconds: UInt32? = nil,
    customReminderMessage: String? = nil,
    enableBreaks: Bool = false,
    breakTimeInMinutes: Int = 15,
    allowMultipleBreaks: Bool = false,
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
}
