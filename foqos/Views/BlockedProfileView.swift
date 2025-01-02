import FamilyControls
import SwiftData
import SwiftUI

struct BlockedProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @EnvironmentObject var nfcScanner: NFCScanner

    // If profile is nil, we're creating a new profile
    var profile: BlockedProfiles?

    @State private var name: String = ""
    @State private var selectedActivity = FamilyActivitySelection()
    @State private var catAndAppCount: Int = 0
    @State private var showingActivityPicker = false
    @State private var errorMessage: String?
    @State private var showError = false

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
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Profile Details") {
                    TextField("Profile Name", text: $name)
                        .textInputAutocapitalization(.words)
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
                
                if isEditing || !name.isEmpty {
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
            .familyActivityPicker(
                isPresented: $showingActivityPicker,
                selection: $selectedActivity
            )
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
            nfcScanner.writeURL(url)
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
