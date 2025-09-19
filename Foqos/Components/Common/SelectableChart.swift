import Charts
import SwiftUI

struct SelectableChart<X: Plottable & Comparable, Data: Identifiable, Content: ChartContent>: View {
  @State private var selectedX: X?

  private let data: [Data]
  private let xValue: (Data) -> X
  private let yValue: ((Data) -> Double)?
  private let content: (Data) -> Content
  private let annotation: ((X, Data?) -> AnyView)?

  init(
    data: [Data],
    xValue: @escaping (Data) -> X,
    yValue: ((Data) -> Double)? = nil,
    @ChartContentBuilder content: @escaping (Data) -> Content,
    annotation: ((X, Data?) -> AnyView)? = nil
  ) {
    self.data = data
    self.xValue = xValue
    self.yValue = yValue
    self.content = content
    self.annotation = annotation
  }

  var body: some View {
    Chart {
      ForEach(data) { item in
        content(item)
      }

      if let selectedX = selectedX, let annotation = annotation {
        RuleMark(x: .value("Selected", selectedX))
          .foregroundStyle(.secondary)
          .lineStyle(StrokeStyle(lineWidth: 1, dash: [3]))
          .annotation(position: .topLeading) {
            let selectedData = data.first { isEqual(xValue($0), selectedX) }
            annotation(selectedX, selectedData)
          }
      }
    }
    .chartXScale(domain: xAxisDomain())
    .chartYScale(domain: yAxisDomain())
    .chartXSelection(value: $selectedX)
  }

  private func xAxisDomain() -> ClosedRange<X> {
    let xValues = data.map(xValue)
    if let minX = xValues.min(), let maxX = xValues.max() {
      return minX...maxX
    }
    // Fallback - this shouldn't happen with valid data
    return xValues.first!...xValues.first!
  }

  private func yAxisDomain() -> ClosedRange<Double> {
    guard let yValue = yValue else {
      // If no y-value extractor provided, let chart auto-scale
      return 0...1
    }

    let yValues = data.map(yValue)
    if let minY = yValues.min(), let maxY = yValues.max() {
      // Add a small padding to prevent clipping
      let padding = (maxY - minY) * 0.05
      return (minY - padding)...(maxY + padding)
    }
    return 0...1
  }

  private func isEqual(_ lhs: X, _ rhs: X) -> Bool {
    if let lhsDate = lhs as? Date, let rhsDate = rhs as? Date {
      return Calendar.current.isDate(lhsDate, inSameDayAs: rhsDate)
    }
    return String(describing: lhs) == String(describing: rhs)
  }
}

// Convenience factory functions
struct SelectableChartFactory {
  static func dailyChart<DataType: Identifiable, ContentType: ChartContent>(
    data: [DataType],
    xValue: @escaping (DataType) -> Date,
    yValue: @escaping (DataType) -> Double,
    @ChartContentBuilder content: @escaping (DataType) -> ContentType,
    annotationValue: @escaping (DataType?) -> String
  ) -> SelectableChart<Date, DataType, ContentType> {
    SelectableChart<Date, DataType, ContentType>(
      data: data,
      xValue: xValue,
      yValue: yValue,
      content: content,
      annotation: { date, selectedData in
        AnyView(
          VStack(alignment: .leading, spacing: 2) {
            Text(date, format: .dateTime.month().day())
            Text(annotationValue(selectedData))
              .font(.caption)
          }
          .padding(6)
          .background(Color(UIColor.systemBackground), in: RoundedRectangle(cornerRadius: 6))
          .overlay(
            RoundedRectangle(cornerRadius: 6)
              .stroke(Color(UIColor.separator), lineWidth: 0.5)
          )
          .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
      }
    )
  }

  static func hourlyChart<DataType: Identifiable, ContentType: ChartContent>(
    data: [DataType],
    xValue: @escaping (DataType) -> Int,
    yValue: @escaping (DataType) -> Double,
    @ChartContentBuilder content: @escaping (DataType) -> ContentType,
    annotationValue: @escaping (DataType?) -> String
  ) -> SelectableChart<Int, DataType, ContentType> {
    SelectableChart<Int, DataType, ContentType>(
      data: data,
      xValue: xValue,
      yValue: yValue,
      content: content,
      annotation: { hour, selectedData in
        AnyView(
          VStack(alignment: .leading, spacing: 2) {
            Text(formatHourShort(hour))
            Text(annotationValue(selectedData))
              .font(.caption)
          }
          .padding(6)
          .background(Color(UIColor.systemBackground), in: RoundedRectangle(cornerRadius: 6))
          .overlay(
            RoundedRectangle(cornerRadius: 6)
              .stroke(Color(UIColor.separator), lineWidth: 0.5)
          )
          .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
      }
    )
  }

  private static func formatHourShort(_ hour: Int) -> String {
    var comps = DateComponents()
    comps.hour = max(0, min(23, hour))
    let calendar = Calendar.current
    let date = calendar.date(from: comps) ?? Date()
    let formatter = DateFormatter()
    formatter.dateFormat = "ha"
    return formatter.string(from: date).lowercased()
  }
}
