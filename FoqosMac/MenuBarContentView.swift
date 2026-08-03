import SwiftUI

struct MenuBarContentView: View {
  @EnvironmentObject private var controller: FoqosMacController
  @EnvironmentObject private var filterManager: FoqosFilterManager

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      statusHeader

      Divider()

      filterSection

      Divider()

      blockedDomainsSection

      Divider()

      HStack {
        Button("Refresh iCloud") {
          controller.refreshFromCloud()
        }

        Spacer()

        Button("Quit Foqos") {
          controller.quit()
        }
      }
    }
    .padding(16)
    .frame(width: 360)
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
    }
  }

  private var filterSection: some View {
    VStack(alignment: .leading, spacing: 10) {
      Toggle("Enable website blocking", isOn: $controller.enableMacBlocking)

      HStack {
        Image(systemName: filterStatusSymbol)
          .foregroundStyle(filterStatusColor)

        Text(filterManager.statusText)
          .font(.caption)

        Spacer()

        Button("Install or Enable") {
          filterManager.installAndEnable()
        }
        .disabled(filterManager.status == .installing)
      }

      Toggle("Test blocking locally", isOn: $controller.enableLocalTest)
        .help("Tests one domain without waiting for an iPhone session.")

      if controller.enableLocalTest {
        TextField("youtube.com", text: $controller.localTestDomain)
          .textFieldStyle(.roundedBorder)
      }
    }
  }

  private var blockedDomainsSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(controller.activeMode == .allowOnly ? "Allowed Websites" : "Blocked Websites")
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

  private var statusTitle: String {
    if controller.isBlocking {
      return controller.enableLocalTest
        ? "Local website test is active"
        : "\(controller.syncedRecord?.profileName ?? "Foqos") is active"
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
    filterManager.status == .enabled ? "checkmark.circle.fill" : "exclamationmark.circle"
  }

  private var filterStatusColor: Color {
    filterManager.status == .enabled ? .green : .orange
  }

  private var emptyDomainMessage: String {
    controller.activeMode == .allowOnly
      ? "No domains are allowed; all hostname-based flows are blocked."
      : "No explicit domains are active."
  }
}

#Preview {
  let filterManager = FoqosFilterManager()

  MenuBarContentView()
    .environmentObject(FoqosMacController(filterManager: filterManager))
    .environmentObject(filterManager)
}
