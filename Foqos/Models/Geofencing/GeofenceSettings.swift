import Foundation

struct GeofenceSettings: Codable {
  var profileID: UUID?
  var isEnabled = false
  var latitude: Double?
  var longitude: Double?
  var radius = 200.0
  var blockOutside = true

  var hasValidRegion: Bool {
    guard let latitude, let longitude else { return false }
    return latitude.isFinite && longitude.isFinite && (-90...90).contains(latitude)
      && (-180...180).contains(longitude) && radius.isFinite && (100...1000).contains(radius)
  }
}
