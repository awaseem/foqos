import Foundation
import XCTest

final class FilterExtensionBundleLocatorTests: XCTestCase {
  func testReadsVersionFromSystemExtensionsDirectory() throws {
    let fileManager = FileManager.default
    let applicationBundleURL = fileManager.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
      .appendingPathExtension("app")
    defer {
      try? fileManager.removeItem(at: applicationBundleURL)
    }

    let extensionIdentifier = "dev.ambitionsoftware.foqos.mac.filter"
    let extensionContentsURL =
      applicationBundleURL
      .appendingPathComponent("Contents/Library/SystemExtensions", isDirectory: true)
      .appendingPathComponent("\(extensionIdentifier).systemextension", isDirectory: true)
      .appendingPathComponent("Contents", isDirectory: true)
    try fileManager.createDirectory(at: extensionContentsURL, withIntermediateDirectories: true)

    let infoDictionary: [String: Any] = [
      "CFBundleIdentifier": extensionIdentifier,
      "CFBundlePackageType": "SYSX",
      "CFBundleVersion": "811",
    ]
    let infoData = try PropertyListSerialization.data(
      fromPropertyList: infoDictionary,
      format: .xml,
      options: 0
    )
    try infoData.write(to: extensionContentsURL.appendingPathComponent("Info.plist"))

    let version = FilterExtensionBundleLocator.bundleVersion(
      in: applicationBundleURL,
      extensionIdentifier: extensionIdentifier
    )

    XCTAssertEqual(version, "811")
  }
}
