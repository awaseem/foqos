import SwiftUI

struct BlockingStrategyActionView: View {
  var customView: (any View)?
  var presentationDetents: Set<PresentationDetent> = [.medium, .large]

  var body: some View {
    VStack {
      if let customViewToDisplay = customView {
        AnyView(customViewToDisplay)
      }
    }
    .presentationDetents(presentationDetents)
  }
}
