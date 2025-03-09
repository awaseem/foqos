import SwiftUI

struct TimeHeader: View {
    // Input properties instead of the whole manager
    let elapsedTime: TimeInterval
    let isBlocking: Bool
    
    // Local state for animation
    @State private var opacityValue = 1.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(timeString(from: elapsedTime))
                .font(.system(size: 80))
                .fontWeight(.semibold)
                .foregroundColor(
                    isBlocking ? Color(hex: "#32CD32") : .primary
                )
                .opacity(isBlocking ? opacityValue : 1)
                .animation(
                    .easeInOut(duration: 0.7).repeatForever(),
                    value: opacityValue
                )
                .onChange(of: isBlocking) { _, newValue in
                    if newValue {
                        withAnimation(
                            .easeInOut(duration: 1).repeatForever()
                        ) {
                            opacityValue = 0.3
                        }
                    } else {
                        opacityValue = 1
                    }
                }
        }
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) / 60 % 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}
