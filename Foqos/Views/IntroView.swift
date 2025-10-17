import SwiftUI

struct IntroView: View {
  let onRequestAuthorization: () -> Void

  var body: some View {
    AnimatedIntroContainer(
      onRequestAuthorization: onRequestAuthorization,
      onComplete: {
        // This callback is currently not used but required by AnimatedIntroContainer
        // Could be used for future enhancements like tracking completion events
      }
    )
  }
}

#Preview {
  IntroView {
    print("Request authorization tapped")
  }
}
