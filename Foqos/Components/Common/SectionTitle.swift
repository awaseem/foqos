import SwiftUI

struct SectionTitle: View {
    let title: String
    let buttonText: String?
    let buttonAction: (() -> Void)?
    
    init(_ title: String, buttonText: String? = nil, buttonAction: (() -> Void)? = nil) {
        self.title = title
        self.buttonText = buttonText
        self.buttonAction = buttonAction
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Spacer()
            
            if let buttonText = buttonText, let buttonAction = buttonAction {
                Button(action: buttonAction) {
                    Text(buttonText)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.secondary.opacity(0.3))
                        .cornerRadius(16)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.bottom, 10)
    }
}

// Preview
#Preview {
    VStack(spacing: 24) {
        SectionTitle("Recent Activity")
        
        SectionTitle("Your Focus Sessions", 
                    buttonText: "See All", 
                    buttonAction: { print("See All tapped") })
        
        SectionTitle("Weekly Insights", 
                    buttonText: "View Report", 
                    buttonAction: { print("View Report tapped") })
        
        SectionTitle("Achievements", 
                    buttonText: "Manage", 
                    buttonAction: { print("Manage tapped") })
        
        SectionTitle("App Usage", 
                    buttonText: "Settings", 
                    buttonAction: { print("Settings tapped") })
    }
    .padding(20)
}
