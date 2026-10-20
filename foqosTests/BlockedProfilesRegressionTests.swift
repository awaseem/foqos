import FamilyControls
import SwiftData
import XCTest

@testable import foqos

final class BlockedProfilesRegressionTests: ModelRegressionTestCase {
  func testDefaultProfileKeepsOriginalStrategyAndSettings() throws {
    let profile = BlockedProfiles(name: "Focus")
    XCTAssertEqual(profile.blockingStrategyId, NFCBlockingStrategy.id)
    XCTAssertTrue(profile.shouldAskForStartSettings)
    XCTAssertTrue(profile.enableSafariBlocking)
    XCTAssertTrue(profile.enableEmergencyUnblock)
    XCTAssertFalse(profile.enableBreaks)
    XCTAssertFalse(profile.allowMultipleBreaks)
    XCTAssertEqual(profile.breakTimeInMinutes, 15)
    XCTAssertEqual(profile.order, 0)
    XCTAssertTrue(profile.sessions.isEmpty)
    XCTAssertNil(profile.strategyData)
    XCTAssertNil(profile.domains)
    XCTAssertNil(profile.physicalUnblockItems)
    XCTAssertNil(profile.schedule)
    context.insert(profile)
    try context.save()
    let fetched = try XCTUnwrap(BlockedProfiles.findProfile(byID: profile.id, in: freshContext()))
    XCTAssertEqual(fetched.blockingStrategyId, NFCBlockingStrategy.id)
  }

  func testAllConfiguredFieldsPersistAndSnapshotMatches() throws {
    let profile = configuredProfile()
    context.insert(profile)
    try context.save()
    let fetched = try XCTUnwrap(BlockedProfiles.findProfile(byID: profile.id, in: freshContext()))
    assertSnapshotFields(BlockedProfiles.getSnapshot(for: fetched), match: profile)
    XCTAssertEqual(fetched.askForStartSettings, profile.askForStartSettings)
    BlockedProfiles.updateSnapshot(for: fetched)
    assertSnapshotFields(
      try XCTUnwrap(SharedData.snapshot(for: profile.id.uuidString)), match: profile)
    BlockedProfiles.deleteSnapshot(for: fetched)
    XCTAssertNil(SharedData.snapshot(for: profile.id.uuidString))
  }

  func testStartSettingsRequirePromptOrMissingConfiguration() {
    let profile = BlockedProfiles(name: "Focus", askForStartSettings: false)
    XCTAssertTrue(profile.shouldAskForStartSettings)
    profile.strategyData = Data([1])
    XCTAssertFalse(profile.shouldAskForStartSettings)
    profile.askForStartSettings = true
    XCTAssertTrue(profile.shouldAskForStartSettings)
  }

  func testTimedBreakEligibilityUsesStrategyAndLegacyFallback() {
    let profile = BlockedProfiles(name: "Focus")
    for id in [NFCSoftUnblockBlockingStrategy.id, QRSoftUnblockBlockingStrategy.id] {
      profile.blockingStrategyId = id
      XCTAssertFalse(profile.allowsTimedBreaks)
    }
    for id in [
      nil, "unknown-strategy", ManualBlockingStrategy.id, NFCBlockingStrategy.id,
      QRCodeBlockingStrategy.id, NFCTimerBlockingStrategy.id, QRTimerBlockingStrategy.id,
      ShortcutTimerBlockingStrategy.id, NFCManualBlockingStrategy.id, QRManualBlockingStrategy.id,
      NFCPauseTimerBlockingStrategy.id, QRPauseTimerBlockingStrategy.id,
    ] as [String?] {
      profile.blockingStrategyId = id
      XCTAssertTrue(profile.allowsTimedBreaks, id ?? "nil")
    }
  }

