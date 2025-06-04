import SwiftUI

struct ManageAction: Identifiable {
    let id = UUID()
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
}

struct ManageSection: View {
    let actions: [ManageAction]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle("Manage")
            
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(UIColor.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(.ultraThinMaterial)
                    )
                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(actions) { action in
                        Button(action: action.action) {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(action.color)
                                        .frame(width: 30, height: 30)
                                    Image(systemName: action.icon)
                                        .foregroundColor(.white)
                                        .font(.system(size: 15))
                                }
                                
                                Text(action.label)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        if action.id != actions.last?.id {
                            Divider()
                                .padding(.horizontal, 16)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview {
    ZStack {
        Color(.systemGroupedBackground).ignoresSafeArea()
        
        ManageSection(actions: [
            ManageAction(
                icon: "person.crop.circle.fill",
                label: "Profiles",
                color: .purple,
                action: {}
            ),
            ManageAction(
                icon: "cart.fill",
                label: "Purchase NFC tags",
                color: .gray,
                action: {}
            ),
            ManageAction(
                icon: "heart.fill",
                label: "Support us",
                color: .pink,
                action: {}
            )
        ])
        .padding()
    }
}
