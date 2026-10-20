import SwiftData
import XCTest

@testable import foqos

final class ModelStoreCompatibilityTests: ModelRegressionTestCase {
  func testPreRefactorStoreMigratesAndRetainsAllData() throws {
    let fixture = try XCTUnwrap(
      Bundle(for: Self.self).url(forResource: "pre-refactor-models", withExtension: "store"))
    let directory = URL.temporaryDirectory.appendingPathComponent(
      UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let url = directory.appendingPathComponent("models.store")
    try FileManager.default.copyItem(at: fixture, to: url)

    try openVerifyAndUpdateStore(at: url)

    // Open a new container, not just a new context, to verify a durable post-upgrade write.
    let reopened = try diskContainer(at: url)
    let reader = ModelContext(reopened)
    let profile = try XCTUnwrap(BlockedProfiles.fetchProfiles(in: reader).first)
    XCTAssertEqual(profile.name, "Updated after upgrade")
    XCTAssertEqual(profile.sessions.count, 2)
    XCTAssertFalse(profile.enableHardMode)
    XCTAssertEqual(profile.hardModeDurationInMinutes, 30)
    XCTAssertEqual(BlockedProfileSession.mostRecentActiveSession(in: reader)?.id, "legacy-active")
  }

  private func openVerifyAndUpdateStore(at url: URL) throws {
    let disk = try diskContainer(at: url)
    let reader = ModelContext(disk)
    let expected = configuredProfile()
    expected.physicalUnblockItems?[0].id = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!
    let profile = try XCTUnwrap(BlockedProfiles.findProfile(byID: expected.id, in: reader))
    assertSnapshotFields(BlockedProfiles.getSnapshot(for: profile), match: expected)
    XCTAssertEqual(profile.askForStartSettings, expected.askForStartSettings)
    XCTAssertEqual(profile.physicalUnblockNFCTagId, "legacy-nfc")
    XCTAssertEqual(profile.physicalUnblockQRCodeId, "legacy-qr")
    XCTAssertEqual(try reader.fetchCount(FetchDescriptor<BlockedProfiles>()), 1)
    XCTAssertEqual(profile.sessions.count, 2)
    let ended = try XCTUnwrap(
      BlockedProfileSession.findSession(byID: "regression-session", in: reader))
    XCTAssertEqual(ended.toSnapshot(), sessionSnapshot(profileID: expected.id))
    XCTAssertEqual(ended.blockedProfile.id, expected.id)
    let active = try XCTUnwrap(BlockedProfileSession.mostRecentActiveSession(in: reader))
    XCTAssertEqual(active.id, "legacy-active")
    XCTAssertEqual(active.tag, "active")
    XCTAssertEqual(active.startTime, referenceDate)
    XCTAssertEqual(active.blockedProfile.id, expected.id)
    XCTAssertNil(active.endTime)
    XCTAssertEqual(active.usedBreakDurationInSeconds, 0)
    XCTAssertFalse(active.forceStarted)
    _ = try BlockedProfiles.updateProfile(profile, in: reader, name: "Updated after upgrade")
  }

  private func diskContainer(at url: URL) throws -> ModelContainer {
    try ModelContainer(
      for: BlockedProfileSession.self, BlockedProfiles.self,
      configurations: ModelConfiguration(url: url))
  }
}
