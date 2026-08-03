import Foundation

struct FilterRules: Codable, Equatable {
  enum Mode: String, Codable {
    case allowOnly
    case block
  }

  static let vendorConfigurationKey = "filterRules"
  static let disabled = FilterRules(isEnabled: false, domains: [], mode: .block)

  let isEnabled: Bool
  let domains: [String]
  let mode: Mode

  init(isEnabled: Bool, domains: [String], mode: Mode) {
    let normalizedDomains = Self.normalize(domains)

    self.isEnabled = isEnabled && (mode == .allowOnly || !normalizedDomains.isEmpty)
    self.domains = normalizedDomains
    self.mode = mode
  }

  func shouldBlock(_ hostname: String) -> Bool {
    guard let normalizedHostname = Self.normalize(hostname) else {
      return mode == .allowOnly
    }

    let matches = domains.contains {
      normalizedHostname == $0 || normalizedHostname.hasSuffix(".\($0)")
    }

    return mode == .block ? matches : !matches
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
