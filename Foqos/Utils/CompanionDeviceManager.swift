import CoreBluetooth
import SwiftData
import SwiftUI

// UserDefaults keys shared between the manager and views that mirror its
// settings via @AppStorage.
enum CompanionDeviceDefaults {
  static let enabledKey = "companionDeviceEnabled"
  static let identifierKey = "companionDeviceIdentifier"
  static let nameKey = "companionDeviceName"
  static let profileIdKey = "companionDeviceProfileId"
}

// Pushes blocking session status to a companion device over BLE and points
// its NFC tag at a profile deep link. Opt-in: no CBCentralManager (and
// therefore no Bluetooth permission prompt) exists until the user enables the
// feature in settings. The canonical GATT contract is
// docs/companion-device-protocol.md.
class CompanionDeviceManager: NSObject, ObservableObject {
  static let shared = CompanionDeviceManager()

  static let serviceUUID = CBUUID(string: "F0C50001-8B1E-4B6D-9F26-3F0B5C7A1D01")
  static let statusCharacteristicUUID = CBUUID(string: "F0C50002-8B1E-4B6D-9F26-3F0B5C7A1D01")
  static let timeSyncCharacteristicUUID = CBUUID(string: "F0C50003-8B1E-4B6D-9F26-3F0B5C7A1D01")
  static let tagConfigCharacteristicUUID = CBUUID(string: "F0C50004-8B1E-4B6D-9F26-3F0B5C7A1D01")
  static let toggleCharacteristicUUID = CBUUID(string: "F0C50005-8B1E-4B6D-9F26-3F0B5C7A1D01")
  static let tagURLMaxBytes = 128
  private static let restoreIdentifier = "dev.ambitionsoftware.foqos.companionCentral"

  @AppStorage(CompanionDeviceDefaults.enabledKey) private(set) var isEnabled: Bool = false
  @AppStorage(CompanionDeviceDefaults.identifierKey) private var pairedIdentifier: String = ""
  @AppStorage(CompanionDeviceDefaults.nameKey) private(set) var pairedDeviceName: String = ""
  @AppStorage(CompanionDeviceDefaults.profileIdKey) var tagProfileId: String = ""

  @Published var isConnected: Bool = false
  @Published var isScanning: Bool = false
  @Published var discoveredPeripherals: [CBPeripheral] = []
  @Published var bluetoothState: CBManagerState = .unknown

  // Fired when the device asks to toggle the session (e.g. a screen tap),
  // passing the profile configured for the device's tag. Wired in foqosApp.
  var onToggleRequested: ((UUID?) -> Void)?

  // Fired after each (re)connection so the app pushes current truth with
  // fresh stats — the device may have rebooted and lost its RAM state, and
  // the cached payload may be stale. Wired in foqosApp.
  var onStatusRefreshNeeded: (() -> Void)?

  private var centralManager: CBCentralManager?
  private var connectedPeripheral: CBPeripheral?
  private var statusCharacteristic: CBCharacteristic?
  private var timeSyncCharacteristic: CBCharacteristic?
  private var tagConfigCharacteristic: CBCharacteristic?

  // Latest truth is kept (not consumed) so sessions toggled while the device
  // is out of range reconcile on reconnect, and every reconnect re-pushes in
  // case the device power-cycled and lost its RAM state.
  private var currentStatus: CompanionStatusPayload?
  private var statusDirty = false
  private var pendingTagConfigURL: String?
  private var wantsScanning = false
  private var lastToggleRequestAt: Date = .distantPast
  private var lastToggleCounter: UInt8?

  // Writes in flight, so a failure re-queues its value instead of the device
  // silently keeping stale state, and a second flush can't double-write.
  private var inFlightStatusWrite = false
  private var inFlightTagConfigURL: String?

  var isPaired: Bool {
    return !pairedIdentifier.isEmpty
  }

  private override init() {
    super.init()
  }

  // Called on app launch; reconnects to a previously paired device.
  func start() {
    guard isEnabled, isPaired else { return }
    ensureCentralManager()
  }

  func setEnabled(_ enabled: Bool) {
    isEnabled = enabled
    if enabled {
      ensureCentralManager()
    } else {
      stopScanning()
      disconnect()
      centralManager = nil
    }
  }

