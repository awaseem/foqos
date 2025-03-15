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
    
    // No position calculations needed for the simplified design
    
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
                GeometryReader { geometry in
                    // Single circle positioned on the right side
                    Circle()
                        .fill(cardColor.opacity(0.5))
                        .frame(width: geometry.size.width * 0.5, height: geometry.size.width * 0.5)
                        .position(
                            x: geometry.size.width * 0.9,
                            y: geometry.size.height / 2
                        )
                        .blur(radius: 15)
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
