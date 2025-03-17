import SwiftUI

struct Welcome: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Top row with category and icon
                HStack {
                    Text("Physically block distracting apps ")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "hourglass")
                        .font(.body)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(Color(hex: "a434eb").opacity(0.8))
                        )
                }
                
                Spacer()
                    .frame(height: 10)
                
                // Title and subtitle
                Text("Welcome to Foqos")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Tap here to get started on your first profile. You can use NFC Tags or even QR codes.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
            .padding(20)
            .frame(maxWidth: .infinity, minHeight: 150)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(UIColor.systemBackground))
                    .overlay(
                        GeometryReader { geometry in
                            ZStack {
                                // Purple circle blob
                                Circle()
                                    .fill(Color(hex: "a434eb").opacity(0.5))
                                    .frame(width: geometry.size.width * 0.5)
                                    .position(
                                        x: geometry.size.width * 0.9,
                                        y: geometry.size.height / 2
                                    )
                                    .blur(radius: 15)
                            }
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(.ultraThinMaterial.opacity(0.7))
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 24))
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// Helper for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3), value: configuration.isPressed)
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.1).ignoresSafeArea()
        
        Welcome(onTap: {
            print("Card tapped")
        })
        .padding(.horizontal)
    }
}
