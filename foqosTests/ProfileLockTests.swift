import SwiftData
import XCTest

@testable import foqos

final class ProfileLockTests: ModelRegressionTestCase {
  func testGivenPasswordBoundaries_WhenCreatingCredential_ThenOnlyValidPasswordsAreAccepted() throws
  {
    for password in ["", "   \n", String(repeating: "a", count: 26)] {
      XCTAssertThrowsError(try ProfileLockUtil.createCredential(password: password))
    }
    XCTAssertNoThrow(try ProfileLockUtil.createCredential(password: "a"))
    XCTAssertNoThrow(
      try ProfileLockUtil.createCredential(password: String(repeating: "🐈", count: 25)))
  }

  func testGivenSamePassword_WhenProtectingTwoProfiles_ThenCredentialsAreSalted() throws {
    let first = try ProfileLockUtil.createCredential(password: "a secret for my friend")
    let second = try ProfileLockUtil.createCredential(password: "a secret for my friend")
    XCTAssertNotEqual(first, second)
    XCTAssertFalse(String(decoding: first, as: UTF8.self).contains("a secret for my friend"))
  }

  func testGivenProtectedProfile_WhenReloaded_ThenItRequiresTheExactPassword() async throws {
    let password = " Cat’s 🐈 secret "
    let profile = try makeProtectedProfile(password: password)
    let reader = freshContext()
    let reloaded = try XCTUnwrap(BlockedProfiles.findProfile(byID: profile.id, in: reader))
    XCTAssertEqual(reloaded.editLockCredential, profile.editLockCredential)
    XCTAssertThrowsError(try BlockedProfiles.updateProfile(reloaded, in: reader, name: "Changed"))

    do {
      _ = try await ProfileLockUtil.unlock(
        reloaded, password: password.trimmingCharacters(in: .whitespaces))
      XCTFail("A different password must not unlock the profile")
    } catch ProfileLockError.incorrectPassword {
    }

    let authorization = try await ProfileLockUtil.unlock(reloaded, password: password)
    _ = try BlockedProfiles.updateProfile(
      reloaded, in: reader, authorization: authorization, name: "Allowed")
    XCTAssertEqual(reloaded.name, "Allowed")
  }

  func testGivenLockedProfile_WhenMutatingWithoutUnlock_ThenNothingChanges() throws {
    let profile = try makeProtectedProfile()
    let originalSchedule = profile.schedule
    let draft = BlockedProfileDraft(profile: profile)
    draft.name = "Bypass"
    draft.schedule.days = []
    XCTAssertThrowsError(try draft.save(existingProfile: profile, in: context))
    XCTAssertThrowsError(try BlockedProfiles.deleteProfile(profile, in: context))
    XCTAssertThrowsError(try BlockedProfiles.cloneProfile(profile, in: context, newName: "Copy"))
    XCTAssertThrowsError(
      try ProfileLockUtil.setCredential(nil, for: profile, in: context, authorization: nil))
    XCTAssertEqual(profile.name, "Regression fixture")
    XCTAssertEqual(profile.schedule, originalSchedule)
    XCTAssertFalse(profile.isDeleted)
    XCTAssertEqual(try context.fetchCount(FetchDescriptor<BlockedProfiles>()), 1)
  }

  func testGivenUnlockedProfile_WhenSavingDraft_ThenSettingsPersist() async throws {
    let profile = try makeProtectedProfile()
    let authorization = try await ProfileLockUtil.unlock(profile, password: "friend")
    let draft = BlockedProfileDraft(profile: profile)
    draft.name = "Protected work"
    draft.schedule.days = []
    _ = try draft.save(existingProfile: profile, in: context, authorization: authorization)
    let reloaded = try XCTUnwrap(BlockedProfiles.findProfile(byID: profile.id, in: freshContext()))
    XCTAssertEqual(reloaded.name, "Protected work")
    XCTAssertEqual(reloaded.schedule?.days, [])
    XCTAssertNotNil(reloaded.editLockCredential)
  }

