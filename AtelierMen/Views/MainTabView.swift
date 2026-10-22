import SwiftUI

public struct MainTabView: View {
    @ObservedObject var dataStore: DataStore
    @State private var selectedTab: Int = 0

    public init(dataStore: DataStore, initialTab: Int = 0) {
        self.dataStore = dataStore
        self._selectedTab = State(initialValue: initialTab)
    }

    public var body: some View {
        TabView(selection: $selectedTab) {
            VaultView(dataStore: dataStore)
                .tabItem {
                    Label("Vault", systemImage: "square.grid.2x2.fill")
                }
                .tag(0)

            WishlistView(dataStore: dataStore)
                .tabItem {
                    Label("Wishlist", systemImage: "bookmark.fill")
                }
                .tag(1)

            StylistView(dataStore: dataStore)
                .tabItem {
                    Label("Stylist", systemImage: "wand.and.stars")
                }
                .tag(2)

            TripChecklistView(dataStore: dataStore)
                .tabItem {
                    Label("Packing", systemImage: "briefcase.fill")
                }
                .tag(3)
        }
        .tint(LuxuryTheme.accentAmber)
    }
}
