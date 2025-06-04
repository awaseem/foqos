import FamilyControls
import SwiftData
import SwiftUI

struct BlockedProfileListView: View {
    @Environment(\.modelContext) private var context

    @Query private var profiles: [BlockedProfiles]
    @State private var showingCreateProfile = false
    @State private var profileToEdit: BlockedProfiles?
    @State private var showErrorAlert = false

    var body: some View {
        NavigationStack {
            Group {
                if profiles.isEmpty {
                    EmptyView(
                        iconName: "person.crop.circle.badge.plus",
                        headingText:
                            "Group and switch between sets of blocked restrictions with customizable profiles"
                    )
                } else {
                    List {
                        ForEach(profiles) { profile in
                            ProfileRow(profile: profile)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    profileToEdit = profile
                                }
                        }
                        .onDelete(perform: deleteProfiles)
                    }
                }
            }
            .navigationTitle("Profiles")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingCreateProfile = true
                    }) {
                        HStack {
                            Text("Create")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingCreateProfile) {
                BlockedProfileView()
            }
            .sheet(item: $profileToEdit) { profile in
                BlockedProfileView(profile: profile)
            }
            .alert(
                "Cannot Delete Active Profile",
                isPresented: $showErrorAlert
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(
                    "You cannot delete a profile that is currently active. Please switch to a different profile first."
                )
            }
        }
    }

    private func deleteProfiles(at offsets: IndexSet) {
        let activeSession = BlockedProfileSession.mostRecentActiveSession(
            in: context)

        for index in offsets {
            let profile = profiles[index]
            if profile.id == activeSession?.blockedProfile.id {
                showErrorAlert = true
                return
            }

            try? BlockedProfiles.deleteProfile(profile, in: context)
        }
    }
}

#Preview {
    BlockedProfileListView()
        .modelContainer(for: BlockedProfiles.self, inMemory: true)
}
