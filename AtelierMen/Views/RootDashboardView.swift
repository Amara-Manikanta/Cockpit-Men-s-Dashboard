import SwiftUI

public struct RootDashboardView: View {
    @ObservedObject var menDataStore: DataStore
    @ObservedObject var womenDataStore: WomenDataStore
    @AppStorage("app_gender_profile") private var selectedGender: String = ""

    public init(menDataStore: DataStore, womenDataStore: WomenDataStore) {
        self.menDataStore = menDataStore
        self.womenDataStore = womenDataStore
    }

    public var body: some View {
        Group {
            if selectedGender == "male" {
                MainTabView(dataStore: menDataStore, activeGenderProfile: $selectedGender)
                    .transition(.opacity)
            } else if selectedGender == "female" {
                WomenMainTabView(womenDataStore: womenDataStore, activeGenderProfile: $selectedGender)
                    .transition(.opacity)
            } else {
                GenderSelectionView(selectedGender: $selectedGender)
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedGender)
    }
}
