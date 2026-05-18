import SwiftUI

struct HomeAlertsView: View {
  let alerts: [HomeAlert]
  let onAlertTapped: (HomeAlert) -> Void

  var body: some View {
    if !alerts.isEmpty {
      VStack(alignment: .leading, spacing: 10) {
        SectionTitle("Alerts")

        VStack(spacing: 8) {
          ForEach(alerts) { alert in
            Button {
              onAlertTapped(alert)
            } label: {
              HomeAlertCard(alert: alert)
            }
            .buttonStyle(.plain)
          }
        }
      }
    }
  }
}

private struct HomeAlertCard: View {
  @EnvironmentObject var themeManager: ThemeManager

  let alert: HomeAlert

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: alert.iconName)
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(.red)
        .frame(width: 32, height: 32)

      VStack(alignment: .leading, spacing: 2) {
        Text(alert.title)
          .font(.subheadline)
          .fontWeight(.semibold)
          .foregroundStyle(.primary)

        Text(alert.message)
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(2)
      }

      Spacer(minLength: 8)

      Image(systemName: "chevron.right")
        .font(.caption)
        .foregroundStyle(.tertiary)
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      Color(.systemBackground),
      in: RoundedRectangle(cornerRadius: 16, style: .continuous)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .strokeBorder(themeManager.themeColor.opacity(0.16), lineWidth: 1)
    )
  }
}

struct HomeAlertDetailView: View {
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject var themeManager: ThemeManager

  let alert: HomeAlert
  let disabledReason: String?
  let onPrimaryAction: () -> Void

  private var canRunPrimaryAction: Bool { disabledReason == nil }

  var body: some View {
    NavigationStack {
      VStack(alignment: .leading, spacing: 20) {
        HStack(alignment: .top, spacing: 14) {
          Image(systemName: alert.iconName)
            .font(.title3)
            .foregroundStyle(.red)
            .frame(width: 44, height: 44)

          VStack(alignment: .leading, spacing: 6) {
            Text(alert.title)
              .font(.title3)
              .fontWeight(.semibold)

            Text(alert.detailMessage)
              .font(.subheadline)
              .foregroundStyle(.secondary)
              .fixedSize(horizontal: false, vertical: true)
          }
        }

        if let disabledReason {
          Text(disabledReason)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
              Color(.secondarySystemBackground),
              in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
        }

        Spacer(minLength: 0)

        Button(action: runPrimaryAction) {
          Text(alert.primaryActionTitle)
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
              themeManager.themeColor,
              in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
        }
        .disabled(!canRunPrimaryAction)
        .opacity(canRunPrimaryAction ? 1 : 0.45)
      }
      .padding(20)
      .navigationTitle("Alert")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Done") {
            dismiss()
          }
        }
      }
    }
  }

  private func runPrimaryAction() {
    onPrimaryAction()
    dismiss()
  }
}

#Preview {
  HomeAlertsView(
    alerts: [
      HomeAlert(
        type: .screenTimeAccess,
        title: "Screen Time access needed",
        message: "Blocking is paused until access is restored.",
        detailMessage:
          "Foqos needs Screen Time access to block apps and websites. Grant access again to restore blocking.",
        primaryActionTitle: "Allow Screen Time Access",
        iconName: "exclamationmark.shield.fill"
      )
    ],
    onAlertTapped: { _ in }
  )
  .padding()
  .environmentObject(ThemeManager.shared)
}
