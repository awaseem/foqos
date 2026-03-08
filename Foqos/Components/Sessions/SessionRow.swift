import Foundation
import SwiftUI

struct SessionRow: View {
  var session: BlockedProfileSession

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(DateFormatters.formatSessionDate(session.startTime))
            .font(.body)
        .fontWeight(.semibold)
        .foregroundStyle(.secondary)

      HStack(alignment: .firstTextBaseline, spacing: 8) {
        Text(DateFormatters.formatDurationHoursSeconds(session.duration))
          .font(.system(size: 24, weight: .bold, design: .rounded))
          .foregroundStyle(.primary)

        Text("total")
          .font(.title3)
          .fontWeight(.semibold)
          .foregroundStyle(.secondary)
      }

      if let breakDuration = session.breakDuration, breakDuration > 0 {
        HStack(spacing: 6) {
          Image(systemName: "cup.and.saucer")
            .font(.caption)
          Text("\(Int(breakDuration / 60))m")
            .monospacedDigit()
        }
        .font(.caption)
        .foregroundStyle(.secondary)
      }
    }
    .padding(.vertical, 6)
    .frame(maxWidth: .infinity, alignment: .leading)
    .contentShape(Rectangle())
  }
}

extension BlockedProfileSession {
  var breakDuration: TimeInterval? {
    guard let breakStartTime = breakStartTime,
          let breakEndTime = breakEndTime else {
      return nil
    }

    return breakEndTime.timeIntervalSince(breakStartTime)
  }
}
