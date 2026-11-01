import FamilyControls
import Foundation
import SwiftData
import SwiftUI

// Alert identifier for managing multiple alerts
struct AlertIdentifier: Identifiable {
  enum AlertType {
    case error
    case deleteProfile
    case removePassword
  }

  let id: AlertType
  var errorMessage: String?
}

private struct ProfilePasswordDestination: Identifiable {
  let profile: BlockedProfiles
  let mode: ProfilePasswordMode

  var id: String { "\(profile.id)-\(mode.rawValue)" }
}

struct BlockedProfileView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss
  @Environment(\.scenePhase) private var scenePhase

  @EnvironmentObject private var nfcWriter: NFCWriter
  @EnvironmentObject private var strategyManager: StrategyManager

  // If profile is nil, we're creating a new profile
  var profile: BlockedProfiles?

  @StateObject private var draft: BlockedProfileDraft
  @State private var editAuthorization: ProfileEditAuthorization?
  @State private var passwordDestination: ProfilePasswordDestination?

  // QR code generator
  @State private var showingGeneratedQRCode = false

  // Sheet for activity picker
  @State private var showingActivityPicker = false

  // Sheet for domain picker
  @State private var showingDomainPicker = false

  // Sheet for schedule picker
  @State private var showingSchedulePicker = false

  // Sheet for strategy picker
  @State private var showingStrategyPicker = false

  // Sheet for strategy-specific start settings
  @State private var startSettingsDestination: StrategyStartSettingsKind?

  // Alert management
  @State private var alertIdentifier: AlertIdentifier?

  // NFC write URL storage for overwrite warning
  @State private var pendingNFCWriteURL: String?
  @State private var showingStrictNFCWriteWarning = false

  // Alert for cloning
  @State private var showingClonePrompt = false
  @State private var cloneName: String = ""

  // Sheet for insights modal
  @State private var showingInsights = false

  private var isEditing: Bool {
    profile != nil
  }

  private var isBlocking: Bool {
    strategyManager.activeSession?.isActive ?? false
  }

  private var isPasswordProtected: Bool {
    profile?.editLockCredential != nil
  }

  private var isLocked: Bool {
    guard let profile, isPasswordProtected else { return false }
    return editAuthorization?.allowsEditing(profile) != true
  }

  init(profile: BlockedProfiles? = nil) {
    self.profile = profile
    _draft = StateObject(wrappedValue: BlockedProfileDraft(profile: profile))
  }

  var body: some View {
    NavigationStack {
      Form {
        if isPasswordProtected {
          ProfileLockStatusSection(
            isLocked: isLocked,
            isBlocking: isBlocking,
            onUnlock: { presentPassword(.unlock) },
            onLock: { relockProfile() }
          )
        }

        // Show lock status when profile is active
        if isBlocking {
          Section {
            HStack {
              Image(systemName: "lock.fill")
                .font(.title2)
                .foregroundColor(.orange)
              Text("A session is active. Stop it before editing this profile.")
                .font(.subheadline)
                .foregroundColor(.red)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 4)
          }
        }

        Group {
          BlockedProfileNameSection(draft: draft, disabled: isBlocking)

          BlockedProfileStrategySection(
            draft: draft,
            showingStrategyPicker: $showingStrategyPicker,
            disabled: isBlocking,
            showsStartSettings: isEditing,
            onUpdateStartSettings: { settingsKind in
              startSettingsDestination = settingsKind
            }
          )

          BlockedProfileAppsSection(
            draft: draft,
            showingActivityPicker: $showingActivityPicker,
            disabled: isBlocking
          )

          BlockedProfileDomainsSection(
            draft: draft,
            showingDomainPicker: $showingDomainPicker,
            disabled: isBlocking
          )

          BlockedProfileStrictUnlocksSection(draft: draft, disabled: isBlocking)

          BlockedProfileScheduleSection(
            draft: draft,
            showingSchedulePicker: $showingSchedulePicker,
            disabled: isBlocking
          )

          BlockedProfileBreaksSection(draft: draft, disabled: isBlocking)

          BlockedProfileStrictSafeguardsSection(draft: draft, disabled: isBlocking)

          BlockedProfileSessionSafeguardsSection(draft: draft, disabled: isBlocking)

          BlockedProfileNotificationsSection(
            draft: draft,
            profile: profile,
            disabled: isBlocking
          )
        }
        .disabled(isLocked)
      }
      .scrollDismissesKeyboard(.interactively)
      .navigationTitle(isEditing ? "Edit Profile" : "New Profile")
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button(action: { dismiss() }) {
            Image(systemName: "xmark")
          }
          .accessibilityLabel("Cancel")
        }

        if isEditing, let validProfile = profile {
          ToolbarItemGroup(placement: .topBarTrailing) {
            if !isBlocking {
              Menu {
                if isPasswordProtected {
                  if isLocked {
                    Button {
                      presentPassword(.unlock)
                    } label: {
                      Label("Unlock Profile", systemImage: "lock.open")
                    }
                  } else {
                    Button {
                      presentPassword(.change)
                    } label: {
                      Label("Change Password", systemImage: "key")
                    }

                    Button(role: .destructive) {
                      alertIdentifier = AlertIdentifier(id: .removePassword)
                    } label: {
                      Label("Remove Password", systemImage: "lock.slash")
                    }
                  }
                } else {
                  Button {
                    presentPassword(.setup)
                  } label: {
                    Label("Protect Profile", systemImage: "lock")
                  }
                }

                Divider()

                Button {
                  writeProfile()
                } label: {
                  Label("Write to NFC Tag", systemImage: "tag")
                }

                Button {
                  showingGeneratedQRCode = true
                } label: {
                  Label("Generate QR code", systemImage: "qrcode")
                }

                Button {
                  cloneName = validProfile.name + " Copy"
                  showingClonePrompt = true
                } label: {
                  Label("Duplicate Profile", systemImage: "square.on.square")
                }
                .disabled(isLocked)

                Divider()

                Button(role: .destructive) {
                  alertIdentifier = AlertIdentifier(id: .deleteProfile)
                } label: {
                  Label("Delete Profile", systemImage: "trash")
                }
                .disabled(isLocked)
              } label: {
                Image(systemName: "ellipsis.circle")
              }
              .accessibilityLabel("Profile Actions")
            }

            Button(action: { showingInsights = true }) {
              Image(systemName: "chart.line.uptrend.xyaxis")
            }
            .accessibilityLabel("View Insights")
          }
        }

        if #available(iOS 26.0, *) {
          ToolbarSpacer(.flexible, placement: .topBarTrailing)
        }

        if !isBlocking {
          ToolbarItem(placement: .topBarTrailing) {
            Button(action: { saveProfile() }) {
              Image(systemName: "checkmark")
            }
            .disabled(!draft.isValid || isLocked)
            .accessibilityLabel(isEditing ? "Update" : "Create")
          }
        }
      }
      .sheet(item: $passwordDestination) { destination in
        ProfilePasswordView(
          profile: destination.profile,
          mode: destination.mode,
          authorization: editAuthorization,
          onUnlock: { authorization in
            guard scenePhase == .active, !isBlocking else {
              authorization.revoke()
              return
            }
            editAuthorization = authorization
          }
        )
      }
      .sheet(isPresented: $showingActivityPicker) {
        AppPicker(
          selection: $draft.selectedActivity,
          isPresented: $showingActivityPicker,
          allowMode: draft.enableAllowMode
        )
      }
      .sheet(isPresented: $showingDomainPicker) {
        DomainPicker(
          domains: $draft.domains,
          isPresented: $showingDomainPicker,
          allowMode: draft.enableAllowModeDomain
        )
      }
      .sheet(isPresented: $showingSchedulePicker) {
        SchedulePicker(
          schedule: $draft.schedule,
          isPresented: $showingSchedulePicker
        )
      }
      .sheet(isPresented: $showingStrategyPicker) {
        StrategyPicker(
          strategies: StrategyManager.availableStrategies,
          selectedStrategy: $draft.selectedStrategy,
          isPresented: $showingStrategyPicker
        )
      }
      .sheet(item: $startSettingsDestination) { settingsKind in
        StrategyStartSettingsView(
          kind: settingsKind,
          draft: draft
        )
        .presentationDetents(settingsKind.presentationDetents)
      }
      .sheet(isPresented: $showingGeneratedQRCode) {
        if let profileToWrite = profile {
          let url = BlockedProfiles.getProfileDeepLink(profileToWrite)
          QRCodeView(
            url: url,
            profileName: profileToWrite
              .name
          )
        }
      }
      .sheet(isPresented: $showingInsights) {
        if let validProfile = profile {
          ProfileInsightsView(profile: validProfile)
        }
      }
      .sheet(isPresented: $showingStrictNFCWriteWarning) {
        StrictNFCWriteWarningView(
          profileName: profile?.name ?? "this profile",
          onCancel: {
            pendingNFCWriteURL = nil
            showingStrictNFCWriteWarning = false
          },
          onContinue: {
            continuePendingNFCWrite()
          }
        )
        .presentationDetents([.height(520), .large])
        .presentationDragIndicator(.visible)
      }
      .background(
        TextFieldAlert(
          isPresented: $showingClonePrompt,
          title: "Duplicate Profile",
          message: nil,
          text: $cloneName,
          placeholder: "Profile Name",
          confirmTitle: "Create",
          cancelTitle: "Cancel",
          onConfirm: { enteredName in
            let trimmed = enteredName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, !isBlocking else { return }
            do {
              if let source = profile {
                let clonedProfile = try BlockedProfiles.cloneProfile(
                  source, in: modelContext, newName: trimmed, authorization: editAuthorization)
                DeviceActivityCenterUtil.scheduleTimerActivity(for: clonedProfile)
              }
            } catch {
              showError(message: error.localizedDescription)
            }
          }
        )
      )
      .alert(item: $alertIdentifier) { alert in
        switch alert.id {
        case .error:
          return Alert(
            title: Text("Error"),
            message: Text(alert.errorMessage ?? "An unknown error occurred"),
            dismissButton: .default(Text("OK"))
          )
        case .deleteProfile:
          return Alert(
            title: Text("Delete Profile"),
            message: Text(
              "Are you sure you want to delete this profile? This action cannot be undone."),
            primaryButton: .cancel(),
            secondaryButton: .destructive(Text("Delete")) {
              guard !isBlocking else { return }
              if let profileToDelete = profile {
                do {
                  try BlockedProfiles.deleteProfile(
                    profileToDelete, in: modelContext, authorization: editAuthorization)
                  try modelContext.save()
                  dismiss()
                } catch {
                  showError(message: error.localizedDescription)
                }
              }
            }
          )
        case .removePassword:
          return Alert(
            title: Text("Remove Password?"),
            message: Text("Anyone using this device will be able to edit or delete this profile."),
            primaryButton: .cancel(),
            secondaryButton: .destructive(Text("Remove Password")) {
              guard !isBlocking, let profile else { return }
              do {
                try ProfileLockUtil.setCredential(
                  nil, for: profile, in: modelContext, authorization: editAuthorization)
                revokeAuthorization()
              } catch {
                showError(message: error.localizedDescription)
              }
            }
          )
        }
      }
      .onChange(of: scenePhase) { _, phase in
        if phase == .background { relockProfile() }
      }
      .onChange(of: isBlocking) { _, blocking in
        if blocking { relockProfile() }
      }
      .onChange(of: profile?.editLockCredential) { _, _ in
        revokeAuthorization()
      }
      .onDisappear { revokeAuthorization() }
    }
  }

  private func showError(message: String) {
    alertIdentifier = AlertIdentifier(id: .error, errorMessage: message)
  }

  private func writeProfile() {
    if let profileToWrite = profile {
      let url = BlockedProfiles.getProfileDeepLink(profileToWrite)

      if shouldWarnBeforeNFCWrite(for: profileToWrite) {
        pendingNFCWriteURL = url
        showingStrictNFCWriteWarning = true
      } else {
        nfcWriter.writeURL(url)
      }
    }
  }

  private func shouldWarnBeforeNFCWrite(for profile: BlockedProfiles) -> Bool {
    return profile.hasPhysicalUnblockItem(ofType: .nfc)
  }

  private func continuePendingNFCWrite() {
    guard let url = pendingNFCWriteURL else {
      showingStrictNFCWriteWarning = false
      return
    }

    pendingNFCWriteURL = nil
    showingStrictNFCWriteWarning = false

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
      nfcWriter.writeURL(url)
    }
  }

  private func saveProfile() {
    guard !isBlocking else { return }
    do {
      _ = try draft.save(
        existingProfile: profile, in: modelContext, authorization: editAuthorization)
      revokeAuthorization()
      dismiss()
    } catch {
      alertIdentifier = AlertIdentifier(id: .error, errorMessage: error.localizedDescription)
    }
  }

  private func revokeAuthorization() {
    editAuthorization?.revoke()
    editAuthorization = nil
  }

  private func presentPassword(_ mode: ProfilePasswordMode) {
    guard let profile, !isBlocking else { return }
    passwordDestination = ProfilePasswordDestination(profile: profile, mode: mode)
  }

  private func relockProfile() {
    revokeAuthorization()
    passwordDestination = nil
    showingActivityPicker = false
    showingDomainPicker = false
    showingSchedulePicker = false
    showingStrategyPicker = false
    startSettingsDestination = nil
    showingClonePrompt = false
    alertIdentifier = nil
  }
}

// Preview provider for SwiftUI previews
#Preview {
  BlockedProfileView()
    .environmentObject(NFCWriter())
    .environmentObject(StrategyManager())
    .modelContainer(for: BlockedProfiles.self, inMemory: true)
}

#Preview {
  let previewProfile = BlockedProfiles(
    name: "test",
    selectedActivity: FamilyActivitySelection(),
    reminderTimeInSeconds: 60
  )

  BlockedProfileView(profile: previewProfile)
    .environmentObject(NFCWriter())
    .environmentObject(StrategyManager())
    .modelContainer(for: BlockedProfiles.self, inMemory: true)
}
