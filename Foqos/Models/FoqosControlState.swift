import Foundation

struct FoqosControlState {
  let session: SharedData.SessionSnapshot?

  init(session: SharedData.SessionSnapshot?) {
    self.session = session?.endTime == nil ? session : nil
  }

  var isBreakActive: Bool {
    session?.breakStartTime != nil && session?.breakEndTime == nil
  }

  func isProfileActive(_ profileID: String?) -> Bool {
    guard let profileID, let id = UUID(uuidString: profileID) else { return false }
    return session?.blockedProfileId == id
  }
}
