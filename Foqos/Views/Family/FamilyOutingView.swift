import CloudKit
import SwiftData
import SwiftUI
import UserNotifications

struct FamilyOutingView: View {
  @EnvironmentObject private var outing: FamilyOutingManager
  @EnvironmentObject private var partner: FamilyPartnerStore
  @Query(sort: \BlockedProfiles.order) private var profiles: [BlockedProfiles]
  @State private var invitation = ""
  @State private var reminder = "Phone away. Family time ❤️"
  @State private var showSharing = false

  var body: some View {
    Form {
      Section {
        Text("Prototype: family blocking, activity triggers and partner check-ins.")
        Text(
          "Remote requests refresh while Foqos is open. They expire after five minutes. This is cooperative accountability; it does not prevent disabling or removing the app."
        )
        .font(.caption).foregroundStyle(.secondary)
      }
      if !partner.isPartner {
        Section("Family phone") {
          Picker("Manual profile", selection: $outing.settings.profileID) {
            Text("Choose a profile").tag(nil as UUID?)
            ForEach(profiles.filter { $0.blockingStrategyId == ManualBlockingStrategy.id }) {
              profile in
              Text(profile.name).tag(Optional(profile.id))
            }
          }
          .disabled(outing.settings.isEnabled)
          Toggle("Enable family automation", isOn: $outing.settings.isEnabled)
            .disabled(outing.settings.profileID == nil)
          Text(
            "Choose a Manual profile with distracting apps selected. Leave calls, maps and camera accessible."
          )
          .font(.caption).foregroundStyle(.secondary)
          Button("Start family time") { outing.apply(.start, source: "Family phone") }
          Button("Stop family time") { outing.apply(.stop, source: "Family phone") }
        }
        Section("Place") {
          Button(
            outing.settings.hasValidRegion
              ? "Replace place with current location" : "Use current location"
          ) {
            outing.setPlaceHere()
          }
          .disabled(outing.settings.isEnabled)
          if outing.settings.hasValidRegion {
            Label("Place saved on this phone", systemImage: "location.circle")
          }
          Picker("Block", selection: $outing.settings.blockOutside) {
            Text("Outside this place (leave home)").tag(true)
            Text("Inside this place (park / venue)").tag(false)
          }
          .disabled(outing.settings.isEnabled)
          Slider(value: $outing.settings.radius, in: 100...1000, step: 100) {
            Text("Radius")
          }
          .disabled(outing.settings.isEnabled)
          Text("Radius: \(Int(outing.settings.radius)) metres")
          Button("Allow background geofencing") { outing.requestBackgroundLocation() }
          Text(outing.status).font(.caption)
          Text(
            "Crossing back stops only a session started by family controls. Background-stop restrictions still apply."
          )
          .font(.caption).foregroundStyle(.secondary)
        }
        Section("Activity") {
          Toggle("Start on walking, running or cycling", isOn: $outing.settings.blockWhileMoving)
          Text("Detected: \(outing.activity)")
          Text(
            "Motion detection works while the app runs and resumes when reopened. Stopping movement never unblocks apps."
          )
          .font(.caption).foregroundStyle(.secondary)
        }
      }
      Section("Partner") {
        if partner.isConnected {
          if partner.isPartner {
            Button("Ask to start family time") { send(.start) }
            Button("Ask to stop family time") { send(.stop) }
            TextField("Reminder", text: $reminder, axis: .vertical)
            Button("Send reminder") { send(.remind) }
          } else {
            Button("Manage invitation / revoke partner access") {
              Task {
                await partner.prepareInvitation()
                showSharing = partner.share != nil
              }
            }
          }
          Button("Refresh status") { Task { await partner.refresh(outing: outing) } }
          Button("Disconnect this phone", role: .destructive) { partner.disconnect() }
        } else {
          Button("Invite partner to control this phone") {
            Task {
              await partner.prepareInvitation()
              showSharing = partner.share != nil
            }
          }
          TextField("Or paste private iCloud invitation", text: $invitation)
            .textInputAutocapitalization(.never).autocorrectionDisabled()
          Button("Join as partner") { Task { await partner.join(invitation) } }
            .disabled(invitation.isEmpty)
        }
        Text(
          "Invite one trusted partner with read/write permission. Only status, recent events and requests are shared, not coordinates or selected apps. iCloud setup is required for this prototype."
        )
        .font(.caption).foregroundStyle(.secondary)
        if partner.isBusy { ProgressView() }
      }
      .disabled(partner.isBusy)
      Section("Reminders") {
        Link("Open iOS permissions", destination: URL(string: UIApplication.openSettingsURLString)!)
        Button("Allow reminder notifications") {
          Task {
            do {
              let allowed = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound])
              if !allowed {
                outing.errorMessage = "Enable notifications for Foqos in iOS Settings."
              }
            } catch { outing.errorMessage = error.localizedDescription }
          }
        }
      }
      Section("Recent status / audit") {
        Text(partner.isPartner ? partner.audit : outing.snapshot())
          .font(.caption).textSelection(.enabled)
        ShareLink(item: partner.isPartner ? partner.audit : outing.snapshot()) {
          Label("Share status log", systemImage: "square.and.arrow.up")
        }
        Text("Recent local events, not a tamper-proof audit or a record of phone pickups.")
          .font(.caption).foregroundStyle(.secondary)
      }
      if let error = outing.errorMessage ?? partner.errorMessage {
        Section("Needs attention") { Text(error).foregroundStyle(.red) }
      }
    }
    .navigationTitle("Family time")
    .onChange(of: outing.settings.isEnabled) { _, _ in outing.saveSettings() }
    .onChange(of: outing.settings.profileID) { _, _ in outing.saveSettings() }
    .onChange(of: outing.settings.radius) { _, _ in outing.saveSettings() }
    .onChange(of: outing.settings.blockOutside) { _, _ in outing.saveSettings() }
    .onChange(of: outing.settings.blockWhileMoving) { _, _ in outing.saveSettings() }
    .sheet(isPresented: $showSharing) {
      if let share = partner.share {
        FamilySharingView(share: share, container: partner.container) { error in
          partner.errorMessage = error.localizedDescription
        }
      }
    }
  }

  private func send(_ action: FamilyCommand.Action) {
    Task { await partner.send(action, message: reminder) }
  }
}

private struct FamilySharingView: UIViewControllerRepresentable {
  let share: CKShare
  let container: CKContainer
  let onError: (Error) -> Void

  func makeCoordinator() -> Coordinator { Coordinator(onError: onError) }

  func makeUIViewController(context: Context) -> UICloudSharingController {
    let controller = UICloudSharingController(share: share, container: container)
    controller.availablePermissions = [.allowPrivate, .allowReadWrite]
    controller.delegate = context.coordinator
    return controller
  }

  func updateUIViewController(_ controller: UICloudSharingController, context: Context) {}

  final class Coordinator: NSObject, UICloudSharingControllerDelegate {
    let onError: (Error) -> Void
    init(onError: @escaping (Error) -> Void) { self.onError = onError }
    func itemTitle(for controller: UICloudSharingController) -> String? { "Foqos family time" }
    func cloudSharingController(
      _ controller: UICloudSharingController, failedToSaveShareWithError error: Error
    ) {
      onError(error)
    }
  }
}