  func testGivenUnlockedProfile_WhenAuthorizationIsRevoked_ThenEditsAndPasswordRemovalFail()
    async throws
  {
    let profile = try makeProtectedProfile()
    let authorization = try await ProfileLockUtil.unlock(profile, password: "friend")
    authorization.revoke()
    XCTAssertFalse(authorization.allowsEditing(profile))
    XCTAssertThrowsError(
      try BlockedProfiles.updateProfile(
        profile, in: context, authorization: authorization, name: "Bypass"))
    XCTAssertThrowsError(
      try ProfileLockUtil.setCredential(
        nil, for: profile, in: context, authorization: authorization))
    XCTAssertThrowsError(
      try BlockedProfiles.deleteProfile(profile, in: context, authorization: authorization))
  }

  func testGivenUnlockedProfile_WhenDuplicated_ThenCopyIsProtectedAndNeedsItsOwnUnlock()
    async throws
  {
    let profile = try makeProtectedProfile()
    let authorization = try await ProfileLockUtil.unlock(profile, password: "friend")
    let copy = try BlockedProfiles.cloneProfile(
      profile, in: context, newName: "Copy", authorization: authorization)
    XCTAssertNotNil(copy.editLockCredential)
    XCTAssertFalse(authorization.allowsEditing(copy))
    XCTAssertThrowsError(
      try BlockedProfiles.deleteProfile(copy, in: context, authorization: authorization))
    let copyAuthorization = try await ProfileLockUtil.unlock(copy, password: "friend")
    try BlockedProfiles.deleteProfile(copy, in: context, authorization: copyAuthorization)
    try context.save()
    XCTAssertNil(try BlockedProfiles.findProfile(byID: copy.id, in: freshContext()))
  }

  func testGivenPasswordChange_WhenUsingOldPasswordOrAuthorization_ThenUnlockIsDenied() async throws
  {
    let profile = try makeProtectedProfile()
    let authorization = try await ProfileLockUtil.unlock(profile, password: "friend")
    let replacement = try ProfileLockUtil.createCredential(password: "new friend")
    try ProfileLockUtil.setCredential(
      replacement, for: profile, in: context, authorization: authorization)
    XCTAssertFalse(authorization.allowsEditing(profile))
    do {
      _ = try await ProfileLockUtil.unlock(profile, password: "friend")
      XCTFail("The old password must not work after a change")
    } catch ProfileLockError.incorrectPassword {
    }
    let newAuthorization = try await ProfileLockUtil.unlock(profile, password: "new friend")
    XCTAssertTrue(newAuthorization.allowsEditing(profile))
  }

  func testGivenUnlockedProfile_WhenRemovingPassword_ThenOrdinaryEditingWorksAgain() async throws {
    let profile = try makeProtectedProfile()
    let authorization = try await ProfileLockUtil.unlock(profile, password: "friend")
    try ProfileLockUtil.setCredential(nil, for: profile, in: context, authorization: authorization)
    XCTAssertNil(profile.editLockCredential)
    _ = try BlockedProfiles.updateProfile(profile, in: context, name: "Unprotected")
    let reloaded = try XCTUnwrap(BlockedProfiles.findProfile(byID: profile.id, in: freshContext()))
    XCTAssertNil(reloaded.editLockCredential)
    XCTAssertEqual(reloaded.name, "Unprotected")
  }

  func testGivenCorruptCredential_WhenUnlocking_ThenProfileRemainsProtected() async throws {
    let profile = configuredProfile()
    profile.editLockCredential = Data([1, 2, 3])
    context.insert(profile)
    try context.save()
    do {
      _ = try await ProfileLockUtil.unlock(profile, password: "friend")
      XCTFail("Invalid stored data must not unlock the profile")
    } catch ProfileLockError.credentialUnavailable {
    }
    XCTAssertThrowsError(try BlockedProfiles.deleteProfile(profile, in: context))
  }

  private func makeProtectedProfile(password: String = "friend") throws -> BlockedProfiles {
    let profile = configuredProfile()
    context.insert(profile)
    let credential = try ProfileLockUtil.createCredential(password: password)
    try ProfileLockUtil.setCredential(credential, for: profile, in: context, authorization: nil)
    return profile
  }
}
