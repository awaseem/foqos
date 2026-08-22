import AppKit
import ServiceManagement
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
          title: "Install the Foqos network extension",
          symbol: "puzzlepiece.extension",
          state: installationStepState
        )

        Divider()
          .padding(.leading, 42)

        SetupProgressRow(
          title: "Enable Foqos in Login Items & Extensions",
          symbol: "checkmark.shield",
          state: approvalStepState,
          detail: approvalStepDetail
        )

        Divider()
          .padding(.leading, 42)

        SetupProgressRow(
          title: "Allow network content filtering",
          symbol: "network.badge.shield.half.filled",
          state: filterStepState,
          detail: filterStepDetail
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
    .frame(minWidth: 480, maxWidth: .infinity, minHeight: 580, maxHeight: .infinity)
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
    case .approvalRequired, .configuringFilter, .disabled, .enabled, .requiresRestart:
      return .complete
    case .activatingExtension:
      return .active
    case .failed, .notConfigured:
      return .active
    case .unknown:
      return .pending
    }
  }

  private var approvalStepState: SetupProgressRow.State {
    switch filterManager.status {
    case .approvalRequired:
      return .active
    case .configuringFilter, .disabled, .enabled, .requiresRestart:
      return .complete
    case .activatingExtension, .failed, .notConfigured, .unknown:
      return .pending
    }
  }

  private var approvalStepDetail: String? {
    guard filterManager.status == .approvalRequired else {
      return nil
    }

    return """
      Choose By Category, open Network Extensions, then turn on Foqos Website Filter. Return to \
      Foqos when it is enabled.
      """
  }

  private var filterStepState: SetupProgressRow.State {
    switch filterManager.status {
    case .configuringFilter, .disabled:
      return .active
    case .enabled:
      return .complete
    case .activatingExtension, .approvalRequired, .failed, .notConfigured, .requiresRestart,
      .unknown:
      return .pending
    }
  }

  private var filterStepDetail: String? {
    guard filterManager.status == .configuringFilter else {
      return nil
    }

    return "Choose Allow in the macOS permission prompt to enable website blocking."
  }

  private var isWorking: Bool {
    switch filterManager.status {
    case .activatingExtension, .configuringFilter, .unknown:
      return true
    default:
      return false
    }
  }

  private var primaryButtonTitle: String {
    switch filterManager.status {
    case .activatingExtension:
      return "Installing Extension…"
    case .approvalRequired:
      return "Open Login Items & Extensions"
    case .configuringFilter:
      return "Waiting for Permission…"
    case .enabled:
      return "Complete"
    case .failed:
      return "Try Again"
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
      SMAppService.openSystemSettingsLoginItems()
    case .disabled, .failed, .notConfigured:
      filterManager.installAndEnable()
    case .enabled:
      onComplete()
    case .requiresRestart:
      onDismiss()
    case .activatingExtension, .configuringFilter, .unknown:
      break
    }
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
  var detail: String? = nil

  var body: some View {
    HStack(spacing: 14) {
      Image(systemName: state == .complete ? "checkmark.circle.fill" : symbol)
        .font(.system(size: 18, weight: .semibold))
        .foregroundStyle(symbolColor)
        .frame(width: 22)

      VStack(alignment: .leading, spacing: 5) {
        Text(title)
          .font(.body.weight(state == .active ? .semibold : .regular))
          .foregroundStyle(state == .pending ? Color.secondary : Color.primary)

        if let detail {
          Text(detail)
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
      }

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
    .frame(width: 520, height: 620)
}
