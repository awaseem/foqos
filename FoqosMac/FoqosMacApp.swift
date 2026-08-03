import SwiftUI

@main
struct FoqosMacApp: App {
  @StateObject private var controller: FoqosMacController
  @StateObject private var filterManager: FoqosFilterManager

  init() {
    let filterManager = FoqosFilterManager()
    _filterManager = StateObject(wrappedValue: filterManager)
    _controller = StateObject(wrappedValue: FoqosMacController(filterManager: filterManager))
  }

  var body: some Scene {
    MenuBarExtra {
      MenuBarContentView()
        .environmentObject(controller)
        .environmentObject(filterManager)
    } label: {
      Label("Foqos", systemImage: controller.isBlocking ? "hourglass.circle.fill" : "hourglass")
    }
    .menuBarExtraStyle(.window)
  }
}
