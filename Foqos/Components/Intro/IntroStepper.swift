import SwiftUI

struct IntroStepper: View {
  let currentStep: Int
  let totalSteps: Int
  let onNext: () -> Void
  let onBack: () -> Void
  let nextButtonTitle: String
  let showBackButton: Bool

  @State private var buttonsVisible: Bool = false
  @Environment(\.accessibilityReduceMotion) var reduceMotion

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

  // Accessibility progress label
  private var progressLabel: String {
    "Step \(currentStep + 1) of \(totalSteps)"
  }

  var body: some View {
    VStack(spacing: Spacing.md) {
      // Buttons
      HStack(spacing: Spacing.sm) {
        // Back button
        if showBackButton && currentStep > 0 {
          Button(action: onBack) {
            HStack(spacing: Spacing.xs) {
              Image(systemName: "chevron.left")
                .font(.system(size: 14, weight: .semibold))
                .accessibilityHidden(true)
              Text("Back")
                .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity)
            .frame(height: TouchTarget.comfortable)
            .background(
              RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color.gray.opacity(0.1))
            )
          }
          .accessibilityLabel("Go back to previous step")
          .accessibilityHint("Returns to step \(currentStep) of \(totalSteps)")
          .transition(.scale.combined(with: .opacity))
        }

        // Next/Continue button
        Button(action: onNext) {
          HStack(spacing: Spacing.xs) {
            Text(nextButtonTitle)
              .font(.system(size: 16, weight: .semibold))
            Image(systemName: "chevron.right")
              .font(.system(size: 14, weight: .semibold))
              .accessibilityHidden(true)
          }
          .foregroundColor(.white)
          .frame(maxWidth: .infinity)
          .frame(height: TouchTarget.comfortable)
          .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
              .fill(
                LinearGradient(
                  gradient: Gradient(colors: [Color.purple, Color.purple.opacity(0.8)]),
                  startPoint: .topLeading,
                  endPoint: .bottomTrailing
                )
              )
          )
        }
        .accessibilityLabel(nextButtonTitle)
        .accessibilityHint(currentStep < totalSteps - 1
          ? "Continues to step \(currentStep + 2) of \(totalSteps)"
          : "Completes the introduction"
        )
      }
      .opacity(buttonsVisible ? 1 : 0)
      .offset(y: buttonsVisible ? 0 : 20)
    }
    .padding(.horizontal, Spacing.lg - 4)
    .padding(.top, Spacing.xl - 2)
    .padding(.bottom, Spacing.lg - 4)
    .onAppear {
      if reduceMotion {
        buttonsVisible = true
      } else {
        withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
          buttonsVisible = true
        }
      }
    }

    // Progress dots
    HStack(spacing: Spacing.xs) {
      ForEach(0..<totalSteps, id: \.self) { index in
        Circle()
          .fill(
            index == currentStep ? Color.primary : Color.gray.opacity(0.3)
          )
          .frame(width: index == currentStep ? 10 : 8, height: index == currentStep ? 10 : 8)
          .animation(reduceMotion ? nil : .snappy, value: currentStep)
      }
    }
    .padding(.bottom, Spacing.xs)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(progressLabel)
    .accessibilityAddTraits(.updatesFrequently)
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