  func testPhysicalCodesNormalizeURLsButPreserveTypeAndPath() {
    let profile = BlockedProfiles(
      name: "Focus",
      physicalUnblockItems: [
        PhysicalUnblockItem(name: "  ", type: .qrCode, codeValue: " HTTPS://EXAMPLE.COM/ "),
        PhysicalUnblockItem(name: " Desk ", type: .nfc, codeValue: " abc123 "),
        PhysicalUnblockItem(name: "Empty", type: .nfc, codeValue: "  "),
      ])
    XCTAssertEqual(profile.physicalUnblockItems?.count, 2)
    XCTAssertEqual(profile.physicalUnblockItems?.first?.name, "QR Code")
    XCTAssertTrue(profile.canUnblock(withCode: "https://example.com", type: .qrCode))
    XCTAssertTrue(profile.canUnblock(withCode: " abc123 ", type: .nfc))
    XCTAssertFalse(profile.canUnblock(withCode: "ABC123", type: .nfc))
    XCTAssertFalse(profile.canUnblock(withCode: "abc123", type: .qrCode))
    XCTAssertFalse(profile.canUnblock(withCode: "https://example.com/path", type: .qrCode))
    XCTAssertTrue(profile.hasPhysicalUnblockItem(ofType: .nfc))
    XCTAssertTrue(profile.hasPhysicalUnblockItem(ofType: .qrCode))
    profile.physicalUnblockItems = nil
    XCTAssertFalse(profile.hasPhysicalUnblockItem(ofType: .nfc))
    XCTAssertFalse(profile.canUnblock(withCode: "abc123", type: .nfc))
  }

  func testStopButtonVisibilityAtTimerBoundaryAndWithoutValidConfiguration() {
    let profile = BlockedProfiles(name: "Focus")
    XCTAssertTrue(profile.showStopButton(elapsedTime: 0))
    profile.strategyData = Data([0xFF])
    XCTAssertTrue(profile.showStopButton(elapsedTime: 0))
    profile.strategyData = StrategyTimerData.toData(
      from: StrategyTimerData(durationInMinutes: 10, hideStopButton: true))
    XCTAssertFalse(profile.showStopButton(elapsedTime: 599))
    XCTAssertTrue(profile.showStopButton(elapsedTime: 600))
    XCTAssertTrue(profile.showStopButton(elapsedTime: 601))
    profile.strategyData = StrategyTimerData.toData(
      from: StrategyTimerData(durationInMinutes: 10, hideStopButton: false))
    XCTAssertTrue(profile.showStopButton(elapsedTime: 0))
  }

  func testFetchOrderingLookupReorderingAndNextOrderPersist() throws {
    XCTAssertEqual(BlockedProfiles.getNextOrder(in: context), 0)
    XCTAssertNil(try BlockedProfiles.fetchMostRecentlyUpdatedProfile(in: context))
    XCTAssertNil(try BlockedProfiles.findProfile(byID: UUID(), in: context))
    let a = BlockedProfiles(name: "A", createdAt: referenceDate, updatedAt: referenceDate, order: 2)
    let b = BlockedProfiles(
      name: "B", createdAt: referenceDate.addingTimeInterval(1), updatedAt: referenceDate, order: 2)
    let c = BlockedProfiles(
      name: "C", createdAt: referenceDate, updatedAt: referenceDate.addingTimeInterval(2), order: 0)
    for profile in [a, b, c] { context.insert(profile) }
    try context.save()
    XCTAssertEqual(
      try BlockedProfiles.fetchProfiles(in: freshContext()).map(\.name), ["C", "B", "A"])
    XCTAssertEqual(try BlockedProfiles.fetchMostRecentlyUpdatedProfile(in: context)?.id, c.id)
    XCTAssertEqual(BlockedProfiles.getNextOrder(in: context), 3)
    try BlockedProfiles.reorderProfiles([a, c, b], in: context)
    XCTAssertEqual(
      try BlockedProfiles.fetchProfiles(in: freshContext()).map(\.name), ["A", "C", "B"])
  }

