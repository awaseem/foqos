//
//  foqosApp.swift
//  foqos
//
//  Created by Ali Waseem on 2024-10-06.
//

import SwiftData
import SwiftUI
import BackgroundTasks

@main
struct foqosApp: App {
    @StateObject private var requestAuthorizer = RequestAuthorizer()
    @StateObject private var startegyManager = StrategyManager()
    @StateObject private var donationManager = TipManager()
    @StateObject private var navigationManager = NavigationManager()
    @StateObject private var nfcWriter = NFCWriter()
    @StateObject private var ratingManager = RatingManager()
    @StateObject private var liveActivityManager = LiveActivityManager.shared
    
    init() {
        TimersUtil.registerBackgroundTasks()
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .onOpenURL() { url in
                    handleUniversalLink(url)
                }
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
                        guard let url = userActivity.webpageURL else {
                                return
                        }
                    handleUniversalLink(url)
                    
                }
                .environmentObject(requestAuthorizer)
                .environmentObject(donationManager)
                .environmentObject(startegyManager)
                .environmentObject(navigationManager)
                .environmentObject(nfcWriter)
                .environmentObject(ratingManager)
                .environmentObject(liveActivityManager)
        }
        .modelContainer(
            for: [
                BlockedProfileSession.self,
                BlockedProfiles.self,
            ]
        )
    }
    
    
    private func handleUniversalLink(_ url: URL) {
        navigationManager.handleLink(url)
    }
}
