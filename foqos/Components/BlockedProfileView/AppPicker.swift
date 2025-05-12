import FamilyControls
import SwiftUI

struct AppPicker: View {
    let stateUpdateTimer = Timer.publish(every: 1, on: .main, in: .common)
        .autoconnect()

    @Binding var selection: FamilyActivitySelection
    @Binding var isPresented: Bool

    var allowMode: Bool = false

    @State private var updateFlag: Bool = false

    private var title: String {
        return allowMode ? "Apps to allow" : "Apps to block"
    }

    private var message: String {
        return allowMode
            ? "Up to 50 apps can be allowed. In Allow mode, each app in a category counts as its own individual value."
            : "Up to 50 apps can be blocked. In Block mode, a single category counts as one value rather than all of its individual apps."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ZStack {
                Text(verbatim: "Updating view state because of bug in iOS...")
                    .foregroundStyle(.clear)
                    .accessibilityHidden(true)
                    .opacity(updateFlag ? 1 : 0)

                FamilyActivityPicker(selection: $selection)
            }
            
            Text(title)
                .font(.title3)
                .padding(.horizontal, 16)
                .bold()

            Text(message)
                .font(.caption)
                .padding(.horizontal, 16)

            Text(
                "Apple's app picker may occasionally crash. We apologize for the inconvenience and are waiting for a offical fix."
            )
            .font(.footnote)
            .foregroundColor(.secondary)
            .padding(.horizontal)
            
            ActionButton(title: "Done", backgroundColor: .blue) {
                isPresented = false
            }
        }
        .onReceive(stateUpdateTimer) { _ in
            updateFlag.toggle()
        }
    }
}

#if DEBUG
    struct AppPicker_Previews: PreviewProvider {
        static var previews: some View {
            AppPicker(
                selection: .constant(FamilyActivitySelection()),
                isPresented: .constant(true)
            )
        }
    }
#endif
