import SwiftUI

struct HomeDashboardLayout<Profiles: View, Insights: View>: View {
  @Binding private var preferredCompactColumn: NavigationSplitViewColumn

  private let insights: Insights
  private let profiles: Profiles

  init(
    preferredCompactColumn: Binding<NavigationSplitViewColumn>,
    @ViewBuilder profiles: () -> Profiles,
    @ViewBuilder insights: () -> Insights
  ) {
    _preferredCompactColumn = preferredCompactColumn
    self.insights = insights()
    self.profiles = profiles()
  }

  var body: some View {
    NavigationSplitView(preferredCompactColumn: $preferredCompactColumn) {
      profiles
    } detail: {
      insights
    }
    .navigationSplitViewStyle(.balanced)
  }
}

#Preview {
  @Previewable @State var preferredColumn: NavigationSplitViewColumn = .sidebar

  HomeDashboardLayout(preferredCompactColumn: $preferredColumn) {
    List {
      Button("Deep Work") { preferredColumn = .detail }
    }
    .navigationTitle("Profiles")
  } insights: {
    Text("Deep Work Insights")
      .navigationTitle("Insights")
  }
}
