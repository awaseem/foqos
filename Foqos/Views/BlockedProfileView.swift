import FamilyControls
import Foundation
import SwiftData
import SwiftUI

// Alert identifier for managing multiple alerts
struct AlertIdentifier: Identifiable {
  enum AlertType {
    case error
    case deleteProfile
  }

  let id: AlertType
  var errorMessage: String?
}

struct BlockedProfileView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss

  @EnvironmentObject private var nfcWriter: NFCWriter
  @EnvironmentObject private var strategyManager: StrategyManager

  // If profile is nil, we're creating a new profile
  var profile: BlockedProfiles?

  @StateObject private var draft: BlockedProfileDraft

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

  init(profile: BlockedProfiles? = nil) {
    self.profile = profile
    _draft = StateObject(wrappedValue: BlockedProfileDraft(profile: profile))
  }

  var body: some View {
    NavigationStack {
      Form {
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

        BlockedProfileNameSection(draft: draft, disabled: false)

        BlockedProfileStrategySection(
          draft: draft,
          showingStrategyPicker: $showingStrategyPicker,
          disabled: isBlocking
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

                Divider()

                Button(role: .destructive) {
                  alertIdentifier = AlertIdentifier(id: .deleteProfile)
                } label: {
                  Label("Delete Profile", systemImage: "trash")
                }
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
            .disabled(!draft.isValid)
            .accessibilityLabel(isEditing ? "Update" : "Create")
          }
        }
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
          strategies: StrategyManager.availableStrategies.filter { !$0.hidden },
          selectedStrategy: $draft.selectedStrategy,
          isPresented: $showingStrategyPicker
        )
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
            guard !trimmed.isEmpty else { return }
            do {
              if let source = profile {
                let clonedProfile = try BlockedProfiles.cloneProfile(
                  source, in: modelContext, newName: trimmed)
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
              dismiss()
              if let profileToDelete = profile {
                do {
                  try BlockedProfiles.deleteProfile(profileToDelete, in: modelContext)
                } catch {
                  showError(message: error.localizedDescription)
                }
              }
            }
          )
        }
      }
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
    do {
      _ = try draft.save(existingProfile: profile, in: modelContext)
      dismiss()
    } catch {
      alertIdentifier = AlertIdentifier(id: .error, errorMessage: error.localizedDescription)
    }
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
