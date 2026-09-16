import Foundation
import NetworkExtension
import SystemExtensions
import XCTest

final class ProfileSyncDiagnosticsTests: XCTestCase {
  func testGivenPrivateProfile_WhenDiagnosed_ThenOnlyOperationalMetadataIsIncluded() throws {
    let record = ActiveProfileSyncRecord(
      profileId: UUID(), profileName: "Secret profile", sessionId: "secret-session",
      domains: ["private.example"], domainMode: .block, state: .active, updatedAt: Date()
    )
    let fields = ProfileSyncDiagnostics.fields(for: record)
    XCTAssertEqual(fields["profileState"], "active")
    XCTAssertEqual(fields["domainCount"], "1")
    XCTAssertEqual(
      Set(fields.keys), ["profileState", "domainMode", "domainCount", "recordUpdatedAt"])
    XCTAssertFalse(fields.values.contains("Secret profile"))
    XCTAssertFalse(fields.values.contains("private.example"))
  }

  func testGivenMalformedRecord_WhenDiagnosed_ThenSchemaFailureIsClearWithoutPayload() throws {
    let data = Data(#"{"state":123,"profileName":"Secret profile"}"#.utf8)
    XCTAssertThrowsError(try JSONDecoder().decode(ActiveProfileSyncRecord.self, from: data)) {
      error in
      let fields = ProfileSyncDiagnostics.fields(for: error)
      XCTAssertEqual(fields["reason"], "wrong_field_type")
      XCTAssertEqual(fields["field"], "state")
      XCTAssertFalse(fields.description.contains("Secret profile"))
    }
    let error = NSError(
      domain: "TestDomain", code: 7,
      userInfo: [NSLocalizedDescriptionKey: "private.example /Users/private"])
    XCTAssertEqual(
      MacDiagnostics.errorFields(error), ["errorDomain": "TestDomain", "errorCode": "7"])
  }

  func testGivenCloudNotification_WhenDiagnosed_ThenReasonIsNamed() {
    XCTAssertEqual(
      ProfileSyncDiagnostics.changeReason(NSUbiquitousKeyValueStoreInitialSyncChange),
      "initial_sync")
    XCTAssertEqual(
      ProfileSyncDiagnostics.changeReason(NSUbiquitousKeyValueStoreQuotaViolationChange),
      "quota_violation")
    XCTAssertEqual(
      ProfileSyncDiagnostics.changeReason(NSUbiquitousKeyValueStoreAccountChange), "account_change")
    XCTAssertEqual(ProfileSyncDiagnostics.changeReason(nil), "unknown_change")
  }

  func testGivenOnboardingPermissionError_WhenDiagnosed_ThenMeaningIsReadable() {
    let extensionError = NSError(
      domain: OSSystemExtensionErrorDomain,
      code: OSSystemExtensionError.authorizationRequired.rawValue)
    XCTAssertEqual(
      MacDiagnostics.errorFields(extensionError)["errorMeaning"],
      "macOS requires authorization for this extension request.")
    let filterError = NSError(
      domain: NEFilterErrorDomain, code: NEFilterManagerError.configurationPermissionDenied.rawValue
    )
    XCTAssertEqual(
      MacDiagnostics.errorFields(filterError)["errorMeaning"],
      "macOS denied permission to change the filter configuration.")
  }
}
