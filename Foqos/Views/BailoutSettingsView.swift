import SwiftUI

struct BailoutSettingsView: View {
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject var themeManager: ThemeManager
  @StateObject private var bailoutManager = BailoutManager.shared

  @State private var isSendingTestWebhook: Bool = false
  @State private var webhookAlertMessage: String?
  @State private var showWebhookAlert: Bool = false

  var body: some View {
    Form {
      Section {
        Picker("Activation", selection: $bailoutManager.bailoutMode) {
          ForEach(BailoutMode.allCases) { mode in
            Text(mode.title).tag(mode)
          }
        }
        .pickerStyle(.menu)

        Text(bailoutManager.bailoutMode.description)
          .font(.footnote)
          .foregroundStyle(.secondary)
      } header: {
        Text("Commitment Mode")
      } footer: {
        Text("Loss aversion creates psychological friction to help you adhere to your focus sessions.")
      }

      if bailoutManager.bailoutMode != .disabled {
        Section("Stake Tier") {
          ForEach(BailoutTier.allCases) { tier in
            HStack(spacing: 12) {
              Text(tier.emoji)
                .font(.title3)

              VStack(alignment: .leading, spacing: 2) {
                HStack {
                  Text(tier.title)
                    .font(.body)
                    .fontWeight(bailoutManager.selectedTier == tier ? .semibold : .regular)

                  Spacer()

                  Text(bailoutManager.displayPrice(for: tier))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                Text(tier.subtitle)
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }

              if bailoutManager.selectedTier == tier {
                Image(systemName: "checkmark")
                  .foregroundStyle(themeManager.themeColor)
                  .font(.subheadline.bold())
              }
            }
            .contentShape(Rectangle())
            .onTapGesture {
              UIImpactFeedbackGenerator(style: .light).impactOccurred()
              bailoutManager.selectedTier = tier
            }
          }
        }

        Section {
          TextField("https://api.beeminder.com/... or custom URL", text: $bailoutManager.webhookUrlString)
            .keyboardType(.URL)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)

          SecureField("Secret token or Bearer token (optional)", text: $bailoutManager.webhookSecret)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)

          if !bailoutManager.webhookUrlString.isEmpty {
            Button {
              sendTestWebhook()
            } label: {
              HStack {
                Text("Send Test Webhook")
                Spacer()
                if isSendingTestWebhook {
                  ProgressView()
                } else {
                  Image(systemName: "paperplane.fill")
                    .font(.caption)
                }
              }
            }
            .disabled(isSendingTestWebhook)
          }

          if let status = bailoutManager.lastWebhookStatusMessage {
            Text(status)
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        } header: {
          Text("External Stakes (Beeminder / Webhook)")
        } footer: {
          Text("Optionally post an event to Beeminder or your custom accountability endpoint whenever a bailout occurs.")
        }
      }

      Section("Commitment History") {
        HStack {
          Text("Emergency Bailouts Used")
          Spacer()
          Text("\(bailoutManager.totalBailoutsCompleted)")
            .foregroundStyle(.secondary)
            .bold()
        }

        HStack {
          Text("Open Source Contribution")
          Spacer()
          Text("100% of proceeds fund Foqos")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
    }
    .navigationTitle("Bailout Stakes")
    .navigationBarTitleDisplayMode(.inline)
    .task {
      await bailoutManager.loadProducts()
    }
    .alert("Webhook Test", isPresented: $showWebhookAlert) {
      Button("OK", role: .cancel) {}
    } message: {
      Text(webhookAlertMessage ?? "")
    }
  }

  private func sendTestWebhook() {
    isSendingTestWebhook = true
    Task {
      let success = await bailoutManager.sendBailoutWebhook(
        tier: bailoutManager.selectedTier,
        profileName: "Test Profile"
      )
      isSendingTestWebhook = false
      webhookAlertMessage = success
        ? "Webhook delivered successfully (200 OK)."
        : (bailoutManager.lastWebhookStatusMessage ?? "Failed to deliver webhook.")
      showWebhookAlert = true
    }
  }
}

#Preview {
  NavigationStack {
    BailoutSettingsView()
      .environmentObject(ThemeManager.shared)
  }
}
