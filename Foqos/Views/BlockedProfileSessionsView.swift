import FamilyControls
import Foundation
import SwiftData
import SwiftUI

struct SessionAlertIdentifier: Identifiable {
  enum AlertType {
    case deleteSession
    case error
  }

  let id: AlertType
  var session: BlockedProfileSession?
  var errorMessage: String?
}

struct BlockedProfileSessionsView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss

  @EnvironmentObject private var themeManager: ThemeManager

  var profile: BlockedProfiles

  @State private var alertIdentifier: SessionAlertIdentifier?
  @State private var showDeleteAllConfirmation = false

  @Query(sort: \BlockedProfileSession.startTime, order: .reverse)
  private var allSessions: [BlockedProfileSession]

  private var sessions: [BlockedProfileSession] {
    allSessions.filter { $0.blockedProfile.id == profile.id }
  }

  private var activeSession: BlockedProfileSession? {
    sessions.first { $0.isActive }
  }

  private var inactiveSessions: [BlockedProfileSession] {
    sessions.filter { !$0.isActive }
  }

  var body: some View {
    NavigationStack {
      List {
        if activeSession != nil {
          Section("Active Session") {
            if let session = activeSession {
              SessionRow(session: session, onDelete: nil)
            }
          }
        }

        if !inactiveSessions.isEmpty {
          Section("Past Sessions") {
            ForEach(inactiveSessions) { session in
              SessionRow(
                session: session,
                onDelete: {
                  alertIdentifier = SessionAlertIdentifier(
                    id: .deleteSession,
                    session: session
                  )
                }
              )
            }
          }
        }

        if sessions.isEmpty {
          Section {
            VStack(alignment: .center, spacing: 12) {
              Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
              Text("No sessions yet")
                .font(.headline)
                .foregroundColor(.secondary)
              Text("When you use this profile, sessions will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
          }
        }
      }
      .navigationTitle("Session History")
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          if !inactiveSessions.isEmpty {
            Button(role: .destructive) {
              showDeleteAllConfirmation = true
            } label: {
              Text("Delete All")
            }
          } else {
            Button(action: { dismiss() }) {
              Image(systemName: "xmark")
            }
          }
        }

        ToolbarItem(placement: .topBarTrailing) {
          Button(action: { dismiss() }) {
            Image(systemName: "xmark")
          }
        }
      }
      .alert(item: $alertIdentifier) { alert in
        switch alert.id {
        case .deleteSession:
          guard let session = alert.session else {
            return Alert(title: Text("Error"))
          }
          return Alert(
            title: Text("Delete Session"),
            message: Text(
              "Are you sure you want to delete this session? This action cannot be undone."
            ),
            primaryButton: .cancel(),
            secondaryButton: .destructive(Text("Delete")) {
              deleteSession(session)
            }
          )
        case .error:
          return Alert(
            title: Text("Error"),
            message: Text(alert.errorMessage ?? "An unknown error occurred"),
            dismissButton: .default(Text("OK"))
          )
        }
      }
      .alert("Delete All Sessions", isPresented: $showDeleteAllConfirmation) {
        Button("Cancel", role: .cancel) {}
        Button("Delete All", role: .destructive) {
          deleteAllSessions()
        }
      } message: {
        Text("Are you sure you want to delete all past sessions? This action cannot be undone.")
      }
    }
  }

  private func deleteSession(_ session: BlockedProfileSession) {
    modelContext.delete(session)
    do {
      try modelContext.save()
    } catch {
      alertIdentifier = SessionAlertIdentifier(
        id: .error,
        errorMessage: error.localizedDescription
      )
    }
  }

  private func deleteAllSessions() {
    for session in inactiveSessions {
      modelContext.delete(session)
    }
    do {
      try modelContext.save()
    } catch {
      alertIdentifier = SessionAlertIdentifier(
        id: .error,
        errorMessage: error.localizedDescription
      )
    }
  }
}

struct SessionRow: View {
  @EnvironmentObject private var themeManager: ThemeManager

  var session: BlockedProfileSession
  var onDelete: (() -> Void)?

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text(formatDate(session.startTime))
          .font(.headline)

        Spacer()

        if onDelete != nil {
          Button(action: onDelete!) {
            Image(systemName: "trash")
              .foregroundColor(.red)
          }
        } else {
          Image(systemName: "play.fill")
            .foregroundColor(.green)
        }
      }

      HStack {
        Label(
          formatTime(session.startTime),
          systemImage: "clock"
        )
        .font(.caption)
        .foregroundColor(.secondary)

        Spacer()

        if session.isActive {
          Label("Active", systemImage: "flame.fill")
            .font(.caption)
            .foregroundColor(.orange)
        } else if let endTime = session.endTime {
          Label("Duration: \(formatDuration(session.duration))", systemImage: "hourglass")
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }

      if session.tag.isEmpty == false {
        HStack {
          Label(session.tag, systemImage: "tag.fill")
            .font(.caption)
            .foregroundColor(themeManager.themeColor)
          Spacer()
        }
      }

      if let breakStartTime = session.breakStartTime {
        HStack {
          Label(
            "Break: \(formatTime(breakStartTime))",
            systemImage: "cup.and.saucer.fill"
          )
          .font(.caption)
          .foregroundColor(.secondary)
          Spacer()
        }
      }
    }
    .padding(.vertical, 4)
  }

  private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter.string(from: date)
  }

  private func formatTime(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    return formatter.string(from: date)
  }

  private func formatDuration(_ timeInterval: TimeInterval) -> String {
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

#Preview {
  struct PreviewWrapper: View {
    let container: ModelContainer
    let profile: BlockedProfiles

    init() {
      do {
        container = try ModelContainer(
          for: BlockedProfiles.self,
          BlockedProfileSession.self
        )
      } catch {
        fatalError("Failed to create preview container: \(error)")
      }

      let context = container.mainContext
      let profile = BlockedProfiles(
        name: "Test Profile",
        selectedActivity: FamilyActivitySelection()
      )
      context.insert(profile)

      let activeSession = BlockedProfileSession(
        tag: "Focus",
        blockedProfile: profile
      )
      context.insert(activeSession)

      let pastSession = BlockedProfileSession(
        tag: "Morning",
        blockedProfile: profile
      )
      pastSession.endTime = Date().addingTimeInterval(-3600)
      context.insert(pastSession)

      self.profile = profile
    }

    var body: some View {
      BlockedProfileSessionsView(profile: profile)
        .environmentObject(ThemeManager())
        .modelContainer(container)
    }
  }

  return PreviewWrapper()
}
