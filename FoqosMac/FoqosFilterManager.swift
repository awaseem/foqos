import Foundation
import NetworkExtension
import SystemExtensions

final class FoqosFilterManager: NSObject, ObservableObject {
  enum Status: Equatable {
    case activatingExtension
    case approvalRequired
    case configuringFilter
    case disabled
    case enabled
    case failed(String)
    case notConfigured
    case requiresRestart
    case unknown

    var diagnosticName: String {
      switch self {
      case .activatingExtension: return "activating_extension"
      case .approvalRequired: return "approval_required"
      case .configuringFilter: return "configuring_filter"
      case .disabled: return "disabled"
      case .enabled: return "enabled"
      case .failed: return "failed"
      case .notConfigured: return "not_configured"
      case .requiresRestart: return "requires_restart"
      case .unknown: return "unknown"
      }
    }
  }

  static let extensionIdentifier = "dev.ambitionsoftware.foqos.mac.filter"

  @Published private(set) var status: Status = .unknown {
    didSet {
      guard status != oldValue else { return }
      let fields = [
        "previousStatus": oldValue.diagnosticName, "status": status.diagnosticName,
        "bundledExtensionActive": String(isBundledExtensionActive),
      ]
      diagnostics.record(
        "filter.status_changed",
        status.diagnosticName == "failed"
          ? "Filter setup or configuration failed. See the preceding error event." : statusText,
        level: status.diagnosticName == "failed" ? .error : .info, fields: fields
      )
      diagnostics.updateState("filter", fields: fields)
    }
  }

  private let diagnostics = MacDiagnostics.shared
  private var configurationObserver: NSObjectProtocol?
  private var activationRequest: OSSystemExtensionRequest?
  private var inspectionRequest: OSSystemExtensionRequest?
  private var isBundledExtensionActive = false
  private var latestRules: FilterRules?
  private var latestRulesAttemptID: String?
  private var isSavingRules = false
  private var activationID: String?
  private var inspectionID: String?

  #if DEBUG
    private var developmentResetCompletion: ((Result<Bool, Error>) -> Void)?
    private var developmentResetRequest: OSSystemExtensionRequest?
  #endif

  var statusText: String {
    switch status {
    case .activatingExtension:
      return "Installing the Foqos network extension."
    case .approvalRequired:
      return """
        In Login Items & Extensions, scroll down to Extensions, choose By Category, then enable \
        Foqos Website Filter under Network Extensions.
        """
    case .configuringFilter:
      return "Choose Allow when macOS asks Foqos to filter network content."
    case .disabled:
      return "Active profiles cannot block websites while the network filter is disabled."
    case .enabled:
      return "Active profiles can block websites across supported browsers."
    case .failed(let message):
      return message
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
      self?.diagnostics.record(
        "filter.configuration_changed",
        "macOS reported a filter configuration change; rechecking status.")
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
      diagnostics.record(
        "onboarding.activation_pending", "An extension activation request is already pending.",
        fields: ["operationID": activationID ?? "unknown"])
      return
    }

    activationID = UUID().uuidString
    diagnostics.record(
      "onboarding.activation_requested",
      "Requesting installation or activation of the bundled network extension.",
      fields: [
        "operationID": activationID!, "bundledVersion": bundledExtensionVersion ?? "missing",
      ])
    isBundledExtensionActive = false
    status = .activatingExtension

    let request = OSSystemExtensionRequest.activationRequest(
      forExtensionWithIdentifier: Self.extensionIdentifier,
      queue: .main
    )
    request.delegate = self
    activationRequest = request
    OSSystemExtensionManager.shared.submitRequest(request)
  }

  private func inspectBundledExtension() {
    inspectionID = UUID().uuidString
    diagnostics.record(
      "onboarding.inspection_requested",
      "Asking macOS which Foqos extension versions are installed.",
      fields: [
        "operationID": inspectionID!, "bundledVersion": bundledExtensionVersion ?? "missing",
      ])
    diagnostics.updateState(
      "filter",
      fields: [
        "status": status.diagnosticName, "bundledVersion": bundledExtensionVersion ?? "missing",
      ])
    let request = OSSystemExtensionRequest.propertiesRequest(
      forExtensionWithIdentifier: Self.extensionIdentifier,
      queue: .main
    )
    request.delegate = self
    inspectionRequest = request
    OSSystemExtensionManager.shared.submitRequest(request)
  }

  private var bundledExtensionVersion: String? {
    FilterExtensionBundleLocator.bundleVersion(
      in: Bundle.main.bundleURL,
      extensionIdentifier: Self.extensionIdentifier
    )
  }

