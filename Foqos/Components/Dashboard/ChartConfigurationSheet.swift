import SwiftUI

struct ChartConfigurationSheet: View {
  @EnvironmentObject var themeManager: ThemeManager
  @Binding var showHabitTracker: Bool
  @Binding var chartType: HabitChartType
  let onDismiss: () -> Void

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
                    .stroke(chartType == type ? themeManager.themeColor : Color.gray.opacity(0.4), lineWidth: 2)
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
      }
      .navigationTitle("Configure")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            onDismiss()
          } label: {
            Image(systemName: "checkmark")
              .font(.system(size: 17, weight: .semibold))
          }
        }
      }
    }
  }
}

#Preview {
  struct PreviewWrapper: View {
    @State private var showChart = true
    @State private var chartType: HabitChartType = .fourWeek

    var body: some View {
      ChartConfigurationSheet(
        showHabitTracker: $showChart,
        chartType: $chartType,
        onDismiss: {}
      )
      .environmentObject(ThemeManager.shared)
    }
  }

  return PreviewWrapper()
}
