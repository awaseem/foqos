import Foundation

struct FilterRules: Codable, Equatable {
  static let vendorConfigurationKey = "filterRules"
  static let disabled = FilterRules(isEnabled: false, domains: [])

  let isEnabled: Bool
  let domains: [String]

  init(isEnabled: Bool, domains: [String]) {
    let normalizedDomains = Self.normalize(domains)

    self.isEnabled = isEnabled && !normalizedDomains.isEmpty
    self.domains = normalizedDomains
  }

  func shouldBlock(_ hostname: String) -> Bool {
    guard let normalizedHostname = Self.normalize(hostname) else {
      return false
    }

    return domains.contains {
      normalizedHostname == $0 || normalizedHostname.hasSuffix(".\($0)")
    }
  }

  static func normalize(_ domains: [String]) -> [String] {
    Array(Set(domains.compactMap(normalize))).sorted()
  }

  private static func normalize(_ domain: String) -> String? {
    var normalized = domain.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

    while normalized.hasSuffix(".") {
      normalized.removeLast()
    }

    return normalized.isEmpty ? nil : normalized
  }
}
