import SwiftUI

struct StatCard: View {
  let title: String
  let valueText: String
  let subtitleText: String?
  let systemImageName: String
  var iconColor: Color = .accentColor

  init(
    title: String,
    valueText: String,
    subtitleText: String? = nil,
    systemImageName: String,
    iconColor: Color = .accentColor
  ) {
    self.title = title
    self.valueText = valueText
    self.subtitleText = subtitleText
    self.systemImageName = systemImageName
    self.iconColor = iconColor
  }

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 24, style: .continuous)
        .fill(.ultraThinMaterial)

      HStack(alignment: .center) {
        VStack(alignment: .leading, spacing: 8) {
          Text(title)
            .font(.caption)
            .foregroundStyle(.secondary)

          Text(valueText)
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundStyle(.primary)

          if let subtitle = subtitleText, !subtitle.isEmpty {
            Text(subtitle)
              .font(.footnote)
              .foregroundStyle(.secondary)
          }
        }

        Spacer(minLength: 12)

        Image(systemName: systemImageName)
          .font(.system(size: 28, weight: .semibold))
          .foregroundStyle(iconColor)
      }
      .padding(16)
    }
    .frame(height: 120)
  }
}

#Preview {
  VStack(spacing: 16) {
    StatCard(
      title: "Total Focus Time", valueText: "3h 42m", subtitleText: "All time",
      systemImageName: "clock", iconColor: .blue)
    StatCard(
      title: "Average Session", valueText: "25m", systemImageName: "chart.bar", iconColor: .purple)
  }
  .padding()
  .background(Color(.systemGroupedBackground))
}
