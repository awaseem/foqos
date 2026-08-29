import SwiftData
import XCTest

@testable import foqos

@MainActor
final class BlockedProfilesCloneTests: XCTestCase {
  func testCloneProfilePreservesBackgroundStopProtection() throws {
    let context = try makeContext()
    let source = BlockedProfiles(
      name: "Protected",
      blockingStrategyId: NFCBlockingStrategy.id,
      disableBackgroundStops: true
    )
    context.insert(source)
    try context.save()

    let cloned = try BlockedProfiles.cloneProfile(
      source,
      in: context,
      newName: "Protected Copy"
    )
    defer { SharedData.removeSnapshot(for: cloned.id.uuidString) }

    XCTAssertTrue(cloned.disableBackgroundStops)
  }

  func testCloneProfilePublishesSnapshotForExtensions() throws {
    let context = try makeContext()
    let source = BlockedProfiles(
      name: "Scheduled",
      blockingStrategyId: QRCodeBlockingStrategy.id,
      disableBackgroundStops: true,
      enableEmergencyUnblock: false
    )
    context.insert(source)
    try context.save()

    let cloned = try BlockedProfiles.cloneProfile(
      source,
      in: context,
      newName: "Scheduled Copy"
    )
    defer { SharedData.removeSnapshot(for: cloned.id.uuidString) }

    let snapshot = SharedData.snapshot(for: cloned.id.uuidString)
    XCTAssertEqual(snapshot, BlockedProfiles.getSnapshot(for: cloned))
  }

  func testCloneProfileTreatsCopiedScheduleAsNew() throws {
    let context = try makeContext()
    let sourceScheduleUpdatedAt = Date(timeIntervalSinceReferenceDate: 1_000)
    let source = BlockedProfiles(
      name: "Scheduled",
      schedule: BlockedProfileSchedule(
        days: [.monday, .friday],
        startHour: 9,
        startMinute: 0,
        endHour: 17,
        endMinute: 0,
        updatedAt: sourceScheduleUpdatedAt
      )
    )
    context.insert(source)
    try context.save()

    let cloned = try BlockedProfiles.cloneProfile(
      source,
      in: context,
      newName: "Scheduled Copy"
    )
    defer { SharedData.removeSnapshot(for: cloned.id.uuidString) }

    XCTAssertEqual(source.schedule?.updatedAt, sourceScheduleUpdatedAt)
    XCTAssertGreaterThan(cloned.schedule?.updatedAt ?? .distantPast, sourceScheduleUpdatedAt)
    XCTAssertEqual(SharedData.snapshot(for: cloned.id.uuidString)?.schedule, cloned.schedule)
  }

  private func makeContext() throws -> ModelContext {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(
      for: BlockedProfileSession.self,
      BlockedProfiles.self,
      configurations: configuration
    )
    return ModelContext(container)
  }
}
