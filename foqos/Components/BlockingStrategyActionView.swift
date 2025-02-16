import SwiftUI

struct BlockingStrategyActionView: View {
    @Environment(\.dismiss) private var dismiss
    
    var customView: (any View)?
    
    var body: some View {
        VStack {
            if let customViewToDisplay = customView {
                AnyView(customViewToDisplay)
            }
        }
        .presentationDetents([.medium])
    }
}
