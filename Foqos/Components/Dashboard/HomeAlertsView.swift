import SwiftUI

struct HomeAlertsView: View {
  let alerts: [HomeAlert]
  let onAlertTapped: (HomeAlert) -> Void

  var body: some View {
    if !alerts.isEmpty {
      VStack(alignment: .leading, spacing: 10) {
        SectionTitle("Alerts")

        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 12) {
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
}

private struct HomeAlertCard: View {
  let alert: HomeAlert

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack {
        Image(systemName: alert.iconName)
          .font(.system(size: 30, weight: .semibold))
          .foregroundStyle(.white)
          .frame(width: 38, height: 38, alignment: .leading)

        Spacer(minLength: 0)
      }

      Spacer(minLength: 8)

      VStack(alignment: .leading, spacing: 4) {
        Text(alert.title)
          .font(.headline)
          .fontWeight(.bold)
          .foregroundStyle(.white)
          .lineLimit(2)
          .minimumScaleFactor(0.82)
      }
    }
    .padding(18)
    .frame(width: 148, height: 148, alignment: .leading)
    .background(
      Color.red.opacity(0.8),
      in: RoundedRectangle(cornerRadius: 28, style: .continuous)
    )
    .accessibilityLabel(alert.title)
    .accessibilityHint(alert.message)
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
      VStack(spacing: 22) {
        Spacer(minLength: 10)

        Image(systemName: alert.iconName)
          .font(.system(size: 50, weight: .semibold))
          .foregroundStyle(.red)
          .frame(width: 104, height: 104)

        VStack(spacing: 10) {
          Text(alert.title)
            .font(.title2.weight(.bold))
            .foregroundStyle(.primary)
            .multilineTextAlignment(.center)

          Text(alert.detailMessage)
            .font(.body)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 28)

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

        Spacer(minLength: 12)

        ActionButton(
          title: alert.primaryActionTitle,
          backgroundColor: themeManager.themeColor,
          isDisabled: !canRunPrimaryAction,
          action: runPrimaryAction
        )
      }
      .padding()
      .navigationTitle("Details")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button {
            dismiss()
          } label: {
            Image(systemName: "xmark")
          }
          .accessibilityLabel("Cancel")
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
