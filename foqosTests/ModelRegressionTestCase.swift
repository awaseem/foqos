import FamilyControls
import SwiftData
import XCTest

@testable import foqos

@MainActor
class ModelRegressionTestCase: XCTestCase {
  var container: ModelContainer!
  var context: ModelContext!
  let referenceDate = Date(timeIntervalSince1970: 1_700_000_000)
  private var savedDefaults: [String: Any] = [:]
  private let suite = UserDefaults(suiteName: "group.dev.ambitionsoftware.foqos")!

  override func setUpWithError() throws {
    try super.setUpWithError()
    // These APIs still serve the Device Activity extensions. Preserve their real backing state.
    savedDefaults = suite.dictionaryRepresentation().filter { isModelKey($0.key) }
    for key in savedDefaults.keys { suite.removeObject(forKey: key) }
    container = try ModelContainer(
      for: BlockedProfileSession.self, BlockedProfiles.self,
      configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    context = ModelContext(container)
    context.autosaveEnabled = false
  }

  override func tearDownWithError() throws {
    for key in suite.dictionaryRepresentation().keys where isModelKey(key) {
      suite.removeObject(forKey: key)
    }
    for (key, value) in savedDefaults { suite.set(value, forKey: key) }
    context = nil
    container = nil
    try super.tearDownWithError()
  }

  private func isModelKey(_ key: String) -> Bool {
    ["profileSnapshots", "activeScheduleSession", "completedScheduleSessions"].contains(key)
      || key.hasPrefix("softUnblock.")
  }

  func freshContext() -> ModelContext { ModelContext(container) }

  func configuredProfile() -> BlockedProfiles {
    BlockedProfiles(
      id: UUID(uuidString: "52990B36-727A-40CA-9427-E26434984634")!,
      name: "Regression fixture",
      selectedActivity: FamilyActivitySelection(includeEntireCategory: true),
      createdAt: referenceDate, updatedAt: referenceDate.addingTimeInterval(60),
      blockingStrategyId: QRTimerBlockingStrategy.id, strategyData: Data([1, 2, 3]),
      askForStartSettings: false, enableLiveActivity: true, reminderTimeInSeconds: 123,
      customReminderMessage: "Keep focusing", enableBreaks: true, breakTimeInMinutes: 7,
      allowMultipleBreaks: true, enableStrictMode: true, enableBlockAppInstallation: true,
      enableAllowMode: true, enableAllowModeDomains: true, enableSafariBlocking: false,
      enableAdultContentBlocking: true, enableMacSync: false, order: 9,
      domains: ["example.com", "example.org"],
      physicalUnblockItems: [
        PhysicalUnblockItem(name: "Desk", type: .qrCode, codeValue: "https://example.com")
      ],
      schedule: BlockedProfileSchedule(
        days: [.monday, .friday], startHour: 9, startMinute: 15,
        endHour: 17, endMinute: 30, updatedAt: referenceDate),
      disableBackgroundStops: true, enableEmergencyUnblock: false
    )
  }

  func sessionSnapshot(profileID: UUID) -> SharedData.SessionSnapshot {
    SharedData.SessionSnapshot(
      id: "regression-session", tag: "scheduled", blockedProfileId: profileID,
      startTime: referenceDate, endTime: referenceDate.addingTimeInterval(3600),
      breakStartTime: referenceDate.addingTimeInterval(60),
      breakEndTime: referenceDate.addingTimeInterval(180), usedBreakDurationInSeconds: 240,
      pauseStartTime: referenceDate.addingTimeInterval(300),
      pauseEndTime: referenceDate.addingTimeInterval(600), forceStarted: true
    )
  }

  func assertSnapshotFields(
    _ snapshot: SharedData.ProfileSnapshot, match profile: BlockedProfiles,
    file: StaticString = #filePath, line: UInt = #line
  ) {
    XCTAssertEqual(snapshot.id, profile.id, file: file, line: line)
    XCTAssertEqual(snapshot.name, profile.name, file: file, line: line)
    XCTAssertEqual(snapshot.selectedActivity, profile.selectedActivity, file: file, line: line)
    XCTAssertEqual(snapshot.createdAt, profile.createdAt, file: file, line: line)
    XCTAssertEqual(snapshot.updatedAt, profile.updatedAt, file: file, line: line)
    XCTAssertEqual(snapshot.blockingStrategyId, profile.blockingStrategyId, file: file, line: line)
    XCTAssertEqual(snapshot.strategyData, profile.strategyData, file: file, line: line)
    XCTAssertEqual(snapshot.order, profile.order, file: file, line: line)
    XCTAssertEqual(snapshot.enableLiveActivity, profile.enableLiveActivity, file: file, line: line)
    XCTAssertEqual(
      snapshot.reminderTimeInSeconds, profile.reminderTimeInSeconds, file: file, line: line)
    XCTAssertEqual(
      snapshot.customReminderMessage, profile.customReminderMessage, file: file, line: line)
    XCTAssertEqual(snapshot.enableBreaks, profile.enableBreaks, file: file, line: line)
    XCTAssertEqual(snapshot.breakTimeInMinutes, profile.breakTimeInMinutes, file: file, line: line)
    XCTAssertEqual(
      snapshot.allowMultipleBreaks, profile.allowMultipleBreaks, file: file, line: line)
    XCTAssertEqual(snapshot.enableStrictMode, profile.enableStrictMode, file: file, line: line)
    XCTAssertEqual(
      snapshot.enableBlockAppInstallation, profile.enableBlockAppInstallation, file: file,
      line: line)
    XCTAssertEqual(snapshot.enableAllowMode, profile.enableAllowMode, file: file, line: line)
    XCTAssertEqual(
      snapshot.enableAllowModeDomains, profile.enableAllowModeDomains, file: file, line: line)
    XCTAssertEqual(
      snapshot.enableSafariBlocking, profile.enableSafariBlocking, file: file, line: line)
    XCTAssertEqual(
      snapshot.enableAdultContentBlocking, profile.enableAdultContentBlocking, file: file,
      line: line)
    XCTAssertEqual(snapshot.enableMacSync, profile.enableMacSync, file: file, line: line)
    XCTAssertEqual(snapshot.domains, profile.domains, file: file, line: line)
    XCTAssertEqual(
      snapshot.physicalUnblockItems, profile.physicalUnblockItems, file: file, line: line)
    XCTAssertEqual(snapshot.schedule, profile.schedule, file: file, line: line)
    XCTAssertEqual(
      snapshot.disableBackgroundStops, profile.disableBackgroundStops, file: file, line: line)
    XCTAssertEqual(
      snapshot.enableEmergencyUnblock, profile.enableEmergencyUnblock, file: file, line: line)
    XCTAssertNil(snapshot.physicalUnblockNFCTagId, file: file, line: line)
    XCTAssertNil(snapshot.physicalUnblockQRCodeId, file: file, line: line)
  }
}
