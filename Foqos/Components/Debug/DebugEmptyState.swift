import SwiftUI

struct DebugEmptyState: View {
  var body: some View {
    VStack(spacing: 16) {
      Image(systemName: "exclamationmark.triangle")
        .font(.system(size: 48))
        .foregroundColor(.orange)

      Text("No Active Profile")
        .font(.headline)

      Text("Start a profile to see debug information")
        .font(.subheadline)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity)
    .padding(.top, 100)
  }
}

#Preview {
  DebugEmptyState()
}
