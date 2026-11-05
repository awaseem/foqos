import Foundation

struct ShareProfileChoice: Codable, Equatable {
  let id: UUID
  let name: String
}

struct PendingSharedDomain: Codable, Equatable {
  let profileId: UUID
  let domain: String
}

// Foundation-only so the share extension can compile it alongside the app.
enum SharedDomainQueue {
  private static let suite = UserDefaults(suiteName: "group.dev.ambitionsoftware.foqos")
  private static let pendingKey = "pendingSharedDomains"
  private static let choicesKey = "shareProfileChoices"
  private static let activeProfileKey = "shareActiveProfileId"

  static var choices: [ShareProfileChoice] {
    guard let data = suite?.data(forKey: choicesKey) else { return [] }
    return (try? JSONDecoder().decode([ShareProfileChoice].self, from: data)) ?? []
  }

  static var activeProfileId: UUID? {
    guard let raw = suite?.string(forKey: activeProfileKey) else { return nil }
    return UUID(uuidString: raw)
  }

  static func publishChoices(_ choices: [ShareProfileChoice], activeProfileId: UUID?) {
    if let data = try? JSONEncoder().encode(choices) {
      suite?.set(data, forKey: choicesKey)
    }
    suite?.set(activeProfileId?.uuidString, forKey: activeProfileKey)
  }

  static func enqueue(domain: String, profileId: UUID) {
    var items = pending()
    items.append(PendingSharedDomain(profileId: profileId, domain: domain))
    store(items)
  }

  static func takeAll() -> [PendingSharedDomain] {
    let items = pending()
    if !items.isEmpty {
      suite?.removeObject(forKey: pendingKey)
    }
    return items
  }

  static func domain(from url: URL) -> String? {
    guard var host = url.host?.lowercased() else { return nil }
    if host.hasPrefix("www.") {
      host.removeFirst(4)
    }
    return host.contains(".") ? host : nil
  }

  static func domain(fromText text: String) -> String? {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

    if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue),
      let url = detector.firstMatch(
        in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed))?.url,
      let domain = domain(from: url)
    {
      return domain
    }

    guard !trimmed.contains(" "), let url = URL(string: "https://\(trimmed)") else { return nil }
    return domain(from: url)
  }

  private static func pending() -> [PendingSharedDomain] {
    guard let data = suite?.data(forKey: pendingKey) else { return [] }
    return (try? JSONDecoder().decode([PendingSharedDomain].self, from: data)) ?? []
  }

  private static func store(_ items: [PendingSharedDomain]) {
    if let data = try? JSONEncoder().encode(items) {
      suite?.set(data, forKey: pendingKey)
    }
  }
}
