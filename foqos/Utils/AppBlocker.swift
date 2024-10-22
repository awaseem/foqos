import SwiftUI
import FamilyControls
import DeviceActivity
import ManagedSettings

class AppBlocker: ObservableObject {
    @Published var isBlocking = false
    @Published var isAuthorized = false
    
    let store = ManagedSettingsStore(named: ManagedSettingsStore.Name("foqosAppRestrictions"))
    let center = DeviceActivityCenter()
    
    func activateRestrictions(selection: FamilyActivitySelection) {
        print("Starting restrictions...")
        
        let applicationTokens = selection.applicationTokens
        let categoriesTokens = selection.categoryTokens
        let webTokens = selection.webDomainTokens

        store.shield.applications = applicationTokens
        store.shield.applicationCategories = .specific(categoriesTokens)
        store.shield.webDomains = webTokens
        
        // Set up a DeviceActivitySchedule
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        
        let activity = DeviceActivityName("foqosDeviceActivity")
        let eventCenter = DeviceActivityCenter()
        do {
            try eventCenter.startMonitoring(activity, during: schedule)
        } catch {
            print("Error starting monitoring: \(error)")
        }
    }
    
    func deactivateRestrictions() {
        store.shield.applications = nil
        store.shield.applicationCategories =  nil
        store.shield.webDomains = nil
        
        center.stopMonitoring([DeviceActivityName("foqosDeviceActivity")])
    }
    
    func requestAuthorization() {
        Task {
            do {
                try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                print("Individual authorization successful")
                                
                // Dispatch the update to the main thread
                await MainActor.run {
                    self.isAuthorized = true
                }
            } catch {
                print("Error requesting authorization: \(error)")
                await MainActor.run {
                    self.isAuthorized = false
                }
            }
        }
    }
}
