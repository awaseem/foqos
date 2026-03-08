import SwiftUI

struct InsightsWeekPickerView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var draftDate: Date

  let onApply: (Date) -> Void

  init(selectedDate: Date, onApply: @escaping (Date) -> Void) {
    _draftDate = State(initialValue: selectedDate)
    self.onApply = onApply
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        DatePicker("", selection: $draftDate, displayedComponents: .date)
          .datePickerStyle(.graphical)
          .labelsHidden()
      }
      .onChange(of: draftDate) { _, newValue in
        onApply(newValue)
        dismiss()
      }
    }
  }
}

#Preview {
  InsightsWeekPickerView(selectedDate: Date()) { _ in }
}
