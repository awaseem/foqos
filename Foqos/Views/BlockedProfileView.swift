import FamilyControls
import Foundation
import SwiftData
import SwiftUI

struct BlockedProfileView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss

  @EnvironmentObject private var nfcWriter: NFCWriter
  @EnvironmentObject private var strategyManager: StrategyManager

  // If profile is nil, we're creating a new profile
  var profile: BlockedProfiles?

  @State private var name: String = ""
  @State private var enableLiveActivity: Bool = false
  @State private var enableReminder: Bool = false
  @State private var enableBreaks: Bool = false
  @State private var enableStrictMode: Bool = false
  @State private var reminderTimeInMinutes: Int = 15
  @State private var enableAllowMode: Bool = false
  @State private var enableAllowModeDomain: Bool = false
  @State private var domains: [String] = []

  @State private var physicalUnblockNFCTagId: String?
  @State private var physicalUnblockQRCodeId: String?

  // QR code generator
  @State private var showingGeneratedQRCode = false

  // Sheet for activity picker
  @State private var showingActivityPicker = false

  // Sheet for domain picker
  @State private var showingDomainPicker = false

  // Error states
  @State private var errorMessage: String?
  @State private var showError = false

  // Sheet for physical unblock
  @State private var showingPhysicalUnblockView = false

  @State private var selectedActivity = FamilyActivitySelection()
  @State private var selectedStrategy: BlockingStrategy? = nil

  private let physicalReader: PhysicalReader = PhysicalReader()

  private var isEditing: Bool {
    profile != nil
  }

  private var isBlocking: Bool {
    strategyManager.activeSession?.isActive ?? false
  }

  init(profile: BlockedProfiles? = nil) {
    self.profile = profile
    _name = State(initialValue: profile?.name ?? "")
    _selectedActivity = State(
      initialValue: profile?.selectedActivity ?? FamilyActivitySelection()
    )
    _enableLiveActivity = State(
      initialValue: profile?.enableLiveActivity ?? false
    )
    _enableBreaks = State(
      initialValue: profile?.enableBreaks ?? false
    )
    _enableStrictMode = State(
      initialValue: profile?.enableStrictMode ?? false
    )
    _enableAllowMode = State(
      initialValue: profile?.enableAllowMode ?? false
    )
    _enableAllowModeDomain = State(
      initialValue: profile?.enableAllowModeDomains ?? false
    )
    _enableReminder = State(
      initialValue: profile?.reminderTimeInSeconds != nil
    )
    _reminderTimeInMinutes = State(
      initialValue: Int(profile?.reminderTimeInSeconds ?? 900) / 60
    )
    _domains = State(
      initialValue: profile?.domains ?? []
    )
    _physicalUnblockNFCTagId = State(
      initialValue: profile?.physicalUnblockNFCTagId ?? nil
    )
    _physicalUnblockQRCodeId = State(
      initialValue: profile?.physicalUnblockQRCodeId ?? nil
    )

    if let profileStrategyId = profile?.blockingStrategyId {
      _selectedStrategy = State(
        initialValue:
          StrategyManager
          .getStrategyFromId(id: profileStrategyId)
      )
    } else {
      _selectedStrategy = State(initialValue: NFCBlockingStrategy())
    }
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
              Text("A session is currently active, profile editing is disabled.")
                .font(.subheadline)
                .foregroundColor(.red)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 4)
          }
        }

        Section("Name") {
          TextField("Profile Name", text: $name)
            .textContentType(.none)
        }

        Section(enableAllowMode ? "Allowed" : "Blocked") {
          BlockedProfileAppSelector(
            selection: selectedActivity,
            buttonAction: { showingActivityPicker = true },
            allowMode: enableAllowMode,
            disabled: isBlocking
          )

          CustomToggle(
            title: "Apps Allow Mode",
            description:
              "Pick apps or websites to allow and block everything else. This will erase any other selection you've made.",
            isOn: $enableAllowMode,
            isDisabled: isBlocking
          )

          BlockedProfileDomainSelector(
            domains: domains,
            buttonAction: { showingDomainPicker = true },
            allowMode: enableAllowMode,
            disabled: isBlocking
          )

          CustomToggle(
            title: "Domain Allow Mode",
            description:
              "Pick domains to allow and block everything else. This will erase any other selection you've made.",
            isOn: $enableAllowModeDomain,
            isDisabled: isBlocking
          )
        }

        BlockingStrategyList(
          strategies: StrategyManager.availableStrategies,
          selectedStrategy: $selectedStrategy,
          disabled: isBlocking
        )

        Section("Safeguards") {
          CustomToggle(
            title: "Breaks",
            description:
              "Have the option to take a single break, you choose when to start/stop the break",
            isOn: $enableBreaks,
            isDisabled: isBlocking
          )

          CustomToggle(
            title: "Strict",
            description:
              "Block deleting apps from your phone, stops you from deleting Foqos to access apps",
            isOn: $enableStrictMode,
            isDisabled: isBlocking
          )
        }

        Section("Physical Unblock") {
          BlockedProfilePhysicalUnblockSelector(
            nfcTagId: physicalUnblockNFCTagId,
            qrCodeId: physicalUnblockQRCodeId,
            disabled: isBlocking,
            onSetNFC: {
              physicalReader.readNFCTag(
                onSuccess: { physicalUnblockNFCTagId = $0 },
              )
            },
            onSetQRCode: {
              showingPhysicalUnblockView = true
            },
            onUnsetNFC: { physicalUnblockNFCTagId = nil },
            onUnsetQRCode: { physicalUnblockQRCodeId = nil }
          )
        }

        Section("Notifications") {
          CustomToggle(
            title: "Live Activity",
            description:
              "Shows a live activity on your lock screen with some inspirational qoute",
            isOn: $enableLiveActivity,
            isDisabled: isBlocking
          )

          CustomToggle(
            title: "Reminder",
            description:
              "Sends a reminder to start this profile when its ended",
            isOn: $enableReminder,
            isDisabled: isBlocking
          )
          if enableReminder {
            HStack {
              Text("Reminder time")
              Spacer()
              TextField(
                "",
                value: $reminderTimeInMinutes,
                format: .number
              )
              .keyboardType(.numberPad)
              .multilineTextAlignment(.trailing)
              .frame(width: 50)
              .disabled(isBlocking)
              .font(.subheadline)
              .foregroundColor(.secondary)

              Text("minutes")
                .font(.subheadline)
                .foregroundColor(.secondary)
            }.padding(.top)
          }

          if !isBlocking {
            Button {
              if let url = URL(
                string: UIApplication.openSettingsURLString
              ) {
                UIApplication.shared.open(url)
              }
            } label: {
              Text("Go to settings to disable globally")
                .font(.caption)
            }
          }
        }

        if isEditing {
          Section("Utilities") {
            Button(action: {
              writeProfile()
            }) {
              HStack {
                Image(systemName: "tag")
                Text("Write to NFC Tag")
                Spacer()
              }
            }
            .disabled(isBlocking)

            Button(action: {
              showingGeneratedQRCode = true
            }) {
              HStack {
                Image(systemName: "qrcode")
                Text("Generate QR code")
                Spacer()
              }
            }
            .disabled(isBlocking)
          }
        }

        if isEditing, let validProfile = profile {
          BlockedProfileStats(profile: validProfile)
        }
      }
      .onChange(of: enableAllowMode) {
        _,
        newValue in
        selectedActivity = FamilyActivitySelection(
          includeEntireCategory: newValue
        )
      }
      .navigationTitle(isEditing ? "Profile Details" : "New Profile")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button("Cancel") {
            dismiss()
          }
        }

        ToolbarItem(placement: .topBarTrailing) {
          Button(isEditing ? "Update" : "Create") {
            saveProfile()
          }
          .disabled(name.isEmpty)
        }
      }
      .sheet(isPresented: $showingActivityPicker) {
        AppPicker(
          selection: $selectedActivity,
          isPresented: $showingActivityPicker,
          allowMode: enableAllowMode
        )
      }
      .sheet(isPresented: $showingDomainPicker) {
        DomainPicker(
          domains: $domains,
          isPresented: $showingDomainPicker,
          allowMode: enableAllowModeDomain
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
      .sheet(isPresented: $showingPhysicalUnblockView) {
        BlockingStrategyActionView(
          customView: physicalReader.readQRCode(
            onSuccess: {
              showingPhysicalUnblockView = false
              physicalUnblockQRCodeId = $0
            },
            onFailure: { _ in
              showingPhysicalUnblockView = false
              showError(
                message: "Failed to read QR code, please try again or use a different QR code."
              )
            }
          )
        )
      }
      .alert("Error", isPresented: $showError) {
        Button("OK") {}
      } message: {
        Text(errorMessage ?? "An unknown error occurred")
      }
    }
  }

  private func showError(message: String) {
    errorMessage = message
    showError = true
  }

  private func writeProfile() {
    if let profileToWrite = profile {
      let url = BlockedProfiles.getProfileDeepLink(profileToWrite)
      nfcWriter.writeURL(url)
    }
  }

  private func saveProfile() {
    do {
      // Calculate reminder time in seconds or nil if disabled
      let reminderTimeSeconds: UInt32? =
        enableReminder ? UInt32(reminderTimeInMinutes * 60) : nil

      if let existingProfile = profile {
        // Update existing profile
        try BlockedProfiles.updateProfile(
          existingProfile,
          in: modelContext,
          name: name,
          selection: selectedActivity,
          blockingStrategyId: selectedStrategy?.getIdentifier(),
          enableLiveActivity: enableLiveActivity,
          reminderTime: reminderTimeSeconds,
          enableBreaks: enableBreaks,
          enableStrictMode: enableStrictMode,
          enableAllowMode: enableAllowMode,
          enableAllowModeDomains: enableAllowModeDomain,
          domains: domains,
          physicalUnblockNFCTagId: physicalUnblockNFCTagId,
          physicalUnblockQRCodeId: physicalUnblockQRCodeId
        )
      } else {
        // Create new profile with next available order
        let nextOrder = BlockedProfiles.getNextOrder(in: modelContext)
        let newProfile = BlockedProfiles(
          name: name,
          selectedActivity: selectedActivity,
          blockingStrategyId: selectedStrategy?
            .getIdentifier() ?? NFCBlockingStrategy.id,
          enableLiveActivity: enableLiveActivity,
          reminderTimeInSeconds: reminderTimeSeconds,
          enableBreaks: enableBreaks,
          enableStrictMode: enableStrictMode,
          enableAllowMode: enableAllowMode,
          enableAllowModeDomains: enableAllowModeDomain,
          order: nextOrder,
          domains: domains,
          physicalUnblockNFCTagId: physicalUnblockNFCTagId,
          physicalUnblockQRCodeId: physicalUnblockQRCodeId
        )

        modelContext.insert(newProfile)
        try modelContext.save()
      }
      dismiss()
    } catch {
      errorMessage = error.localizedDescription
      showError = true
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
