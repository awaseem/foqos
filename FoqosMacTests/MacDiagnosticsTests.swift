import Foundation
import XCTest

final class MacDiagnosticsTests: XCTestCase {
  private var directory: URL!

  override func setUpWithError() throws {
    directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
  }

  override func tearDownWithError() throws {
    try FileManager.default.removeItem(at: directory)
  }

  func testGivenRelaunch_WhenExported_ThenPreviousEventsAndCurrentStateAreReadable() async throws {
    let logDirectory = directory.appendingPathComponent("logs")
    let first = MacDiagnostics(directory: logDirectory)
    first.record("onboarding.opened", "Showing onboarding.")
    _ = try await first.exportArchive()
    let second = MacDiagnostics(directory: logDirectory)
    second.record(
      "sync.decode_failed", "The profile could not be decoded.", level: .error,
      fields: ["attemptID": "attempt-1"])
    second.updateState("sync", fields: ["result": "decode_failed"])
    let files = try unpack(try await second.exportArchive())
    let events = try readEvents(files)
    XCTAssertEqual(events.map(\.event), ["onboarding.opened", "sync.decode_failed"])
    XCTAssertNotEqual(events[0].launchID, events[1].launchID)
    XCTAssertEqual(events[1].fields["attemptID"], "attempt-1")
    let timeline = try String(
      contentsOf: files.appendingPathComponent("timeline.txt"), encoding: .utf8)
    XCTAssertTrue(timeline.contains("[ERROR] sync.decode_failed"))
    let state = try JSONDecoder().decode(
      [String: [String: String]].self,
      from: Data(contentsOf: files.appendingPathComponent("state.json")))
    XCTAssertEqual(state["sync"]?["result"], "decode_failed")
    XCTAssertNotNil(state["sync"]?["observedAt"])
  }

  func testGivenExpiredLogs_WhenExported_ThenOnlyRecentEventsRemain() async throws {
    let logDirectory = directory.appendingPathComponent("logs")
    let date = Date()
    let old = MacDiagnostics(
      directory: logDirectory, now: { date.addingTimeInterval(-8 * 24 * 60 * 60) })
    old.record("old.event", "Old event.")
    _ = try await old.exportArchive()
    let recent = MacDiagnostics(directory: logDirectory, now: { date })
    recent.record("recent.event", "Recent event.")
    let files = try unpack(try await recent.exportArchive())
    XCTAssertEqual(try readEvents(files).map(\.event), ["recent.event"])
  }

  func testGivenSizeLimit_WhenRecordingManyEvents_ThenStorageIsBoundedAndNewestEventSurvives()
    async throws
  {
    let logDirectory = directory.appendingPathComponent("logs")
    let date = Date()
    let log = MacDiagnostics(directory: logDirectory, maxBytes: 1_024, now: { date })
    for index in 0..<30 { log.record("event.\(index)", String(repeating: "message ", count: 10)) }
    let files = try unpack(try await log.exportArchive())
    let size = try FileManager.default.contentsOfDirectory(
      at: logDirectory, includingPropertiesForKeys: [.fileSizeKey]
    )
    .reduce(0) { try $0 + ($1.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0) }
    XCTAssertLessThanOrEqual(size, 1_024)
    XCTAssertEqual(try readEvents(files).last?.event, "event.29")
  }

  func testGivenPartialWrite_WhenExported_ThenValidEventsSurviveAndDamageIsReported() async throws {
    let logDirectory = directory.appendingPathComponent("logs")
    let log = MacDiagnostics(directory: logDirectory)
    log.record("valid.event", "Valid event.")
    _ = try await log.exportArchive()
    let file = try XCTUnwrap(
      FileManager.default.contentsOfDirectory(at: logDirectory, includingPropertiesForKeys: nil)
        .first)
    let handle = try FileHandle(forWritingTo: file)
    try handle.seekToEnd()
    try handle.write(contentsOf: Data("{partial".utf8))
    try handle.close()
    let files = try unpack(try await log.exportArchive())
    XCTAssertEqual(try readEvents(files).map(\.event), ["valid.event"])
    let readme = try String(contentsOf: files.appendingPathComponent("README.txt"), encoding: .utf8)
    XCTAssertTrue(readme.contains("Unreadable event lines omitted: 1"))
  }

  func testGivenUnwritableLogLocation_WhenExporting_ThenFailureIsReported() async throws {
    let file = directory.appendingPathComponent("not-a-directory")
    try Data().write(to: file)
    let log = MacDiagnostics(directory: file)
    log.record("event", "Cannot persist this event.")
    do {
      _ = try await log.exportArchive()
      XCTFail("Export should not silently succeed when storage is unreadable.")
    } catch {
      XCTAssertFalse(MacDiagnostics.errorFields(error).isEmpty)
    }
  }

  private func unpack(_ data: Data) throws -> URL {
    let archive = directory.appendingPathComponent("\(UUID().uuidString).zip")
    let destination = directory.appendingPathComponent(UUID().uuidString)
    try data.write(to: archive)
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
    process.arguments = ["-x", "-k", archive.path, destination.path]
    try process.run()
    process.waitUntilExit()
    XCTAssertEqual(process.terminationStatus, 0)
    let enumerator = try XCTUnwrap(
      FileManager.default.enumerator(at: destination, includingPropertiesForKeys: nil))
    let readme = try XCTUnwrap(
      (enumerator.allObjects as? [URL])?.first { $0.lastPathComponent == "README.txt" })
    return readme.deletingLastPathComponent()
  }

  private func readEvents(_ files: URL) throws -> [MacDiagnostics.Entry] {
    try Data(contentsOf: files.appendingPathComponent("events.jsonl")).split(separator: 0x0A).map {
      try JSONDecoder().decode(MacDiagnostics.Entry.self, from: Data($0))
    }
  }
}
