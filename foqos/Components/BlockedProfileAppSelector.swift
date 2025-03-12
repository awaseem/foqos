import SwiftUI
import FamilyControls

struct BlockedProfileAppSelector: View {
    var selection: FamilyActivitySelection
    var buttonAction: () -> Void
    var disabled: Bool = false
    var disabledText: String?
    
    private var catAndAppCount: Int {
        return BlockedProfiles
            .countSelectedActivities(selection)
    }
    
    var body: some View {
        Section("Restrictions") {
            Button(action: buttonAction) {
                HStack {
                    Text("Select Apps & Websites")
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
}
