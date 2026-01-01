import Foundation
import SwiftData
import SwiftUI

import FamilyControls

struct SessionRow: View {
  @EnvironmentObject private var themeManager: ThemeManager

  var session: BlockedProfileSession

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          HStack(spacing: 6) {
            Image(systemName: "calendar")
              .foregroundColor(.secondary)
              .font(.caption)

            Text(session.formattedDate)
              .font(.subheadline)
              .fontWeight(.medium)
              .foregroundColor(.primary)

            if session.isActive {
              Label("Active", systemImage: "flame.fill")
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.orange.opacity(0.15))
                .foregroundColor(.orange)
                .cornerRadius(4)
            }
          }

          HStack(spacing: 6) {
            Image(systemName: "clock")
              .foregroundColor(.secondary)
              .font(.caption)

            Text(session.formattedStartTime)
              .font(.caption)
              .foregroundColor(.secondary)

            if let endTime = session.endTime {
              Image(systemName: "arrow.right")
                .font(.caption2)
                .foregroundColor(.secondary)

              Text(endTime.formatted(date: .omitted, time: .shortened))
                .font(.caption)
                .foregroundColor(.secondary)
            }
          }
        }

        Spacer()

        VStack(alignment: .trailing, spacing: 4) {
          Label(
            session.formattedDuration,
            systemImage: "hourglass"
          )
          .font(.caption)
          .foregroundColor(.secondary)

          if session.forceStarted {
            Label(
              "Force Started",
              systemImage: "bolt.fill"
            )
            .font(.caption2)
            .foregroundColor(.orange)
          }
        }
      }

      if !session.tag.isEmpty {
        HStack(spacing: 6) {
          Image(systemName: "tag.fill")
            .foregroundColor(themeManager.themeColor)
            .font(.caption)

          Text(session.tag)
            .font(.caption)
            .foregroundColor(themeManager.themeColor)
        }
      }

      if let breakStartTime = session.breakStartTime {
        HStack(spacing: 6) {
          Image(systemName: "cup.and.saucer.fill")
            .foregroundColor(.secondary)
            .font(.caption)

          Text("Break: \(breakStartTime.formatted(date: .omitted, time: .shortened))")
            .font(.caption)
            .foregroundColor(.secondary)

          if let breakEndTime = session.breakEndTime {
            Text("- \(breakEndTime.formatted(date: .omitted, time: .shortened))")
              .font(.caption)
              .foregroundColor(.secondary)
          } else if session.isActive {
            Text("(ongoing)")
              .font(.caption2)
              .foregroundColor(.secondary)
          }
        }
      }
    }
    .padding(.vertical, 4)
  }
}

extension BlockedProfileSession {
  var formattedDate: String {
    let calendar = Calendar.current
    if calendar.isDateInToday(startTime) {
      return "Today"
    } else if calendar.isDateInYesterday(startTime) {
      return "Yesterday"
    } else {
      let formatter = DateFormatter()
      formatter.dateStyle = .medium
      formatter.timeStyle = .none
      return formatter.string(from: startTime)
    }
  }

  var formattedStartTime: String {
    startTime.formatted(date: .omitted, time: .shortened)
  }

  var formattedDuration: String {
    let timeInterval = duration
    let minutes = Int(timeInterval) / 60
    let hours = minutes / 60
    let remainingMinutes = minutes % 60

    if hours > 0 {
      return "\(hours)h \(remainingMinutes)m"
    } else {
      return "\(minutes)m"
    }
  }
}
