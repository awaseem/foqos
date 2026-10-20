import Foundation
import NetworkExtension
import OSLog
import SystemExtensions

/// Only pass operational metadata here. Never include profile names, domains, or raw errors.
// All mutable state and file access are confined to queue.
final class MacDiagnostics: @unchecked Sendable {
  enum Level: String, Codable {
    case info, warning, error
  }

  struct Entry: Codable {
    let timestamp: String
    let launchID: String
    let sequence: Int
    let level: Level
    let event: String
    let message: String
    let fields: [String: String]

    var text: String {
      let details = fields.keys.sorted().map { "\($0)=\(fields[$0]!)" }.joined(separator: " ")
      return "\(timestamp) [\(level.rawValue.uppercased())] \(event) — \(message) "
        + "[launch=\(launchID) sequence=\(sequence)] \(details)"
    }
  }

  static let shared = MacDiagnostics(
    directory: FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("Foqos/Diagnostics", isDirectory: true)
  )

  private let directory: URL
  private let maxBytes: Int
  private let retention: TimeInterval
  private let now: () -> Date
  private let queue = DispatchQueue(label: "dev.ambitionsoftware.foqos.diagnostics", qos: .utility)
  private let logger = Logger(subsystem: "dev.ambitionsoftware.foqos.mac", category: "diagnostics")
  private let launchID = UUID().uuidString
  private var sequence = 0
  private var currentFile: URL?
  private var state: [String: [String: String]] = [:]
  private var storageIssue: String?

  init(
    directory: URL, maxBytes: Int = 5 * 1_024 * 1_024,
    retention: TimeInterval = 7 * 24 * 60 * 60, now: @escaping () -> Date = Date.init
  ) {
    self.directory = directory
    self.maxBytes = maxBytes
    self.retention = retention
    self.now = now
  }

  static func timestamp(_ date: Date) -> String {
    date.ISO8601Format(.init(includingFractionalSeconds: true, timeZone: .gmt))
  }

  static func errorFields(_ error: Error) -> [String: String] {
    let error = error as NSError
    var fields = ["errorDomain": error.domain, "errorCode": String(error.code)]
    if error.domain == OSSystemExtensionErrorDomain {
      let reasons: [Int: String] = [
        OSSystemExtensionError.missingEntitlement.rawValue:
          "The app is missing a required entitlement.",
        OSSystemExtensionError.unsupportedParentBundleLocation.rawValue:
          "The app must be installed in a supported location, normally Applications.",
        OSSystemExtensionError.extensionNotFound.rawValue:
          "macOS could not find the bundled extension.",
        OSSystemExtensionError.codeSignatureInvalid.rawValue:
          "The extension code signature is invalid.",
        OSSystemExtensionError.validationFailed.rawValue: "macOS could not validate the extension.",
        OSSystemExtensionError.forbiddenBySystemPolicy.rawValue:
          "System policy prevents this extension from being activated.",
        OSSystemExtensionError.requestCanceled.rawValue: "The extension request was canceled.",
        OSSystemExtensionError.requestSuperseded.rawValue:
          "A newer extension request replaced this request.",
        OSSystemExtensionError.authorizationRequired.rawValue:
          "macOS requires authorization for this extension request.",
      ]
      fields["errorMeaning"] = reasons[error.code]
    } else if error.domain == NEFilterErrorDomain {
      let reasons: [Int: String] = [
        NEFilterManagerError.configurationInvalid.rawValue: "The filter configuration is invalid.",
        NEFilterManagerError.configurationDisabled.rawValue:
          "The filter configuration is disabled.",
        NEFilterManagerError.configurationStale.rawValue:
          "The filter preferences changed; they need to be reloaded before saving.",
        NEFilterManagerError.configurationCannotBeRemoved.rawValue:
          "macOS cannot remove the filter configuration.",
        NEFilterManagerError.configurationPermissionDenied.rawValue:
          "macOS denied permission to change the filter configuration.",
        NEFilterManagerError.configurationInternalError.rawValue:
          "macOS encountered an internal filter configuration error.",
      ]
      fields["errorMeaning"] = reasons[error.code]
    }
    return fields
  }

