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
