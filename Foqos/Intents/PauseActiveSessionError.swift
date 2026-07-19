import Foundation

enum PauseActiveSessionError: LocalizedError, Equatable {
  case noActiveSession
  case unsupportedStrategy(profileName: String)
  case alreadyPaused(profileName: String)
  case breakActive(profileName: String)
  case missingPauseConfiguration(profileName: String)
  case schedulingFailed(profileName: String, reason: String)

  var errorDescription: String? {
    switch self {
    case .noActiveSession:
      return "No active Foqos session to pause."
    case .unsupportedStrategy(let profileName):
      return "\(profileName) does not use a strategy that supports pausing."
    case .alreadyPaused(let profileName):
      return "\(profileName) is already paused."
    case .breakActive(let profileName):
      return "End the active break before pausing \(profileName)."
    case .missingPauseConfiguration(let profileName):
      return "\(profileName) does not have a pause duration configured."
    case .schedulingFailed(let profileName, let reason):
      return "Could not pause \(profileName): \(reason)"
    }
  }
}
