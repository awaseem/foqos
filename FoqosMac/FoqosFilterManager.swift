import Foundation
import NetworkExtension
import OSLog
import SystemExtensions

final class FoqosFilterManager: NSObject, ObservableObject {
  enum Status: Equatable {
    case approvalRequired
    case disabled
    case enabled
    case failed(String)
    case installing
    case notConfigured
    case requiresRestart
    case unknown
  }

  static let extensionIdentifier = "dev.ambitionsoftware.foqos.mac.filter"

  @Published private(set) var status: Status = .unknown

  private let logger = Logger(
    subsystem: "dev.ambitionsoftware.foqos.mac",
    category: "filter-manager"
  )
  private var configurationObserver: NSObjectProtocol?
  private var activationRequest: OSSystemExtensionRequest?
  private var inspectionRequest: OSSystemExtensionRequest?
  private var isBundledExtensionActive = false
  private var latestRules: FilterRules?
  private var isSavingRules = false

  #if DEBUG
    private var developmentResetCompletion: ((Result<Bool, Error>) -> Void)?
    private var developmentResetRequest: OSSystemExtensionRequest?
  #endif

  var statusText: String {
    switch status {
    case .approvalRequired:
      return "Enable Foqos in System Settings › Network › Filters to finish setup."
    case .disabled:
      return "Active profiles cannot block websites while the network filter is disabled."
    case .enabled:
      return "Active profiles can block websites across supported browsers."
    case .failed(let message):
      return message
    case .installing:
      return "macOS may ask you to approve the Foqos network filter."
    case .notConfigured:
      return "Set up the network filter to block websites across browsers."
    case .requiresRestart:
      return "Restart your Mac to finish installing the filter."
    case .unknown:
      return "Reading the current network filter configuration."
    }
  }

  override init() {
    super.init()
    configurationObserver = NotificationCenter.default.addObserver(
      forName: .NEFilterConfigurationDidChange,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.refreshStatus()
    }
    inspectBundledExtension()
  }

  deinit {
    if let configurationObserver {
      NotificationCenter.default.removeObserver(configurationObserver)
    }
  }

  func installAndEnable() {
    guard activationRequest == nil else {
      return
    }

    isBundledExtensionActive = false
    status = .installing

    let request = OSSystemExtensionRequest.activationRequest(
      forExtensionWithIdentifier: Self.extensionIdentifier,
      queue: .main
    )
    request.delegate = self
    activationRequest = request
    OSSystemExtensionManager.shared.submitRequest(request)
  }

  private func inspectBundledExtension() {
    let request = OSSystemExtensionRequest.propertiesRequest(
      forExtensionWithIdentifier: Self.extensionIdentifier,
      queue: .main
    )
    request.delegate = self
    inspectionRequest = request
    OSSystemExtensionManager.shared.submitRequest(request)
  }

  private var bundledExtensionVersion: String? {
    guard
      let bundleURL = Bundle.main.url(
        forResource: Self.extensionIdentifier,
        withExtension: "systemextension",
        subdirectory: "Contents/Library/SystemExtensions"
      )
    else {
      return nil
    }

    return Bundle(url: bundleURL)?.object(forInfoDictionaryKey: "CFBundleVersion") as? String
  }

  func refreshStatus() {
    guard isBundledExtensionActive else {
      return
    }

    NEFilterManager.shared().loadFromPreferences { [weak self] error in
      DispatchQueue.main.async {
        guard let self else {
          return
        }

        if let error {
          self.status = .failed(error.localizedDescription)
          return
        }

        let manager = NEFilterManager.shared()
        guard manager.providerConfiguration != nil else {
          self.status = .notConfigured
          return
        }

        self.status = manager.isEnabled ? .enabled : .disabled
      }
    }
  }

  func setRules(_ rules: FilterRules) {
    guard latestRules != rules else {
      return
    }

    latestRules = rules
    saveLatestRulesIfNeeded()
  }

  #if DEBUG
    func resetForDevelopment(completion: @escaping (Result<Bool, Error>) -> Void) {
      guard developmentResetCompletion == nil else {
        return
      }

      developmentResetCompletion = completion

      let manager = NEFilterManager.shared()
      manager.loadFromPreferences { [weak self] error in
        DispatchQueue.main.async {
          guard let self else {
            return
          }

          if let error {
            self.finishDevelopmentReset(.failure(error))
            return
          }

          guard manager.providerConfiguration != nil || manager.localizedDescription != nil else {
            self.deactivateExtensionForDevelopment()
            return
          }

          manager.removeFromPreferences { error in
            DispatchQueue.main.async {
              if let error {
                self.finishDevelopmentReset(.failure(error))
              } else {
                self.deactivateExtensionForDevelopment()
              }
            }
          }
        }
      }
    }

    private func deactivateExtensionForDevelopment() {
      let request = OSSystemExtensionRequest.deactivationRequest(
        forExtensionWithIdentifier: Self.extensionIdentifier,
        queue: .main
      )
      request.delegate = self
      developmentResetRequest = request
      OSSystemExtensionManager.shared.submitRequest(request)
    }

    private func finishDevelopmentReset(_ result: Result<Bool, Error>) {
      let completion = developmentResetCompletion
      developmentResetCompletion = nil
      developmentResetRequest = nil
      completion?(result)
    }
  #endif

