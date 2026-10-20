import AppKit
import Combine
import UniformTypeIdentifiers

@MainActor
final class DiagnosticsExportController: ObservableObject {
  static let shared = DiagnosticsExportController()

  @Published private(set) var isWorking = false
  @Published private(set) var buttonTitle = "Export Diagnostics…"

  private var exportTask: Task<Void, Never>?
  private var savePanel: NSSavePanel?

  func export() {
    if let savePanel {
      NSApplication.shared.activate(ignoringOtherApps: true)
      savePanel.makeKeyAndOrderFront(nil)
      return
    }
    guard exportTask == nil else { return }

    isWorking = true
    buttonTitle = "Preparing Diagnostics…"
    exportTask = Task { @MainActor in
      defer {
        savePanel = nil
        exportTask = nil
        isWorking = false
        buttonTitle = "Export Diagnostics…"
      }
      let diagnostics = MacDiagnostics.shared
      diagnostics.record("diagnostics.export_requested", "Preparing a local diagnostic archive.")
      do {
        let data = try await diagnostics.exportArchive()
        let panel = NSSavePanel()
        panel.title = "Export Foqos Diagnostics"
        panel.message = "Save setup and sync diagnostics to share with Foqos support."
        panel.allowedContentTypes = [.zip]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue =
          "Foqos-Diagnostics-\(Date().formatted(.iso8601.year().month().day())).zip"
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        savePanel = panel
        isWorking = false
        buttonTitle = "Export Diagnostics…"

        // The menu-bar popover is transient. Keep this panel independent of its view/window.
        NSApplication.shared.activate(ignoringOtherApps: true)
        diagnostics.record(
          "diagnostics.destination_requested", "Showing the diagnostic archive save panel.")
        let response = await panel.begin()
        savePanel = nil
        guard response == .OK, let url = panel.url else {
          diagnostics.record(
            "diagnostics.export_cancelled", "User cancelled the diagnostic export.")
          return
        }

        isWorking = true
        buttonTitle = "Saving Diagnostics…"
        let hasAccess = url.startAccessingSecurityScopedResource()
        defer { if hasAccess { url.stopAccessingSecurityScopedResource() } }
        try await Task.detached(priority: .utility) {
          try data.write(to: url, options: .atomic)
        }.value
        diagnostics.record("diagnostics.export_saved", "User saved a diagnostic archive.")
      } catch {
        diagnostics.record(
          "diagnostics.export_failed", "Unable to prepare or save the diagnostic archive.",
          level: .error, fields: MacDiagnostics.errorFields(error)
        )
        let alert = NSAlert()
        alert.messageText = "Unable to Export Diagnostics"
        alert.informativeText =
          "The diagnostics could not be saved. Check available disk space or try another location."
        alert.addButton(withTitle: "OK")
        NSApplication.shared.activate(ignoringOtherApps: true)
        alert.runModal()
      }
    }
  }
}
