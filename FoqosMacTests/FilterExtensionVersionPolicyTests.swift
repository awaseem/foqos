import XCTest

final class FilterExtensionVersionPolicyTests: XCTestCase {
  func testCurrentEnabledVersionDoesNotRequireActivation() {
    let status = FilterExtensionVersionPolicy.status(
      bundledVersion: "808",
      installedExtensions: [installedExtension(version: "808", isEnabled: true)]
    )

    XCTAssertEqual(status, .current)
  }

  func testOlderEnabledVersionRequiresUpdate() {
    let status = FilterExtensionVersionPolicy.status(
      bundledVersion: "808",
      installedExtensions: [installedExtension(version: "806", isEnabled: true)]
    )

    XCTAssertEqual(status, .requiresUpdate(installedVersion: "806"))
  }

  func testDisabledVersionPreservesSetupFlow() {
    let status = FilterExtensionVersionPolicy.status(
      bundledVersion: "808",
      installedExtensions: [installedExtension(version: "806", isEnabled: false)]
    )

    XCTAssertEqual(status, .notConfigured)
  }

  func testNewerEnabledVersionIsNotDowngraded() {
    let status = FilterExtensionVersionPolicy.status(
      bundledVersion: "808",
      installedExtensions: [installedExtension(version: "810", isEnabled: true)]
    )

    XCTAssertEqual(status, .current)
  }

  func testCurrentVersionTakesPrecedenceOverStaleVersions() {
    let status = FilterExtensionVersionPolicy.status(
      bundledVersion: "808",
      installedExtensions: [
        installedExtension(version: "806", isEnabled: true),
        installedExtension(version: "808", isEnabled: true),
      ]
    )

    XCTAssertEqual(status, .current)
  }

  func testMissingBundledVersionPreservesSetupFlow() {
    let status = FilterExtensionVersionPolicy.status(
      bundledVersion: nil,
      installedExtensions: [installedExtension(version: "806", isEnabled: true)]
    )

    XCTAssertEqual(status, .notConfigured)
  }

  private func installedExtension(
    version: String,
    isEnabled: Bool
  ) -> FilterExtensionVersionPolicy.InstalledExtension {
    FilterExtensionVersionPolicy.InstalledExtension(
      bundleVersion: version,
      isEnabled: isEnabled
    )
  }
}
