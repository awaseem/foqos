import FamilyControls
import Foundation
import XCTest

@testable import foqos

final class SharedProfileSnapshotTests: XCTestCase {
  func testGivenV124Snapshot_WhenDecoded_ThenUsesCurrentDefaults() throws {
    let snapshot = makeSnapshot()
    let data = try encodedCollection(
      containing: snapshot,
      removing: [
        "breakTimeInMinutes",
        "enableSafariBlocking",
        "enableBlockAppInstallation",
      ]
    )

    let decoded = try XCTUnwrap(
      SharedData.decodeProfileSnapshots(from: data)[snapshot.id.uuidString]
    )

    XCTAssertEqual(decoded.id, snapshot.id)
    XCTAssertEqual(decoded.name, snapshot.name)
    XCTAssertEqual(decoded.breakTimeInMinutes, 15)
    XCTAssertTrue(decoded.enableSafariBlocking)
    XCTAssertFalse(decoded.enableBlockAppInstallation)
  }

  func testGivenV1251Snapshot_WhenDecoded_ThenPreservesBreakDuration() throws {
    let snapshot = makeSnapshot()
    let data = try encodedCollection(
      containing: snapshot,
      removing: ["enableSafariBlocking", "enableBlockAppInstallation"]
    )

    let decoded = try XCTUnwrap(
      SharedData.decodeProfileSnapshots(from: data)[snapshot.id.uuidString]
    )

    XCTAssertEqual(decoded.breakTimeInMinutes, snapshot.breakTimeInMinutes)
    XCTAssertTrue(decoded.enableSafariBlocking)
    XCTAssertFalse(decoded.enableBlockAppInstallation)
  }

  func testGivenV1324Snapshot_WhenDecoded_ThenPreservesSafariSetting() throws {
    let snapshot = makeSnapshot()
    let data = try encodedCollection(
      containing: snapshot,
      removing: ["enableBlockAppInstallation"]
    )

    let decoded = try XCTUnwrap(
      SharedData.decodeProfileSnapshots(from: data)[snapshot.id.uuidString]
    )

    XCTAssertEqual(decoded.breakTimeInMinutes, snapshot.breakTimeInMinutes)
    XCTAssertEqual(decoded.enableSafariBlocking, snapshot.enableSafariBlocking)
    XCTAssertFalse(decoded.enableBlockAppInstallation)
  }

  func testGivenCurrentSnapshot_WhenRoundTripped_ThenPreservesExplicitValues() throws {
    let snapshot = makeSnapshot()
    let data = try JSONEncoder().encode([snapshot.id.uuidString: snapshot])

    let decoded = SharedData.decodeProfileSnapshots(from: data)

    XCTAssertEqual(decoded[snapshot.id.uuidString], snapshot)
  }

  func testGivenMalformedSibling_WhenCollectionDecoded_ThenKeepsValidSnapshot() throws {
    let validSnapshot = makeSnapshot(
      id: UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!
    )
    let malformedSnapshot = makeSnapshot(
      id: UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!
    )
    let encoded = try JSONEncoder().encode([
      validSnapshot.id.uuidString: validSnapshot,
      malformedSnapshot.id.uuidString: malformedSnapshot,
    ])
    var collection = try XCTUnwrap(
      JSONSerialization.jsonObject(with: encoded) as? [String: [String: Any]]
    )
    collection[malformedSnapshot.id.uuidString]?.removeValue(forKey: "id")

    let data = try JSONSerialization.data(withJSONObject: collection)
    let decoded = SharedData.decodeProfileSnapshots(from: data)

    XCTAssertEqual(decoded, [validSnapshot.id.uuidString: validSnapshot])
  }

  func testGivenMalformedTopLevelData_WhenDecoded_ThenReturnsEmptyCollection() {
    let decoded = SharedData.decodeProfileSnapshots(from: Data("[]".utf8))

    XCTAssertTrue(decoded.isEmpty)
  }

  private func makeSnapshot(
    id: UUID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
  ) -> SharedData.ProfileSnapshot {
    SharedData.ProfileSnapshot(
      id: id,
      name: "Focus",
      selectedActivity: FamilyActivitySelection(),
      createdAt: Date(timeIntervalSince1970: 1_700_000_000),
      updatedAt: Date(timeIntervalSince1970: 1_700_000_100),
      blockingStrategyId: "manual",
      strategyData: Data([0x01, 0x02]),
      order: 2,
      enableLiveActivity: true,
      reminderTimeInSeconds: 300,
      customReminderMessage: "Stay focused",
      enableBreaks: true,
      breakTimeInMinutes: 30,
      allowMultipleBreaks: true,
      enableStrictMode: true,
      enableBlockAppInstallation: true,
      enableAllowMode: false,
      enableAllowModeDomains: false,
      enableSafariBlocking: false,
      enableAdultContentBlocking: true,
      enableMacSync: true,
      domains: ["example.com"],
      physicalUnblockNFCTagId: "legacy-nfc",
      physicalUnblockQRCodeId: "legacy-qr",
      physicalUnblockItems: [
        PhysicalUnblockItem(
          id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
          name: "Desk tag",
          type: .nfc,
          codeValue: "desk-tag"
        )
      ],
      schedule: BlockedProfileSchedule(
        days: [.monday, .friday],
        startHour: 9,
        startMinute: 30,
        endHour: 11,
        endMinute: 0,
        updatedAt: Date(timeIntervalSince1970: 1_700_000_050)
      ),
      disableBackgroundStops: true,
      enableEmergencyUnblock: false
    )
  }

  private func encodedCollection(
    containing snapshot: SharedData.ProfileSnapshot,
    removing keys: [String]
  ) throws -> Data {
    let encoded = try JSONEncoder().encode([snapshot.id.uuidString: snapshot])
    var collection = try XCTUnwrap(
      JSONSerialization.jsonObject(with: encoded) as? [String: [String: Any]]
    )
    var storedSnapshot = try XCTUnwrap(collection[snapshot.id.uuidString])

    for key in keys {
      storedSnapshot.removeValue(forKey: key)
    }

    collection[snapshot.id.uuidString] = storedSnapshot
    return try JSONSerialization.data(withJSONObject: collection)
  }
}
