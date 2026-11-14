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

#Preview("Timer · Small", as: .systemSmall) {
  ProfileControlWidget()
} timeline: {
  WidgetPreviewData.entry(
    activeSession: WidgetPreviewData.session(focusedFor: 15 * 60, remaining: 45 * 60))
}

#Preview("Timer · Inline", as: .accessoryInline) {
  ProfileControlWidget()
} timeline: {
  WidgetPreviewData.entry(
    activeSession: WidgetPreviewData.session(focusedFor: 15 * 60, remaining: 45 * 60))
}

#Preview("Expired timer · Circular", as: .accessoryCircular) {
  ProfileControlWidget()
} timeline: {
  WidgetPreviewData.entry(
    activeSession: WidgetPreviewData.session(focusedFor: 61 * 60, remaining: -60))
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

#Preview("Break countdown · Circular", as: .accessoryCircular) {
  ProfileControlWidget()
} timeline: {
  WidgetPreviewData.entry(
    activeSession: WidgetPreviewData.session(
      focusedFor: 30 * 60, remaining: nil, isOnBreak: true, breakOrPauseRemaining: 10 * 60))
}

#Preview("Pause countdown · Circular", as: .accessoryCircular) {
  ProfileControlWidget()
} timeline: {
  WidgetPreviewData.entry(
    activeSession: WidgetPreviewData.session(
      focusedFor: 30 * 60, remaining: nil, isPaused: true, breakOrPauseRemaining: 10 * 60))
}