  func record(
    _ event: String, _ message: String, level: Level = .info, fields: [String: String] = [:]
  ) {
    queue.async {
      self.sequence += 1
      let entry = Entry(
        timestamp: Self.timestamp(self.now()), launchID: self.launchID, sequence: self.sequence,
        level: level, event: event, message: message, fields: fields
      )
      let category = event.split(separator: ".").first.map(String.init) ?? "app"
      self.state["latest.\(category)"] = fields.merging([
        "event": event, "message": message, "level": level.rawValue, "observedAt": entry.timestamp,
      ]) { _, new in new }
      self.logger.log(level: level == .error ? .error : .default, "\(entry.text, privacy: .public)")
      do {
        try self.append(entry)
      } catch {
        self.storageIssue = "Local logging failed: \(Self.errorFields(error))"
        self.logger.error(
          "Unable to persist diagnostic events; export will report missing history.")
      }
    }
  }

  func updateState(_ section: String, fields: [String: String]) {
    queue.async {
      self.state[section] = fields.merging(["observedAt": Self.timestamp(self.now())]) { _, new in
        new
      }
    }
  }

  func exportArchive() async throws -> Data {
    try await withCheckedThrowingContinuation { continuation in
      queue.async {
        continuation.resume(with: Result { try self.makeArchive() })
      }
    }
  }

  func flush() {
    queue.sync {}
  }

  private func logFiles() throws -> [URL] {
    guard FileManager.default.fileExists(atPath: directory.path) else { return [] }
    return try FileManager.default.contentsOfDirectory(
      at: directory, includingPropertiesForKeys: [.fileSizeKey]
    ).filter { $0.pathExtension == "jsonl" }.sorted { $0.lastPathComponent < $1.lastPathComponent }
  }

  private func prune() throws {
    let cutoff = Self.timestamp(now().addingTimeInterval(-retention))
    var files = try logFiles()
    for file in files where String(file.lastPathComponent.prefix(cutoff.count)) < cutoff {
      try FileManager.default.removeItem(at: file)
      if currentFile == file { currentFile = nil }
    }
    files = try logFiles()
    var total = try files.reduce(0) { try $0 + size(of: $1) }
    for file in files where total > maxBytes {
      total -= try size(of: file)
      try FileManager.default.removeItem(at: file)
      if currentFile == file { currentFile = nil }
    }
  }

  private func size(of file: URL) throws -> Int {
    // URL resource values can cache the pre-append size, defeating rotation.
    (try FileManager.default.attributesOfItem(atPath: file.path)[.size] as? NSNumber)?.intValue ?? 0
  }

  private func append(_ entry: Entry) throws {
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    try prune()
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    var data = try encoder.encode(entry)
    data.append(0x0A)
    guard data.count <= maxBytes else { throw CocoaError(.fileWriteOutOfSpace) }
    if let file = currentFile, try size(of: file) + data.count > min(512 * 1_024, maxBytes) {
      currentFile = nil
    }
    if currentFile == nil {
      let file = directory.appendingPathComponent(
        "\(entry.timestamp)-\(launchID)-\(String(format: "%010d", entry.sequence)).jsonl")
      try data.write(to: file, options: .atomic)
      currentFile = file
    } else if let file = currentFile {
      let handle = try FileHandle(forWritingTo: file)
      defer { try? handle.close() }
      try handle.seekToEnd()
      try handle.write(contentsOf: data)
    }
    try prune()
  }

