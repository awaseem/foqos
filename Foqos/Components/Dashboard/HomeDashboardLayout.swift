import SwiftUI

struct HomeDashboardLayout<Profiles: View, Insights: View>: View {
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
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
        .background {
          if horizontalSizeClass == .regular {
            Color(uiColor: .systemGroupedBackground)
              .ignoresSafeArea()
          }
        }
        .overlay(alignment: .trailing) {
          if horizontalSizeClass == .regular {
            Rectangle()
              .fill(.primary.opacity(0.35))
              .frame(width: 2)
              .ignoresSafeArea(edges: .vertical)
              .allowsHitTesting(false)
              .accessibilityHidden(true)
          }
        }
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
