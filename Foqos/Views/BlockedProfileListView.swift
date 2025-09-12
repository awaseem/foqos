import FamilyControls
import SwiftData
import SwiftUI

struct BlockedProfileListView: View {
  @Environment(\.modelContext) private var context
  @Environment(\.dismiss) private var dismiss

  @Query(sort: [
    SortDescriptor(\BlockedProfiles.order, order: .forward),
    SortDescriptor(\BlockedProfiles.createdAt, order: .reverse),
  ]) private var profiles: [BlockedProfiles]

  @State private var showingCreateProfile = false
  @State private var showingDataExport = false

  @State private var profileToEdit: BlockedProfiles?
  @State private var showErrorAlert = false
  @State private var editMode: EditMode = .inactive

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
                  if editMode == .inactive {
                    profileToEdit = profile
                  }
                }
            }
            .onDelete(perform: editMode == .active ? deleteProfiles : nil)
            .onMove(perform: editMode == .active ? moveProfiles : nil)
          }
          .environment(\.editMode, $editMode)
        }
      }
      .navigationTitle("Profiles")
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button(action: { dismiss() }) {
            Image(systemName: "xmark")
          }
        }

        ToolbarItemGroup(placement: .topBarTrailing) {
          if editMode == .active {
            Button(action: { editMode = .inactive }) {
              Image(systemName: "checkmark.circle")
            }
          }
          if !profiles.isEmpty {
            Menu {
              Button {
                editMode = .active
              } label: {
                Label("Edit/Move", systemImage: "pencil")
              }

              Button {
                showingDataExport = true
              } label: {
                Label("Export Data", systemImage: "square.and.arrow.up")
              }
            } label: {
              Image(systemName: "ellipsis.circle")
            }
          }
          Button(action: { showingCreateProfile = true }) {
            Image(systemName: "plus")
          }
        }
      }
      .sheet(isPresented: $showingCreateProfile) {
        BlockedProfileView()
      }
      .sheet(item: $profileToEdit) { profile in
        BlockedProfileView(profile: profile)
      }
      .sheet(isPresented: $showingDataExport) {
        BlockedProfileDataExportView()
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

    // Check if any of the profiles to delete are active
    for index in offsets {
      let profile = profiles[index]
      if profile.id == activeSession?.blockedProfile.id {
        showErrorAlert = true
        return
      }
    }

    // Delete the profiles and reorder
    do {
      for index in offsets {
        let profile = profiles[index]
        try BlockedProfiles.deleteProfile(profile, in: context)
      }

      // Reorder remaining profiles to fix gaps in ordering
      let remainingProfiles = try BlockedProfiles.fetchProfiles(in: context)
      try BlockedProfiles.reorderProfiles(remainingProfiles, in: context)
    } catch {
      print("Failed to delete or reorder profiles: \(error)")
    }
  }

  private func moveProfiles(from source: IndexSet, to destination: Int) {
    var reorderedProfiles = Array(profiles)
    reorderedProfiles.move(fromOffsets: source, toOffset: destination)

    do {
      try BlockedProfiles.reorderProfiles(reorderedProfiles, in: context)
    } catch {
      print("Failed to reorder profiles: \(error)")
    }
  }
}

#Preview {
  BlockedProfileListView()
    .modelContainer(for: BlockedProfiles.self, inMemory: true)
}
