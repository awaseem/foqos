import SwiftUI

struct DebugSection<Content: View>: View {
  let title: String
  let content: Content

  init(title: String, @ViewBuilder content: () -> Content) {
    self.title = title
    self.content = content()
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(title)
        .font(.headline.monospaced())
        .foregroundColor(.primary)

      VStack(alignment: .leading, spacing: 8) {
        content
      }
      .padding(.vertical, 12)
    }
  }
}

#Preview {
  DebugSection(title: "Session Information") {
    DebugRow(label: "Session ID", value: "ABC123-DEF456")
    DebugRow(label: "Is Active", value: "true")
    DebugRow(label: "Duration", value: "1h 23m 45s")
  }
  .padding()
}

#Preview("Multiple Sections") {
  ScrollView {
    VStack(spacing: 16) {
      DebugSection(title: "Profile Details") {
        DebugRow(label: "Name", value: "Work Focus")
        DebugRow(label: "Strategy", value: "NFC")
      }

      DebugSection(title: "Session Status") {
        DebugRow(label: "Is Active", value: "true")
        DebugRow(label: "Elapsed Time", value: "45m 12s")
      }
    }
    .padding()
  }
}
