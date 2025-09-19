import SwiftUI

struct MultiStatCard: View {
  struct StatItem: Identifiable {
    let id = UUID()
    let title: String
    let valueText: String
    let systemImageName: String
    var iconColor: Color = .accentColor
  }

  let stats: [StatItem]
  var columns: Int = 2

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 24, style: .continuous)
        .fill(.ultraThinMaterial)

      LazyVGrid(columns: gridColumns, alignment: .leading, spacing: 12) {
        ForEach(stats) { stat in
          HStack(alignment: .top, spacing: 12) {
            Image(systemName: stat.systemImageName)
              .font(.system(size: 20, weight: .semibold))
              .foregroundStyle(stat.iconColor)
              .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 4) {
              Text(stat.title)
                .font(.caption)
                .foregroundStyle(.secondary)

              Text(stat.valueText)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
      .padding(16)
    }
    .frame(maxWidth: .infinity)
  }

  private var gridColumns: [GridItem] {
    Array(
      repeating: GridItem(.flexible(), spacing: 12, alignment: .topLeading), count: max(1, columns))
  }
}

#Preview {
  MultiStatCard(
    stats: [
      .init(
        title: "Total Focus Time", valueText: "3h 42m", systemImageName: "clock", iconColor: .blue),
      .init(
        title: "Average Session", valueText: "25m", systemImageName: "chart.bar", iconColor: .purple
      ),
      .init(
        title: "Longest Session", valueText: "1h 10m", systemImageName: "timer", iconColor: .green),
      .init(
        title: "Shortest Session", valueText: "5m", systemImageName: "hourglass", iconColor: .orange
      ),
      .init(
        title: "Total Sessions", valueText: "128", systemImageName: "list.number", iconColor: .blue),
    ],
    columns: 2
  )
  .background(Color(.systemGroupedBackground))
}
