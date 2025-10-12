import FamilyControls
import SwiftUI

struct ProfileStatsRow: View {
  let selectedActivity: FamilyActivitySelection
  let sessionCount: Int
  let domainsCount: Int

  var body: some View {
    HStack(spacing: 16) {
      // Apps count
      VStack(alignment: .leading, spacing: 2) {
        Text("Apps & Categories")
          .font(.caption)
          .foregroundColor(.secondary)

        Text(
          "\(FamilyActivityUtil.countSelectedActivities(selectedActivity))"
        )
        .font(.subheadline)
        .fontWeight(.semibold)
      }

      Divider()
        .frame(height: 24)

      VStack(alignment: .leading, spacing: 2) {
        Text("Domains")
          .font(.caption)
          .foregroundColor(.secondary)

        Text(
          "\(domainsCount)"
        )
        .font(.subheadline)
        .fontWeight(.semibold)
      }

      Divider()
        .frame(height: 24)

      // Active sessions
      VStack(alignment: .leading, spacing: 2) {
        Text("Total Sessions")
          .font(.caption)
          .foregroundColor(.secondary)

        Text(
          sessionCount.description
            .localizedLowercase
        )
        .font(.subheadline)
        .fontWeight(.semibold)
      }
    }
  }
}

#Preview {
  ProfileStatsRow(
    selectedActivity: FamilyActivitySelection(),
    sessionCount: 12,
    domainsCount: 12
  )
  .padding()
  .background(Color(.systemGroupedBackground))
}
