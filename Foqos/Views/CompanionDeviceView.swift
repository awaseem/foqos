import CoreBluetooth
import SwiftData
import SwiftUI

struct CompanionDeviceView: View {
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject var themeManager: ThemeManager
  @EnvironmentObject var companionDeviceManager: CompanionDeviceManager

  @Query(sort: \BlockedProfiles.order) private var profiles: [BlockedProfiles]

  // Mirrored from CompanionDeviceManager so the view re-renders on changes.
  @AppStorage(CompanionDeviceDefaults.enabledKey) private var isEnabled: Bool = false
  @AppStorage(CompanionDeviceDefaults.identifierKey) private var pairedIdentifier: String = ""
  @AppStorage(CompanionDeviceDefaults.nameKey) private var pairedDeviceName: String = ""
  @AppStorage(CompanionDeviceDefaults.profileIdKey) private var tagProfileId: String = ""

  @State private var showUnpairAlert = false

  private var isPaired: Bool {
    return !pairedIdentifier.isEmpty
  }

  var body: some View {
    NavigationStack {
      Form {
        Section {
          HStack {
            Image(systemName: "sensor.tag.radiowaves.forward.fill")
              .foregroundStyle(themeManager.themeColor)
              .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
              Text("Companion Device")
                .font(.headline)
              Text(
                "Show live session status on a companion device and toggle sessions with its NFC tag"
              )
              .font(.caption)
              .foregroundStyle(.secondary)
            }
          }
          .padding(.vertical, 8)

          Toggle("Enable Companion Device", isOn: $isEnabled)
            .onChange(of: isEnabled) { _, enabled in
              companionDeviceManager.setEnabled(enabled)
            }
        }

        if isEnabled {
          if isPaired {
            pairedSection
          } else {
            scanningSection
          }
        }
      }
      .navigationTitle("Companion Device")
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button(action: { dismiss() }) {
            Image(systemName: "xmark")
          }
          .accessibilityLabel("Close")
        }
      }
      .alert("Unpair Device", isPresented: $showUnpairAlert) {
        Button("Cancel", role: .cancel) {}
        Button("Unpair", role: .destructive) {
          companionDeviceManager.unpair()
        }
      } message: {
        Text("The device will stop receiving session updates until paired again.")
      }
      .onDisappear {
        companionDeviceManager.stopScanning()
      }
    }
  }

  private var pairedSection: some View {
    Section("Device") {
      HStack {
        Text(pairedDeviceName.isEmpty ? "Foqos Companion" : pairedDeviceName)
          .foregroundStyle(.primary)
        Spacer()
        HStack(spacing: 8) {
          Circle()
            .fill(companionDeviceManager.isConnected ? .green : .red)
            .frame(width: 8, height: 8)
          Text(connectionStatusText)
            .foregroundStyle(.secondary)
            .font(.subheadline)
        }
      }

      Picker("Device Profile", selection: $tagProfileId) {
        Text("None").tag("")
        ForEach(profiles, id: \.id) { profile in
          Text(profile.name).tag(profile.id.uuidString)
        }
      }
      .onChange(of: tagProfileId) { _, newValue in
        if newValue.isEmpty {
          companionDeviceManager.clearTagConfig()
        } else {
          writeTagProfile(id: newValue)
        }
      }

      Button {
        writeTagProfile(id: tagProfileId)
      } label: {
        Text("Write Tag to Device")
          .foregroundColor(themeManager.themeColor)
      }
      .disabled(tagProfileId.isEmpty || !companionDeviceManager.isConnected)

      Button {
        showUnpairAlert = true
      } label: {
        Text("Unpair Device")
          .foregroundColor(.red)
      }
    }
  }

  // User-actionable explanation for why scanning or reconnecting can't work
  // right now; nil when Bluetooth is usable.
  private var bluetoothProblem: String? {
    switch companionDeviceManager.bluetoothState {
    case .poweredOff:
      return "Bluetooth is turned off. Turn it on to connect to your device."
    case .unauthorized:
      return "Foqos doesn't have Bluetooth access. "
        + "Allow it in Settings > Privacy & Security > Bluetooth."
    case .unsupported:
      return "Bluetooth is not available on this device."
    default:
      return nil
    }
  }

  private var connectionStatusText: String {
    if companionDeviceManager.isConnected {
      return "Connected"
    }
    switch companionDeviceManager.bluetoothState {
    case .poweredOff:
      return "Bluetooth Off"
    case .unauthorized:
      return "No Bluetooth Access"
    default:
      return "Not Connected"
    }
  }

  private var scanningSection: some View {
    Section("Nearby Devices") {
      if let problem = bluetoothProblem {
        Label(problem, systemImage: "exclamationmark.triangle")
          .foregroundStyle(.secondary)
          .font(.subheadline)
      } else if companionDeviceManager.discoveredPeripherals.isEmpty {
        HStack {
          ProgressView()
          Text("Searching for devices...")
            .foregroundStyle(.secondary)
            .padding(.leading, 8)
        }
      }

      ForEach(companionDeviceManager.discoveredPeripherals, id: \.identifier) { peripheral in
        Button {
          companionDeviceManager.pair(peripheral)
        } label: {
          HStack {
            Text(peripheral.name ?? "Unknown Device")
              .foregroundColor(.primary)
            Spacer()
            Image(systemName: "link")
              .foregroundColor(.secondary)
              .font(.caption)
          }
        }
      }
    }
    // On the section, not the placeholder row: the row never reappears once
    // a stale discovery survives in the shared manager, so reopening the
    // sheet would otherwise never rescan.
    .onAppear {
      companionDeviceManager.startScanning()
    }
  }

  private func writeTagProfile(id: String) {
    guard let uuid = UUID(uuidString: id),
      let profile = profiles.first(where: { $0.id == uuid })
    else { return }
    companionDeviceManager.pushTagConfig(profile: profile)
  }
}

#Preview {
  CompanionDeviceView()
    .environmentObject(ThemeManager.shared)
    .environmentObject(CompanionDeviceManager.shared)
    .modelContainer(for: BlockedProfiles.self, inMemory: true)
}
