import SwiftData
import SwiftUI

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

  private var isExportDisabled: Bool {
    isGenerating || selectedProfileIDs.isEmpty
  }

  private var defaultFilename: String {
    let timestamp = Int(Date().timeIntervalSince1970)
    return "foqos_sessions_\(timestamp)"
  }

  var body: some View {
    NavigationStack {
      Form {
        Section(header: Text("Profiles")) {
          if profiles.isEmpty {
            Text("No profiles yet")
              .foregroundStyle(.secondary)
          } else {
            ForEach(profiles) { profile in
              let isSelected = selectedProfileIDs.contains(profile.id)
              HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                  .foregroundStyle(isSelected ? .green : .secondary)
                Text(profile.name)
                Spacer()
              }
              .contentShape(Rectangle())
              .onTapGesture { toggleSelection(for: profile.id) }
              .accessibilityAddTraits(.isButton)
            }
          }
        }

        Section(
          header: Text("Sorting"),
          footer: Text("Controls the order of sessions in the CSV based on their start time.")
        ) {
          Picker("Sort order", selection: $sortDirection) {
            Text("Ascending (oldest first)").tag(DataExportSortDirection.ascending)
            Text("Descending (newest first)").tag(DataExportSortDirection.descending)
          }
          .pickerStyle(.menu)
        }

        Section(
          header: Text("Date & Time"),
          footer: Text(
            "Choose how timestamps are exported. UTC is portable across tools. Local uses your device's time zone. All timestamps use ISO 8601."
          )
        ) {
          Picker("Time zone", selection: $timeZone) {
            Text("UTC").tag(DataExportTimeZone.utc)
            Text("Local").tag(DataExportTimeZone.local)
          }
          .pickerStyle(.menu)
        }

        ActionButton(
          title: "Export as CSV",
          backgroundColor: .blue,
          isLoading: isGenerating,
          isDisabled: isExportDisabled
        ) {
          generateAndExport()
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
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
