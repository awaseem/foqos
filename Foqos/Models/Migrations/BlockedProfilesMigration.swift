import Foundation
import SwiftData

// MARK: - Physical Unblock Backfill

/// One-time app-level backfill for moving legacy physical unblock fields into
/// the new physicalUnblockItems array.
/// Remove this in the next app version once legacy data is no longer expected.
class PhysicalUnblockMigrationHelper {

  /// Migrates data from the deprecated physicalUnblockNFCTagId and physicalUnblockQRCodeId
  /// fields to the new physicalUnblockItems array
  /// - Parameter context: The ModelContext to perform the migration in
  @MainActor
  static func migrateOldPhysicalUnblockFields(in context: ModelContext) throws {
    let descriptor = FetchDescriptor<BlockedProfiles>()
    let profiles = try context.fetch(descriptor)
    var updatedProfiles: [BlockedProfiles] = []

    for profile in profiles {
      let hasLegacyNFC = !(profile.physicalUnblockNFCTagId?.isEmpty ?? true)
      let hasLegacyQRCode = !(profile.physicalUnblockQRCodeId?.isEmpty ?? true)

      if profile.physicalUnblockItems != nil || (!hasLegacyNFC && !hasLegacyQRCode) {
        continue
      }

      guard
        let items = PhysicalUnblockItem.resolvedItems(
          physicalUnblockItems: nil,
          legacyNFCTagId: profile.physicalUnblockNFCTagId,
          legacyQRCodeId: profile.physicalUnblockQRCodeId
        )
      else { continue }

      profile.physicalUnblockItems = items
      updatedProfiles.append(profile)
    }

    guard !updatedProfiles.isEmpty else { return }

    try context.save()

    for profile in updatedProfiles {
      BlockedProfiles.updateSnapshot(for: profile)
    }
  }
}
