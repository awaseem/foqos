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

struct RefreshControl: View {
    @Binding var isRefreshing: Bool
    let action: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            let pullDistance = geometry.frame(in: .global).minY
            let threshold: CGFloat = 50
            
            HStack {
                Spacer()
                if pullDistance > 0 {
                    HourglassView()
                        .opacity(min(pullDistance / threshold, 1.0))
                        .onAppear {
                            if pullDistance > threshold {
                                isRefreshing = true
                                action()
                            }
                        }
                }
                Spacer()
            }
        }
        .padding(.top, -50)
        .frame(height: 0)
    }
}
