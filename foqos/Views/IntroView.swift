import SwiftUI

struct IntroView: View {
    let onRequestAuthorization: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "hourglass")
                        .font(.system(size: 40))
                        .foregroundColor(.purple)
                    
                    Text("Welcome\nto Foqos")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 16)
                
                // Explanation
                VStack(spacing: 24) {
                    explanationSection(
                        icon: "hand.raised.fill",
                        title: "Block Distracting Apps",
                        description: "Select which apps you want to block during focus time"
                    )
                    
                    explanationSection(
                        icon: "creditcard.and.123",
                        title: "NFC Tag Integration",
                        description: "Use NFC tags to start and stop your focus sessions"
                    )
                    
                    explanationSection(
                        icon: "list.star",
                        title: "Options for Focus",
                        description: "Use QR codes and even manually trigger profiles to help you stay focused"
                    )
                    
                    explanationSection(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Track Your Progress",
                        description: "Monitor your focus sessions and build better habits"
                    )
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                
                Spacer()
                
                // Privacy Note
                Text("Your app selection and usage data never leaves your device")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                
                ActionButton(
                    title: "Allow Screen Time Access",
                    backgroundColor: .purple
                ) {
                    onRequestAuthorization()
                }
                .padding(.top, 8)
                .padding(.bottom, 16)
            }
            .padding(.vertical, 16)
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .padding(.horizontal, 12)
    }
    
    private func explanationSection(
        icon: String,
        title: String,
        description: String
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.purple)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.4)
            .ignoresSafeArea()
        
        IntroView {
            print("Request authorization tapped")
        }
    }
}