  func refreshStatus() {
    guard isBundledExtensionActive else {
      diagnostics.record(
        "filter.status_deferred",
        "Cannot read filter readiness until the bundled extension is confirmed active.",
        fields: ["status": status.diagnosticName])
      return
    }

    let operationID = UUID().uuidString
    diagnostics.record(
      "filter.status_requested", "Loading saved filter preferences from macOS.",
      fields: ["operationID": operationID])
    NEFilterManager.shared().loadFromPreferences { [weak self] error in
      DispatchQueue.main.async {
        guard let self else {
          return
        }

        if let error {
          self.diagnostics.record(
            "filter.status_failed", "macOS could not load filter preferences.", level: .error,
            fields: MacDiagnostics.errorFields(error).merging(["operationID": operationID]) {
              _, new in new
            })
          self.status = .failed(error.localizedDescription)
          return
        }

        let manager = NEFilterManager.shared()
        self.diagnostics.record(
          "filter.status_loaded", "Read saved filter preferences from macOS.",
          fields: [
            "operationID": operationID,
            "hasConfiguration": String(manager.providerConfiguration != nil),
            "enabled": String(manager.isEnabled),
          ])
        guard manager.providerConfiguration != nil else {
          self.status = .notConfigured
          return
        }

        self.status = manager.isEnabled ? .enabled : .disabled
      }
    }
  }

