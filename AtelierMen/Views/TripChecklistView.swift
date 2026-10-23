import SwiftUI

public struct TripChecklistView: View {
    @ObservedObject var dataStore: DataStore

    @State private var showNewTripSheet = false
    @State private var tripToDelete: TripPlan? = nil
    @State private var showDeleteConfirmation = false

    public init(dataStore: DataStore) {
        self.dataStore = dataStore
    }

    private var totalPackedCount: Int {
        dataStore.tripPlans.reduce(0) { $0 + $1.packedCount }
    }

    private var totalItemCount: Int {
        dataStore.tripPlans.reduce(0) { $0 + $1.totalCount }
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    // Executive Packing Portfolio Banner
                    packingSummaryBanner
                        .padding(.horizontal)
                        .padding(.top, 4)

                    // Section Header
                    HStack {
                        Text("ACTIVE PACKING LISTS")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .tracking(1.4)
                            .foregroundStyle(LuxuryTheme.textTertiary)

                        Spacer()

                        Text("\(dataStore.tripPlans.count) Lists")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(LuxuryTheme.accentAmber)
                    }
                    .padding(.horizontal)

                    // List of Packing Lists (Default View)
                    if dataStore.tripPlans.isEmpty {
                        emptyTripsView
                            .padding(.top, 40)
                    } else {
                        VStack(spacing: 14) {
                            ForEach(dataStore.tripPlans) { trip in
                                NavigationLink(destination: TripDetailChecklistView(tripId: trip.id, dataStore: dataStore)) {
                                    packingListCard(trip: trip)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                    }

                    Spacer(minLength: 40)
                }
            }
            .background(LuxuryTheme.background.ignoresSafeArea())
            .navigationTitle("Packing Lists")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showNewTripSheet = true }) {
                        HStack(spacing: 5) {
                            Image(systemName: "plus")
                                .font(.system(size: 13, weight: .bold))
                            Text("New List")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundStyle(LuxuryTheme.accentAmber)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(LuxuryTheme.accentAmber.opacity(0.15))
                        .clipShape(Capsule())
                    }
                }
            }
            .sheet(isPresented: $showNewTripSheet) {
                NewTripSheet(dataStore: dataStore)
            }
            .alert("Delete Packing List?", isPresented: $showDeleteConfirmation, presenting: tripToDelete) { trip in
                Button("Delete", role: .destructive) {
                    withAnimation {
                        dataStore.deleteTripPlan(id: trip.id)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: { trip in
                Text("Are you sure you want to delete '\(trip.destination)'? This packing list and all its items will be permanently removed.")
            }
        }
    }

    // MARK: - Packing Summary Banner
    private var packingSummaryBanner: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("PACKING & TRAVEL CHECKLISTS")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .tracking(1.4)
                        .foregroundStyle(LuxuryTheme.textTertiary)

                    Text("\(dataStore.tripPlans.count) Active Lists")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundStyle(LuxuryTheme.accentAmber)
                }

                Spacer()

                ZStack {
                    Circle()
                        .fill(LuxuryTheme.accentAmber.opacity(0.15))
                        .frame(width: 52, height: 52)
                    Image(systemName: "suitcase.rolling.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(LuxuryTheme.accentAmber)
                }
            }

            // Global Packing Progress
            if totalItemCount > 0 {
                let ratio = Double(totalPackedCount) / Double(totalItemCount)
                VStack(spacing: 6) {
                    HStack {
                        Text("Overall Readiness")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(LuxuryTheme.textSecondary)
                        Spacer()
                        Text("\(totalPackedCount) of \(totalItemCount) items packed (\(Int(ratio * 100))%)")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(LuxuryTheme.accentAmber)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(LuxuryTheme.secondaryBackground)
                                .frame(height: 6)
                            Capsule()
                                .fill(LuxuryTheme.accentAmber)
                                .frame(width: max(0, min(geo.size.width * CGFloat(ratio), geo.size.width)), height: 6)
                        }
                    }
                    .frame(height: 6)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .luxuryCardStyle(cornerRadius: 16)
    }

    // MARK: - Packing List Card
    private func packingListCard(trip: TripPlan) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header Row: Destination & Delete Button
            HStack(alignment: .top) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(LuxuryTheme.secondaryBackground)
                        .frame(width: 44, height: 44)
                    Image(systemName: "briefcase.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(LuxuryTheme.accentAmber)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(trip.destination.uppercased())
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(LuxuryTheme.textPrimary)
                        .multilineTextAlignment(.leading)

                    Text("\(trip.durationDays) Days • \(trip.purpose)")
                        .font(.system(size: 12))
                        .foregroundStyle(LuxuryTheme.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                // Delete Button
                Button(action: {
                    tripToDelete = trip
                    showDeleteConfirmation = true
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.red.opacity(0.85))
                        .padding(8)
                        .background(Color.red.opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(BorderlessButtonStyle())
            }

            // Progress Bar
            VStack(spacing: 6) {
                HStack {
                    Text("\(Int(trip.progress * 100))% Packed")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(trip.progress == 1.0 ? Color.green : LuxuryTheme.accentAmber)

                    Spacer()

                    Text("\(trip.packedCount)/\(trip.totalCount) items")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(LuxuryTheme.textTertiary)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(LuxuryTheme.secondaryBackground)
                            .frame(height: 5)
                        Capsule()
                            .fill(trip.progress == 1.0 ? Color.green : LuxuryTheme.accentAmber)
                            .frame(width: max(0, min(geo.size.width * CGFloat(trip.progress), geo.size.width)), height: 5)
                    }
                }
                .frame(height: 5)
            }

            // Category Breakdown Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(ItemCategory.allCases) { cat in
                        let count = trip.items.filter { $0.category == cat }.count
                        if count > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: cat.iconName)
                                    .font(.system(size: 10))
                                Text("\(cat.rawValue) (\(count))")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundStyle(cat.accentColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(cat.accentColor.opacity(0.12))
                            .clipShape(Capsule())
                        }
                    }

                    let generalCount = trip.items.filter { $0.category == nil }.count
                    if generalCount > 0 {
                        Text("General (\(generalCount))")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(LuxuryTheme.textSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(LuxuryTheme.secondaryBackground)
                            .clipShape(Capsule())
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(LuxuryTheme.textTertiary)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .luxuryCardStyle(cornerRadius: 16)
    }

    // MARK: - Empty State
    private var emptyTripsView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(LuxuryTheme.accentAmber.opacity(0.12))
                    .frame(width: 76, height: 76)
                Image(systemName: "suitcase.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(LuxuryTheme.accentAmber)
            }

            Text("No Packing Lists Yet")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(LuxuryTheme.textPrimary)

            Text("Create an intelligent packing checklist for your next flight, business summit, or weekend getaway.")
                .font(.system(size: 13))
                .foregroundStyle(LuxuryTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            Button(action: { showNewTripSheet = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                    Text("Create First Packing List")
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.black)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(LuxuryTheme.accentAmber)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.top, 6)
        }
    }
}

