import SwiftUI
import FamilyControls

struct BlockedProfileAppSelector: View {
    var selection: FamilyActivitySelection
    var buttonAction: () -> Void
    var allowMode: Bool = false
    var disabled: Bool = false
    var disabledText: String?
    
    private var title: String {
        return allowMode ? "Allowed" : "Blocked"
    }
    
    private var buttonText: String {
        return allowMode ? "Select Apps & Websites to Allow" : "Select Apps & Websites to Restrict"
    }
    
    private var catAndAppCount: Int {
        return BlockedProfiles
            .countSelectedActivities(selection)
    }
    
    var body: some View {
        Section(title) {
            Button(action: buttonAction) {
                HStack {
                    Text(buttonText)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.gray)
                }
            }
            .disabled(disabled)
            
            if let disabledText = disabledText, disabled {
                Text(disabledText)
                    .foregroundStyle(.red)
                    .padding(.top, 4)
                    .font(.caption)
            } else if catAndAppCount == 0 {
                Text("No apps or websites selected")
                    .foregroundStyle(.gray)
            } else {
                Text("\(catAndAppCount) items selected")
                    .font(.footnote)
                    .foregroundStyle(.gray)
                    .padding(.top, 4)
            }
        }
    }
}

#Preview {
    BlockedProfileAppSelector(
        selection: FamilyActivitySelection(),
        buttonAction: {},
        disabled: true,
        disabledText: "Disable the current session to edit apps for blocking"
    )
    
    BlockedProfileAppSelector(
        selection: FamilyActivitySelection(),
        buttonAction: {},
        allowMode: true,
        disabled: true,
        disabledText: "Disable the current session to edit apps for blocking"
    )
}
