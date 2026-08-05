import SwiftUI

struct MenuBarContentView: View {
  @EnvironmentObject private var controller: FoqosMacController
  @EnvironmentObject private var filterManager: FoqosFilterManager
  @EnvironmentObject private var onboardingController: FoqosOnboardingWindowController
  @EnvironmentObject private var updaterController: FoqosUpdaterController

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      statusHeader

      Divider()

      blockedDomainsSection

      Divider()

      footer
    }
    .padding(16)
    .frame(width: 360)
    .onAppear {
      filterManager.refreshStatus()
    }
  }

  private var statusHeader: some View {
    HStack(alignment: .top, spacing: 10) {
      Image(systemName: controller.isBlocking ? "hourglass.circle.fill" : "hourglass.circle")
        .font(.title)
        .foregroundStyle(controller.isBlocking ? .blue : .secondary)

      VStack(alignment: .leading, spacing: 3) {
        Text(statusTitle)
          .font(.headline)

        Text(statusDetail)
          .font(.caption)
          .foregroundStyle(.secondary)

        if !controller.isICloudAvailable {
          Text("Sign in to iCloud to receive iPhone updates.")
            .font(.caption)
            .foregroundStyle(.orange)
        }
      }

      Spacer()

      Button {
        controller.refreshFromCloud()
        filterManager.refreshStatus()
      } label: {
        Image(systemName: "arrow.clockwise")
      }
      .buttonStyle(.borderless)
      .help("Refresh Foqos status")
      .accessibilityLabel("Refresh Foqos status")

      Button {
        updaterController.checkForUpdates()
      } label: {
        Image(systemName: "arrow.down.circle")
      }
      .buttonStyle(.borderless)
      .disabled(!updaterController.isConfigured)
      .help(updaterHelpText)
      .accessibilityLabel("Check for updates")

      Button {
        controller.quit()
      } label: {
        Image(systemName: "power")
      }
      .buttonStyle(.borderless)
      .help("Quit Foqos")
      .accessibilityLabel("Quit Foqos")
    }
  }

  private var blockedDomainsSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Blocked Websites")
        .font(.subheadline.weight(.semibold))

      if controller.activeDomains.isEmpty {
        Text(emptyDomainMessage)
          .font(.caption)
          .foregroundStyle(.secondary)
      } else {
        ForEach(controller.activeDomains, id: \.self) { domain in
          Label(domain, systemImage: "globe")
            .lineLimit(1)
        }
      }
    }
  }

  private var footer: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(alignment: .top, spacing: 9) {
        Image(systemName: filterStatusSymbol)
          .foregroundStyle(filterStatusColor)
          .accessibilityHidden(true)

        VStack(alignment: .leading, spacing: 2) {
          Text(filterStatusTitle)
            .font(.caption.weight(.semibold))

          if filterManager.status != .enabled {
            Text(filterManager.statusText)
              .font(.caption2)
              .foregroundStyle(.secondary)
              .fixedSize(horizontal: false, vertical: true)
          }
        }

        Spacer(minLength: 8)

        if showsSetupButton {
          Button(setupButtonTitle) {
            onboardingController.show()
          }
        }
      }

    }
  }

  private var updaterHelpText: String {
    if updaterController.isConfigured {
      return "Check GitHub Releases for a newer version of Foqos"
    }

    return "The Sparkle appcast and signing key have not been configured yet"
  }

  private var statusTitle: String {
    if controller.isAllowModeActive {
      return "Allow mode isn't supported on Mac"
    }

    if controller.isBlocking {
      return "\(controller.syncedRecord?.profileName ?? "Foqos") is active"
    }

    switch controller.syncedRecord?.state {
    case .active:
      return "Profile has no explicit website rules"
    case .breakActive:
      return "Foqos break is active"
    case .paused:
      return "Foqos is paused"
    default:
      return "No active Foqos profile"
    }
  }

  private var statusDetail: String {
    guard let record = controller.syncedRecord else {
      return "Waiting for an iPhone update"
    }

    return "Updated \(record.updatedAt.formatted(date: .abbreviated, time: .shortened))"
  }

  private var filterStatusSymbol: String {
    switch filterManager.status {
    case .enabled:
      return "checkmark.circle.fill"
    case .failed:
      return "xmark.circle.fill"
    case .installing:
      return "arrow.triangle.2.circlepath.circle.fill"
    case .requiresRestart:
      return "arrow.clockwise.circle.fill"
    default:
      return "exclamationmark.circle.fill"
    }
  }

  private var filterStatusTitle: String {
    switch filterManager.status {
    case .approvalRequired:
      return "Approval required"
    case .disabled:
      return "Website blocking is off"
    case .enabled:
      return "Website blocking is ready"
    case .failed:
      return "Website blocking error"
    case .installing:
      return "Setting up website blocking"
    case .notConfigured:
      return "Website blocking needs setup"
    case .requiresRestart:
      return "Restart required"
    case .unknown:
      return "Checking website blocking"
    }
  }

  private var showsSetupButton: Bool {
    switch filterManager.status {
    case .approvalRequired, .disabled, .failed, .notConfigured:
      return true
    default:
      return false
    }
  }

  private var setupButtonTitle: String {
    switch filterManager.status {
    case .approvalRequired:
      return "Approve"
    case .disabled:
      return "Enable"
    default:
      return "Set Up"
    }
  }

  private var filterStatusColor: Color {
    switch filterManager.status {
    case .enabled:
      return .green
    case .failed:
      return .red
    case .installing:
      return .blue
    default:
      return .orange
    }
  }

  private var emptyDomainMessage: String {
    "No blocked websites are active."
  }
}

#Preview {
  let filterManager = FoqosFilterManager()
  let onboardingController = FoqosOnboardingWindowController(filterManager: filterManager)

  MenuBarContentView()
    .environmentObject(FoqosMacController(filterManager: filterManager))
    .environmentObject(filterManager)
    .environmentObject(onboardingController)
    .environmentObject(FoqosUpdaterController())
}
