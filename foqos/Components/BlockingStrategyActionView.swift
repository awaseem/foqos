import SwiftUI

struct BlockingStrategyActionView: View {
    var body: some View {
        VStack {
            Text("Bottom Sheet Content (using .sheet)")
                .font(.title)
                .padding()
            Divider()

            List {
                Text("Item A")
                Text("Item B")
                Text("Item C")
            }
            .padding()
        }
        .presentationDetents([.medium, .large]) // iOS 15+ for sizing options
        .presentationDragIndicator(.visible) // iOS 15+ for drag to dismiss indicator
    }
}
