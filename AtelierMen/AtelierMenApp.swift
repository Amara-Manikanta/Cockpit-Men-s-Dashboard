import SwiftUI

@main
struct AtelierMenApp: App {
    @StateObject private var dataStore = DataStore()
    @StateObject private var womenDataStore = WomenDataStore()

    init() {
        // Configure standard UIKit Dark Luxury Appearance
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor(LuxuryTheme.background)
        tabAppearance.stackedLayoutAppearance.selected.iconColor = UIColor(LuxuryTheme.accentAmber)
        tabAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(LuxuryTheme.accentAmber)
        ]
        tabAppearance.stackedLayoutAppearance.normal.iconColor = UIColor(LuxuryTheme.textTertiary)
        tabAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(LuxuryTheme.textTertiary)
        ]
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance

        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor(LuxuryTheme.background)
        navAppearance.titleTextAttributes = [
            .foregroundColor: UIColor(LuxuryTheme.textPrimary)
        ]
        navAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(LuxuryTheme.textPrimary)
        ]
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
    }

    var body: some Scene {
        WindowGroup {
            RootDashboardView(menDataStore: dataStore, womenDataStore: womenDataStore)
                .preferredColorScheme(.dark)
                .background(Color.black.ignoresSafeArea())
        }
    }
}