  // MARK: - Pairing

  func startScanning() {
    guard isEnabled else { return }
    ensureCentralManager()
    wantsScanning = true
    discoveredPeripherals = []
    scanIfPoweredOn()
  }

  func stopScanning() {
    wantsScanning = false
    isScanning = false
    centralManager?.stopScan()
  }

  func pair(_ peripheral: CBPeripheral) {
    stopScanning()
    pairedIdentifier = peripheral.identifier.uuidString
    pairedDeviceName = peripheral.name ?? "Foqos Companion"
    connect(to: peripheral)
  }

  func unpair() {
    disconnect()
    pairedIdentifier = ""
    pairedDeviceName = ""
    tagProfileId = ""
    currentStatus = nil
    statusDirty = false
    pendingTagConfigURL = nil
  }

  // MARK: - Pushes

  func pushStatus(session: BlockedProfileSession?, context: ModelContext) {
    guard isEnabled, isPaired else { return }

    var payload = makePayload(for: session)
    if connectedPeripheral?.state == .connected || currentStatus == nil {
      let stats = CompanionStatsCalculator.stats(in: context)
      payload.streakDays = UInt16(clamping: stats.streakDays)
      payload.todayFocusSeconds = UInt32(clamping: stats.todayFocusSeconds)
      payload.weekMinutes = stats.weekMinutes.map { UInt16(clamping: $0) }
    } else if let previous = currentStatus {
      // Nothing is listening, so skip the year-long session fetch; the
      // reconnect flow re-pushes via onStatusRefreshNeeded with fresh stats.
      payload.streakDays = previous.streakDays
      payload.todayFocusSeconds = previous.todayFocusSeconds
      payload.weekMinutes = previous.weekMinutes
    }

    if payload == currentStatus && !statusDirty { return }
    currentStatus = payload
    statusDirty = true
    flushPendingWrites()
  }

  func pushSessionEnded(context: ModelContext) {
    pushStatus(session: nil, context: context)
  }

  func pushTagConfig(profile: BlockedProfiles) {
    guard isEnabled, isPaired else { return }
    let url = BlockedProfiles.getProfileDeepLink(profile)
    // The protocol caps tag URLs at 128 bytes; generated deep links are far
    // shorter, and a truncated URL would be worse than no write.
    guard url.utf8.count <= Self.tagURLMaxBytes else { return }
    tagProfileId = profile.id.uuidString
    pendingTagConfigURL = url
    flushPendingWrites()
  }

  // Clears the device's NFC tag (a zero-length tag-config write, per the
  // protocol doc) and forgets the configured profile.
  func clearTagConfig() {
    guard isEnabled, isPaired else { return }
    tagProfileId = ""
    pendingTagConfigURL = ""
    flushPendingWrites()
  }

  // MARK: - Internals

  private func makePayload(for session: BlockedProfileSession?) -> CompanionStatusPayload {
    guard let session = session, session.isActive else {
      return .inactive
    }

    let expectedEnd = SessionTimeCalculator.expectedEndTime(for: session)
    return CompanionStatusPayload(
      isActive: true,
      isBreakActive: session.isBreakActive,
      isPauseActive: session.isPauseActive,
      sessionStartEpoch: Int64(session.startTime.timeIntervalSince1970),
      expectedEndEpoch: expectedEnd.map { Int64($0.timeIntervalSince1970) } ?? 0,
      profileName: session.blockedProfile.name
    )
  }

  private func ensureCentralManager() {
    guard centralManager == nil else { return }
    centralManager = CBCentralManager(
      delegate: self,
      queue: nil,
      options: [CBCentralManagerOptionRestoreIdentifierKey: Self.restoreIdentifier]
    )
  }

  private func scanIfPoweredOn() {
    guard wantsScanning, centralManager?.state == .poweredOn else { return }
    isScanning = true
    centralManager?.scanForPeripherals(withServices: [Self.serviceUUID])
  }

  private func reconnectPairedPeripheral() {
    guard let central = centralManager,
      central.state == .poweredOn,
      let identifier = UUID(uuidString: pairedIdentifier),
      connectedPeripheral == nil
    else { return }

    if let peripheral = central.retrievePeripherals(withIdentifiers: [identifier]).first {
      connect(to: peripheral)
    }
  }

