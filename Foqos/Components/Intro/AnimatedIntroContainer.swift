import SwiftUI

struct AnimatedIntroContainer: View {
  @State private var currentStep: Int = 0
  @State private var showPasscodeMessage: Bool = false
  @State private var authorizationRequested: Bool = false
  let onRequestAuthorization: () -> Void

  private let totalSteps = 3
  private let passcodeMessageDelay: TimeInterval = 3.0

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
          PermissionsIntroScreen(showPasscodeMessage: showPasscodeMessage)
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
      authorizationRequested = true
      showPasscodeMessage = false
      onRequestAuthorization()

      // Show passcode message after delay if still on this screen
      DispatchQueue.main.asyncAfter(deadline: .now() + passcodeMessageDelay) {
        if authorizationRequested && currentStep == totalSteps - 1 {
          withAnimation {
            showPasscodeMessage = true
          }
        }
      }
    }
  }

  private func handleBack() {
    if currentStep > 0 {
      withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
        currentStep -= 1
        // Reset authorization state when navigating back
        if currentStep < totalSteps - 1 {
          authorizationRequested = false
          showPasscodeMessage = false
        }
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
    }
  )
}
