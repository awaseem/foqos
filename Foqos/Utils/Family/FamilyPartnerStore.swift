import CloudKit
import SwiftUI

@MainActor
final class FamilyPartnerStore: ObservableObject {
  @Published var audit = "No partner status received."
  @Published var errorMessage: String?
  @Published var share: CKShare?
  @Published var isBusy = false
  @Published private(set) var isPartner: Bool
  @Published private(set) var isConnected: Bool

  lazy var container = CKContainer(identifier: "iCloud.dev.ambitionsoftware.foqos")
  private let defaults: UserDefaults
  private var recordID: CKRecord.ID?
  private var lastCommand: String?

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
    isPartner = defaults.bool(forKey: "family.partner")
    lastCommand = defaults.string(forKey: "family.command")
    if let data = defaults.data(forKey: "family.record") {
      recordID = try? NSKeyedUnarchiver.unarchivedObject(ofClass: CKRecord.ID.self, from: data)
    }
    isConnected = recordID != nil
  }

  private var database: CKDatabase {
    isPartner ? container.sharedCloudDatabase : container.privateCloudDatabase
  }

  func prepareInvitation() async {
    guard !isBusy else { return }
    isBusy = true
    errorMessage = nil
    defer { isBusy = false }
    do {
      if let recordID {
        let root = try await database.record(for: recordID)
        guard !isPartner, let shareID = root.share?.recordID else {
          throw FamilyOutingError.invalidInvitation
        }
        share = try await database.record(for: shareID) as? CKShare
        return
      }
      let zone = CKRecordZone(zoneName: "FamilyOuting")
      _ = try await container.privateCloudDatabase.save(zone)
      let id = CKRecord.ID(recordName: "outing", zoneID: zone.zoneID)
      let root: CKRecord
      do {
        root = try await database.record(for: id)
      } catch let error as CKError where error.code == .unknownItem {
        root = CKRecord(recordType: "FamilyOuting", recordID: id)
      }
      if let shareID = root.share?.recordID {
        share = try await database.record(for: shareID) as? CKShare
        try remember(id, partner: false)
        return
      }
      root["audit"] = "Waiting for the family phone." as CKRecordValue
      let invitation = CKShare(rootRecord: root)
      invitation.publicPermission = .none
      invitation[CKShare.SystemFieldKey.title] = "Foqos family time" as CKRecordValue
      let result = try await database.modifyRecords(saving: [root, invitation], deleting: [])
      _ = try result.saveResults[root.recordID]?.get()
      guard let savedShare = try result.saveResults[invitation.recordID]?.get() as? CKShare else {
        throw FamilyOutingError.invalidInvitation
      }
      try remember(root.recordID, partner: false)
      share = savedShare
    } catch { errorMessage = error.localizedDescription }
  }

  func join(_ text: String) async {
    guard !isBusy, !isConnected else { return }
    isBusy = true
    errorMessage = nil
    defer { isBusy = false }
    do {
      guard let url = URL(string: text.trimmingCharacters(in: .whitespacesAndNewlines)),
        url.scheme == "https", url.host == "www.icloud.com" || url.host == "icloud.com"
      else { throw FamilyOutingError.invalidInvitation }
      let metadata = try await container.shareMetadata(for: url)
      guard let root = metadata.hierarchicalRootRecordID,
        metadata.participantRole != .owner, metadata.participantPermission == .readWrite
      else { throw FamilyOutingError.invalidInvitation }
      _ = try await container.accept(metadata)
      try remember(root, partner: true)
    } catch { errorMessage = error.localizedDescription }
  }

  func send(_ action: FamilyCommand.Action, message: String) async {
    guard !isBusy, isPartner, let recordID else { return }
    isBusy = true
    errorMessage = nil
    defer { isBusy = false }
    do {
      let root = try await database.record(for: recordID)
      let command = FamilyCommand(action: action, message: String(message.prefix(200)))
      root["command"] = try JSONEncoder().encode(command) as CKRecordValue
      _ = try await database.save(root)
      audit = "Request sent. Awaiting the family phone's next refresh.\n" + audit
    } catch { errorMessage = error.localizedDescription }
  }

  func refresh(outing: FamilyOutingManager) async {
    guard !isBusy, let recordID else { return }
    isBusy = true
    errorMessage = nil
    defer { isBusy = false }
    do {
      let root = try await database.record(for: recordID)
      if isPartner {
        audit = root["audit"] as? String ?? "No status yet."
        return
      }
      if let data = root["command"] as? Data {
        let command = try JSONDecoder().decode(FamilyCommand.self, from: data)
        if command.id.uuidString != lastCommand {
          // Mark before execution so an upload failure cannot replay a reminder or stop.
          lastCommand = command.id.uuidString
          defaults.set(lastCommand, forKey: "family.command")
          if command.isFresh(at: Date()) {
            outing.apply(command.action, source: "Partner", message: command.message)
          } else {
            outing.record("Partner request expired or invalid; ignored.")
          }
        }
      }
      root["audit"] = outing.snapshot() as CKRecordValue
      _ = try await database.save(root)
      audit = outing.snapshot()
    } catch { errorMessage = error.localizedDescription }
  }

  func disconnect() {
    recordID = nil
    share = nil
    isPartner = false
    isConnected = false
    lastCommand = nil
    for key in ["family.record", "family.partner", "family.command"] {
      defaults.removeObject(forKey: key)
    }
    audit = "Disconnected on this phone. The owner can revoke access in Manage invitation."
  }

  private func remember(_ id: CKRecord.ID, partner: Bool) throws {
    defaults.set(
      try NSKeyedArchiver.archivedData(withRootObject: id, requiringSecureCoding: true),
      forKey: "family.record")
    defaults.set(partner, forKey: "family.partner")
    recordID = id
    isPartner = partner
    isConnected = true
  }
}
