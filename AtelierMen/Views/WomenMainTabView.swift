import SwiftUI

public struct WomenMainTabView: View {
    @ObservedObject var womenDataStore: WomenDataStore
    @Binding var activeGenderProfile: String
    @AppStorage("women_app_selected_tab") private var selectedTab: Int = 0

    public init(womenDataStore: WomenDataStore, activeGenderProfile: Binding<String>) {
        self.womenDataStore = womenDataStore
        self._activeGenderProfile = activeGenderProfile
    }

    public var body: some View {
        TabView(selection: $selectedTab) {
            WomenBoutiqueView(womenDataStore: womenDataStore, activeGenderProfile: $activeGenderProfile)
                .tabItem {
                    Label("Boutique", systemImage: "sparkles")
                }
                .tag(0)

            WomenWishlistView(womenDataStore: womenDataStore, activeGenderProfile: $activeGenderProfile)
                .tabItem {
                    Label("Wishlist", systemImage: "bookmark.fill")
                }
                .tag(1)

            WomenStylistView(womenDataStore: womenDataStore, activeGenderProfile: $activeGenderProfile)
                .tabItem {
                    Label("Stylist", systemImage: "wand.and.stars")
                }
                .tag(2)

            WomenTripChecklistView(womenDataStore: womenDataStore, activeGenderProfile: $activeGenderProfile)
                .tabItem {
                    Label("Packing", systemImage: "briefcase.fill")
                }
                .tag(3)
        }
        .tint(WomenLuxuryTheme.roseGold)
    }
}
