import SwiftUI

public struct WomenTripChecklistView: View {
    @ObservedObject var womenDataStore: WomenDataStore
    @Binding var activeGenderProfile: String

    @State private var isReturnMode: Bool = false
    @State private var showNewTripSheet = false
    @State private var showWardrobePicker = false
    @State private var showDeleteConfirmation = false

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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if let trip = activeTrip {
                        Menu {
                            Button(action: { showWardrobePicker = true }) {
                                Label("Select Boutique Pieces", systemImage: "tshirt.fill")
                            }

                            Button(action: { showNewTripSheet = true }) {
                                Label("New Trip List", systemImage: "plus")
                            }

                            Divider()

                            Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                                Label("Delete Trip List", systemImage: "trash")
                            }
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "plus")
                                    .font(.system(size: 12, weight: .bold))
                                Text("Manage")
                                    .font(.system(size: 13, weight: .bold))
                            }
                            .foregroundStyle(WomenLuxuryTheme.roseGold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(WomenLuxuryTheme.roseGold.opacity(0.15))
                            .clipShape(Capsule())
                        }
                    } else {
                        Button(action: { showNewTripSheet = true }) {
                            HStack(spacing: 5) {
                                Image(systemName: "plus")
                                    .font(.system(size: 12, weight: .bold))
                                Text("New List")
                                    .font(.system(size: 13, weight: .bold))
                            }
                            .foregroundStyle(WomenLuxuryTheme.roseGold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(WomenLuxuryTheme.roseGold.opacity(0.15))
                            .clipShape(Capsule())
                        }
                    }
                }
            }
            .sheet(isPresented: $showNewTripSheet) {
                NewWomenTripSheet(womenDataStore: womenDataStore)
            }
            .sheet(isPresented: $showWardrobePicker) {
                WomenWardrobeItemPickerSheet(womenDataStore: womenDataStore) { items in
                    if let trip = activeTrip, let idx = womenDataStore.trips.firstIndex(where: { $0.id == trip.id }) {
                        for item in items {
                            womenDataStore.trips[idx].packedItemIds.insert(item.id)
                        }
                        womenDataStore.saveTrips()
                    }
                }
            }
            .alert("Delete Trip List?", isPresented: $showDeleteConfirmation, presenting: activeTrip) { trip in
                Button("Delete", role: .destructive) {
                    womenDataStore.deleteTrip(id: trip.id)
                }
                Button("Cancel", role: .cancel) {}
            } message: { trip in
                Text("Are you sure you want to delete '\(trip.destination)'?")
            }
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

            Button(action: { showWardrobePicker = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Boutique Pieces to Trip")
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(WomenLuxuryTheme.roseGold)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(WomenLuxuryTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(WomenLuxuryTheme.cardBorder, lineWidth: 1)
                )
            }
            .padding(.top, 4)
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
        VStack(spacing: 16) {
            Image(systemName: "briefcase")
                .font(.system(size: 44))
                .foregroundStyle(WomenLuxuryTheme.textTertiary)
            Text("No Active Packing Lists")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(WomenLuxuryTheme.textPrimary)
            Text("Create a travel packing checklist and select the sarees, dresses, and jewelry pieces you want to bring.")
                .font(.system(size: 13))
                .foregroundStyle(WomenLuxuryTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            Button(action: { showNewTripSheet = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                    Text("Create Packing List ✨")
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.black)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(WomenLuxuryTheme.roseGold)
                .clipShape(Capsule())
            }
        }
    }
}

// MARK: - New Women Trip / Packing List Sheet with Boutique Piece Selector
public struct NewWomenTripSheet: View {
    @ObservedObject var womenDataStore: WomenDataStore
    @Environment(\.dismiss) private var dismiss

    @State private var destination = ""
    @State private var travelDate = ""
    @State private var searchQuery = ""
    @State private var selectedCategory: WomenCategory? = nil
    @State private var selectedPieceIds: Set<UUID> = []

    public init(womenDataStore: WomenDataStore) {
        self.womenDataStore = womenDataStore
    }

    private var filteredPieces: [WomenWardrobeItem] {
        var list = womenDataStore.items
        if let cat = selectedCategory {
            list = list.filter { $0.category == cat }
        }
        let q = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !q.isEmpty {
            list = list.filter {
                $0.title.lowercased().contains(q) ||
                $0.brand.lowercased().contains(q) ||
                $0.subcategory.lowercased().contains(q)
            }
        }
        return list
    }

    public var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        // Trip details
                        VStack(spacing: 12) {
                            TextField("Destination / Occasion (e.g. Udaipur Destination Wedding)", text: $destination)
                                .font(.system(size: 15, weight: .medium))
                                .padding(14)
                                .background(WomenLuxuryTheme.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .foregroundStyle(WomenLuxuryTheme.textPrimary)

                            TextField("Travel Date (e.g. Nov 14 - Nov 18)", text: $travelDate)
                                .font(.system(size: 14))
                                .padding(14)
                                .background(WomenLuxuryTheme.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .foregroundStyle(WomenLuxuryTheme.textPrimary)
                        }

                        // Boutique pieces selector
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "sparkle")
                                    .foregroundStyle(WomenLuxuryTheme.roseGold)
                                Text("SELECT BOUTIQUE PIECES TO PACK")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundStyle(WomenLuxuryTheme.textTertiary)

                                Spacer()

                                Text("\(selectedPieceIds.count) Selected")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundStyle(WomenLuxuryTheme.roseGold)
                            }

