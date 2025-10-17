import SwiftUI

struct IntroStepper: View {
  let currentStep: Int
  let totalSteps: Int
  let onNext: () -> Void
  let onBack: () -> Void
  let nextButtonTitle: String
  let showBackButton: Bool

  @State private var buttonsVisible: Bool = false

  init(
    currentStep: Int,
    totalSteps: Int,
    onNext: @escaping () -> Void,
    onBack: @escaping () -> Void,
    nextButtonTitle: String = "Next",
    showBackButton: Bool = true
  ) {
    self.currentStep = currentStep
    self.totalSteps = totalSteps
    self.onNext = onNext
    self.onBack = onBack
    self.nextButtonTitle = nextButtonTitle
    self.showBackButton = showBackButton
  }

  var body: some View {
    VStack(spacing: 16) {
      // Buttons
      HStack(spacing: 12) {
        // Back button
        if showBackButton && currentStep > 0 {
          Button(action: onBack) {
            HStack {
              Image(systemName: "chevron.left")
                .font(.system(size: 14, weight: .semibold))
              Text("Back")
                .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
              RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
            )
          }
          .transition(.scale.combined(with: .opacity))
        }

        // Next/Continue button
        Button(action: onNext) {
          HStack {
            Text(nextButtonTitle)
              .font(.system(size: 16, weight: .semibold))
            Image(systemName: "chevron.right")
              .font(.system(size: 14, weight: .semibold))
          }
          .foregroundColor(.white)
          .frame(maxWidth: .infinity)
          .frame(height: 50)
          .background(
            RoundedRectangle(cornerRadius: 12)
              .fill(
                LinearGradient(
                  gradient: Gradient(colors: [Color.purple, Color.purple.opacity(0.8)]),
                  startPoint: .topLeading,
                  endPoint: .bottomTrailing
                )
              )
          )
        }
      }
      .opacity(buttonsVisible ? 1 : 0)
      .offset(y: buttonsVisible ? 0 : 20)
    }
    .padding(.horizontal, 20)
    .padding(.top, 30)
    .padding(.bottom, 20)
    .onAppear {
      withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
        buttonsVisible = true
      }
    }

    // Progress dots
    HStack(spacing: 8) {
      ForEach(0..<totalSteps, id: \.self) { index in
        Circle()
          .fill(
            index == currentStep ? Color.primary : Color.gray.opacity(0.3)
          )
          .frame(width: index == currentStep ? 10 : 8, height: index == currentStep ? 10 : 8)
          .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentStep)
      }
    }
    .padding(.bottom, 8)
  }
}

#Preview {
  VStack {
    Spacer()

    IntroStepper(
      currentStep: 0,
      totalSteps: 3,
      onNext: { print("Next") },
      onBack: { print("Back") },
      nextButtonTitle: "Next",
      showBackButton: true
    )
  }
  .background(Color(.systemBackground))
}
