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