  func testCreateProfilePersistsConfigurationAndPublishesSnapshot() throws {
    let profile = try BlockedProfiles.createProfile(
      in: context, name: "Created",
      selection: FamilyActivitySelection(includeEntireCategory: true),
      blockingStrategyId: QRTimerBlockingStrategy.id,
      strategyData: Data([7]), askForStartSettings: false, enableLiveActivity: true,
      reminderTimeInSeconds: 55, customReminderMessage: "Focus", enableBreaks: true,
      breakTimeInMinutes: 4, allowMultipleBreaks: true, enableStrictMode: true,
      enableBlockAppInstallation: true, enableAllowMode: true, enableAllowModeDomains: true,
      enableSafariBlocking: false, enableAdultContentBlocking: true, domains: ["example.com"],
      physicalUnblockItems: configuredProfile().physicalUnblockItems,
      schedule: configuredProfile().schedule,
      disableBackgroundStops: true, enableEmergencyUnblock: false)
    let fetched = try XCTUnwrap(BlockedProfiles.findProfile(byID: profile.id, in: freshContext()))
    assertSnapshotFields(
      try XCTUnwrap(SharedData.snapshot(for: profile.id.uuidString)), match: fetched)
    XCTAssertEqual(fetched.name, "Created")
    XCTAssertEqual(fetched.strategyData, Data([7]))
    XCTAssertFalse(fetched.askForStartSettings)
    XCTAssertTrue(fetched.enableBlockAppInstallation)
    XCTAssertTrue(fetched.disableBackgroundStops)
    XCTAssertEqual(fetched.schedule, configuredProfile().schedule)
    XCTAssertEqual(fetched.order, 0)
    let second = try BlockedProfiles.createProfile(in: context, name: "Second")
    XCTAssertEqual(second.order, 1)
  }

  func testUpdatePersistsEverySuppliedSettingAndRefreshesSnapshot() throws {
    let profile = BlockedProfiles(name: "Original", updatedAt: referenceDate)
    context.insert(profile)
    let items = [PhysicalUnblockItem(name: " Desk ", type: .nfc, codeValue: " tag ")]
    let schedule = configuredProfile().schedule
    let before = Date()
    let updated = try BlockedProfiles.updateProfile(
      profile, in: context, name: "Updated",
      selection: FamilyActivitySelection(includeEntireCategory: true),
      blockingStrategyId: QRTimerBlockingStrategy.id,
      strategyData: .some(Data([9])), askForStartSettings: false, enableLiveActivity: true,
      reminderTime: 90, customReminderMessage: "Reminder", enableBreaks: true,
      breakTimeInMinutes: 8,
      allowMultipleBreaks: true, enableStrictMode: true, enableBlockAppInstallation: true,
      enableAllowMode: true, enableAllowModeDomains: true, enableSafariBlocking: false,
      enableAdultContentBlocking: true, enableMacSync: false, order: 5, domains: ["example.org"],
      physicalUnblockItems: .some(items), schedule: schedule, disableBackgroundStops: true,
      enableEmergencyUnblock: false)
    XCTAssertTrue(updated === profile)
    let fetched = try XCTUnwrap(BlockedProfiles.findProfile(byID: profile.id, in: freshContext()))
    XCTAssertEqual(fetched.name, "Updated")
    XCTAssertEqual(fetched.selectedActivity, FamilyActivitySelection(includeEntireCategory: true))
    XCTAssertEqual(fetched.blockingStrategyId, QRTimerBlockingStrategy.id)
    XCTAssertEqual(fetched.strategyData, Data([9]))
    XCTAssertFalse(fetched.askForStartSettings)
    XCTAssertTrue(fetched.enableLiveActivity)
    XCTAssertEqual(fetched.reminderTimeInSeconds, 90)
    XCTAssertEqual(fetched.customReminderMessage, "Reminder")
    XCTAssertTrue(fetched.enableBreaks)
    XCTAssertEqual(fetched.breakTimeInMinutes, 8)
    XCTAssertTrue(fetched.allowMultipleBreaks)
    XCTAssertTrue(fetched.enableStrictMode)
    XCTAssertTrue(fetched.enableBlockAppInstallation)
    XCTAssertTrue(fetched.enableAllowMode)
    XCTAssertTrue(fetched.enableAllowModeDomains)
    XCTAssertFalse(fetched.enableSafariBlocking)
    XCTAssertTrue(fetched.enableAdultContentBlocking)
    XCTAssertFalse(fetched.enableMacSync)
    XCTAssertEqual(fetched.order, 5)
    XCTAssertEqual(fetched.domains, ["example.org"])
    XCTAssertEqual(fetched.physicalUnblockItems?.first?.name, "Desk")
    XCTAssertEqual(fetched.physicalUnblockItems?.first?.codeValue, "tag")
    XCTAssertEqual(fetched.schedule, schedule)
    XCTAssertTrue(fetched.disableBackgroundStops)
    XCTAssertFalse(fetched.enableEmergencyUnblock)
    XCTAssertGreaterThanOrEqual(fetched.updatedAt, before)
    assertSnapshotFields(
      try XCTUnwrap(SharedData.snapshot(for: profile.id.uuidString)), match: fetched)
  }

