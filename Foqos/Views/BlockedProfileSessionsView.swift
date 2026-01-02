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
        if let activeSession = activeSession {
          Section("Active Session") {
            SessionRow(session: activeSession)
          }
        }

        if !inactiveSessions.isEmpty {
          Section("Past Sessions") {
            ForEach(inactiveSessions) { session in
              SessionRow(session: session)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                  Button(role: .destructive) {
                    alertIdentifier = SessionAlertIdentifier(
                      id: .deleteSession,
                      session: session
                    )
                  } label: {
                    Label("Delete", systemImage: "trash")
                  }
                }
            }
          }
        }

        if sessions.isEmpty {
          VStack(spacing: 16) {
            Spacer()

            Image(systemName: "clock.arrow.circlepath")
              .font(.system(size: 48))
              .foregroundColor(.secondary)

            VStack(spacing: 8) {
              Text("No sessions yet")
                .font(.headline)
                .foregroundColor(.secondary)

              Text("When you use this profile, sessions will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            }

            Spacer()
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .listRowBackground(Color.clear)
          .listRowSeparator(.hidden)
        }
      }
      .navigationTitle("Sessions")
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button(action: { dismiss() }) {
            Image(systemName: "xmark")
          }
        }

        ToolbarItem(placement: .topBarTrailing) {
          if !inactiveSessions.isEmpty {
            Button(role: .destructive) {
              showDeleteAllConfirmation = true
            } label: {
              Image(systemName: "trash.fill")
                .foregroundColor(.red)
            }
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
        name: "Work Focus",
        selectedActivity: FamilyActivitySelection()
      )
      context.insert(profile)

      let activeSession = BlockedProfileSession(
        tag: "Deep Work",
        blockedProfile: profile
      )
      activeSession.forceStarted = true
      context.insert(activeSession)

      let pastSession1 = BlockedProfileSession(
        tag: "Morning Focus",
        blockedProfile: profile
      )
      pastSession1.endTime = Date().addingTimeInterval(-3600)
      context.insert(pastSession1)

      let pastSession2 = BlockedProfileSession(
        tag: "Afternoon Session",
        blockedProfile: profile
      )
      pastSession2.endTime = Date().addingTimeInterval(-86400 * 2)
      pastSession2.breakStartTime = Date().addingTimeInterval(-86400 * 2 + 1800)
      pastSession2.breakEndTime = Date().addingTimeInterval(-86400 * 2 + 2400)
      context.insert(pastSession2)

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
