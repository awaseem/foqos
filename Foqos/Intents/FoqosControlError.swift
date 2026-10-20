import Foundation

enum FoqosControlError: LocalizedError, Equatable {
  case appUnavailable
  case profileUnavailable
  case anotherProfileActive
  case backgroundStopDisabled
  case sessionChanged
  case actionFailed(String)

  static func requireAppProcess() throws {
    #if FOQOS_WIDGET_EXTENSION
      throw FoqosControlError.appUnavailable
    #endif
  }

  var errorDescription: String? {
    switch self {
    case .appUnavailable:
      return "Open Foqos and try the control again."
    case .profileUnavailable:
      return "Choose an existing Foqos profile in this control's settings."
    case .anotherProfileActive:
      return "Another Foqos profile is already active."
    case .backgroundStopDisabled:
      return "Background stops are disabled for this profile. Stop it in Foqos."
    case .sessionChanged:
      return "The active session has changed. Try the control again."
    case .actionFailed(let message):
      return message
    }
  }
}
