import SwiftUI

struct ChartConfigurationSheet: View {
  @EnvironmentObject var themeManager: ThemeManager
  @Binding var showHabitTracker: Bool
  @Binding var chartType: HabitChartType
  @Binding var heatmapThresholds: HeatmapThresholds
  let onDismiss: () -> Void

  private var normalizedHeatmapThresholds: HeatmapThresholds {
    heatmapThresholds.normalized
  }

  private var lowThresholdBinding: Binding<Double> {
    Binding(
      get: { normalizedHeatmapThresholds.lowHours },
      set: {
        heatmapThresholds = HeatmapThresholds(
          lowHours: $0,
          mediumHours: normalizedHeatmapThresholds.mediumHours,
          highHours: normalizedHeatmapThresholds.highHours
        ).normalized
      }
    )
  }

  private var mediumThresholdBinding: Binding<Double> {
    Binding(
      get: { normalizedHeatmapThresholds.mediumHours },
      set: {
        heatmapThresholds = HeatmapThresholds(
          lowHours: normalizedHeatmapThresholds.lowHours,
          mediumHours: $0,
          highHours: normalizedHeatmapThresholds.highHours
        ).normalized
      }
    )
  }

  private var highThresholdBinding: Binding<Double> {
    Binding(
      get: { normalizedHeatmapThresholds.highHours },
      set: {
        heatmapThresholds = HeatmapThresholds(
          lowHours: normalizedHeatmapThresholds.lowHours,
          mediumHours: normalizedHeatmapThresholds.mediumHours,
          highHours: $0
        ).normalized
      }
    )
  }

  private var lowThresholdRange: ClosedRange<Double> {
    ClosedRange(
      uncheckedBounds: (
        lower: HeatmapThresholds.minimumHours,
        upper: normalizedHeatmapThresholds.mediumHours - HeatmapThresholds.minimumGapHours
      ))
  }

  private var mediumThresholdRange: ClosedRange<Double> {
    ClosedRange(
      uncheckedBounds: (
        lower: normalizedHeatmapThresholds.lowHours + HeatmapThresholds.minimumGapHours,
        upper: normalizedHeatmapThresholds.highHours - HeatmapThresholds.minimumGapHours
      ))
  }

  private var highThresholdRange: ClosedRange<Double> {
    ClosedRange(
      uncheckedBounds: (
        lower: normalizedHeatmapThresholds.mediumHours + HeatmapThresholds.minimumGapHours,
        upper: HeatmapThresholds.maximumHours
      ))
  }

  var body: some View {
    NavigationStack {
      List {
        Section("Visibility") {
          Toggle("Show Chart", isOn: $showHabitTracker)
            .tint(themeManager.themeColor)
        }
        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))

        Section("Chart Type") {
          ForEach(HabitChartType.allCases, id: \.self) { type in
            Button {
              chartType = type
            } label: {
              HStack(alignment: .top, spacing: 12) {
                ZStack {
                  Circle()
                    .stroke(
                      chartType == type ? themeManager.themeColor : Color.gray.opacity(0.4),
                      lineWidth: 2
                    )
                    .frame(width: 22, height: 22)

                  if chartType == type {
                    Circle()
                      .fill(themeManager.themeColor)
                      .frame(width: 12, height: 12)
                  }
                }
                .padding(.top, 2)

                VStack(alignment: .leading, spacing: 4) {
                  HStack(spacing: 8) {
                    Image(systemName: type.icon)
                      .foregroundStyle(themeManager.themeColor)
                      .font(.system(size: 16))

                    Text(type.rawValue)
                      .font(.system(size: 16, weight: .medium))
                      .foregroundStyle(.primary)
                  }

                  Text(type.description)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
              }
              .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
            .listRowSeparator(.hidden)
          }
        }

        if chartType == .fourWeek {
          Section {
            thresholdSlider(
              title: "Light activity",
              value: lowThresholdBinding,
              range: lowThresholdRange
            )

            thresholdSlider(
              title: "Moderate activity",
              value: mediumThresholdBinding,
              range: mediumThresholdRange
            )

            thresholdSlider(
              title: "High activity",
              value: highThresholdBinding,
              range: highThresholdRange
            )

            Button {
              heatmapThresholds = .defaults
            } label: {
              Label("Reset to Default", systemImage: "arrow.counterclockwise")
            }
            .foregroundStyle(themeManager.themeColor)
          } header: {
            Text("Heatmap Scale")
          } footer: {
            Text(
              "Adjust these when your focus sessions usually run longer than the default 1h, 3h, and 5h buckets."
            )
          }
        }
      }
      .navigationTitle("Manage chart")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            onDismiss()
          } label: {
            Image(systemName: "checkmark")
          }
        }
      }
    }
  }

  private func thresholdSlider(
    title: String,
    value: Binding<Double>,
    range: ClosedRange<Double>
  ) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text(title)
          .foregroundStyle(.primary)

        Spacer()

        Text(HeatmapThresholds.formattedHours(value.wrappedValue))
          .font(.subheadline.monospacedDigit())
          .foregroundStyle(.secondary)
      }

      Slider(value: value, in: range, step: 0.5)
        .tint(themeManager.themeColor)
    }
    .padding(.vertical, 4)
  }
}

#Preview {
  struct PreviewWrapper: View {
    @State private var showChart = true
    @State private var chartType: HabitChartType = .fourWeek
    @State private var heatmapThresholds: HeatmapThresholds = .defaults

    var body: some View {
      ChartConfigurationSheet(
        showHabitTracker: $showChart,
        chartType: $chartType,
        heatmapThresholds: $heatmapThresholds,
        onDismiss: {}
      )
      .environmentObject(ThemeManager.shared)
    }
  }

  return PreviewWrapper()
}
