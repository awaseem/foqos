import SwiftUI

struct ProfileRow: View {
  let profile: BlockedProfiles
  let isActive: Bool

  init(profile: BlockedProfiles, isActive: Bool = false) {
    self.profile = profile
    self.isActive = isActive
  }

  var body: some View {
    ProfileSummaryContent(
      profile: profile,
      isActive: isActive,
      metadata: .appsAndDomains,
      showsStatusLine: false,
      layout: .compact
    )
  }
}

#Preview {
  let previewProfile = BlockedProfiles(
    name: "⌛ School Hours",
    createdAt: Date(),
    updatedAt: Date().addingTimeInterval(-3600)
  )

  return ProfileRow(profile: previewProfile)
    .padding()
    .environmentObject(ThemeManager.shared)
}
