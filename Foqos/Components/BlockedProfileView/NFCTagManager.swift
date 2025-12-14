import SwiftUI
import SwiftData

/**
 Simple UI for managing multiple NFC tags per profile.
 */
struct NFCTagManager: View {
    @Environment(\.modelContext) private var context
    @Binding var profile: BlockedProfiles
    @Binding var isPresented: Bool

    @State private var isScanning = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var editingTag: NFCTagWhitelist? = nil
    @State private var showingRenameAlert = false
    @State private var newTagName = ""

    private let maxTags = 15
    private let nfcScanner = NFCScannerUtil()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button(action: startScanning) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.blue)
                            Text("Add NFC Tag")
                            Spacer()
                            if isScanning {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                    .disabled(isScanning || profile.nfcWhitelist.count >= maxTags)

                    // Temporary test button for simulator
                    Button(action: addTestTag) {
                        HStack {
                            Image(systemName: "wrench.and.screwdriver.fill")
                                .foregroundStyle(.orange)
                            Text("Add Test Tag (Simulator)")
                        }
                    }
                    .disabled(profile.nfcWhitelist.count >= maxTags)
                } header: {
                    Text("Add New Tag")
                } footer: {
                    Text("Scan an NFC tag to add it to this profile. Use 'Add Test Tag' for simulator testing.")
                }

                Section {
                    ForEach(profile.nfcWhitelist, id: \.id) { tag in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(tag.name ?? "Unnamed Tag")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Spacer()
                                Button("Rename") {
                                    editingTag = tag
                                    newTagName = tag.name ?? ""
                                    showingRenameAlert = true
                                }
                                .font(.caption)
                                .foregroundStyle(.blue)
                            }
                            Text("ID: \(String(tag.tagId.prefix(8)))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                    .onDelete(perform: deleteTags)

                    if profile.nfcWhitelist.isEmpty {
                        Text("No NFC tags configured.")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    }
                } header: {
                    HStack {
                        Text("NFC Tags")
                        Spacer()
                        Text("\(profile.nfcWhitelist.count) of \(maxTags)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("NFC Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
        .onAppear(perform: setupNFCScanner)
        .alert("Error", isPresented: $showingError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
        .alert("Rename Tag", isPresented: $showingRenameAlert) {
            TextField("Tag Name", text: $newTagName)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                renameTag()
            }
        }
    }

    private func setupNFCScanner() {
        nfcScanner.onTagScanned = { result in
            Task { @MainActor in
                self.isScanning = false
                await self.handleScannedTag(result)
            }
        }

        nfcScanner.onError = { error in
            Task { @MainActor in
                self.isScanning = false
                self.showError(error)
            }
        }
    }

    private func startScanning() {
        guard nfcScanner.isNFCAvailable() else {
            showError("NFC is not available on this device.")
            return
        }

        isScanning = true
        nfcScanner.scanForWhitelist(profileName: profile.name)
    }

    // Temporary test method for simulator
    private func addTestTag() {
        Task { @MainActor in
            let timestamp = Int(Date().timeIntervalSince1970)
            let testTagId = "test_tag_\(timestamp)"
            let testResult = NFCResult(id: testTagId, url: nil, DateScanned: Date())
            await handleScannedTag(testResult)
        }
    }

    @MainActor
    private func handleScannedTag(_ result: NFCResult) async {
        let tagId = result.url ?? result.id

        // Check if tag already exists
        if profile.nfcWhitelist.contains(where: { $0.tagId == tagId }) {
            showError("This NFC tag is already in the list.")
            return
        }

        // Check limit
        if profile.nfcWhitelist.count >= maxTags {
            showError("Maximum of \(maxTags) tags allowed.")
            return
        }

        // Add new tag
        let newTag = NFCTagWhitelist(tagId: tagId, tagUrl: result.url, name: "NFC Tag")
        newTag.profile = profile
        context.insert(newTag)

        do {
            try context.save()
        } catch {
            showError("Failed to save tag: \(error.localizedDescription)")
        }
    }

    private func deleteTags(at offsets: IndexSet) {
        for index in offsets {
            let tag = profile.nfcWhitelist[index]
            context.delete(tag)
        }

        do {
            try context.save()
        } catch {
            showError("Failed to delete tag: \(error.localizedDescription)")
        }
    }

    private func renameTag() {
        guard let tag = editingTag else { return }

        tag.name = newTagName.isEmpty ? "NFC Tag" : newTagName

        do {
            try context.save()
        } catch {
            showError("Failed to rename tag: \(error.localizedDescription)")
        }

        editingTag = nil
        newTagName = ""
    }

    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}