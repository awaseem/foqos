import SwiftUI

struct ProfileIndicators: View {
    let enableLiveActivity: Bool
    let hasReminders: Bool
    let enableBreaks: Bool
    let enableStrictMode: Bool

    var body: some View {
        HStack(spacing: 16) {
            indicatorView(isEnabled: enableLiveActivity, label: "Live Activity")
            indicatorView(isEnabled: hasReminders, label: "Reminders")
            indicatorView(isEnabled: enableBreaks, label: "Breaks")
            indicatorView(isEnabled: enableStrictMode, label: "Strict")
        }
    }

    private func indicatorView(isEnabled: Bool, label: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(
                    isEnabled
                        ? Color.green.opacity(0.85)
                        : Color.gray.opacity(0.35)
                )
                .frame(width: 6, height: 6)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ProfileIndicators(
            enableLiveActivity: true,
            hasReminders: true,
            enableBreaks: false,
            enableStrictMode: false
        )
        ProfileIndicators(
            enableLiveActivity: false,
            hasReminders: false,
            enableBreaks: true,
            enableStrictMode: true
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
