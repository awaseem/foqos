import SwiftUI

struct CardBackground: View {
    let name: String
    var isActive: Bool = false
    
    // Animation properties for lava lamp effect
    @State private var blob1Offset: CGSize = .zero
    @State private var blob2Offset: CGSize = .zero
    @State private var blob3Offset: CGSize = .zero
    @State private var blob1Scale: CGFloat = 1.0
    @State private var blob2Scale: CGFloat = 0.9
    @State private var blob3Scale: CGFloat = 0.8
    
    // Predefined bright iOS-friendly solid colors that work well with white text
    private let predefinedColors: [Color] = [
        Color.blue,
        Color.indigo,
        Color.purple,
        Color.pink,
        Color.orange,
        Color.red,
    ]
    
    // Active state color - slightly darker green
    private let activeColor: Color = Color(red: 0, green: 0.75, blue: 0)
    
    // No position calculations needed for the simplified design
    
    // Select a color based on the name or active state
    private var cardColor: Color {
        if isActive {
            return activeColor
        }
        
        if name.isEmpty {
            // Fallback to the first color if name is empty
            return predefinedColors[0]
        }
        
        // Sum the Unicode values of characters in the name for a deterministic result
        let nameSum = name.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        
        // Use modulo to get an index within the array bounds
        let index = nameSum % predefinedColors.count
        return predefinedColors[index]
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(Color(UIColor.systemBackground))
            .overlay(
                GeometryReader { geometry in
                    ZStack {
                        if isActive {
                            // Lava lamp effect with blob-like shapes
                            Group {
                                // Blob 1 - starts top left, moves to bottom right
                                Circle()
                                    .fill(activeColor.opacity(0.5))
                                    .frame(width: geometry.size.width * 0.45 * blob1Scale)
                                    .position(
                                        x: geometry.size.width * 0.2 + blob1Offset.width,
                                        y: geometry.size.height * 0.2 + blob1Offset.height
                                    )
                                    .blur(radius: 12)
                                
                                // Blob 2 - starts top right, moves to bottom left
                                Circle()
                                    .fill(activeColor.opacity(0.45))
                                    .frame(width: geometry.size.width * 0.5 * blob2Scale)
                                    .position(
                                        x: geometry.size.width * 0.8 + blob2Offset.width,
                                        y: geometry.size.height * 0.25 + blob2Offset.height
                                    )
                                    .blur(radius: 15)
                                
                                // Blob 3 - starts bottom, moves to top
                                Circle()
                                    .fill(activeColor.opacity(0.4))
                                    .frame(width: geometry.size.width * 0.4 * blob3Scale)
                                    .position(
                                        x: geometry.size.width * 0.5 + blob3Offset.width,
                                        y: geometry.size.height * 0.8 + blob3Offset.height
                                    )
                                    .blur(radius: 14)
                            }
                        } else {
                            // Default single circle for inactive state
                            Circle()
                                .fill(cardColor.opacity(0.5))
                                .frame(width: geometry.size.width * 0.5, height: geometry.size.width * 0.5)
                                .position(
                                    x: geometry.size.width * 0.9,
                                    y: geometry.size.height / 2
                                )
                                .blur(radius: 15)
                        }
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial.opacity(0.7))
            )
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .onAppear {
                if isActive {
                    // Animate blobs with different timing to create organic motion
                    animateLavaLamp()
                }
            }
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    // Start animation when card becomes active
                    animateLavaLamp()
                }
            }
    }
    
    // Utility method to get the card color for other components
    public func getCardColor() -> Color {
        return cardColor
    }
    
    // Create lava lamp animation
    private func animateLavaLamp() {
        // Animate blob 1 - moving from top left to bottom right
        withAnimation(Animation.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
            blob1Offset = CGSize(width: 60, height: 70)
            blob1Scale = 1.3
        }
        
        // Animate blob 2 - moving from top right to bottom left
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(Animation.easeInOut(duration: 4.2).repeatForever(autoreverses: true)) {
                blob2Offset = CGSize(width: -75, height: 60)
                blob2Scale = 1.2
            }
        }
        
        // Animate blob 3 - moving from bottom to top
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(Animation.easeInOut(duration: 3.7).repeatForever(autoreverses: true)) {
                blob3Offset = CGSize(width: 30, height: -80)
                blob3Scale = 1.1
            }
        }
    }
}

#Preview {
    ZStack {
        Color(.systemGroupedBackground).ignoresSafeArea()
        
        VStack(spacing: 16) {
            CardBackground(name: "Work Focus")
                .frame(height: 170)
                .padding(.horizontal)
                
            CardBackground(name: "Gaming")
                .frame(height: 170)
                .padding(.horizontal)
                
            CardBackground(name: "Social Media")
                .frame(height: 170)
                .padding(.horizontal)
        }
    }
}
