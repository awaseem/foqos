import Foundation

enum ProfileSyncDiagnostics {
  static func fields(for record: ActiveProfileSyncRecord) -> [String: String] {
    [
      "profileState": record.state.rawValue,
      "domainMode": record.domainMode.rawValue,
      "domainCount": String(record.domains.count),
      "recordUpdatedAt": MacDiagnostics.timestamp(record.updatedAt),
    ]
  }

  static func fields(for error: Error) -> [String: String] {
    var fields = MacDiagnostics.errorFields(error)
    let reason: String
    let path: [CodingKey]
    switch error {
    case DecodingError.keyNotFound(let key, let context):
      reason = "missing_required_field"
      path = context.codingPath + [key]
    case DecodingError.typeMismatch(_, let context):
      reason = "wrong_field_type"
      path = context.codingPath
    case DecodingError.valueNotFound(_, let context):
      reason = "null_required_value"
      path = context.codingPath
    case DecodingError.dataCorrupted(let context):
      reason = "invalid_value_or_json"
      path = context.codingPath
    default:
      reason = "unknown_decode_error"
      path = []
    }
    let schemaKeys: Set<String> = [
      "profileId", "profileName", "sessionId", "domains", "domainMode", "state", "updatedAt",
    ]
    fields["reason"] = reason
    fields["field"] = path.map { schemaKeys.contains($0.stringValue) ? $0.stringValue : "item" }
      .joined(separator: ".")
    return fields
  }

  static func changeReason(_ reason: Int?) -> String {
    switch reason {
    case NSUbiquitousKeyValueStoreServerChange: return "server_change"
    case NSUbiquitousKeyValueStoreInitialSyncChange: return "initial_sync"
    case NSUbiquitousKeyValueStoreQuotaViolationChange: return "quota_violation"
    case NSUbiquitousKeyValueStoreAccountChange: return "account_change"
    default: return "unknown_change"
    }
  }
}
