import Foundation

struct WidgetProfileInfo {
  let enableStrictMode: Bool
  let enableAllowMode: Bool
  let selectedItemCount: Int
}

struct WidgetSessionInfo {
  let blockedProfileId: UUID
  let startTime: Date
  let endTime: Date?
  let breakStartTime: Date?
  let breakEndTime: Date?
  let pauseStartTime: Date?
  let pauseEndTime: Date?
}