// MARK: - Dedicated Detail Checklist View for Selected Packing List
public struct TripDetailChecklistView: View {
    let tripId: UUID
    @ObservedObject var dataStore: DataStore
    @Environment(\.dismiss) private var dismiss

    @State private var showAddItemSheet = false
    @State private var showWardrobePicker = false
    @State private var newItemTitle = ""
    @State private var newItemCategory: ItemCategory = .sportswear
    @State private var showDeleteConfirmation = false

    private var trip: TripPlan? {
        dataStore.tripPlans.first(where: { $0.id == tripId })
    }

    public var body: some View {
        Group {
            if let trip = trip {
                ScrollView {
                    VStack(spacing: 18) {
                        // Hero Progress Card
                        tripHeroCard(trip: trip)
                            .padding(.horizontal)
                            .padding(.top, 4)

                        // Packing Items Grouped by Category
                        ForEach(ItemCategory.allCases) { cat in
                            let items = trip.items.filter { $0.category == cat }
                            if !items.isEmpty {
                                packingGroupSection(title: cat.luxuryTag, category: cat, items: items, trip: trip)
                                    .padding(.horizontal)
                            }
                        }

                        // General Travel Essentials
                        let generalItems = trip.items.filter { $0.category == nil }
                        if !generalItems.isEmpty {
                            generalPackingSection(title: "Travel Essentials & EDC", items: generalItems, trip: trip)
                                .padding(.horizontal)
                        }

                        // Add Item Action Buttons
                        HStack(spacing: 12) {
                            Button(action: { showWardrobePicker = true }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "tshirt.fill")
                                    Text("Add From Wardrobe")
                                }
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Color.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(LuxuryTheme.accentAmber)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }

                            Button(action: { showAddItemSheet = true }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "plus")
                                    Text("Custom Item")
                                }
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(LuxuryTheme.textPrimary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(LuxuryTheme.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(LuxuryTheme.cardBorder, lineWidth: 1)
                                )
                            }
                        }
                        .padding(.horizontal)

                        Spacer(minLength: 40)
                    }
                }
                .background(LuxuryTheme.background.ignoresSafeArea())
                .navigationTitle(trip.destination)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button(action: { showWardrobePicker = true }) {
                                Label("Select from Wardrobe", systemImage: "tshirt.fill")
                            }

