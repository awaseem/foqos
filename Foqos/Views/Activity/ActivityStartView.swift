import SwiftData
import SwiftUI

struct ActivityStartView: View {
  @EnvironmentObject private var activityStarts: ActivityStartManager
  @Query(sort: \BlockedProfiles.order) private var profiles: [BlockedProfiles]

  var body: some View {
    Form {
      Section("Activity starts") {
        Picker("Manual profile", selection: $activityStarts.profileID) {
          Text("Choose a profile").tag(nil as UUID?)
          ForEach(profiles.filter { $0.blockingStrategyId == ManualBlockingStrategy.id }) {
            profile in
            Text(profile.name).tag(Optional(profile.id))
          }
        }.disabled(activityStarts.isEnabled)
        Toggle("Start on walking, running or cycling", isOn: $activityStarts.isEnabled)
          .disabled(activityStarts.profileID == nil)
        Text(activityStarts.status)
        Text(
          "Works while Foqos runs and resumes when reopened. Stopping movement never unblocks apps. Disabling this sensor leaves an existing block active."
        )
        .font(.caption)
        Button("Start selected profile") { activityStarts.setActive(true) }
        Button("Stop activity session") { activityStarts.setActive(false) }
      }
      if let error = activityStarts.errorMessage { Section("Needs attention") { Text(error) } }
    }
    .navigationTitle("Activity starts")
  }
}
