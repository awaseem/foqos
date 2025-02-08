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
    @State private var showingActivityPicker = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    @State private var selectedActivity = FamilyActivitySelection()
    @State private var selectedStrategy: BlockingStrategy? = nil
    
    private var isEditing: Bool {
        profile != nil
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
        
        if let profileStrategyId = profile?.blockingStrategyId {
            _selectedStrategy = State(
                initialValue: strategyManager
                    .getStrategy(id: profileStrategyId))
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Profile Details") {
                    TextField("Profile Name", text: $name)
                        .textContentType(.none)
                }
                
                Section("Selected Restrictions") {
                    Button(action: {
                        showingActivityPicker = true
                    }) {
                        HStack {
                            Text("Select Apps & Websites")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.gray)
                        }
                    }
                    if catAndAppCount == 0 {
                        Text("No apps or websites selected")
                            .foregroundStyle(.gray)
                    } else {
                        Text("\(catAndAppCount) items selected")
                            .font(.footnote)
                            .foregroundStyle(.gray)
                            .padding(.top, 4)
                    }
                }
                
                Section("Selected Blocking Strategy") {
                    BlockingStrategyList(
                        strategies: StrategyManager.availableStrategies,
                        selectedStrategy: $selectedStrategy
                    )
                }
                
                if isEditing {
                    Section("Utilities") {
                        Button(action: {
                            writeProfile()
                        }) {
                            HStack {
                                Image(systemName: "pencil.circle.fill")
                                    .foregroundStyle(.green)
                                Text("Write Profile to NFC Tag")
                                Spacer()
                            }
                        }
                    }
                }
                
                if isEditing, let validProfile = profile {
                    Section("Stats for Nerds") {
                        // Profile ID
                        HStack {
                            Text("Profile ID")
                                .foregroundStyle(.gray)
                            Spacer()
                            Text(validProfile.id.uuidString)
                                .truncationMode(.tail)
                                .foregroundStyle(.gray)
                        }
                        
                        // Created Date
                        HStack {
                            Text("Created")
                                .foregroundStyle(.gray)
                            Spacer()
                            Text(validProfile.createdAt.formatted())
                                .foregroundStyle(.gray)
                        }
                        
                        // Last Modified
                        HStack {
                            Text("Last Modified")
                                .foregroundStyle(.gray)
                            Spacer()
                            Text(validProfile.updatedAt.formatted())
                                .foregroundStyle(.gray)
                        }
                        
                        // Total Sessions
                        HStack {
                            Text("Total Sessions")
                                .foregroundStyle(.gray)
                            Spacer()
                            Text("\(validProfile.sessions.count)")
                                .foregroundStyle(.gray)
                        }
                        
                        
                        // Selected Restrictions Details
                        HStack {
                            Text("Categories Blocked")
                                .foregroundStyle(.gray)
                            Spacer()
                            Text("\(validProfile.selectedActivity.categories.count)")
                                .foregroundStyle(.gray)
                        }
                        
                        HStack {
                            Text("Apps Blocked")
                                .foregroundStyle(.gray)
                            Spacer()
                            Text("\(validProfile.selectedActivity.applications.count)")
                                .foregroundStyle(.gray)
                        }
                    }
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
                    selection: selectedActivity
                )
            } else {
                // Create new profile
                let newProfile = BlockedProfiles(
                    name: name,
                    selectedActivity: selectedActivity
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
        .modelContainer(for: BlockedProfiles.self, inMemory: true)
}
