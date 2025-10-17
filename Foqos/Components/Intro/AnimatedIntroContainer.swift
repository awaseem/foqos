import SwiftUI

struct AnimatedIntroContainer: View {
  @State private var currentStep: Int = 0
  let onRequestAuthorization: () -> Void
  let onComplete: () -> Void

  private let totalSteps = 3

  var body: some View {
    VStack(spacing: 0) {
      // Content area
      Group {
        switch currentStep {
        case 0:
          WelcomeIntroScreen()
        case 1:
          FeaturesIntroScreen()
        case 2:
          PermissionsIntroScreen()
        default:
          WelcomeIntroScreen()
        }
      }
      .transition(
        .asymmetric(
          insertion: .move(edge: .trailing).combined(with: .opacity),
          removal: .move(edge: .leading).combined(with: .opacity)
        )
      )
      .animation(.easeInOut(duration: 0.3), value: currentStep)

      // Stepper
      IntroStepper(
        currentStep: currentStep,
        totalSteps: totalSteps,
        onNext: handleNext,
        onBack: handleBack,
        nextButtonTitle: getNextButtonTitle(),
        showBackButton: currentStep > 0
      )
      .animation(.easeInOut, value: currentStep)
    }
    .padding(.top, 10)
  }

  private func handleNext() {
    if currentStep < totalSteps - 1 {
      withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
        currentStep += 1
      }
    } else {
      // Last step - request authorization
      onRequestAuthorization()
    }
  }

  private func handleBack() {
    if currentStep > 0 {
      withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
        currentStep -= 1
      }
    }
  }

  private func getNextButtonTitle() -> String {
    switch currentStep {
    case totalSteps - 1:
      return "Allow Screen Time Access"
    default:
      return "Continue"
    }
  }
}

#Preview {
  AnimatedIntroContainer(
    onRequestAuthorization: {
      print("Request authorization")
    },
    onComplete: {
      print("Complete")
    }
  )
}