                            // Search
                            HStack(spacing: 8) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(WomenLuxuryTheme.textTertiary)
                                TextField("Search boutique pieces...", text: $searchQuery)
                                    .font(.system(size: 13))
                                    .foregroundStyle(WomenLuxuryTheme.textPrimary)
                                if !searchQuery.isEmpty {
                                    Button { searchQuery = "" } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(WomenLuxuryTheme.textTertiary)
                                    }
                                }
                            }
                            .padding(10)
                            .background(WomenLuxuryTheme.secondaryBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                            // Category filter tabs
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    Button {
                                        selectedCategory = nil
                                    } label: {
                                        Text("All (\(womenDataStore.items.count))")
                                            .font(.system(size: 11, weight: selectedCategory == nil ? .bold : .medium))
                                            .foregroundStyle(selectedCategory == nil ? Color.black : WomenLuxuryTheme.textSecondary)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(selectedCategory == nil ? WomenLuxuryTheme.roseGold : WomenLuxuryTheme.secondaryBackground)
                                            .clipShape(Capsule())
                                    }

                                    ForEach(WomenCategory.allCases) { cat in
                                        let count = womenDataStore.itemCount(for: cat)
                                        Button {
                                            selectedCategory = (selectedCategory == cat) ? nil : cat
                                        } label: {
                                            HStack(spacing: 3) {
                                                Image(systemName: cat.iconName)
                                                    .font(.system(size: 9))
                                                Text(cat.rawValue)
                                                Text("(\(count))")
                                                    .opacity(0.7)
                                            }
                                            .font(.system(size: 11, weight: selectedCategory == cat ? .bold : .medium))
                                            .foregroundStyle(selectedCategory == cat ? Color.black : WomenLuxuryTheme.textSecondary)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(selectedCategory == cat ? cat.accentColor : WomenLuxuryTheme.secondaryBackground)
                                            .clipShape(Capsule())
                                        }
                                    }
                                }
                            }

                            // Selection summary
                            HStack {
                                Text("\(filteredPieces.count) pieces available")
                                    .font(.system(size: 11))
                                    .foregroundStyle(WomenLuxuryTheme.textTertiary)
                                Spacer()
                                Button(selectedPieceIds.count == filteredPieces.count && !filteredPieces.isEmpty ? "Deselect All" : "Select All in View") {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    if selectedPieceIds.count == filteredPieces.count && !filteredPieces.isEmpty {
                                        selectedPieceIds.removeAll()
                                    } else {
                                        for p in filteredPieces {
                                            selectedPieceIds.insert(p.id)
                                        }
                                    }
                                }
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(WomenLuxuryTheme.roseGold)
                            }
                        }
                        .padding(14)
                        .womenLuxuryCardStyle(cornerRadius: 14)

                        // Pieces grid
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                            ForEach(filteredPieces) { piece in
                                let isSelected = selectedPieceIds.contains(piece.id)
                                Button {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    if isSelected {
                                        selectedPieceIds.remove(piece.id)
                                    } else {
                                        selectedPieceIds.insert(piece.id)
                                    }
                                } label: {
                                    VStack(alignment: .leading, spacing: 0) {
                                        ZStack(alignment: .topTrailing) {
                                            WomenItemImageView(photoNameOrUrl: piece.primaryPhoto, category: piece.category)
                                                .frame(height: 110)
                                                .frame(maxWidth: .infinity)
                                                .clipped()

                                            ZStack {
                                                Circle()
                                                    .fill(isSelected ? WomenLuxuryTheme.roseGold : Color.black.opacity(0.55))
                                                    .frame(width: 24, height: 24)

                                                Image(systemName: isSelected ? "checkmark" : "plus")
                                                    .font(.system(size: 11, weight: .bold))
                                                    .foregroundStyle(isSelected ? Color.black : Color.white)
                                            }
                                            .padding(6)
                                        }

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(piece.brand.uppercased())
                                                .font(.system(size: 9, weight: .bold))
                                                .foregroundStyle(piece.category.accentColor)
                                                .lineLimit(1)

                                            Text(piece.title)
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundStyle(WomenLuxuryTheme.textPrimary)
                                                .lineLimit(2)
                                                .frame(height: 28, alignment: .topLeading)

                                            Text(piece.formattedPrice)
                                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                                .foregroundStyle(WomenLuxuryTheme.champagne)
                                        }
                                        .padding(8)
                                    }
                                    .background(WomenLuxuryTheme.cardBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(isSelected ? WomenLuxuryTheme.roseGold : WomenLuxuryTheme.cardBorder, lineWidth: isSelected ? 2 : 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        Spacer(minLength: 85)
                    }
                    .padding(16)
                }

                // Floating Action Button
                VStack {
                    Button(action: {
                        if !destination.isEmpty {
                            let trip = WomenTripPlan(
                                destination: destination,
                                travelDate: travelDate.isEmpty ? "Upcoming" : travelDate,
                                packedItemIds: selectedPieceIds
                            )
                            womenDataStore.addTrip(trip)
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            dismiss()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "suitcase.fill")
                            Text("Create Packing List (\(selectedPieceIds.count) Pieces) ✨")
                        }
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(destination.isEmpty ? WomenLuxuryTheme.roseGold.opacity(0.4) : WomenLuxuryTheme.roseGold)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: destination.isEmpty ? Color.clear : WomenLuxuryTheme.roseGold.opacity(0.3), radius: 10, y: 4)
                    }
                    .disabled(destination.isEmpty)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
                .background(
                    LinearGradient(
                        colors: [Color.clear, WomenLuxuryTheme.background.opacity(0.95), WomenLuxuryTheme.background],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .background(WomenLuxuryTheme.background.ignoresSafeArea())
            .navigationTitle("New Travel Packing List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(WomenLuxuryTheme.textSecondary)
                }
            }
        }
    }
}
