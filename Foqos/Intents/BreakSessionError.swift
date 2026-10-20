import Foundation

enum BreakSessionError: LocalizedError, Equatable {
  case noActiveSession
  case breaksUnavailable(profileName: String)
  case pauseActive(profileName: String)
  case allowanceExhausted(profileName: String)
  case schedulingFailed(reason: String)

  var errorDescription: String? {
    switch self {
    case .noActiveSession:
      return "Start a Foqos session before taking a break."
    case .breaksUnavailable(let profileName):
      return
        "A break is not available for \(profileName). Check its break settings and blocking strategy."
    case .pauseActive(let profileName):
      return "End the active pause before taking a break from \(profileName)."
    case .allowanceExhausted(let profileName):
      return "No break time remains for \(profileName)."
    case .schedulingFailed(let reason):
      return "Could not schedule the end of the break: \(reason)"
    }
  }
}
