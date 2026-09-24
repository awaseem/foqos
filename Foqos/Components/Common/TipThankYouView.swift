import SwiftUI

struct TipThankYouView: View {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  @State private var isPulsing = false
  @State private var isTextVisible = false

  var body: some View {
    VStack(spacing: 28) {
      Image(systemName: "heart.fill")
        .font(.system(size: 88))
        .foregroundStyle(.pink)
        .scaleEffect(isPulsing && !reduceMotion ? 1.12 : 1)
        .animation(
          reduceMotion ? nil : .easeInOut(duration: 0.55).repeatForever(autoreverses: true),
          value: isPulsing
        )
        .accessibilityHidden(true)

      VStack(spacing: 12) {
        Text("Thank you so much!")
          .font(.title2.bold())

        Text("Your support means a lot and helps keep Foqos going.")
          .font(.body)
          .foregroundStyle(.secondary)
      }
      .multilineTextAlignment(.center)
      .opacity(isTextVisible || reduceMotion ? 1 : 0)
      .offset(y: isTextVisible || reduceMotion ? 0 : 20)
      .animation(
        reduceMotion ? nil : .easeOut(duration: 0.5).delay(0.15),
        value: isTextVisible
      )
    }
    .padding(32)
    .frame(maxWidth: 420)
    .accessibilityElement(children: .combine)
    .onAppear {
      isPulsing = true
      isTextVisible = true
    }
  }
}

#Preview("Thank you") {
  TipThankYouView()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
}

#Preview("Dark") {
  TipThankYouView()
    .preferredColorScheme(.dark)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
}
