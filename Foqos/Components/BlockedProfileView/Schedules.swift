import SwiftUI
import WebKit

struct SchedulesView: View {
  var body: some View {
    ScrollView {
      VStack(spacing: 24) {
        // Header
        Image(systemName: "calendar.badge.clock")
          .font(.title)
          .foregroundColor(.gray)

        Text("Schedules")
          .font(.title2)
          .fontWeight(.semibold)

        Text("🚧 Coming Soon")
          .font(.subheadline)
          .fontWeight(.medium)

        Text(
          "We're working on native scheduling within the app. In the meantime, you can create custom schedules using Apple's Shortcuts app. Below is a 30 second video to help you get started."
        )
        .font(.body)
        .foregroundColor(.secondary)

        WebView(url: URL(string: "https://youtube.com/shorts/1xZeO9lg5f8")!)
          .frame(height: 500)
          .cornerRadius(12)
          .overlay(
            RoundedRectangle(cornerRadius: 12)
              .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
          )
      }
      .padding()
    }
    .navigationBarTitleDisplayMode(.inline)
  }
}

struct WebView: UIViewRepresentable {
  let url: URL

  func makeUIView(context: Context) -> WKWebView {
    let webView = WKWebView()
    webView.allowsBackForwardNavigationGestures = true
    return webView
  }

  func updateUIView(_ webView: WKWebView, context: Context) {
    let request = URLRequest(url: url)
    webView.load(request)
  }
}

#Preview {
  NavigationView {
    SchedulesView()
  }
}