  private func configureFilter() {
    let manager = NEFilterManager.shared()
    manager.loadFromPreferences { [weak self] error in
      guard let self, error == nil else {
        DispatchQueue.main.async {
          self?.status = .failed(error?.localizedDescription ?? "Unable to load filter settings.")
        }
        return
      }

      let configuration = NEFilterProviderConfiguration()
      configuration.filterDataProviderBundleIdentifier = Self.extensionIdentifier
      configuration.filterPackets = false
      configuration.filterSockets = true
      configuration.organization = "Foqos"
      configuration.vendorConfiguration = self.vendorConfiguration(
        for: self.latestRules ?? .disabled)

      manager.localizedDescription = "Foqos Website Filter"
      manager.providerConfiguration = configuration
      manager.isEnabled = true
      manager.saveToPreferences { error in
        DispatchQueue.main.async {
          if let error {
            self.status = .failed(error.localizedDescription)
          } else {
            self.status = .enabled
          }
        }
      }
    }
  }

  private func saveLatestRulesIfNeeded() {
    guard !isSavingRules else {
      return
    }

    guard let rules = latestRules else {
      return
    }

    isSavingRules = true

    let manager = NEFilterManager.shared()
    manager.loadFromPreferences { [weak self] error in
      DispatchQueue.main.async {
        guard
          let self,
          error == nil,
          let configuration = manager.providerConfiguration
        else {
          self?.finishSavingRules(rules, error: error)
          return
        }

        configuration.vendorConfiguration = self.vendorConfiguration(for: rules)
        manager.providerConfiguration = configuration
        manager.saveToPreferences { error in
          DispatchQueue.main.async {
            self.finishSavingRules(rules, error: error)
          }
        }
      }
    }
  }

  private func finishSavingRules(_ savedRules: FilterRules, error: Error?) {
    if let error {
      status = .failed(error.localizedDescription)
    }

    isSavingRules = false

    if latestRules != savedRules {
      saveLatestRulesIfNeeded()
    }
  }

  private func vendorConfiguration(for rules: FilterRules) -> [String: Any]? {
    guard let data = try? JSONEncoder().encode(rules) else {
      return nil
    }

    return [FilterRules.vendorConfigurationKey: data]
  }
}

extension FoqosFilterManager: OSSystemExtensionRequestDelegate {
  func request(
    _ request: OSSystemExtensionRequest,
    actionForReplacingExtension existing: OSSystemExtensionProperties,
    withExtension extension: OSSystemExtensionProperties
  ) -> OSSystemExtensionRequest.ReplacementAction {
    .replace
  }

  func request(
    _ request: OSSystemExtensionRequest,
    didFailWithError error: Error
  ) {
    #if DEBUG
      if request === developmentResetRequest {
        let resetError = error as NSError
        if resetError.domain == OSSystemExtensionErrorDomain,
          resetError.code == OSSystemExtensionError.extensionNotFound.rawValue
        {
          finishDevelopmentReset(.success(false))
        } else {
          finishDevelopmentReset(.failure(error))
        }
        return
      }
    #endif

    if request === inspectionRequest {
      inspectionRequest = nil
      logger.error("Unable to inspect installed filter version: \(error.localizedDescription)")
      status = .disabled
      return
    }

    if request === activationRequest {
      activationRequest = nil
    }

    status = .failed(error.localizedDescription)
  }

  func request(
    _ request: OSSystemExtensionRequest,
    didFinishWithResult result: OSSystemExtensionRequest.Result
  ) {
    #if DEBUG
      if request === developmentResetRequest {
        switch result {
        case .completed:
          finishDevelopmentReset(.success(false))
        case .willCompleteAfterReboot:
          finishDevelopmentReset(.success(true))
        @unknown default:
          finishDevelopmentReset(
            .failure(
              NSError(
                domain: "FoqosDevelopmentReset",
                code: 1,
                userInfo: [
                  NSLocalizedDescriptionKey: "The system returned an unknown reset result."
                ]
              )
            )
          )
        }
        return
      }
    #endif

    if request === inspectionRequest {
      inspectionRequest = nil
      return
    }

    guard request === activationRequest else {
      return
    }

    activationRequest = nil

    switch result {
    case .completed:
      isBundledExtensionActive = true
      configureFilter()
    case .willCompleteAfterReboot:
      status = .requiresRestart
    @unknown default:
      status = .failed("The system returned an unknown filter installation result.")
    }
  }

  func requestNeedsUserApproval(_ request: OSSystemExtensionRequest) {
    status = .approvalRequired
  }

  func request(
    _ request: OSSystemExtensionRequest,
    foundProperties properties: [OSSystemExtensionProperties]
  ) {
    guard request === inspectionRequest else {
      return
    }

    let installedExtensions = properties.map { properties in
      FilterExtensionVersionPolicy.InstalledExtension(
        bundleVersion: properties.bundleVersion,
        isEnabled: properties.isEnabled
      )
    }
    let versionStatus = FilterExtensionVersionPolicy.status(
      bundledVersion: bundledExtensionVersion,
      installedExtensions: installedExtensions
    )

    switch versionStatus {
    case .current:
      isBundledExtensionActive = true
      refreshStatus()
    case .notConfigured:
      isBundledExtensionActive = false
      status = .notConfigured
    case .requiresUpdate(let installedVersion):
      logger.info(
        "Updating installed filter version \(installedVersion, privacy: .public) to the bundled version."
      )
      installAndEnable()
    }
  }
}
