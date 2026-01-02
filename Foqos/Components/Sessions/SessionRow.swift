import Foundation
import SwiftUI

struct SessionRow: View {
  @EnvironmentObject private var themeManager: ThemeManager

  var session: BlockedProfileSession

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(alignment: .firstTextBaseline, spacing: 8) {
        Text(session.formattedDate)
          .font(.headline)
          .fontWeight(.semibold)
          .lineLimit(1)

        

        Spacer(minLength: 8)

        HStack(spacing: 4) {
          Image(systemName: "clock")
            .font(.caption)
          Text(session.formattedDuration)
            .monospacedDigit()
        }
        .font(.subheadline)
        .foregroundColor(.secondary)
      }

      HStack(spacing: 6) {
        Image(systemName: "timer")
          .font(.caption)
        Text(session.timeRangeText)
          .monospacedDigit()
      }
      .font(.subheadline)
      .foregroundColor(.secondary)

      

      if let breakText = session.breakRangeText {
        HStack(spacing: 6) {
          Image(systemName: "cup.and.saucer")
            .font(.caption)
          Text(breakText)
            .font(.caption)
            .foregroundColor(.secondary)
            .monospacedDigit()
            .lineLimit(1)
        }
      }
    }
    .padding(.vertical, 6)
  }
}



extension BlockedProfileSession {
  var formattedDate: String {
    let calendar = Calendar.current
    if calendar.isDateInToday(startTime) {
      return "Today"
    } else if calendar.isDateInYesterday(startTime) {
      return "Yesterday"
    }

    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter.string(from: startTime)
  }

  

  var formattedStartTime: String {
    startTime.formatted(date: .omitted, time: .shortened)
  }

  var formattedEndTime: String? {
    endTime?.formatted(date: .omitted, time: .shortened)
  }

  var timeRangeText: String {
    if let endTimeText = formattedEndTime {
      return "\(formattedStartTime) → \(endTimeText)"
    }

    return "Started \(formattedStartTime)"
  }

  var breakRangeText: String? {
    guard let breakStartTime else {
      return nil
    }

    let breakStartText = breakStartTime.formatted(date: .omitted, time: .shortened)

    if let breakEndTime {
      let breakEndText = breakEndTime.formatted(date: .omitted, time: .shortened)
      return "Break \(breakStartText) → \(breakEndText)"
    }

    return isActive ? "Break \(breakStartText) (ongoing)" : "Break \(breakStartText)"
  }

  var formattedDuration: String {
    let minutes = Int(duration) / 60
    let hours = minutes / 60
    let remainingMinutes = minutes % 60

    if hours > 0 {
      return "\(hours)h \(remainingMinutes)m"
    }

    return "\(minutes)m"
  }
}
