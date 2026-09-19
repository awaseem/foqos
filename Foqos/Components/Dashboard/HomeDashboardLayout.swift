import SwiftUI

struct HomeDashboardLayout<Profiles: View, Insights: View>: View {
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  @Binding private var preferredCompactColumn: NavigationSplitViewColumn

  private let insights: Insights
  private let profiles: (Bool) -> Profiles

  init(
    preferredCompactColumn: Binding<NavigationSplitViewColumn>,
    @ViewBuilder profiles: @escaping (Bool) -> Profiles,
    @ViewBuilder insights: () -> Insights
  ) {
    _preferredCompactColumn = preferredCompactColumn
    self.insights = insights()
    self.profiles = profiles
  }

  var body: some View {
    GeometryReader { geometry in
      let showsProfileInsights =
        horizontalSizeClass == .regular && geometry.size.width > geometry.size.height

      if showsProfileInsights {
        NavigationSplitView(preferredCompactColumn: $preferredCompactColumn) {
          profiles(true)
            .background {
              Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()
            }
            .overlay(alignment: .trailing) {
              Rectangle()
                .fill(.primary.opacity(0.35))
                .frame(width: 2)
                .ignoresSafeArea(edges: .vertical)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }
        } detail: {
          insights
        }
        .navigationSplitViewStyle(.balanced)
      } else {
        NavigationStack {
          profiles(false)
        }
      }
    }
  }
}

#Preview {
  @Previewable @State var preferredColumn: NavigationSplitViewColumn = .sidebar

  HomeDashboardLayout(preferredCompactColumn: $preferredColumn) { _ in
    List {
      Button("Deep Work") { preferredColumn = .detail }
    }
    .navigationTitle("Profiles")
  } insights: {
    Text("Deep Work Insights")
      .navigationTitle("Insights")
  }
}
