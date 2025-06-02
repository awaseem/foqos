import SwiftUI

struct HourglassView: View {
    @State private var isAnimating = false
    
    var body: some View {
        Image(systemName: "hourglass")
            .font(.system(size: 24))
            .foregroundColor(.purple)
            .offset(y: isAnimating ? -5 : 5)
            .animation(
                Animation
                    .easeInOut(duration: 0.8)
                    .repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}
