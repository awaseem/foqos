import SwiftData
import XCTest

@testable import foqos

final class LegacyFixtureWriterTests: ModelRegressionTestCase {
  func testWritePreRefactorStore() throws {
    let directory = URL.temporaryDirectory.appendingPathComponent(
      "foqos-pre-refactor-fixture", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let url = directory.appendingPathComponent("models.store")
    let diskContainer = try ModelContainer(
      for: BlockedProfileSession.self, BlockedProfiles.self,
      configurations: ModelConfiguration(url: url))
    let writer = ModelContext(diskContainer)
    let profile = configuredProfile()
    profile.physicalUnblockItems?[0].id = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!
    profile.physicalUnblockNFCTagId = "legacy-nfc"
    profile.physicalUnblockQRCodeId = "legacy-qr"
    writer.insert(profile)
    BlockedProfileSession.upsertSessionFromSnapshot(
      in: writer, withSnapshot: sessionSnapshot(profileID: profile.id))
    let active = BlockedProfileSession(tag: "active", blockedProfile: profile)
    active.id = "legacy-active"
    active.startTime = referenceDate
    writer.insert(active)
    try writer.save()
    print("LEGACY_STORE_PATH=\(url.path)")
  }
}
