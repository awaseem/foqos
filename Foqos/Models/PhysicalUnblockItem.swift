import Foundation

/// Represents a physical NFC tag or QR code that can unblock a profile
/// Supports having multiple NFC tags and/or QR codes per profile
struct PhysicalUnblockItem: Codable, Hashable, Identifiable, Sendable {
  var id: UUID
  var name: String
  var type: PhysicalUnblockType
  var codeValue: String

  enum PhysicalUnblockType: String, Codable, CaseIterable, Sendable {
    case nfc = "nfc"
    case qrCode = "qrCode"

    var displayName: String {
      switch self {
      case .nfc: return "NFC Tag"
      case .qrCode: return "QR Code"
      }
    }
  }

  init(
    id: UUID = UUID(),
    name: String,
    type: PhysicalUnblockType,
    codeValue: String
  ) {
    self.id = id
    self.name = name
    self.type = type
    self.codeValue = codeValue
  }
}
