import SwiftUI

struct HomeDashboardLayout<Insights: View, Profiles: View>: View {
  private let insights: Insights
  private let profiles: Profiles

  init(
    @ViewBuilder insights: () -> Insights,
    @ViewBuilder profiles: () -> Profiles
  ) {
    self.insights = insights()
    self.profiles = profiles()
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 30) {
      insights
      profiles
    }
  }
}

#Preview {
  HomeDashboardLayout {
    Text("Activity")
      .frame(maxWidth: .infinity, minHeight: 200)
      .background(.quaternary, in: RoundedRectangle(cornerRadius: 24))
  } profiles: {
    Text("Profiles")
      .frame(maxWidth: .infinity, minHeight: 160)
      .background(.quaternary, in: RoundedRectangle(cornerRadius: 20))
  }
  .padding(16)
}
