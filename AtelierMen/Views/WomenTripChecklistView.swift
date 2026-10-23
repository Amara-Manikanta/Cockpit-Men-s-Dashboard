import SwiftUI

public struct WomenTripChecklistView: View {
    @ObservedObject var womenDataStore: WomenDataStore
    @Binding var activeGenderProfile: String

    @State private var isReturnMode: Bool = false
    @State private var showNewTripSheet = false

    public init(womenDataStore: WomenDataStore, activeGenderProfile: Binding<String>) {
        self.womenDataStore = womenDataStore
        self._activeGenderProfile = activeGenderProfile
    }

    private var activeTrip: WomenTripPlan? {
        womenDataStore.trips.first
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Switcher Header
                    profileSwitcherHeader
                        .padding(.horizontal)
                        .padding(.top, 4)

                    if let trip = activeTrip {
                        tripHeaderCard(trip: trip)
                            .padding(.horizontal)

                        modeToggleBar
                            .padding(.horizontal)

                        itemsChecklistSection(trip: trip)
                            .padding(.horizontal)
                    } else {
                        emptyTripsView
                            .padding(.top, 40)
                    }

                    Spacer(minLength: 80)
                }
            }
            .background(WomenLuxuryTheme.background.ignoresSafeArea())
            .navigationTitle("Travel Packing")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var profileSwitcherHeader: some View {
        HStack {
            HStack(spacing: 6) {
                Text("👗")
                Text("WOMEN'S PACKING")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .tracking(1.2)
                    .foregroundStyle(WomenLuxuryTheme.roseGold)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(WomenLuxuryTheme.cardBackground)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(WomenLuxuryTheme.roseGold.opacity(0.3), lineWidth: 1))

            Spacer()

            Button(action: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    activeGenderProfile = "male"
                }
            }) {
                HStack(spacing: 5) {
                    Text("🎩")
                    Text("Switch to Men's")
                        .font(.system(size: 12, weight: .bold))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .bold))
                }
                .foregroundStyle(LuxuryTheme.accentAmber)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(LuxuryTheme.cardBackground)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(LuxuryTheme.accentAmber.opacity(0.4), lineWidth: 1))
            }
        }
    }

    private func tripHeaderCard(trip: WomenTripPlan) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "airplane.departure")
                    .foregroundStyle(WomenLuxuryTheme.roseGold)
                Text(trip.destination.uppercased())
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(WomenLuxuryTheme.textPrimary)

                Spacer()

                Text(trip.travelDate)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(WomenLuxuryTheme.champagne)
            }

            Text("Before & After Trip Checklist. Ensures high-value jewelry and couture pieces safely return to your home vault without being left behind.")
                .font(.system(size: 12))
                .foregroundStyle(WomenLuxuryTheme.textSecondary)
        }
        .padding(18)
        .womenLuxuryCardStyle(cornerRadius: 18)
    }

    private var modeToggleBar: some View {
        HStack(spacing: 0) {
            Button(action: { withAnimation { isReturnMode = false } }) {
                HStack(spacing: 6) {
                    Image(systemName: "suitcase.fill")
                    Text("1. Packing for Trip")
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(!isReturnMode ? Color.black : WomenLuxuryTheme.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(!isReturnMode ? WomenLuxuryTheme.roseGold : Color.clear)
                .clipShape(Capsule())
            }

            Button(action: { withAnimation { isReturnMode = true } }) {
                HStack(spacing: 6) {
                    Image(systemName: "house.fill")
                    Text("2. Safe Return Home")
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(isReturnMode ? Color.black : WomenLuxuryTheme.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(isReturnMode ? WomenLuxuryTheme.champagne : Color.clear)
                .clipShape(Capsule())
            }
        }
        .padding(4)
        .background(WomenLuxuryTheme.cardBackground)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(WomenLuxuryTheme.cardBorder, lineWidth: 1))
    }

    private func itemsChecklistSection(trip: WomenTripPlan) -> some View {
        let tripItems = womenDataStore.items.filter { trip.packedItemIds.contains($0.id) }

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(isReturnMode ? "UNPACKING & VAULT VERIFICATION" : "PIECES IN TRAVEL CHECKLIST")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .tracking(1.2)
                    .foregroundStyle(WomenLuxuryTheme.textTertiary)

                Spacer()

                Text("\(tripItems.count) items")
                    .font(.system(size: 11))
                    .foregroundStyle(WomenLuxuryTheme.textTertiary)
            }

            ForEach(tripItems) { item in
                let isChecked = isReturnMode ? trip.returnedItemIds.contains(item.id) : true

                HStack(spacing: 12) {
                    WomenItemImageView(photoNameOrUrl: item.primaryPhoto, category: item.category)
                        .frame(width: 55, height: 65)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.brand.uppercased())
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(item.category.accentColor)

                        Text(item.title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(WomenLuxuryTheme.textPrimary)
                            .lineLimit(1)

                        if isReturnMode {
                            HStack(spacing: 4) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(WomenLuxuryTheme.champagne)
                                Text("Return to: \(item.storageLocation)")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(WomenLuxuryTheme.roseGold)
                            }
                        } else {
                            Text(item.formattedPrice)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(WomenLuxuryTheme.champagne)
                        }
                    }

                    Spacer()

                    Button(action: {
                        toggleCheck(for: item, in: trip)
                    }) {
                        Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 22))
                            .foregroundStyle(isChecked ? WomenLuxuryTheme.roseGold : WomenLuxuryTheme.textTertiary)
                    }
                }
                .padding(12)
                .womenLuxuryCardStyle(cornerRadius: 12)
            }
        }
    }

    private func toggleCheck(for item: WomenWardrobeItem, in trip: WomenTripPlan) {
        if let idx = womenDataStore.trips.firstIndex(where: { $0.id == trip.id }) {
            var updated = womenDataStore.trips[idx]
            if isReturnMode {
                if updated.returnedItemIds.contains(item.id) {
                    updated.returnedItemIds.remove(item.id)
                } else {
                    updated.returnedItemIds.insert(item.id)
                }
            }
            womenDataStore.trips[idx] = updated
            womenDataStore.saveTrips()
        }
    }

    private var emptyTripsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "briefcase")
                .font(.system(size: 40))
                .foregroundStyle(WomenLuxuryTheme.textTertiary)
            Text("No Active Trips")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(WomenLuxuryTheme.textPrimary)
        }
    }
}
