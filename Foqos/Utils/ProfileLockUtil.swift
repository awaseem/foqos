import CommonCrypto
import Foundation
import Security
import SwiftData

final class ProfileEditAuthorization {
  private let profileID: UUID
  private let credential: Data
  private var isRevoked = false

  fileprivate init(profileID: UUID, credential: Data) {
    self.profileID = profileID
    self.credential = credential
  }

  func allowsEditing(_ profile: BlockedProfiles) -> Bool {
    !isRevoked && profile.id == profileID && profile.editLockCredential == credential
  }

  func revoke() {
    isRevoked = true
  }
}

enum ProfileLockError: LocalizedError {
  case invalidPassword
  case incorrectPassword
  case unlockRequired
  case credentialUnavailable

  var errorDescription: String? {
    switch self {
    case .invalidPassword:
      return "Choose a password with 1–25 characters. It cannot be only spaces."
    case .incorrectPassword:
      return "That password doesn’t match. Try again."
    case .unlockRequired:
      return "Unlock this profile before making changes."
    case .credentialUnavailable:
      return "The profile password could not be processed. Please try again."
    }
  }
}

enum ProfileLockUtil {
  static let maximumPasswordLength = 25

  private struct Credential: Codable {
    let version: Int
    let salt: Data
    let hash: Data
  }

  static func isValidPassword(_ password: String) -> Bool {
    !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      && password.count <= maximumPasswordLength
  }

  static func createCredential(password: String) throws -> Data {
    guard isValidPassword(password) else { throw ProfileLockError.invalidPassword }
    var salt = [UInt8](repeating: 0, count: 16)
    guard SecRandomCopyBytes(kSecRandomDefault, salt.count, &salt) == errSecSuccess else {
      throw ProfileLockError.credentialUnavailable
    }
    let saltData = Data(salt)
    return try JSONEncoder().encode(
      Credential(version: 1, salt: saltData, hash: deriveKey(password: password, salt: saltData))
    )
  }

  @MainActor
  static func unlock(_ profile: BlockedProfiles, password: String) async throws
    -> ProfileEditAuthorization
  {
    guard let credential = profile.editLockCredential else {
      throw ProfileLockError.credentialUnavailable
    }
    let matches = try await Task.detached(priority: .userInitiated) {
      try verify(password: password, credential: credential)
    }.value
    try Task.checkCancellation()
    guard matches else { throw ProfileLockError.incorrectPassword }
    guard profile.editLockCredential == credential else { throw ProfileLockError.unlockRequired }
    return ProfileEditAuthorization(profileID: profile.id, credential: credential)
  }

  static func requireAuthorization(
    for profile: BlockedProfiles, authorization: ProfileEditAuthorization?
  ) throws {
    guard profile.editLockCredential != nil else { return }
    guard authorization?.allowsEditing(profile) == true else {
      throw ProfileLockError.unlockRequired
    }
  }

  static func setCredential(
    _ credential: Data?, for profile: BlockedProfiles, in context: ModelContext,
    authorization: ProfileEditAuthorization?
  ) throws {
    try requireAuthorization(for: profile, authorization: authorization)
    if let credential {
      _ = try decodeCredential(credential)
    }
    let previousCredential = profile.editLockCredential
    profile.editLockCredential = credential
    do {
      try context.save()
      authorization?.revoke()
    } catch {
      profile.editLockCredential = previousCredential
      throw error
    }
  }

  private static func verify(password: String, credential: Data) throws -> Bool {
    guard isValidPassword(password) else { return false }
    let decoded = try decodeCredential(credential)
    let candidate = try deriveKey(password: password, salt: decoded.salt)
    return zip(candidate, decoded.hash).reduce(UInt8(0)) { $0 | ($1.0 ^ $1.1) } == 0
  }

  private static func decodeCredential(_ data: Data) throws -> Credential {
    guard let credential = try? JSONDecoder().decode(Credential.self, from: data),
      credential.version == 1, credential.salt.count == 16, credential.hash.count == 32
    else {
      throw ProfileLockError.credentialUnavailable
    }
    return credential
  }

  private static func deriveKey(password: String, salt: Data) throws -> Data {
    var key = [UInt8](repeating: 0, count: 32)
    let status = password.withCString { passwordBytes in
      salt.withUnsafeBytes { saltBytes in
        CCKeyDerivationPBKDF(
          CCPBKDFAlgorithm(kCCPBKDF2), passwordBytes, password.utf8.count,
          saltBytes.bindMemory(to: UInt8.self).baseAddress, salt.count,
          CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256), 600_000, &key, key.count
        )
      }
    }
    guard status == kCCSuccess else { throw ProfileLockError.credentialUnavailable }
    return Data(key)
  }
}
