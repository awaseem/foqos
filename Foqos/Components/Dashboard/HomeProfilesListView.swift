import SwiftUI

struct HomeProfilesListView: View {
  let profiles: [BlockedProfiles]
  let isBlocking: Bool
  let activeSessionProfileId: UUID?
  let elapsedTime: TimeInterval
  let onManageTapped: () -> Void
  let onStartTapped: (BlockedProfiles) -> Void
  let onStopTapped: (BlockedProfiles) -> Void
  let onEditTapped: (BlockedProfiles) -> Void
  let onStatsTapped: (BlockedProfiles) -> Void
  let onActiveTapped: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      SectionTitle(
        "Profiles",
        buttonText: "Manage",
        buttonAction: onManageTapped,
        buttonIcon: "brain.head.profile"
      )

      VStack(spacing: 0) {
        ForEach(Array(profiles.enumerated()), id: \.element.id) { index, profile in
          HomeProfileRow(
            profile: profile,
            isBlocking: isBlocking,
            isActive: profile.id == activeSessionProfileId,
            elapsedTime: elapsedTime,
            onStartTapped: {
              onStartTapped(profile)
            },
            onStopTapped: {
              onStopTapped(profile)
            },
            onEditTapped: {
              onEditTapped(profile)
            },
            onStatsTapped: {
              onStatsTapped(profile)
            },
            onActiveTapped: onActiveTapped
          )

          if index < profiles.count - 1 {
            Divider()
              .padding(.leading, 64)
          }
        }
      }
      .background(
        Color(.systemBackground),
        in: RoundedRectangle(cornerRadius: 20, style: .continuous)
      )
      .overlay(
        RoundedRectangle(cornerRadius: 20, style: .continuous)
          .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
      )
    }
  }
}

private struct HomeProfileRow: View {
  let profile: BlockedProfiles
  let isBlocking: Bool
  let isActive: Bool
  let elapsedTime: TimeInterval
  let onStartTapped: () -> Void
  let onStopTapped: () -> Void
  let onEditTapped: () -> Void
  let onStatsTapped: () -> Void
  let onActiveTapped: () -> Void

  private var canStart: Bool {
    !isBlocking
  }

  private var canStop: Bool {
    profile.showStopButton(elapsedTime: elapsedTime)
  }

  var body: some View {
    HStack(spacing: 12) {
      Button(action: rowTapped) {
        ProfileSummaryRow(
          profile: profile,
          isActive: isActive,
          metadata: .appsAndDomains,
          showsStatusLine: true
        ) {
          ProfileUsageMiniBarChart(profile: profile)
            .frame(width: 118, height: 62)
        }
      }
      .buttonStyle(.plain)
      .accessibilityLabel(
        isActive ? "Open active profile \(profile.name)" : "Show \(profile.name) insights"
      )

      actionMenu
    }
    .padding(16)
  }

  private var actionMenu: some View {
    Menu {

      Button(action: onStatsTapped) {
        Label("Insights", systemImage: "chart.line.uptrend.xyaxis")
      }

      Button(action: onEditTapped) {
        Label("Edit", systemImage: "pencil")
      }

      if isActive {
        Button(action: onActiveTapped) {
          Label("Active Session", systemImage: "timer")
        }

        Button(action: onStopTapped) {
          Label(canStop ? "Stop" : "Stop Locked", systemImage: canStop ? "stop.fill" : "lock.fill")
        }
        .disabled(!canStop)
      } else {
        Button(action: onStartTapped) {
          Label("Start", systemImage: "play.fill")
        }
        .disabled(!canStart)
      }
    } label: {
      Image(systemName: "ellipsis")
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(.gray)
        .frame(width: 32, height: 44)
        .contentShape(Rectangle())
    }
    .accessibilityLabel("More actions for \(profile.name)")
  }

  private func rowTapped() {
    if isActive {
      onActiveTapped()
    } else {
      onStatsTapped()
    }
  }
}
