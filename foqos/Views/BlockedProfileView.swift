import FamilyControls
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
    @State private var catAndAppCount: Int = 0
    @State private var enableLiveActivity: Bool = false
    
    // QR code generator
    @State private var showingGeneratedQRCode = false
    
    // Sheet for activity picker
    @State private var showingActivityPicker = false
    
    // Error states
    @State private var errorMessage: String?
    @State private var showError = false
    
    @State private var selectedActivity = FamilyActivitySelection()
    @State private var selectedStrategy: BlockingStrategy? = nil
    
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
        _catAndAppCount = State(
            initialValue:
                BlockedProfiles
                .countSelectedActivities(selectedActivity)
        )
        _enableLiveActivity = State(
            initialValue: profile?.enableLiveActivity ?? false
        )
        
        if let profileStrategyId = profile?.blockingStrategyId {
            _selectedStrategy = State(
                initialValue: StrategyManager
                    .getStrategyFromId(id: profileStrategyId))
        } else {
            _selectedStrategy = State(initialValue: NFCBlockingStrategy())
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Profile Details") {
                    TextField("Profile Name", text: $name)
                        .textContentType(.none)
                }
                
                BlockedProfileAppSelector(
                    selection: selectedActivity,
                    buttonAction: { showingActivityPicker = true },
                    disabled: isBlocking,
                    disabledText: "Disable the current session to edit"
                )
                
                BlockingStrategyList(
                    strategies: StrategyManager.availableStrategies,
                    selectedStrategy: $selectedStrategy,
                    disabled: isBlocking,
                    disabledText: "Disable the current session to edit"
                )
                
                Section("Notifications") {
                    Toggle("Live Activity", isOn: $enableLiveActivity)
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
                        
                        Button(action: {
                            showingGeneratedQRCode = true
                        }) {
                            HStack {
                                Image(systemName: "qrcode")
                                Text("Generate QR code")
                                Spacer()
                            }
                        }
                    }
                }
                
                if isEditing, let validProfile = profile {
                    BlockedProfileStats(profile: validProfile)
                }
            }
            .onChange(of: selectedActivity) { _, newValue in
                catAndAppCount =
                BlockedProfiles
                    .countSelectedActivities(newValue)
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
                    isPresented: $showingActivityPicker
                )
            }
            .sheet(isPresented: $showingGeneratedQRCode) {
                if let profileToWrite = profile {
                    let url = BlockedProfiles.getProfileDeepLink(profileToWrite)
                    QRCodeView(
                        url: url,
                        profileName: profileToWrite
                            .name)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage ?? "An unknown error occurred")
            }
        }
    }
    
    private func writeProfile() {
        if let profileToWrite = profile {
            let url = BlockedProfiles.getProfileDeepLink(profileToWrite)
            nfcWriter.writeURL(url)
        }
    }
    
    private func saveProfile() {
        do {
            if let existingProfile = profile {
                // Update existing profile
                try BlockedProfiles.updateProfile(
                    existingProfile,
                    in: modelContext,
                    name: name,
                    selection: selectedActivity,
                    blockingStrategyId: selectedStrategy?.getIdentifier(),
                    enableLiveActivity: enableLiveActivity
                )
            } else {
                // Create new profile
                let newProfile = BlockedProfiles(
                    name: name,
                    selectedActivity: selectedActivity,
                    blockingStrategyId: selectedStrategy?
                        .getIdentifier() ?? NFCBlockingStrategy.id,
                    enableLiveActivity: enableLiveActivity
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
        selectedActivity: FamilyActivitySelection()
    )
    
    BlockedProfileView(profile: previewProfile)
        .environmentObject(NFCWriter())
        .environmentObject(StrategyManager())
        .modelContainer(for: BlockedProfiles.self, inMemory: true)
}
