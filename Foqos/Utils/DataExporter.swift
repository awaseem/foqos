import Foundation
import SwiftData

struct DataExporter {
  enum ExportSortDirection {
    case ascending
    case descending
  }

  enum ExportTimeZone {
    case utc
    case local
  }

  static func exportSessionsCSV(
    forProfileIDs profileIDs: [UUID],
    in context: ModelContext,
    sortDirection: ExportSortDirection = .ascending,
    timeZone: ExportTimeZone = .utc
  ) throws -> String {
    var lines: [String] = [
      "Id,start_time,end_time,break_start_time,break_end_time"
    ]

    if profileIDs.isEmpty {
      return lines.joined(separator: "\n")
    }

    let order: SortOrder = (sortDirection == .ascending) ? .forward : .reverse
    let descriptor = FetchDescriptor<BlockedProfileSession>(
      predicate: #Predicate { session in
        profileIDs.contains(session.blockedProfile.id)
      },
      sortBy: [SortDescriptor(\.startTime, order: order)]
    )

    let sessions = try context.fetch(descriptor)

    let dateFormatter = makeISO8601Formatter(timeZone: timeZone)
    lines.reserveCapacity(sessions.count + 1)
    for session in sessions {
      let id = session.id
      let start = dateFormatter.string(from: session.startTime)
      let end = session.endTime.map { dateFormatter.string(from: $0) } ?? ""
      let breakStart = session.breakStartTime.map { dateFormatter.string(from: $0) } ?? ""
      let breakEnd = session.breakEndTime.map { dateFormatter.string(from: $0) } ?? ""

      let row = [id, start, end, breakStart, breakEnd]
        .map { escapeCSVField($0) }
        .joined(separator: ",")
      lines.append(row)
    }

    return lines.joined(separator: "\n")
  }

  private static func escapeCSVField(_ field: String) -> String {
    if field.contains(",") || field.contains("\"") || field.contains("\n") {
      let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
      return "\"\(escaped)\""
    }
    return field
  }

  private static func makeISO8601Formatter(timeZone: ExportTimeZone) -> ISO8601DateFormatter {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    switch timeZone {
    case .utc:
      formatter.timeZone = TimeZone(secondsFromGMT: 0)
    case .local:
      formatter.timeZone = .current
    }
    return formatter
  }
}
