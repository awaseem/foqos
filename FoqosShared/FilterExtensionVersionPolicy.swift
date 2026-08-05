import Foundation

struct FilterExtensionVersionPolicy {
  struct InstalledExtension: Equatable {
    let bundleVersion: String
    let isEnabled: Bool
  }

  enum Status: Equatable {
    case current
    case notConfigured
    case requiresUpdate(installedVersion: String)
  }

  static func status(
    bundledVersion: String?,
    installedExtensions: [InstalledExtension]
  ) -> Status {
    guard let bundledVersion else {
      return .notConfigured
    }

    let enabledExtensions = installedExtensions.filter(\.isEnabled)
    guard !enabledExtensions.isEmpty else {
      return .notConfigured
    }

    let hasCurrentOrNewerVersion = enabledExtensions.contains { installedExtension in
      installedExtension.bundleVersion.compare(bundledVersion, options: .numeric)
        != .orderedAscending
    }
    if hasCurrentOrNewerVersion {
      return .current
    }

    return .requiresUpdate(installedVersion: enabledExtensions[0].bundleVersion)
  }
}
