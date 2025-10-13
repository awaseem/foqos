//
//  ProfileWidgetEntryView.swift
//  FoqosWidget
//
//  Created by Ali Waseem on 2025-03-11.
//

import SwiftUI
import WidgetKit

// MARK: - Widget View
struct ProfileWidgetEntryView: View {
  var entry: ProfileControlProvider.Entry

  var body: some View {
    Link(destination: entry.deepLinkURL ?? URL(string: "foqos://")!) {
      HStack(alignment: .center, spacing: 8) {
        // Left side - App info
        VStack(alignment: .leading, spacing: 4) {
          HStack(spacing: 2) {
            Text("Foqos")
              .font(.caption2)
              .fontWeight(.bold)
              .foregroundColor(.primary)
            Image(systemName: "hourglass")
              .font(.caption2)
              .foregroundColor(.purple)
          }

          Text(entry.profileName ?? "No Profile")
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.primary)
            .lineLimit(1)

          Text(entry.focusMessage)
            .font(.caption2)
            .foregroundColor(.secondary)
            .lineLimit(2)
        }

        Spacer()

        // Right side - Timer or status
        VStack(alignment: .trailing, spacing: 2) {
          if entry.isSessionActive {
            if entry.isBreakActive {
              VStack(spacing: 1) {
                Image(systemName: "cup.and.heat.waves.fill")
                  .font(.caption)
                  .foregroundColor(.orange)
                Text("Break")
                  .font(.caption2)
                  .fontWeight(.medium)
                  .foregroundColor(.orange)
              }
            } else if let startTime = entry.sessionStartTime {
              Text(
                Date(
                  timeIntervalSinceNow: startTime.timeIntervalSince1970
                    - Date().timeIntervalSince1970
                ),
                style: .timer
              )
              .font(.caption)
              .fontWeight(.semibold)
              .foregroundColor(.secondary)
              .multilineTextAlignment(.trailing)
            }
          } else {
            VStack(spacing: 1) {
              Image(systemName: "play.circle")
                .font(.caption)
                .foregroundColor(.green)
              Text("Tap to Start")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.green)
            }
          }
        }
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
    }
  }
}
