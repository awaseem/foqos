import UIKit
import XCTest

@testable import foqos

@MainActor
final class QuickActionManagerTests: XCTestCase {
  func testShortcutItemsUseProfileNamesAndIDs() {
    let profileID = UUID()
    let profile = BlockedProfiles(id: profileID, name: "Work", order: 0)

    let shortcut = try! XCTUnwrap(QuickActionManager.shortcutItems(from: [profile]).first)

    XCTAssertEqual(shortcut.localizedTitle, "Start Work")
    XCTAssertEqual(QuickActionManager.profileID(from: shortcut), profileID)
  }

  func testShortcutItemsAreSortedByOrderThenCreationDateAndLimited() {
    let now = Date()
    let newest = BlockedProfiles(
      id: UUID(), name: "Newest", createdAt: now.addingTimeInterval(1), order: 1)
    let oldest = BlockedProfiles(
      id: UUID(), name: "Oldest", createdAt: now, order: 1)
    let first = BlockedProfiles(id: UUID(), name: "First", createdAt: now, order: 0)
    let extraProfiles = (0..<QuickActionManager.maximumDynamicActions).map { index in
      BlockedProfiles(id: UUID(), name: "Extra \(index)", createdAt: now, order: index + 2)
    }

    let shortcuts = QuickActionManager.shortcutItems(
      from: [extraProfiles, [oldest, newest, first]].flatMap { $0 })

    XCTAssertEqual(shortcuts.count, QuickActionManager.maximumDynamicActions)
    XCTAssertEqual(
      shortcuts.map(\.localizedTitle),
      ["Start First", "Start Newest", "Start Oldest", "Start Extra 0"]
    )
  }

  func testNoProfilesProducesNoShortcuts() {
    XCTAssertTrue(QuickActionManager.shortcutItems(from: []).isEmpty)
  }

  func testMalformedShortcutIsIgnored() {
    let shortcut = UIApplicationShortcutItem(
      type: QuickActionManager.profileStartActionType,
      localizedTitle: "Start Work",
      userInfo: [QuickActionManager.profileIDUserInfoKey: "not-a-uuid" as NSString]
    )

    XCTAssertNil(QuickActionManager.profileID(from: shortcut))
  }

  func testPendingRequestRemainsUntilExplicitlyConsumed() {
    let manager = QuickActionManager()
    let profileID = UUID()
    let shortcut = UIApplicationShortcutItem(
      type: QuickActionManager.profileStartActionType,
      localizedTitle: "Start Work",
      userInfo: [QuickActionManager.profileIDUserInfoKey: profileID.uuidString as NSString]
    )

    manager.handle(shortcut)
    XCTAssertEqual(manager.pendingProfileID, profileID)

    manager.clearPendingProfileStart()
    XCTAssertNil(manager.pendingProfileID)
  }
}