  private func makeArchive() throws -> Data {
    try prune()
    let temporary = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: temporary, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: temporary) }

    var entries: [Entry] = []
    var unreadableLines = 0
    for file in try logFiles() {
      for line in try Data(contentsOf: file).split(separator: 0x0A) {
        if let entry = try? JSONDecoder().decode(Entry.self, from: Data(line)) {
          entries.append(entry)
        } else {
          unreadableLines += 1
        }
      }
    }
    // Preserve sequence across file rotations when events share a millisecond.
    entries = entries.enumerated().sorted {
      if $0.element.timestamp == $1.element.timestamp, $0.element.launchID == $1.element.launchID {
        return $0.element.sequence < $1.element.sequence
      }
      return $0.element.timestamp == $1.element.timestamp
        ? $0.offset < $1.offset : $0.element.timestamp < $1.element.timestamp
    }.map(\.element)

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    var jsonLines = Data()
    for entry in entries {
      jsonLines.append(try encoder.encode(entry))
      jsonLines.append(0x0A)
    }
    try jsonLines.write(to: temporary.appendingPathComponent("events.jsonl"))
    try entries.map(\.text).joined(separator: "\n").write(
      to: temporary.appendingPathComponent("timeline.txt"), atomically: true, encoding: .utf8
    )
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    try encoder.encode(state).write(to: temporary.appendingPathComponent("state.json"))
    let summary = state.keys.sorted().map { section in
      let fields = state[section] ?? [:]
      return section + "\n"
        + fields.keys.sorted().map { "  \($0): \(fields[$0]!)" }.joined(separator: "\n")
    }.joined(separator: "\n\n")
    try summary.write(
      to: temporary.appendingPathComponent("summary.txt"), atomically: true, encoding: .utf8)

    let overview = """
      FOQOS MAC DIAGNOSTICS — format version 1
      Exported: \(Self.timestamp(now()))
      Current launch: \(launchID)
      Retained events: \(entries.count)
      Unreadable event lines omitted: \(unreadableLines)
      Logging health: \(storageIssue ?? "No storage failures observed in this launch.")

      START HERE
      Read summary.txt for the last observed onboarding, sync, and filter state.
      state.json contains the same summary as structured data.
      Read timeline.txt chronologically; search [WARNING], [ERROR], onboarding., sync., and filter.
      events.jsonl contains the same events as one JSON object per line for automated analysis.
      Timestamps are UTC. launchID separates app launches; sequence orders events within a launch.
      attemptID links a sync refresh to its rule submission. operationID links asynchronous filter steps.

      INTERPRETING RESULTS
      sync.refresh_requested starts a read of the Mac's local iCloud key-value cache.
      synchronizeAccepted=true does NOT confirm a server round trip or a new iPhone update.
      sync.record_missing means no profile record is available locally yet.
      sync.decode_failed means a record arrived but could not be read.
      sync.rules_selected explains why blocking is active or inactive.
      filter.rules_saved confirms macOS saved configuration, NOT that the extension enforced it.
      A requested operation with no matching result may still be waiting for macOS or user approval.
      State is the last observation in this launch, not a fresh probe of iCloud or the extension.

      SCOPE AND PRIVACY
      Local Mac-app events only; no iPhone logs, filter-process logs, or browsing history.
      Profile names, profile/session identifiers, website domains, account identifiers, raw payloads,
      and free-form error descriptions are excluded. Error domains/codes and schema fields are included.
      Logs persist across relaunches, with files retained for up to seven days and a 5 MB total cap.
      Older files may be removed sooner when the size limit is reached. No automatic upload occurs.
      """
    try overview.write(
      to: temporary.appendingPathComponent("README.txt"), atomically: true, encoding: .utf8)

    var coordinationError: NSError?
    var archive: Result<Data, Error>?
    NSFileCoordinator().coordinate(
      readingItemAt: temporary, options: .forUploading, error: &coordinationError
    ) { url in
      archive = Result { try Data(contentsOf: url) }
    }
    if let coordinationError { throw coordinationError }
    guard let archive else { throw CocoaError(.fileReadUnknown) }
    return try archive.get()
  }
}
