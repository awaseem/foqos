import SwiftUI
import FamilyControls

struct AppPicker: View {
    let stateUpdateTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    @Binding var selection: FamilyActivitySelection
    @Binding var isPresented: Bool
    
    @State private var updateFlag: Bool = false
    
    var body : some View {
        VStack {
            HStack {
                Spacer()
                Button("Done") {
                    isPresented = false
                }
                .padding([.top, .trailing], 16)
            }
            
            Text("Note: Apple's app picker may occasionally crash. We apologize for the inconvenience and are waiting for a offical fix.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.vertical, 8)
            
            ZStack {
                Text(verbatim: "Updating view state because of bug in iOS...")
                    .foregroundStyle(.clear)
                    .accessibilityHidden(true)
                    .opacity(updateFlag ? 1 : 0)
                
                FamilyActivityPicker(selection: $selection)
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