  func testOptionalUpdatesDistinguishOmittedFromExplicitlyClearedData() throws {
    let profile = configuredProfile()
    context.insert(profile)
    _ = try BlockedProfiles.updateProfile(profile, in: context, name: "Rename")
    XCTAssertEqual(profile.strategyData, Data([1, 2, 3]))
    XCTAssertNotNil(profile.physicalUnblockItems)
    XCTAssertNotNil(profile.schedule)
    // Existing API semantics: omitted reminder arguments clear the reminder.
    XCTAssertNil(profile.reminderTimeInSeconds)
    XCTAssertNil(profile.customReminderMessage)
    _ = try BlockedProfiles.updateProfile(
      profile, in: context, strategyData: .some(nil), physicalUnblockItems: .some(nil))
    let fetched = try XCTUnwrap(BlockedProfiles.findProfile(byID: profile.id, in: freshContext()))
    XCTAssertNil(fetched.strategyData)
    XCTAssertNil(fetched.physicalUnblockItems)
  }

  func testLeavingAnyTimerClearsDataButExplicitReplacementWins() throws {
    for id in [
      NFCTimerBlockingStrategy.id, QRTimerBlockingStrategy.id, ShortcutTimerBlockingStrategy.id,
    ] {
      let profile = BlockedProfiles(name: id, blockingStrategyId: id, strategyData: Data([1]))
      context.insert(profile)
      _ = try BlockedProfiles.updateProfile(
        profile, in: context, blockingStrategyId: ManualBlockingStrategy.id)
      XCTAssertNil(profile.strategyData, id)
      profile.blockingStrategyId = id
      profile.strategyData = Data([1])
      _ = try BlockedProfiles.updateProfile(
        profile, in: context, blockingStrategyId: ManualBlockingStrategy.id,
        strategyData: .some(Data([2])))
      XCTAssertEqual(profile.strategyData, Data([2]), id)
    }
  }

  func testTimerToTimerAndNonTimerToTimerPreserveConfiguration() throws {
    let profile = BlockedProfiles(
      name: "Focus", blockingStrategyId: NFCTimerBlockingStrategy.id, strategyData: Data([1]))
    context.insert(profile)
    _ = try BlockedProfiles.updateProfile(
      profile, in: context, blockingStrategyId: QRTimerBlockingStrategy.id)
    XCTAssertEqual(profile.strategyData, Data([1]))
    profile.blockingStrategyId = ManualBlockingStrategy.id
    _ = try BlockedProfiles.updateProfile(
      profile, in: context, blockingStrategyId: NFCTimerBlockingStrategy.id)
    XCTAssertEqual(profile.strategyData, Data([1]))
  }

  func testMacSyncDisablesIncompatibleSettingsOnInitializationAndUpdate() throws {
    let profile = BlockedProfiles(
      name: "Mac", enableAllowModeDomains: true, enableAdultContentBlocking: true,
      enableMacSync: true)
    XCTAssertFalse(profile.enableAllowModeDomains)
    XCTAssertFalse(profile.enableAdultContentBlocking)
    context.insert(profile)
    _ = try BlockedProfiles.updateProfile(
      profile, in: context, enableAllowModeDomains: true, enableAdultContentBlocking: true)
    XCTAssertFalse(profile.enableAllowModeDomains)
    XCTAssertFalse(profile.enableAdultContentBlocking)
    _ = try BlockedProfiles.updateProfile(
      profile, in: context, enableAllowModeDomains: true, enableAdultContentBlocking: true,
      enableMacSync: false)
    XCTAssertTrue(profile.enableAllowModeDomains)
    XCTAssertTrue(profile.enableAdultContentBlocking)
  }