  private func connect(to peripheral: CBPeripheral) {
    connectedPeripheral = peripheral
    peripheral.delegate = self
    // Pending connects persist until the device comes into range, at no cost.
    centralManager?.connect(peripheral)
  }

  private func disconnect() {
    if let peripheral = connectedPeripheral {
      centralManager?.cancelPeripheralConnection(peripheral)
    }
    clearPeripheralState()
  }

  // Drops all references to the current peripheral without cancelling the
  // connection; used when iOS has already invalidated it.
  private func clearPeripheralState() {
    connectedPeripheral = nil
    statusCharacteristic = nil
    timeSyncCharacteristic = nil
    tagConfigCharacteristic = nil
    inFlightStatusWrite = false
    inFlightTagConfigURL = nil
    isConnected = false
    isScanning = false
  }

  private func flushPendingWrites() {
    guard let peripheral = connectedPeripheral, peripheral.state == .connected else {
      reconnectPairedPeripheral()
      return
    }

    if statusDirty, !inFlightStatusWrite, let status = currentStatus,
      let characteristic = statusCharacteristic
    {
      inFlightStatusWrite = true
      statusDirty = false
      peripheral.writeValue(status.encoded(), for: characteristic, type: .withResponse)
    }

    if let url = pendingTagConfigURL, inFlightTagConfigURL == nil,
      let characteristic = tagConfigCharacteristic,
      let data = url.data(using: .utf8)
    {
      inFlightTagConfigURL = url
      pendingTagConfigURL = nil
      peripheral.writeValue(data, for: characteristic, type: .withResponse)
    }
  }

  private func writeTimeSync(to peripheral: CBPeripheral) {
    guard let characteristic = timeSyncCharacteristic else { return }
    var epoch = Int64(Date().timeIntervalSince1970).littleEndian
    let data = withUnsafeBytes(of: &epoch) { Data($0) }
    peripheral.writeValue(data, for: characteristic, type: .withResponse)
  }
}

// MARK: - CBCentralManagerDelegate

extension CompanionDeviceManager: CBCentralManagerDelegate {
  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    bluetoothState = central.state
    switch central.state {
    case .poweredOn:
      scanIfPoweredOn()
      if let peripheral = connectedPeripheral, peripheral.state == .connected {
        // Restored by iOS while already connected; didConnect will not fire
        // again, so resume service discovery here.
        isConnected = true
        peripheral.discoverServices([Self.serviceUUID])
      } else {
        reconnectPairedPeripheral()
      }
    case .poweredOff, .resetting, .unauthorized:
      // iOS invalidates peripherals here without firing
      // didDisconnectPeripheral; a stale connectedPeripheral would block
      // reconnectPairedPeripheral forever once Bluetooth comes back.
      clearPeripheralState()
    default:
      isConnected = false
    }
  }

  func centralManager(
    _ central: CBCentralManager, willRestoreState dict: [String: Any]
  ) {
    // iOS relaunched us for a BLE event; re-adopt the peripheral it kept.
    let peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] ?? []
    if let peripheral = peripherals.first(where: {
      $0.identifier.uuidString == pairedIdentifier
    }) {
      connectedPeripheral = peripheral
      peripheral.delegate = self
    }
  }

  func centralManager(
    _ central: CBCentralManager,
    didDiscover peripheral: CBPeripheral,
    advertisementData: [String: Any],
    rssi: NSNumber
  ) {
    if !discoveredPeripherals.contains(where: { $0.identifier == peripheral.identifier }) {
      discoveredPeripherals.append(peripheral)
    }
  }

  func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    isConnected = true
    peripheral.discoverServices([Self.serviceUUID])
  }

  func centralManager(
    _ central: CBCentralManager,
    didDisconnectPeripheral peripheral: CBPeripheral,
    error: Error?
  ) {
    isConnected = false
    statusCharacteristic = nil
    timeSyncCharacteristic = nil
    tagConfigCharacteristic = nil
    inFlightStatusWrite = false
    inFlightTagConfigURL = nil

    // Re-issue the connect so iOS delivers the device when it reappears.
    if isEnabled, isPaired {
      centralManager?.connect(peripheral)
    }
  }

  func centralManager(
    _ central: CBCentralManager,
    didFailToConnect peripheral: CBPeripheral,
    error: Error?
  ) {
    isConnected = false
    if isEnabled, isPaired {
      centralManager?.connect(peripheral)
    }
  }
}

