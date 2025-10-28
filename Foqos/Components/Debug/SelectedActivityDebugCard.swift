import FamilyControls
import SwiftUI

struct SelectedActivityDebugCard: View {
  let selection: FamilyActivitySelection

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      // Counts
      Group {
        DebugRow(label: "Applications Count", value: "\(selection.applications.count)")
        DebugRow(label: "Categories Count", value: "\(selection.categories.count)")
        DebugRow(label: "Web Domains Count", value: "\(selection.webDomains.count)")
      }

      // Applications Detail
      if !selection.applications.isEmpty {
        Divider()
        VStack(alignment: .leading, spacing: 4) {
          Text("Applications:")
            .font(.caption)
            .foregroundColor(.secondary)
          Text("\(selection.applications.count) app(s) selected")
            .font(.caption)
            .foregroundColor(.primary)
        }
      }

      // Categories Detail
      if !selection.categories.isEmpty {
        Divider()
        VStack(alignment: .leading, spacing: 4) {
          Text("Categories:")
            .font(.caption)
            .foregroundColor(.secondary)
          Text("\(selection.categories.count) category(ies) selected")
            .font(.caption)
            .foregroundColor(.primary)
        }
      }

      // Web Domains Detail
      if !selection.webDomains.isEmpty {
        Divider()
        VStack(alignment: .leading, spacing: 4) {
          Text("Web Domains:")
            .font(.caption)
            .foregroundColor(.secondary)
          Text("\(selection.webDomains.count) domain(s) selected")
            .font(.caption)
            .foregroundColor(.primary)
        }
      }
    }
  }
}

#Preview {
  SelectedActivityDebugCard(selection: FamilyActivitySelection())
    .padding()
}