                            Button(action: { showAddItemSheet = true }) {
                                Label("Add Custom Item", systemImage: "plus")
                            }

                            Button(action: {
                                dataStore.markAllPacked(tripId: trip.id, packed: true)
                            }) {
                                Label("Mark All Packed", systemImage: "checkmark.circle.fill")
                            }

                            Button(action: {
                                dataStore.markAllPacked(tripId: trip.id, packed: false)
                            }) {
                                Label("Unpack All", systemImage: "circle")
                            }

                            Divider()

                            Button(role: .destructive, action: {
                                showDeleteConfirmation = true
                            }) {
                                Label("Delete Packing List", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(LuxuryTheme.accentAmber)
                        }
                    }
                }
                .sheet(isPresented: $showAddItemSheet) {
                    addItemSheet(trip: trip)
                }
                .sheet(isPresented: $showWardrobePicker) {
                    WardrobeItemPickerSheet(dataStore: dataStore) { items in
                        let newPackingItems = items.map { item in
                            PackingItem(title: item.name, category: item.category, linkedWardrobeItemId: item.id)
                        }
                        dataStore.addPackingItems(tripId: trip.id, newItems: newPackingItems)
                    }
                }
                .alert("Delete Packing List?", isPresented: $showDeleteConfirmation) {
                    Button("Delete", role: .destructive) {
                        dataStore.deleteTripPlan(id: trip.id)
                        dismiss()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("Are you sure you want to delete '\(trip.destination)'? This cannot be undone.")
                }
            } else {
                Text("Packing list not found")
                    .foregroundStyle(LuxuryTheme.textSecondary)
            }
        }
    }

    // MARK: - Hero Progress Card
    private func tripHeroCard(trip: TripPlan) -> some View {
        HStack(spacing: 18) {
            ZStack {
                Circle()
                    .stroke(LuxuryTheme.secondaryBackground, lineWidth: 8)
                    .frame(width: 72, height: 72)

                Circle()
                    .trim(from: 0, to: CGFloat(trip.progress))
                    .stroke(
                        trip.progress == 1.0 ? Color.green : LuxuryTheme.accentAmber,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 72, height: 72)
                    .animation(.spring(), value: trip.progress)

                Text("\(Int(trip.progress * 100))%")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(LuxuryTheme.textPrimary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(trip.destination.uppercased())
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(LuxuryTheme.textPrimary)

                Text(trip.purpose)
                    .font(.system(size: 12))
                    .foregroundStyle(LuxuryTheme.textSecondary)

                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 11))
                    Text("\(trip.durationDays) Days • \(trip.packedCount)/\(trip.totalCount) Packed")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                }
                .foregroundStyle(LuxuryTheme.accentAmber)
                .padding(.top, 2)
            }

            Spacer()
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .luxuryCardStyle(cornerRadius: 16)
    }

    // MARK: - Packing Group Section
    private func packingGroupSection(title: String, category: ItemCategory, items: [PackingItem], trip: TripPlan) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: category.iconName)
                    .foregroundStyle(category.accentColor)
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(LuxuryTheme.textPrimary)

                Spacer()

                let packed = items.filter { $0.isPacked }.count
                Text("\(packed)/\(items.count)")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(LuxuryTheme.textTertiary)
            }

            VStack(spacing: 8) {
                ForEach(items) { item in
                    packingItemRow(item: item, trip: trip)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .luxuryCardStyle(cornerRadius: 16)
    }

    // MARK: - General Packing Section
    private func generalPackingSection(title: String, items: [PackingItem], trip: TripPlan) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "briefcase.fill")
                    .foregroundStyle(LuxuryTheme.accentAmber)
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(LuxuryTheme.textPrimary)

                Spacer()

                let packed = items.filter { $0.isPacked }.count
                Text("\(packed)/\(items.count)")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(LuxuryTheme.textTertiary)
            }

            VStack(spacing: 8) {
                ForEach(items) { item in
                    packingItemRow(item: item, trip: trip)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .luxuryCardStyle(cornerRadius: 16)
    }

    // MARK: - Packing Item Row
    private func packingItemRow(item: PackingItem, trip: TripPlan) -> some View {
        HStack(spacing: 12) {
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                dataStore.togglePackingItem(tripId: trip.id, itemId: item.id)
            }) {
                HStack(spacing: 12) {
                    Image(systemName: item.isPacked ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 18))
                        .foregroundStyle(item.isPacked ? LuxuryTheme.accentAmber : LuxuryTheme.textTertiary)

                    Text(item.title)
                        .font(.system(size: 14, weight: item.isPacked ? .regular : .medium))
                        .foregroundStyle(item.isPacked ? LuxuryTheme.textTertiary : LuxuryTheme.textPrimary)
                        .strikethrough(item.isPacked, color: LuxuryTheme.textTertiary)

                    Spacer()

                    if item.linkedWardrobeItemId != nil {
                        Text("Vault Linked")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(LuxuryTheme.secondaryBackground)
                            .foregroundStyle(LuxuryTheme.textSecondary)
                            .clipShape(Capsule())
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())

            // Individual item delete
            Button(action: {
                dataStore.deletePackingItem(tripId: trip.id, itemId: item.id)
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(LuxuryTheme.textTertiary)
                    .padding(6)
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding(.vertical, 3)
    }

    // MARK: - Add Item Sheet
    private func addItemSheet(trip: TripPlan) -> some View {
        NavigationStack {
            VStack(spacing: 20) {
                TextField("Item name (e.g. Compression Tights, USB-C Cable)", text: $newItemTitle)
                    .font(.system(size: 15))
                    .padding(14)
                    .background(LuxuryTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(LuxuryTheme.textPrimary)

                VStack(alignment: .leading, spacing: 8) {
                    Text("CATEGORY")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(LuxuryTheme.textTertiary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(ItemCategory.allCases) { cat in
                                Button(action: { newItemCategory = cat }) {
                                    HStack(spacing: 5) {
                                        Image(systemName: cat.iconName)
                                            .font(.system(size: 11))
                                        Text(cat.rawValue)
                                            .font(.system(size: 12, weight: .bold))
                                    }
                                    .foregroundStyle(newItemCategory == cat ? Color.black : LuxuryTheme.textSecondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(newItemCategory == cat ? LuxuryTheme.accentAmber : LuxuryTheme.cardBackground)
                                    .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }

                Button(action: {
                    if !newItemTitle.trimmingCharacters(in: .whitespaces).isEmpty {
                        let newItem = PackingItem(title: newItemTitle, category: newItemCategory)
                        dataStore.addPackingItem(tripId: trip.id, item: newItem)
                        newItemTitle = ""
                        showAddItemSheet = false
                    }
                }) {
                    Text("Add to Checklist")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(newItemTitle.isEmpty ? LuxuryTheme.accentAmber.opacity(0.4) : LuxuryTheme.accentAmber)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(newItemTitle.isEmpty)

                Spacer()
            }
            .padding(20)
            .background(LuxuryTheme.background.ignoresSafeArea())
            .navigationTitle("New Packing Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { showAddItemSheet = false }
                        .foregroundStyle(LuxuryTheme.textSecondary)
                }
            }
        }
    }
}

// MARK: - New Trip / Packing List Sheet
public struct NewTripSheet: View {
    @ObservedObject var dataStore: DataStore
    @Environment(\.dismiss) private var dismiss

    @State private var destination = ""
    @State private var purpose = ""
    @State private var durationDays = 3

    // Wardrobe Selection
    @State private var searchQuery = ""
    @State private var selectedCategory: ItemCategory? = nil
    @State private var selectedWardrobeItemIds: Set<UUID> = []

    public init(dataStore: DataStore) {
        self.dataStore = dataStore
    }

    private var filteredWardrobeItems: [WardrobeItem] {
        var list = dataStore.items
        if let cat = selectedCategory {
            list = list.filter { $0.category == cat }
        }
        let q = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !q.isEmpty {
            list = list.filter {
                $0.name.lowercased().contains(q) ||
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
                        // 1. Trip Details
                        VStack(spacing: 12) {
                            TextField("Destination / Trip Name (e.g. Tokyo Tech Summit)", text: $destination)
                                .font(.system(size: 15, weight: .medium))
                                .padding(14)
                                .background(LuxuryTheme.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .foregroundStyle(LuxuryTheme.textPrimary)

                            TextField("Purpose (e.g. Keynote & Client Dinners)", text: $purpose)
                                .font(.system(size: 14))
                                .padding(14)
                                .background(LuxuryTheme.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .foregroundStyle(LuxuryTheme.textPrimary)

                            Stepper("Duration: \(durationDays) Days", value: $durationDays, in: 1...30)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(LuxuryTheme.textPrimary)
                                .padding(14)
                                .background(LuxuryTheme.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        // 2. Select Items from Wardrobe Header
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "tshirt.fill")
                                    .foregroundStyle(LuxuryTheme.accentAmber)
                                Text("SELECT ITEMS FROM WARDROBE")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundStyle(LuxuryTheme.textTertiary)

                                Spacer()

                                Text("\(selectedWardrobeItemIds.count) Selected")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundStyle(LuxuryTheme.accentAmber)
                            }

                            // Search bar
                            HStack(spacing: 8) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(LuxuryTheme.textTertiary)
                                TextField("Search closet pieces...", text: $searchQuery)
                                    .font(.system(size: 13))
                                    .foregroundStyle(LuxuryTheme.textPrimary)
                                if !searchQuery.isEmpty {
                                    Button { searchQuery = "" } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(LuxuryTheme.textTertiary)
                                    }
                                }
                            }
                            .padding(10)
                            .background(LuxuryTheme.secondaryBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                            // Category filter chips
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    Button {
                                        selectedCategory = nil
                                    } label: {
                                        Text("All (\(dataStore.items.count))")
                                            .font(.system(size: 11, weight: selectedCategory == nil ? .bold : .medium))
                                            .foregroundStyle(selectedCategory == nil ? Color.black : LuxuryTheme.textSecondary)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(selectedCategory == nil ? LuxuryTheme.accentAmber : LuxuryTheme.secondaryBackground)
                                            .clipShape(Capsule())
                                    }

                                    ForEach(ItemCategory.allCases) { cat in
                                        let count = dataStore.itemCount(for: cat)
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
                                            .foregroundStyle(selectedCategory == cat ? Color.black : LuxuryTheme.textSecondary)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(selectedCategory == cat ? cat.accentColor : LuxuryTheme.secondaryBackground)
                                            .clipShape(Capsule())
                                        }
                                    }
                                }
                            }

                            // Select / Deselect All
                            HStack {
                                Text("\(filteredWardrobeItems.count) items available")
                                    .font(.system(size: 11))
                                    .foregroundStyle(LuxuryTheme.textTertiary)
                                Spacer()
                                Button(selectedWardrobeItemIds.count == filteredWardrobeItems.count && !filteredWardrobeItems.isEmpty ? "Deselect All" : "Select All in View") {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    if selectedWardrobeItemIds.count == filteredWardrobeItems.count && !filteredWardrobeItems.isEmpty {
                                        selectedWardrobeItemIds.removeAll()
                                    } else {
                                        for it in filteredWardrobeItems {
                                            selectedWardrobeItemIds.insert(it.id)
                                        }
                                    }
                                }
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(LuxuryTheme.accentAmber)
                            }
                        }
                        .padding(14)
                        .luxuryCardStyle(cornerRadius: 14)

                        // 3. Grid of Wardrobe Items
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                            ForEach(filteredWardrobeItems) { item in
                                let isSelected = selectedWardrobeItemIds.contains(item.id)
                                Button {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    if isSelected {
                                        selectedWardrobeItemIds.remove(item.id)
                                    } else {
                                        selectedWardrobeItemIds.insert(item.id)
                                    }
                                } label: {
                                    VStack(alignment: .leading, spacing: 0) {
                                        ZStack(alignment: .topTrailing) {
                                            ItemImageView(photoNameOrUrl: item.primaryPhoto, category: item.category)
                                                .frame(height: 110)
                                                .frame(maxWidth: .infinity)
                                                .clipped()

                                            ZStack {
                                                Circle()
                                                    .fill(isSelected ? LuxuryTheme.accentAmber : Color.black.opacity(0.55))
                                                    .frame(width: 24, height: 24)

                                                Image(systemName: isSelected ? "checkmark" : "plus")
                                                    .font(.system(size: 11, weight: .bold))
                                                    .foregroundStyle(isSelected ? Color.black : Color.white)
                                            }
                                            .padding(6)
                                        }

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.brand.uppercased())
                                                .font(.system(size: 9, weight: .bold))
                                                .foregroundStyle(item.category.accentColor)
                                                .lineLimit(1)

                                            Text(item.name)
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundStyle(LuxuryTheme.textPrimary)
                                                .lineLimit(2)
                                                .frame(height: 28, alignment: .topLeading)

                                            HStack {
                                                Text(item.formattedPrice)
                                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                                    .foregroundStyle(LuxuryTheme.gold)
                                                Spacer()
                                                if !item.size.isEmpty {
                                                    Text(item.size)
                                                        .font(.system(size: 9))
                                                        .foregroundStyle(LuxuryTheme.textTertiary)
                                                }
                                            }
                                        }
                                        .padding(8)
                                    }
                                    .background(LuxuryTheme.cardBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(isSelected ? LuxuryTheme.accentAmber : LuxuryTheme.cardBorder, lineWidth: isSelected ? 2 : 1)
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
                            let chosenItems = dataStore.items.filter { selectedWardrobeItemIds.contains($0.id) }
                            let packingItems = chosenItems.map { it in
                                PackingItem(title: it.name, category: it.category, linkedWardrobeItemId: it.id, isPacked: false)
                            }
                            let plan = TripPlan(
                                destination: destination,
                                purpose: purpose.isEmpty ? "Travel" : purpose,
                                durationDays: durationDays,
                                items: packingItems
                            )
                            dataStore.addTripPlan(plan)
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            dismiss()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "suitcase.fill")
                            Text("Create Packing List (\(selectedWardrobeItemIds.count) Items) ✈️")
                        }
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(destination.isEmpty ? LuxuryTheme.accentAmber.opacity(0.4) : LuxuryTheme.accentAmber)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: destination.isEmpty ? Color.clear : LuxuryTheme.accentAmber.opacity(0.3), radius: 10, y: 4)
                    }
                    .disabled(destination.isEmpty)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
                .background(
                    LinearGradient(
                        colors: [Color.clear, LuxuryTheme.background.opacity(0.95), LuxuryTheme.background],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .background(LuxuryTheme.background.ignoresSafeArea())
            .navigationTitle("New Packing List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(LuxuryTheme.textSecondary)
                }
            }
        }
    }
}