  func testCloneCopiesSettingsWithNewIdentityAndNoSessionHistory() throws {
    let source = configuredProfile()
    context.insert(source)
    let session = BlockedProfileSession(tag: "history", blockedProfile: source)
    context.insert(session)
    try context.save()
    let clone = try BlockedProfiles.cloneProfile(source, in: context, newName: "Copy")
    XCTAssertNotEqual(clone.id, source.id)
    XCTAssertEqual(clone.name, "Copy")
    XCTAssertEqual(clone.order, 10)
    XCTAssertTrue(clone.sessions.isEmpty)
    XCTAssertFalse(clone.askForStartSettings)
    var expected = BlockedProfiles.getSnapshot(for: source)
    expected.id = clone.id
    expected.name = "Copy"
    expected.order = 10
    expected.createdAt = clone.createdAt
    expected.updatedAt = clone.updatedAt
    // Preserved pre-refactor behavior: clones use the initializer default here.
    expected.disableBackgroundStops = false
    XCTAssertEqual(BlockedProfiles.getSnapshot(for: clone), expected)
    XCTAssertNil(SharedData.snapshot(for: clone.id.uuidString))
    XCTAssertNotNil(try BlockedProfiles.findProfile(byID: clone.id, in: freshContext()))
    source.blockingStrategyId = nil
    let fallback = try BlockedProfiles.cloneProfile(source, in: context, newName: "Legacy")
    XCTAssertEqual(fallback.blockingStrategyId, NFCBlockingStrategy.id)
  }

  func testDomainChangesDeduplicateAndPersistAndNilDomainsRemainNil() throws {
    let profile = BlockedProfiles(name: "Domains")
    context.insert(profile)
    try BlockedProfiles.addDomain(to: profile, context: context, domain: "ignored.com")
    try BlockedProfiles.removeDomain(from: profile, context: context, domain: "ignored.com")
    XCTAssertNil(profile.domains)
    profile.domains = []
    try BlockedProfiles.addDomain(to: profile, context: context, domain: "example.com")
    try BlockedProfiles.addDomain(to: profile, context: context, domain: "example.com")
    XCTAssertEqual(profile.domains, ["example.com"])
    try BlockedProfiles.removeDomain(from: profile, context: context, domain: "example.com")
    XCTAssertEqual(
      try BlockedProfiles.findProfile(byID: profile.id, in: freshContext())?.domains, [])
  }

  func testDeleteRemovesOnlyTargetProfileSessionsAndSnapshotAfterExplicitSave() throws {
    let profile = try BlockedProfiles.createProfile(in: context, name: "Delete")
    let keep = try BlockedProfiles.createProfile(in: context, name: "Keep")
    let ended = BlockedProfileSession(tag: "ended", blockedProfile: profile)
    ended.endTime = referenceDate
    context.insert(ended)
    let active = BlockedProfileSession.createSession(
      in: context, withTag: "active", withProfile: profile)
    let other = BlockedProfileSession(tag: "other", blockedProfile: keep)
    context.insert(other)
    try context.save()
    let profileID = profile.id
    let removedIDs = [ended.id, active.id]
    try BlockedProfiles.deleteProfile(profile, in: context)
    XCTAssertTrue(context.hasChanges)
    XCTAssertNil(SharedData.activeSharedSession)
    XCTAssertNil(SharedData.snapshot(for: profileID.uuidString))
    XCTAssertNotNil(SharedData.snapshot(for: keep.id.uuidString))
    try context.save()
    let reader = freshContext()
    XCTAssertNil(try BlockedProfiles.findProfile(byID: profileID, in: reader))
    for id in removedIDs {
      XCTAssertNil(try BlockedProfileSession.findSession(byID: id, in: reader))
    }
    XCTAssertNotNil(try BlockedProfileSession.findSession(byID: other.id, in: reader))
  }

  func testDeepLinkAndScheduleWithoutRegisteredActivity() {
    let profile = configuredProfile()
    XCTAssertEqual(
      BlockedProfiles.getProfileDeepLink(profile),
      "https://foqos.app/profile/52990B36-727A-40CA-9427-E26434984634")
    XCTAssertNil(profile.activeScheduleTimerActivity)
    XCTAssertTrue(profile.scheduleIsOutOfSync)
    profile.schedule?.days = []
    XCTAssertFalse(profile.scheduleIsOutOfSync)
    profile.schedule = nil
    XCTAssertFalse(profile.scheduleIsOutOfSync)
  }
}
