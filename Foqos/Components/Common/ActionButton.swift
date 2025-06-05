import SwiftUI

struct ActionButton: View {
    let title: String
    let backgroundColor: Color?
    let iconName: String?
    let iconColor: Color?
    let isLoading: Bool
    
    let action: () -> Void
    
    init(
        title: String,
        backgroundColor: Color? = nil,
        iconName: String? = nil,
        iconColor: Color? = nil,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.backgroundColor = backgroundColor
        self.iconName = iconName
        self.iconColor = iconColor
        self.isLoading = isLoading
        self.action = action
    }
    
    var body: some View {
        Button(action: isLoading ? {} : action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    if let iconName = iconName {
                        Image(systemName: iconName)
                            .font(.headline)
                            .foregroundColor(iconColor ?? .white)
                    }
                    
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(backgroundColor ?? Color.indigo)
            .opacity(isLoading ? 0.7 : 1.0)
            .clipShape(Capsule())
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            .padding(.horizontal, 20)
        }
        .disabled(isLoading)
    }
}

#Preview("Action Button Examples") {
    VStack(spacing: 20) {
        // Basic button
        ActionButton(title: "Save") {
            print("Save tapped")
        }
        
        // Button with icon
        ActionButton(
            title: "Download",
            iconName: "arrow.down.circle"
        ) {
            print("Download tapped")
        }
        
        // Loading state
        ActionButton(
            title: "Saving...",
            isLoading: true
        ) {
            print("This won't execute while loading")
        }
        
        // Custom background with icon
        ActionButton(
            title: "Delete",
            backgroundColor: .red,
            iconName: "trash"
        ) {
            print("Delete tapped")
        }
        
        // Success button with icon
        ActionButton(
            title: "Complete",
            backgroundColor: .green,
            iconName: "checkmark.circle"
        ) {
            print("Complete tapped")
        }
        
        // Custom icon color example
        ActionButton(
            title: "Favorite",
            backgroundColor: .gray,
            iconName: "heart.fill",
            iconColor: .red
        ) {
            print("Favorite tapped")
        }
        
        // Loading with custom color
        ActionButton(
            title: "Processing...",
            backgroundColor: .orange,
            isLoading: true
        ) {
            print("Processing")
        }
        
        // Warning button
        ActionButton(
            title: "Backup",
            backgroundColor: .yellow,
            iconName: "cloud.fill"
        ) {
            print("Backup tapped")
        }
        
        // Icon only style (short title)
        ActionButton(
            title: "Share",
            backgroundColor: .blue,
            iconName: "square.and.arrow.up"
        ) {
            print("Share tapped")
        }
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
