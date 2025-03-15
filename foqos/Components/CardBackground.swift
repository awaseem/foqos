import SwiftUI

struct CardBackground: View {
    let name: String
    
    // Predefined bright iOS-friendly solid colors that work well with white text
    private let predefinedColors: [Color] = [
        Color.blue,
        Color.indigo,
        Color.purple,
        Color.pink,
        Color.orange,
        Color.red,
    ]
    
    // Structure to hold position data for shapes
    private struct ShapePosition {
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
    }
    
    // Generate deterministic position based on name and index
    private func getPositionFromName(name: String, index: Int) -> ShapePosition {
        if name.isEmpty {
            // Fallback values if name is empty
            return ShapePosition(
                x: CGFloat(index * 20 - 60), y: CGFloat(index * 15 - 40),
                size: CGFloat(index * 5))
        }
        
        // Create a deterministic seed value from name and index
        let nameBytes = Array(name.utf8)
        let seedValue =
            nameBytes.count > 0
            ? nameBytes.reduce(UInt64(index * 17)) { ($0 << 5) &+ UInt64($1) }
            : UInt64(index * 31)
        
        // Generate position values within appropriate ranges
        let xMultiplier = index % 2 == 0 ? -1.0 : 1.0  // Alternate sides
        let xRange: CGFloat = 100.0
        let yRange: CGFloat = 80.0
        
        let xOffset = CGFloat(seedValue % 100) / 100.0 * xRange * xMultiplier
        let yOffset =
            CGFloat((seedValue >> 8) % 100) / 100.0 * yRange - yRange / 2
        let size = CGFloat((seedValue >> 16) % 40)  // Size variation
        
        return ShapePosition(
            x: xOffset,
            y: yOffset,
            size: size
        )
    }
    
    // Select a color based on the name
    private var cardColor: Color {
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
                ZStack {
                    // Generate dynamic shapes based on name
                    ForEach(0..<5, id: \.self) { index in
                        let seed = getPositionFromName(name: name, index: index)
                        
                        Group {
                            if index % 3 == 0 {
                                Circle()
                                    .fill(
                                        cardColor.opacity(
                                            0.4 + Double(index) * 0.04)
                                    )
                                    .frame(
                                        width: 70 + CGFloat(seed.size),
                                        height: 70 + CGFloat(seed.size))
                            } else if index % 3 == 1 {
                                Capsule()
                                    .fill(
                                        cardColor.opacity(
                                            0.4 + Double(index) * 0.04)
                                    )
                                    .frame(
                                        width: 100 + CGFloat(seed.size),
                                        height: 50
                                            + CGFloat(seed.size * 0.5))
                            } else {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(
                                        cardColor.opacity(
                                            0.4 + Double(index) * 0.04)
                                    )
                                    .frame(
                                        width: 60 + CGFloat(seed.size),
                                        height: 60 + CGFloat(seed.size))
                            }
                        }
                        .offset(x: seed.x, y: seed.y)
                        .blur(radius: 15 + CGFloat(index * 3))
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial.opacity(0.7))
            )
            .clipShape(RoundedRectangle(cornerRadius: 24))
    }
    
    // Utility method to get the card color for other components
    public func getCardColor() -> Color {
        return cardColor
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