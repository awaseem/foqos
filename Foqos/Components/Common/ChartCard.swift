import Charts
import SwiftUI

struct ChartCard<Content: View>: View {
  let title: String
  let subtitle: String?
  let content: () -> Content

  init(
    title: String,
    subtitle: String? = nil,
    @ViewBuilder content: @escaping () -> Content
  ) {
    self.title = title
    self.subtitle = subtitle
    self.content = content
  }

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 24, style: .continuous)
        .fill(.ultraThinMaterial)

      VStack(alignment: .leading, spacing: 12) {
        VStack(alignment: .leading, spacing: 4) {
          Text(title)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(.primary)

          if let subtitle = subtitle, !subtitle.isEmpty {
            Text(subtitle)
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }

        content()
          .frame(maxWidth: .infinity, minHeight: 160, alignment: .center)
      }
      .padding(16)
    }
    .frame(maxWidth: .infinity)
  }
}

// Preview intentionally omitted to keep build clean
