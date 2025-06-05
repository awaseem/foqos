import SwiftUI
import UIKit

struct RoundedButton: View {
    let text: String
    let action: () -> Void
    let backgroundColor: Color
    let textColor: Color
    let font: Font
    let fontWeight: Font.Weight
    let iconName: String?
    
    init(
        _ text: String,
        action: @escaping () -> Void,
        backgroundColor: Color = Color.secondary.opacity(0.2),
        textColor: Color = .gray,
        font: Font = .subheadline,
        fontWeight: Font.Weight = .medium,
        iconName: String? = nil
    ) {
        self.text = text
        self.action = action
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.font = font
        self.fontWeight = fontWeight
        self.iconName = iconName
    }
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            action()
        }) {
            HStack(spacing: 6) {
                if let iconName = iconName {
                    Image(systemName: iconName)
                        .font(font)
                        .fontWeight(fontWeight)
                }
                
                Text(text)
                    .font(font)
                    .fontWeight(fontWeight)
            }
            .foregroundColor(textColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(backgroundColor)
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Preview
#Preview {
    VStack(spacing: 16) {
        RoundedButton("See All") {
            print("See All tapped")
        }
        
        RoundedButton("View Report", 
                     action: { print("View Report tapped") },
                     iconName: "chart.bar")
        
        RoundedButton("Custom Style", 
                     action: { print("Custom tapped") },
                     backgroundColor: .blue,
                     textColor: .white,
                     iconName: "star.fill")
        
        RoundedButton("Large Button", 
                     action: { print("Large tapped") },
                     backgroundColor: .green.opacity(0.2),
                     textColor: .green,
                     font: .title3,
                     fontWeight: .semibold,
                     iconName: "checkmark.circle")
        
        RoundedButton("Settings", 
                     action: { print("Settings tapped") },
                     iconName: "gear")
    }
    .padding(20)
} 
