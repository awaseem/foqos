import SwiftUI
import FamilyControls

struct BlockedProfileAppSelector: View {
    var selection: FamilyActivitySelection
    var buttonAction: () -> Void
    
    private var catAndAppCount: Int {
        return BlockedProfiles
            .countSelectedActivities(selection)
    }
    
    var body: some View {
        Section("Selected Restrictions") {
            Button(action: buttonAction) {
                HStack {
                    Text("Select Apps & Websites")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.gray)
                }
            }
            if catAndAppCount == 0 {
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
