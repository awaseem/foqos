import SwiftUI
import WidgetKit

#Preview("Weekly · Small", as: .systemSmall) {
  ProfileControlWidget()
} timeline: {
  WidgetPreviewData.entry()
}

#Preview("Weekly · Medium", as: .systemMedium) {
  ProfileControlWidget()
} timeline: {
  WidgetPreviewData.entry()
}

#Preview("Monthly · Medium", as: .systemMedium) {
  ProfileControlWidget()
} timeline: {
  WidgetPreviewData.entry(period: .month)
}

#Preview("Idle · Circular", as: .accessoryCircular) {
  ProfileControlWidget()
} timeline: {
  WidgetPreviewData.entry()
}

#Preview("Timer · Circular", as: .accessoryCircular) {
  ProfileControlWidget()
} timeline: {
  WidgetPreviewData.entry(
    activeSession: WidgetPreviewData.session(focusedFor: 20 * 60, remaining: 40 * 60))
}

#Preview("Open-ended · Circular", as: .accessoryCircular) {
  ProfileControlWidget()
} timeline: {
  WidgetPreviewData.entry(
    activeSession: WidgetPreviewData.session(focusedFor: 75 * 60, remaining: nil))
}

#Preview("Break · Circular", as: .accessoryCircular) {
  ProfileControlWidget()
} timeline: {
  WidgetPreviewData.entry(
    activeSession: WidgetPreviewData.session(focusedFor: 30 * 60, remaining: nil, isOnBreak: true))
}
