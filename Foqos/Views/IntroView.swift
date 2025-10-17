import SwiftUI

struct IntroView: View {
  let onRequestAuthorization: () -> Void

  var body: some View {
    AnimatedIntroContainer(
      onRequestAuthorization: onRequestAuthorization
    )
  }
}

#Preview {
  IntroView {
    print("Request authorization tapped")
  }
}
