import CoreLocation
import Foundation
import NetworkExtension
import SystemConfiguration.CaptiveNetwork

final class WiFiMonitorManager: NSObject, ObservableObject, CLLocationManagerDelegate {
  static let shared = WiFiMonitorManager()

  @Published var currentSSID: String? = nil
  @Published var isLocationAuthorized: Bool = false

  private let locationManager = CLLocationManager()
  private var monitorTimer: Timer?
  private var disconnectTimers: [UUID: Timer] = [:]

  override private init() {
    super.init()
    locationManager.delegate = self
  }

  func requestLocationAuthorization() {
    locationManager.requestWhenInUseAuthorization()
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    let status = manager.authorizationStatus
    DispatchQueue.main.async {
      self.isLocationAuthorized = (status == .authorizedWhenInUse || status == .authorizedAlways)
      self.fetchCurrentSSID()
    }
  }

  func startMonitoring() {
    stopMonitoring()
    fetchCurrentSSID()

    // Poll current SSID every 10 seconds
    monitorTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
      self?.fetchCurrentSSID()
    }
  }

  func stopMonitoring() {
    monitorTimer?.invalidate()
    monitorTimer = nil
  }

  var onSSIDChanged: ((String?) -> Void)?

  func fetchCurrentSSID(completion: ((String?) -> Void)? = nil) {
    NEHotspotNetwork.fetchCurrent { hotspotNetwork in
      let ssid = hotspotNetwork?.ssid
      DispatchQueue.main.async {
        let oldSSID = self.currentSSID
        let newSSID: String?
        if let ssid = ssid, !ssid.isEmpty {
          newSSID = ssid
        } else {
          newSSID = self.fetchSSIDFallback()
        }

        self.currentSSID = newSSID
        completion?(newSSID)

        if oldSSID != newSSID {
          self.onSSIDChanged?(newSSID)
        }
      }
    }
  }

  private func fetchSSIDFallback() -> String? {
    guard let interfaces = CNCopySupportedInterfaces() as? [String] else { return nil }
    for interface in interfaces {
      guard let interfaceInfo = CNCopyCurrentNetworkInfo(interface as CFString) as? [String: Any],
        let ssid = interfaceInfo[kCNNetworkInfoKeySSID as String] as? String
      else { continue }
      return ssid
    }
    return nil
  }

  // MARK: - Disconnect Grace Period Management

  func scheduleDisconnectStop(for profileID: UUID, onDisconnect: @escaping () -> Void) {
    cancelDisconnectStop(for: profileID)

    // Schedule 1-minute (60 seconds) grace period before stopping blocking
    let timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: false) { [weak self] _ in
      self?.disconnectTimers.removeValue(forKey: profileID)
      onDisconnect()
    }
    disconnectTimers[profileID] = timer
  }

  func cancelDisconnectStop(for profileID: UUID) {
    disconnectTimers[profileID]?.invalidate()
    disconnectTimers.removeValue(forKey: profileID)
  }

  func isDisconnectTimerPending(for profileID: UUID) -> Bool {
    return disconnectTimers[profileID] != nil
  }
}
