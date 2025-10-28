import FamilyControls
import SwiftData
import SwiftUI

struct DebugView: View {
  @Environment(\.modelContext) private var modelContext
  @EnvironmentObject var strategyManager: StrategyManager

  @State private var activeProfile: BlockedProfiles?

  var body: some View {
    NavigationView {
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          if let session = strategyManager.activeSession,
            let profile = activeProfile
          {
            // Active Profile Section
            DebugSection(title: "Active Profile") {
              ProfileDebugCard(profile: profile)
            }

            // Active Session Section
            DebugSection(title: "Active Session") {
              SessionDebugCard(session: session)
            }

            // Schedule Section
            if let schedule = profile.schedule {
              DebugSection(title: "Schedule") {
                ScheduleDebugCard(schedule: schedule)
              }
            }

            // Strategy Manager Section
            DebugSection(title: "Strategy Manager") {
              StrategyManagerDebugCard(strategyManager: strategyManager)
            }

            // Selected Apps & Categories
            DebugSection(title: "Selected Activity") {
              SelectedActivityDebugCard(selection: profile.selectedActivity)
            }

            // Domains Section
            if let domains = profile.domains, !domains.isEmpty {
              DebugSection(title: "Domains (\(domains.count))") {
                DomainsDebugCard(domains: domains)
              }
            }

          } else {
            DebugEmptyState()
          }
        }
        .padding()
      }
      .navigationTitle("Debug Mode")
      .navigationBarTitleDisplayMode(.inline)
      .onAppear {
        loadActiveProfile()
      }
      .refreshable {
        loadActiveProfile()
      }
    }
  }

  private func loadActiveProfile() {
    if let session = strategyManager.activeSession {
      activeProfile = session.blockedProfile
    }
  }
}

#Preview {
  DebugView()
    .environmentObject(StrategyManager.shared)
}
