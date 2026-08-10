import Foundation

struct FilterExtensionBundleLocator {
  static func bundleVersion(
    in applicationBundleURL: URL,
    extensionIdentifier: String
  ) -> String? {
    let systemExtensionsURL =
      applicationBundleURL
      .appendingPathComponent("Contents/Library/SystemExtensions", isDirectory: true)
    let extensionBundleURL =
      systemExtensionsURL
      .appendingPathComponent("\(extensionIdentifier).systemextension", isDirectory: true)

    return Bundle(url: extensionBundleURL)?
      .object(forInfoDictionaryKey: "CFBundleVersion") as? String
  }
}
