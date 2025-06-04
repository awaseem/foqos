import SwiftUI

struct RoundedButton: View {
    let text: String
    let action: () -> Void
    let backgroundColor: Color
    let textColor: Color
    let font: Font
    let fontWeight: Font.Weight
    
    init(
        _ text: String,
        action: @escaping () -> Void,
        backgroundColor: Color = Color.secondary.opacity(0.3),
        textColor: Color = .white,
        font: Font = .subheadline,
        fontWeight: Font.Weight = .medium
    ) {
        self.text = text
        self.action = action
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.font = font
        self.fontWeight = fontWeight
    }
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(font)
                .fontWeight(fontWeight)
                .foregroundColor(textColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
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
        
        RoundedButton("View Report") {
            print("View Report tapped")
        }
        
        RoundedButton("Custom Style", 
                     action: { print("Custom tapped") },
                     backgroundColor: .blue,
                     textColor: .white)
        
        RoundedButton("Large Button", 
                     action: { print("Large tapped") },
                     backgroundColor: .green.opacity(0.2),
                     textColor: .green,
                     font: .title3,
                     fontWeight: .semibold)
    }
    .padding(20)
} 
