import Foundation

enum PartnerSharingError: LocalizedError {
  case invalidInvitation
  var errorDescription: String? {
    "Paste a private read/write iCloud sharing invitation from your partner."
  }
}
