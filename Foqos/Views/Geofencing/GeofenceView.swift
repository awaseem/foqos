import SwiftData
import SwiftUI

struct GeofenceView: View {
  @EnvironmentObject private var geofence: GeofenceManager
  @Query(sort: \BlockedProfiles.order) private var profiles: [BlockedProfiles]

  var body: some View {
    Form {
      Section("Profile") {
        Picker("Profile", selection: $geofence.settings.profileID) {
          Text("Choose a profile").tag(nil as UUID?)
          ForEach(
            profiles.filter {
              $0.blockingStrategyId.map {
                StrategyManager.getStrategyFromId(id: $0).supportsSessionControls
              } == true
            }
          ) {
            profile in
            Text(profile.name).tag(Optional(profile.id))
          }
        }.disabled(geofence.settings.isEnabled)
        Toggle("Enable geofencing", isOn: $geofence.settings.isEnabled)
          .disabled(geofence.settings.profileID == nil || !geofence.settings.hasValidRegion)
        Button("Start selected profile") { geofence.setActive(true) }
        Button("Stop geofence session") { geofence.setActive(false) }
        Text(
          "Disable before changing settings. Disabling monitoring leaves an existing block active."
        )
        .font(.caption)
      }
      Section("Place") {
        Button(
          geofence.settings.hasValidRegion
            ? "Replace place with current location" : "Use current location"
        ) {
          geofence.setPlaceHere()
        }
        .disabled(geofence.settings.isEnabled)
        if geofence.settings.hasValidRegion {
          Label("Place saved on this phone", systemImage: "location.circle")
        }
        Picker("Block", selection: $geofence.settings.blockOutside) {
          Text("Outside this place (leave home)").tag(true)
          Text("Inside this place (park / venue)").tag(false)
        }
        .disabled(geofence.settings.isEnabled)
        Slider(value: $geofence.settings.radius, in: 100...1000, step: 100) {
          Text("Radius")
        }
        .disabled(geofence.settings.isEnabled)
        Text("Radius: \(Int(geofence.settings.radius)) metres")
        Button("Allow background geofencing") { geofence.requestBackgroundLocation() }
        Text(geofence.status).font(.caption)
        Text(
          "Crossing back stops only a session started by this geofence. Background-stop restrictions still apply."
        )
        .font(.caption).foregroundStyle(.secondary)
      }

      if let error = geofence.errorMessage { Section("Needs attention") { Text(error) } }
    }
    .navigationTitle("Geofencing")
    .onChange(of: geofence.settings.profileID) { _, _ in geofence.saveSettings() }
    .onChange(of: geofence.settings.isEnabled) { _, _ in geofence.saveSettings() }
    .onChange(of: geofence.settings.radius) { _, _ in geofence.saveSettings() }
    .onChange(of: geofence.settings.blockOutside) { _, _ in geofence.saveSettings() }
  }
}
