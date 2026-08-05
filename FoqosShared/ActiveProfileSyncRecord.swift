import Foundation

struct ActiveProfileSyncRecord: Codable, Equatable {
  enum DomainMode: String, Codable {
    case allowOnly
    case block
  }

  enum State: String, Codable {
    case active
    case breakActive
    case inactive
    case paused
  }

  static let storeKey = "activeProfileSyncRecord"

  let profileId: UUID?
  let profileName: String?
  let sessionId: String?
  let domains: [String]
  let domainMode: DomainMode
  let state: State
  let updatedAt: Date

  init(
    profileId: UUID?,
    profileName: String?,
    sessionId: String?,
    domains: [String],
    domainMode: DomainMode,
    state: State,
    updatedAt: Date
  ) {
    self.profileId = profileId
    self.profileName = profileName
    self.sessionId = sessionId
    self.domains = domains
    self.domainMode = domainMode
    self.state = state
    self.updatedAt = updatedAt
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    profileId = try container.decodeIfPresent(UUID.self, forKey: .profileId)
    profileName = try container.decodeIfPresent(String.self, forKey: .profileName)
    sessionId = try container.decodeIfPresent(String.self, forKey: .sessionId)
    domains = try container.decodeIfPresent([String].self, forKey: .domains) ?? []
    domainMode = try container.decodeIfPresent(DomainMode.self, forKey: .domainMode) ?? .block
    state = try container.decode(State.self, forKey: .state)
    updatedAt = try container.decode(Date.self, forKey: .updatedAt)
  }
}
