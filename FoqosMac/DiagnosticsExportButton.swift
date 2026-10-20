import SwiftUI

struct DiagnosticsExportButton: View {
  var isMenuItem = false

  @ObservedObject private var exporter = DiagnosticsExportController.shared

  var body: some View {
    Group {
      if isMenuItem {
        MenuActionItem(
          title: exporter.buttonTitle, isEnabled: !exporter.isWorking, action: exporter.export
        )
      } else {
        Button(exporter.buttonTitle, action: exporter.export)
          .disabled(exporter.isWorking)
      }
    }
    .help(
      "Save setup and sync diagnostics to share with Foqos support. No website or profile names are included."
    )
  }
}

#Preview {
  DiagnosticsExportButton()
}