// MARK: - CBPeripheralDelegate

extension CompanionDeviceManager: CBPeripheralDelegate {
  func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    guard let service = peripheral.services?.first(where: { $0.uuid == Self.serviceUUID })
    else { return }
    peripheral.discoverCharacteristics(
      [
        Self.statusCharacteristicUUID,
        Self.timeSyncCharacteristicUUID,
        Self.tagConfigCharacteristicUUID,
        Self.toggleCharacteristicUUID,
      ],
      for: service
    )
  }

  func peripheral(
    _ peripheral: CBPeripheral,
    didDiscoverCharacteristicsFor service: CBService,
    error: Error?
  ) {
    for characteristic in service.characteristics ?? [] {
      switch characteristic.uuid {
      case Self.statusCharacteristicUUID:
        statusCharacteristic = characteristic
      case Self.timeSyncCharacteristicUUID:
        timeSyncCharacteristic = characteristic
      case Self.tagConfigCharacteristicUUID:
        tagConfigCharacteristic = characteristic
      case Self.toggleCharacteristicUUID:
        // Toggle requests wake the app in the background via this subscription
        peripheral.setNotifyValue(true, for: characteristic)
      default:
        break
      }
    }

    // The device has no RTC: sync the wall clock, then re-push the current
    // truth (the device may have rebooted since the last write). The cached
    // payload goes out immediately; onStatusRefreshNeeded follows up with a
    // freshly computed one, coalesced away when nothing changed.
    writeTimeSync(to: peripheral)
    statusDirty = currentStatus != nil
    flushPendingWrites()
    onStatusRefreshNeeded?()
  }

  func peripheral(
    _ peripheral: CBPeripheral,
    didWriteValueFor characteristic: CBCharacteristic,
    error: Error?
  ) {
    switch characteristic.uuid {
    case Self.statusCharacteristicUUID:
      inFlightStatusWrite = false
      if error != nil {
        // Re-queue instead of letting the device keep stale state; the next
        // lifecycle push or reconnect delivers it.
        statusDirty = true
      } else if statusDirty {
        // A newer payload arrived while this write was in flight.
        flushPendingWrites()
      }
    case Self.tagConfigCharacteristicUUID:
      let attempted = inFlightTagConfigURL
      inFlightTagConfigURL = nil
      if error != nil {
        // Keep a newer pending URL if one superseded the failed write.
        pendingTagConfigURL = pendingTagConfigURL ?? attempted
      } else if pendingTagConfigURL != nil {
        flushPendingWrites()
      }
    default:
      break
    }
  }

  func peripheral(
    _ peripheral: CBPeripheral,
    didUpdateValueFor characteristic: CBCharacteristic,
    error: Error?
  ) {
    guard characteristic.uuid == Self.toggleCharacteristicUUID, error == nil else { return }

    let now = Date()
    let counter = characteristic.value?.first
    guard
      Self.shouldAcceptToggle(
        counter: counter, at: now, lastAcceptedAt: lastToggleRequestAt,
        lastCounter: lastToggleCounter)
    else { return }
    lastToggleRequestAt = now
    lastToggleCounter = counter

    onToggleRequested?(UUID(uuidString: tagProfileId))
  }

  // Debounces double taps and drops BLE retransmits (same counter value
  // shortly after the original). Counters can repeat after a device reboot,
  // so a match only counts as a duplicate within a short window. Pure so the
  // documented semantics stay test-locked (CompanionToggleDedupTests).
  static func shouldAcceptToggle(
    counter: UInt8?, at now: Date, lastAcceptedAt: Date, lastCounter: UInt8?
  ) -> Bool {
    guard now.timeIntervalSince(lastAcceptedAt) > 1.5 else { return false }
    if let counter = counter, counter == lastCounter,
      now.timeIntervalSince(lastAcceptedAt) < 30
    {
      return false
    }
    return true
  }
}
