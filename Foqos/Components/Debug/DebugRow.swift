import SwiftUI

struct DebugRow: View {
  let label: String
  let value: String

  var body: some View {
    HStack(alignment: .top) {
      Text(label + ":")
        .font(.caption)
        .foregroundColor(.secondary)
        .frame(width: 160, alignment: .leading)

      Text(value)
        .font(.caption.monospaced())
        .foregroundColor(.primary)
        .textSelection(.enabled)

      Spacer()
    }
  }
}

#Preview {
  DebugRow(label: "Session ID", value: "ABC123-DEF456")
    .padding()
}

#Preview("Long Value") {
  DebugRow(
    label: "Profile ID",
    value: "550e8400-e29b-41d4-a716-446655440000"
  )
  .padding()
}

#Preview("Boolean Value") {
  VStack(spacing: 8) {
    DebugRow(label: "Is Active", value: "true")
    DebugRow(label: "Is Break Available", value: "false")
  }
  .padding()
}
