import SwiftUI

struct ContentSizedSheetScrollView<Content: View>: View {
  @State private var topInset: CGFloat = 0

  @ViewBuilder let content: () -> Content

  var body: some View {
    ScrollView {
      content()
        .frame(maxWidth: .infinity)
        .fixedSize(horizontal: false, vertical: true)
        .background {
          GeometryReader { geometry in
            Color.clear.preference(
              key: SheetContentHeightKey.self,
              value: ceil(geometry.size.height + topInset)
            )
          }
        }
    }
    .scrollBounceBehavior(.basedOnSize)
    .onGeometryChange(for: CGFloat.self) { geometry in
      // Include the grabber and any navigation bar, but let the sheet add its bottom safe area.
      geometry.safeAreaInsets.top
    } action: {
      topInset = $0
    }
  }
}

extension View {
  func contentSizedSheetPresentation(
    fallbackDetents: Set<PresentationDetent> = [.large]
  ) -> some View {
    modifier(ContentSizedSheetPresentation(fallbackDetents: fallbackDetents))
  }
}

private struct ContentSizedSheetPresentation: ViewModifier {
  let fallbackDetents: Set<PresentationDetent>
  @State private var contentHeight: CGFloat = 0
  @State private var selectedDetent: PresentationDetent = .large

  init(fallbackDetents: Set<PresentationDetent>) {
    self.fallbackDetents = fallbackDetents
    _selectedDetent = State(initialValue: fallbackDetents.contains(.medium) ? .medium : .large)
  }

  func body(content: Content) -> some View {
    content
      .onPreferenceChange(SheetContentHeightKey.self) { height in
        let wasFitted = contentHeight == 0 || selectedDetent == .height(contentHeight)
        contentHeight = height
        if height > 0, wasFitted {
          selectedDetent = .height(height)
        } else if height == 0 {
          selectedDetent = .large
        }
      }
      .presentationDetents(
        contentHeight > 0 ? [.height(contentHeight), .large] : fallbackDetents,
        selection: $selectedDetent
      )
      .presentationDragIndicator(.visible)
  }
}

private struct SheetContentHeightKey: PreferenceKey {
  static var defaultValue: CGFloat = 0

  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value = max(value, nextValue())
  }
}

#Preview {
  @Previewable @State var isPresented = true

  Color.clear
    .sheet(isPresented: $isPresented) {
      ContentSizedSheetScrollView {
        VStack(alignment: .leading, spacing: 24) {
          Text("Sheet settings")
            .font(.title2.bold())
          Text("This sheet fits its content and scrolls when the available space is limited.")
          Button("Done") { isPresented = false }
        }
        .padding(24)
      }
      .contentSizedSheetPresentation()
    }
}