  func setRules(_ rules: FilterRules, attemptID: String? = nil) {
    let fields = [
      "attemptID": attemptID ?? "none", "domainCount": String(rules.domains.count),
      "enabled": String(rules.isEnabled),
    ]
    guard latestRules != rules else {
      diagnostics.record(
        "filter.rules_unchanged",
        "Rules match the last requested rules; no new save is scheduled. This does not confirm a previous save succeeded.",
        fields: fields)
      return
    }

    diagnostics.record(
      "filter.rules_received", "Received a new desired rule set from the Mac app.", fields: fields)
    latestRules = rules
    latestRulesAttemptID = attemptID
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
    let operationID = activationID ?? UUID().uuidString
    diagnostics.record(
      "onboarding.configuration_requested",
      "Loading preferences before enabling content filtering.", fields: ["operationID": operationID]
    )
    status = .configuringFilter

    let manager = NEFilterManager.shared()
    manager.loadFromPreferences { [weak self] error in
      guard let self, error == nil else {
        DispatchQueue.main.async {
          self?.diagnostics.record(
            "onboarding.configuration_failed", "Could not load filter preferences during setup.",
            level: .error,
            fields: (error.map(MacDiagnostics.errorFields) ?? [:]).merging([
              "operationID": operationID, "stage": "load_preferences",
            ]) { _, new in new })
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
      self.diagnostics.record(
        "onboarding.permission_requested",
        "Saving the enabled filter configuration; macOS may be waiting for the user to allow content filtering.",
        fields: [
          "operationID": operationID, "domainCount": String(self.latestRules?.domains.count ?? 0),
        ])
      manager.saveToPreferences { error in
        DispatchQueue.main.async {
          if let error {
            self.diagnostics.record(
              "onboarding.configuration_failed",
              "macOS did not save the enabled filter configuration.", level: .error,
              fields: MacDiagnostics.errorFields(error).merging([
                "operationID": operationID, "stage": "save_preferences",
              ]) { _, new in new })
            self.status = .failed(error.localizedDescription)
          } else {
            self.diagnostics.record(
              "onboarding.configuration_saved",
              "macOS saved the enabled filter configuration. Setup can be completed.",
              fields: ["operationID": operationID])
            self.status = .enabled
          }
        }
      }
    }
  }

  private func saveLatestRulesIfNeeded() {
    guard !isSavingRules else {
      diagnostics.record(
        "filter.rules_queued",
        "A save is in progress; the newest rules will be checked when it finishes.",
        fields: ["attemptID": latestRulesAttemptID ?? "none"])
      return
    }

    guard let rules = latestRules else {
      return
    }

    isSavingRules = true
    let fields = [
      "operationID": UUID().uuidString, "attemptID": latestRulesAttemptID ?? "none",
      "domainCount": String(rules.domains.count), "enabled": String(rules.isEnabled),
    ]
    diagnostics.record(
      "filter.rules_save_requested", "Loading preferences before saving the desired rules.",
      fields: fields)

    let manager = NEFilterManager.shared()
    manager.loadFromPreferences { [weak self] error in
      DispatchQueue.main.async {
        guard let self else { return }
        if let error {
          self.diagnostics.record(
            "filter.rules_failed", "Could not load preferences for the rule update.", level: .error,
            fields: fields.merging(MacDiagnostics.errorFields(error)) { _, new in new })
          self.finishSavingRules(rules, error: error)
          return
        }
        guard let configuration = manager.providerConfiguration else {
          self.diagnostics.record(
            "filter.rules_deferred",
            "No filter configuration exists yet. Desired rules are retained for onboarding; nothing was saved.",
            level: .warning, fields: fields)
          self.finishSavingRules(rules, error: nil)
          return
        }

        configuration.vendorConfiguration = self.vendorConfiguration(for: rules)
        manager.providerConfiguration = configuration
        manager.saveToPreferences { error in
          DispatchQueue.main.async {
            if let error {
              self.diagnostics.record(
                "filter.rules_failed", "macOS did not save the rule update.", level: .error,
                fields: fields.merging(MacDiagnostics.errorFields(error)) { _, new in new })
            } else {
              self.diagnostics.record(
                "filter.rules_saved",
                "macOS saved the rule configuration. Extension enforcement has not been verified.",
                fields: fields)
            }
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
    do {
      let data = try JSONEncoder().encode(rules)
      return [FilterRules.vendorConfigurationKey: data]
    } catch {
      diagnostics.record(
        "filter.rules_encode_failed", "Unable to encode rules for macOS filter configuration.",
        level: .error, fields: MacDiagnostics.errorFields(error))
      return nil
    }
  }
}

extension FoqosFilterManager: OSSystemExtensionRequestDelegate {
  func request(
    _ request: OSSystemExtensionRequest,
    actionForReplacingExtension existing: OSSystemExtensionProperties,
    withExtension extension: OSSystemExtensionProperties
  ) -> OSSystemExtensionRequest.ReplacementAction {
    diagnostics.record(
      "onboarding.extension_replacement",
      "macOS asked to replace the installed extension; accepting the bundled version.",
      fields: [
        "operationID": activationID ?? "unknown", "installedVersion": existing.bundleVersion,
        "replacementVersion": `extension`.bundleVersion,
      ])
    return .replace
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
      diagnostics.record(
        "onboarding.inspection_failed",
        "macOS could not inspect the installed extension; setup will be offered.", level: .error,
        fields: MacDiagnostics.errorFields(error).merging(["operationID": inspectionID ?? "unknown"]
        ) { _, new in new })
      status = .disabled
      return
    }

    if request === activationRequest {
      diagnostics.record(
        "onboarding.activation_failed", "macOS rejected or failed extension activation.",
        level: .error,
        fields: MacDiagnostics.errorFields(error).merging(["operationID": activationID ?? "unknown"]
        ) { _, new in new })
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
      diagnostics.record(
        "onboarding.activation_completed",
        "macOS completed extension activation; configuring content filtering next.",
        fields: ["operationID": activationID ?? "unknown"])
      isBundledExtensionActive = true
      configureFilter()
    case .willCompleteAfterReboot:
      diagnostics.record(
        "onboarding.restart_required", "Extension activation will complete after the Mac restarts.",
        level: .warning, fields: ["operationID": activationID ?? "unknown"])
      status = .requiresRestart
    @unknown default:
      diagnostics.record(
        "onboarding.activation_unknown_result", "macOS returned an unrecognized activation result.",
        level: .error,
        fields: ["operationID": activationID ?? "unknown", "result": String(result.rawValue)])
      status = .failed("The system returned an unknown filter installation result.")
    }
  }

  func requestNeedsUserApproval(_ request: OSSystemExtensionRequest) {
    guard request === activationRequest else {
      return
    }

    status = .approvalRequired
    diagnostics.record(
      "onboarding.approval_required",
      "Waiting for the user to enable Foqos in Login Items & Extensions, under Network Extensions.",
      fields: ["operationID": activationID ?? "unknown"])
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
    diagnostics.record(
      "onboarding.inspection_completed",
      "Compared installed extension versions with the bundled extension.",
      fields: [
        "operationID": inspectionID ?? "unknown", "installedCount": String(properties.count),
        "installedVersions": properties.map(\.bundleVersion).joined(separator: ","),
        "enabledCount": String(properties.filter(\.isEnabled).count),
        "bundledVersion": bundledExtensionVersion ?? "missing",
      ])

    switch versionStatus {
    case .current:
      isBundledExtensionActive = true
      refreshStatus()
    case .notConfigured:
      isBundledExtensionActive = false
      status = .notConfigured
    case .requiresUpdate(let installedVersion):
      diagnostics.record(
        "onboarding.extension_update_required",
        "The installed extension differs from the bundled version; requesting an update.",
        fields: [
          "installedVersion": installedVersion,
          "bundledVersion": bundledExtensionVersion ?? "missing",
        ])
      installAndEnable()
    }
  }
}
