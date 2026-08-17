import UIKit
import XCTest

@testable import foqos

@MainActor
final class QuickActionManagerTests: XCTestCase {
  func testShortcutItemUsesProfileNameAndID() throws {
    let profileID = UUID()
    let profile = BlockedProfiles(id: profileID, name: "Work", order: 0)

    let shortcut = try XCTUnwrap(QuickActionManager.shortcutItems(from: [profile]).first)

    XCTAssertEqual(shortcut.localizedTitle, "Start Work")
    XCTAssertEqual(QuickActionManager.profileID(from: shortcut), profileID)
  }

  func testShortcutItemsSortByOrderThenNewestCreationDate() {
    let now = Date()
    let newest = BlockedProfiles(
      id: UUID(), name: "Newest", createdAt: now.addingTimeInterval(1), order: 1)
    let oldest = BlockedProfiles(
      id: UUID(), name: "Oldest", createdAt: now, order: 1)
    let first = BlockedProfiles(id: UUID(), name: "First", createdAt: now, order: 0)

    let shortcuts = QuickActionManager.shortcutItems(from: [oldest, newest, first])

    XCTAssertEqual(
      shortcuts.map(\.localizedTitle),
      ["Start First", "Start Newest", "Start Oldest"]
    )
  }

  func testNoProfilesProducesNoShortcuts() {
    XCTAssertTrue(QuickActionManager.shortcutItems(from: []).isEmpty)
  }

  func testMalformedShortcutIsIgnored() {
    let shortcut = UIApplicationShortcutItem(
      type: QuickActionManager.profileStartActionType,
      localizedTitle: "Start Work",
      localizedSubtitle: nil,
      icon: nil,
      userInfo: [QuickActionManager.profileIDUserInfoKey: "not-a-uuid" as NSString]
    )

    XCTAssertNil(QuickActionManager.profileID(from: shortcut))
  }

  func testUnknownShortcutTypeIsIgnored() {
    let shortcut = UIApplicationShortcutItem(
      type: "unknown-action",
      localizedTitle: "Start Work",
      localizedSubtitle: nil,
      icon: nil,
      userInfo: [QuickActionManager.profileIDUserInfoKey: UUID().uuidString as NSString]
    )

    XCTAssertNil(QuickActionManager.profileID(from: shortcut))
  }

  func testPendingRequestRemainsUntilExplicitlyConsumed() {
    let manager = QuickActionManager()
    let profileID = UUID()
    let shortcut = UIApplicationShortcutItem(
      type: QuickActionManager.profileStartActionType,
      localizedTitle: "Start Work",
      localizedSubtitle: nil,
      icon: nil,
      userInfo: [QuickActionManager.profileIDUserInfoKey: profileID.uuidString as NSString]
    )

    manager.handle(shortcut)
    XCTAssertEqual(manager.pendingProfileID, profileID)

    manager.clearPendingProfileStart()
    XCTAssertNil(manager.pendingProfileID)
  }

  func testNewPendingRequestReplacesPreviousRequest() {
    let manager = QuickActionManager()
    let firstProfileID = UUID()
    let secondProfileID = UUID()

    manager.handle(makeShortcut(for: firstProfileID))
    manager.handle(makeShortcut(for: secondProfileID))

    XCTAssertEqual(manager.pendingProfileID, secondProfileID)
  }

  private func makeShortcut(for profileID: UUID) -> UIApplicationShortcutItem {
    UIApplicationShortcutItem(
      type: QuickActionManager.profileStartActionType,
      localizedTitle: "Start Work",
      localizedSubtitle: nil,
      icon: nil,
      userInfo: [QuickActionManager.profileIDUserInfoKey: profileID.uuidString as NSString]
    )
  }
}
