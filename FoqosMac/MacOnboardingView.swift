import AppKit
import SwiftUI

struct MacOnboardingView: View {
  @EnvironmentObject private var filterManager: FoqosFilterManager

  let onComplete: () -> Void
  let onDismiss: () -> Void

  var body: some View {
    VStack(spacing: 0) {
      Spacer(minLength: 8)

      Image("FoqosStickerLogo")
        .resizable()
        .scaledToFit()
        .frame(width: 180, height: 180)
        .shadow(color: Color.black.opacity(0.1), radius: 16, y: 10)
        .accessibilityLabel("Foqos hourglass")

      Spacer(minLength: 30)

      VStack(spacing: 0) {
        SetupProgressRow(
          title: "Install the website filter",
          symbol: "puzzlepiece.extension",
          state: installationStepState
        )

        Divider()
          .padding(.leading, 42)

        SetupProgressRow(
          title: "Approve Foqos in System Settings",
          symbol: "checkmark.shield",
          state: approvalStepState
        )

        Divider()
          .padding(.leading, 42)

        SetupProgressRow(
          title: "Ready for focused sessions",
          symbol: "sparkles",
          state: readyStepState
        )
      }
      .frame(maxWidth: 390)

      Spacer(minLength: 30)

      Button(action: handlePrimaryAction) {
        HStack(spacing: 8) {
          if isWorking {
            ProgressView()
              .controlSize(.small)
          } else {
            Image(systemName: primaryButtonSymbol)
          }

          Text(primaryButtonTitle)
        }
        .frame(maxWidth: .infinity)
      }
      .buttonStyle(.borderedProminent)
      .controlSize(.large)
      .tint(filterManager.status == .enabled ? .green : .indigo)
      .disabled(isWorking)
      .frame(maxWidth: 390)
    }
    .padding(.horizontal, 48)
    .padding(.vertical, 38)
    .frame(minWidth: 480, maxWidth: .infinity, minHeight: 500, maxHeight: .infinity)
    .background {
      Color.white
        .ignoresSafeArea()
    }
    .preferredColorScheme(.light)
    .onAppear {
      filterManager.refreshStatus()
    }
    .onReceive(
      NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
    ) { _ in
      filterManager.refreshStatus()
    }
  }

  private var installationStepState: SetupProgressRow.State {
    switch filterManager.status {
    case .approvalRequired, .disabled, .enabled, .requiresRestart:
      return .complete
    case .installing:
      return .active
    case .failed, .notConfigured:
      return .active
    case .unknown:
      return .pending
    }
  }

  private var approvalStepState: SetupProgressRow.State {
    switch filterManager.status {
    case .approvalRequired, .disabled:
      return .active
    case .enabled, .requiresRestart:
      return .complete
    case .failed, .installing, .notConfigured, .unknown:
      return .pending
    }
  }

  private var readyStepState: SetupProgressRow.State {
    filterManager.status == .enabled ? .complete : .pending
  }

  private var isWorking: Bool {
    filterManager.status == .installing || filterManager.status == .unknown
  }

  private var primaryButtonTitle: String {
    switch filterManager.status {
    case .approvalRequired:
      return "Open System Settings"
    case .enabled:
      return "Complete"
    case .failed:
      return "Try Again"
    case .installing:
      return "Completing Setup…"
    case .requiresRestart:
      return "Restart to Complete"
    case .disabled, .notConfigured:
      return "Complete Setup"
    case .unknown:
      return "Checking…"
    }
  }

  private var primaryButtonSymbol: String {
    switch filterManager.status {
    case .approvalRequired:
      return "gear"
    case .enabled:
      return "checkmark"
    case .requiresRestart:
      return "arrow.clockwise"
    default:
      return "arrow.right"
    }
  }

  private func handlePrimaryAction() {
    switch filterManager.status {
    case .approvalRequired:
      openSystemSettings()
    case .disabled, .failed, .notConfigured:
      filterManager.installAndEnable()
    case .enabled:
      onComplete()
    case .requiresRestart:
      onDismiss()
    case .installing, .unknown:
      break
    }
  }

  private func openSystemSettings() {
    let settingsURL = URL(fileURLWithPath: "/System/Applications/System Settings.app")
    NSWorkspace.shared.open(settingsURL)
  }
}

private struct SetupProgressRow: View {
  enum State {
    case active
    case complete
    case pending
  }

  let title: String
  let symbol: String
  let state: State

  var body: some View {
    HStack(spacing: 14) {
      Image(systemName: state == .complete ? "checkmark.circle.fill" : symbol)
        .font(.system(size: 18, weight: .semibold))
        .foregroundStyle(symbolColor)
        .frame(width: 22)

      Text(title)
        .font(.body.weight(state == .active ? .semibold : .regular))
        .foregroundStyle(state == .pending ? Color.secondary : Color.primary)

      Spacer()
    }
    .padding(.vertical, 16)
  }

  private var symbolColor: Color {
    switch state {
    case .active:
      return .indigo
    case .complete:
      return .green
    case .pending:
      return Color(nsColor: .tertiaryLabelColor)
    }
  }
}

#Preview("Onboarding") {
  MacOnboardingView(onComplete: {}, onDismiss: {})
    .environmentObject(FoqosFilterManager())
    .frame(width: 520, height: 540)
}
