import SwiftData
import SwiftUI
import UniformTypeIdentifiers

// Simple CSV FileDocument for exporting
struct CSVDocument: FileDocument {
  static var readableContentTypes: [UTType] { [.commaSeparatedText] }

  var text: String

  init(text: String) {
    self.text = text
  }

  init(configuration: ReadConfiguration) throws {
    if let data = configuration.file.regularFileContents,
      let string = String(data: data, encoding: .utf8)
    {
      self.text = string
    } else {
      self.text = ""
    }
  }

  func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
    let data = text.data(using: .utf8) ?? Data()
    return .init(regularFileWithContents: data)
  }
}

struct BlockedProfileDataExportView: View {
  @Environment(\.modelContext) private var context

  @Query(sort: [
    SortDescriptor(\BlockedProfiles.order, order: .forward),
    SortDescriptor(\BlockedProfiles.createdAt, order: .reverse),
  ]) private
    var profiles: [BlockedProfiles]

  @State private var selectedProfileIDs: Set<UUID> = []
  @State private var sortDirection: DataExportSortDirection = .ascending
  @State private var timeZone: DataExportTimeZone = .utc

  @State private var isExportPresented: Bool = false
  @State private var exportDocument: CSVDocument = .init(text: "")
  @State private var isGenerating: Bool = false
  @State private var errorMessage: String? = nil

  var body: some View {
    NavigationStack {
      Form {
        Section(header: Text("Profiles")) {
          if profiles.isEmpty {
            Text("No profiles yet")
              .foregroundStyle(.secondary)
          } else {
            Button(action: toggleSelectAll) {
              let allSelected = selectedProfileIDs.count == profiles.count && !profiles.isEmpty
              Label(
                allSelected ? "Deselect All" : "Select All",
                systemImage: allSelected ? "checkmark.circle.fill" : "circle")
            }

            ForEach(profiles) { profile in
              HStack {
                let isSelected = selectedProfileIDs.contains(profile.id)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                Text(profile.name)
                Spacer()
              }
              .contentShape(Rectangle())
              .onTapGesture { toggleSelection(for: profile.id) }
              .accessibilityAddTraits(.isButton)
            }
          }
        }

        Section(header: Text("Options")) {
          Picker("Sort Direction", selection: $sortDirection) {
            Text("Ascending").tag(DataExportSortDirection.ascending)
            Text("Descending").tag(DataExportSortDirection.descending)
          }
          .pickerStyle(.segmented)

          Picker("Time Zone", selection: $timeZone) {
            Text("UTC").tag(DataExportTimeZone.utc)
            Text("Local").tag(DataExportTimeZone.local)
          }
          .pickerStyle(.segmented)
        }

        Section {
          Button(action: generateAndExport) {
            if isGenerating {
              ProgressView()
            } else {
              Label("Export CSV", systemImage: "square.and.arrow.up")
            }
          }
          .disabled(isGenerating)
        }
      }
      .navigationTitle("Export Data")
      .navigationBarTitleDisplayMode(.inline)
      .fileExporter(
        isPresented: $isExportPresented,
        document: exportDocument,
        contentType: .commaSeparatedText,
        defaultFilename: defaultFilename,
        onCompletion: { result in
          if case let .failure(error) = result {
            errorMessage = error.localizedDescription
          }
        }
      )
      .alert(
        "Export Error",
        isPresented: Binding(
          get: { errorMessage != nil },
          set: { if !$0 { errorMessage = nil } }
        )
      ) {
        Button("OK", role: .cancel) { errorMessage = nil }
      } message: {
        Text(errorMessage ?? "Unknown error")
      }
    }
  }

  private var defaultFilename: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
    return "foqos-sessions_\(formatter.string(from: Date()))"
  }

  private func toggleSelectAll() {
    if selectedProfileIDs.count == profiles.count {
      selectedProfileIDs.removeAll()
    } else {
      selectedProfileIDs = Set(profiles.map { $0.id })
    }
  }

  private func toggleSelection(for id: UUID) {
    if selectedProfileIDs.contains(id) {
      selectedProfileIDs.remove(id)
    } else {
      selectedProfileIDs.insert(id)
    }
  }

  private func generateAndExport() {
    isGenerating = true
    do {
      let csv = try DataExporter.exportSessionsCSV(
        forProfileIDs: Array(selectedProfileIDs),
        in: context,
        sortDirection: sortDirection,
        timeZone: timeZone
      )
      exportDocument = CSVDocument(text: csv)
      isExportPresented = true
    } catch {
      errorMessage = error.localizedDescription
    }
    isGenerating = false
  }
}

#Preview {
  BlockedProfileDataExportView()
    .modelContainer(for: [BlockedProfiles.self, BlockedProfileSession.self], inMemory: true)
}
