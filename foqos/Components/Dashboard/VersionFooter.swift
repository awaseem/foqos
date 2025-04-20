import SwiftUI

struct VersionFooter: View {
    // Get the current app version from the bundle
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            ?? "1.0"
    }

    var body: some View {
        VStack(spacing: 10) {
            Text("Version \(appVersion)")
                .font(.footnote)
                .foregroundColor(.secondary)

            Text("Made with ❤️ in Calgary, AB 🇨🇦")
                .font(.footnote)
                .foregroundColor(.secondary)

            Link(
                "Ambition Software Inc.",
                destination: URL(string: "https://www.ambitionsoftware.dev/")!
            )
            .font(.footnote)
            .tint(.blue)
        }
        .padding(.bottom, 8)
    }
}

// Preview provider for SwiftUI canvas
struct VersionFooter_Previews: PreviewProvider {
    static var previews: some View {
        VersionFooter()
    }
}
