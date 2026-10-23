import SwiftUI

public struct WomenBoutiqueView: View {
    @ObservedObject var womenDataStore: WomenDataStore
    @Binding var activeGenderProfile: String

    @State private var searchText: String = ""
    @State private var selectedCategory: WomenCategory? = nil
    @State private var sortOption: WomenSortOption = .priceHighToLow

    // Multi-Select
    @State private var isSelecting = false
    @State private var selectedItemIds: Set<UUID> = []
    @State private var showDeleteConfirmation = false
    @State private var toastMessage: String? = nil

    // Sheets
    @State private var selectedDetailItem: WomenWardrobeItem? = nil
    @State private var itemToEdit: WomenWardrobeItem? = nil
    @State private var showAddItemSheet = false

    public init(womenDataStore: WomenDataStore, activeGenderProfile: Binding<String>) {
        self.womenDataStore = womenDataStore
        self._activeGenderProfile = activeGenderProfile
    }

    private var filteredItems: [WomenWardrobeItem] {
        var list = womenDataStore.items
        if let cat = selectedCategory {
            list = list.filter { $0.category == cat }
        }
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !q.isEmpty {
            list = list.filter {
                $0.title.lowercased().contains(q) ||
                $0.brand.lowercased().contains(q) ||
                $0.subcategory.lowercased().contains(q) ||
                $0.storageLocation.lowercased().contains(q) ||
                $0.purity.lowercased().contains(q) ||
                $0.notes.lowercased().contains(q)
            }
        }
        switch sortOption {
        case .priceHighToLow: return list.sorted { $0.price > $1.price }
        case .priceLowToHigh: return list.sorted { $0.price < $1.price }
        case .newest: return list.sorted { $0.dateAdded > $1.dateAdded }
        case .mostWorn: return list.sorted { $0.timesWorn > $1.timesWorn }
        }
    }

    public var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 16) {
                        // Profile Switcher Banner
                        profileSwitcherHeader
                            .padding(.horizontal)
                            .padding(.top, 4)

                        // Hero Valuation Card
                        heroValuationCard
                            .padding(.horizontal)

                        // Search Bar
                        searchBar
                            .padding(.horizontal)

                        // Category Filter Scroll
                        categoryFilterScroll
                            .padding(.horizontal)

                        // Grid Controls (Count & Sort)
                        gridControlsRow
                            .padding(.horizontal)

                        // 2-Column Luxury Grid
                        if filteredItems.isEmpty {
                            emptyStateView
                                .padding(.top, 40)
                        } else {
                            LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                                ForEach(filteredItems) { item in
                                    womenItemCard(item: item)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            if isSelecting {
                                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                if selectedItemIds.contains(item.id) {
                                                    selectedItemIds.remove(item.id)
                                                } else {
                                                    selectedItemIds.insert(item.id)
                                                }
                                            } else {
                                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                selectedDetailItem = item
                                            }
                                        }
                                }
                            }
                            .padding(.horizontal)
                        }

                        Spacer(minLength: 100)
                    }
                }
                .background(WomenLuxuryTheme.background.ignoresSafeArea())
                .navigationTitle("Women's Boutique")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    if isSelecting {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Done") {
                                withAnimation {
                                    isSelecting = false
                                    selectedItemIds.removeAll()
                                }
                            }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(WomenLuxuryTheme.roseGold)
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            Button(action: {
                                if selectedItemIds.count == filteredItems.count {
                                    selectedItemIds.removeAll()
                                } else {
                                    selectedItemIds = Set(filteredItems.map { $0.id })
                                }
                            }) {
                                Text(selectedItemIds.count == filteredItems.count ? "Deselect All" : "Select All")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(WomenLuxuryTheme.champagne)
                            }
                        }
                    } else {
                        ToolbarItem(placement: .topBarLeading) {
                            Button(action: {
                                withAnimation {
                                    isSelecting = true
                                    selectedItemIds.removeAll()
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle")
                                    Text("Select")
                                        .font(.system(size: 12, weight: .bold))
                                }
                                .foregroundStyle(WomenLuxuryTheme.textPrimary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(WomenLuxuryTheme.secondaryBackground)
                                .clipShape(Capsule())
                            }
                        }

                        ToolbarItem(placement: .topBarTrailing) {
                            HStack(spacing: 8) {
                                Button(action: { showAddItemSheet = true }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundStyle(WomenLuxuryTheme.roseGold)
                                }

                                Menu {
                                    Button(action: {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                            activeGenderProfile = "male"
                                        }
                                    }) {
                                        Label("Switch to Men's Atelier 🎩", systemImage: "person.crop.circle")
                                    }
                                    Button(action: {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                            activeGenderProfile = ""
                                        }
                                    }) {
                                        Label("Change Profile (Men / Women)", systemImage: "arrow.triangle.2.circlepath")
                                    }
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                        .font(.system(size: 18))
                                        .foregroundStyle(WomenLuxuryTheme.roseGold)
                                        .padding(4)
                                }
                            }
                        }
                    }
                }

                // Toast
                if let toast = toastMessage {
                    VStack {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .foregroundStyle(WomenLuxuryTheme.roseGold)
                            Text(toast)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(WomenLuxuryTheme.textPrimary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(white: 0.16))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(WomenLuxuryTheme.roseGold.opacity(0.4), lineWidth: 1))
                        .padding(.top, 8)
                        Spacer()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(100)
                }

                // Floating Action Bar (Select vs Add)
                if isSelecting {
                    bulkActionBar
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(90)
                } else {
                    HStack {
                        Spacer()
                        floatingAddButton
                    }
                    .padding(20)
                    .zIndex(80)
                }
            }
            .alert("Delete \(selectedItemIds.count) Pieces?", isPresented: $showDeleteConfirmation) {
                Button("Delete (\(selectedItemIds.count))", role: .destructive) {
                    let count = selectedItemIds.count
                    womenDataStore.deleteItems(ids: selectedItemIds)
                    selectedItemIds.removeAll()
                    isSelecting = false
                    showToast("Removed \(count) pieces from Boutique")
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to permanently delete the selected pieces from your boutique? This action cannot be undone.")
            }
            .sheet(item: $selectedDetailItem) { item in
                WomenItemDetailView(womenDataStore: womenDataStore, item: item) { editItem in
                    self.itemToEdit = editItem
                }
            }
            .sheet(item: $itemToEdit) { item in
                WomenAddEditItemView(womenDataStore: womenDataStore, existingItem: item)
            }
            .sheet(isPresented: $showAddItemSheet) {
                WomenAddEditItemView(womenDataStore: womenDataStore)
            }
        }
    }

    // MARK: - Profile Switcher Header
    private var profileSwitcherHeader: some View {
        HStack {
            HStack(spacing: 6) {
                Text("👗")
                    .font(.system(size: 14))
                Text("WOMEN'S BOUTIQUE")
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

    // MARK: - Hero Valuation Card
    private var heroValuationCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("TOTAL BOUTIQUE PORTFOLIO")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .tracking(1.4)
                        .foregroundStyle(WomenLuxuryTheme.textTertiary)

                    Text(womenDataStore.formattedTotalValuation)
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(WomenLuxuryTheme.champagne)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(womenDataStore.items.count)")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(WomenLuxuryTheme.textPrimary)

                    Text("PIECES")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .tracking(1.2)
                        .foregroundStyle(WomenLuxuryTheme.textTertiary)
                }
            }

            // Category mini stats
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(WomenCategory.allCases) { cat in
                        let count = womenDataStore.itemCount(for: cat)
                        if count > 0 {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(cat.accentColor)
                                    .frame(width: 8, height: 8)
                                VStack(alignment: .leading, spacing: 1) {
                                    HStack(spacing: 4) {
                                        Text(cat.rawValue)
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundStyle(WomenLuxuryTheme.textPrimary)
                                        Text("\(count)")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundStyle(Color.black)
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 1)
                                            .background(cat.accentColor)
                                            .clipShape(Capsule())
                                    }
                                    Text(womenDataStore.formattedValuation(for: cat))
                                        .font(.system(size: 11, weight: .bold, design: .rounded))
                                        .foregroundStyle(WomenLuxuryTheme.textSecondary)
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(WomenLuxuryTheme.secondaryBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .womenLuxuryCardStyle(cornerRadius: 18)
    }

    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(WomenLuxuryTheme.textTertiary)
                .font(.system(size: 15))

            TextField("Search sarees, jewelry, gowns, bags, fabrics...", text: $searchText)
                .font(.system(size: 14))
                .foregroundStyle(WomenLuxuryTheme.textPrimary)

            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(WomenLuxuryTheme.textTertiary)
                        .font(.system(size: 15))
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(WomenLuxuryTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(WomenLuxuryTheme.cardBorder, lineWidth: 1)
        )
    }

    // MARK: - Category Filter Scroll
    private var categoryFilterScroll: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button(action: { selectedCategory = nil }) {
                    Text("All (\(womenDataStore.items.count))")
                        .font(.system(size: 12, weight: selectedCategory == nil ? .bold : .medium))
                        .foregroundStyle(selectedCategory == nil ? Color.black : WomenLuxuryTheme.textSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(selectedCategory == nil ? WomenLuxuryTheme.roseGold : WomenLuxuryTheme.cardBackground)
                        .clipShape(Capsule())
                }

                ForEach(WomenCategory.allCases) { cat in
                    let count = womenDataStore.itemCount(for: cat)
                    Button(action: {
                        selectedCategory = (selectedCategory == cat) ? nil : cat
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: cat.iconName)
                                .font(.system(size: 11))
                            Text(cat.rawValue)
                            Text("(\(count))")
                                .opacity(0.7)
                        }
                        .font(.system(size: 12, weight: selectedCategory == cat ? .bold : .medium))
                        .foregroundStyle(selectedCategory == cat ? Color.black : WomenLuxuryTheme.textSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(selectedCategory == cat ? cat.accentColor : WomenLuxuryTheme.cardBackground)
                        .clipShape(Capsule())
                    }
                }
            }
        }
    }

    // MARK: - Grid Controls Row
    private var gridControlsRow: some View {
        HStack {
            Text("\(filteredItems.count) Pieces")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(WomenLuxuryTheme.textSecondary)

            Spacer()

            Menu {
                ForEach(WomenSortOption.allCases) { opt in
                    Button(action: { sortOption = opt }) {
                        HStack {
                            Text(opt.rawValue)
                            if sortOption == opt {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 11))
                    Text(sortOption.rawValue)
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundStyle(WomenLuxuryTheme.roseGold)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(WomenLuxuryTheme.secondaryBackground)
                .clipShape(Capsule())
            }
        }
    }

    // MARK: - Women Item Card
    private func womenItemCard(item: WomenWardrobeItem) -> some View {
        let isSelected = selectedItemIds.contains(item.id)

        return VStack(alignment: .leading, spacing: 0) {
            // Image with Badges
            ZStack(alignment: .topTrailing) {
                WomenItemImageView(photoNameOrUrl: item.primaryPhoto, category: item.category)
                    .frame(height: 180)
                    .frame(maxWidth: .infinity)
                    .clipped()

                // Checkbox when selecting
                if isSelecting {
                    ZStack {
                        Circle()
                            .fill(isSelected ? WomenLuxuryTheme.roseGold : Color.black.opacity(0.6))
                            .frame(width: 28, height: 28)
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .black))
                                .foregroundStyle(Color.black)
                        } else {
                            Circle()
                                .stroke(Color.white.opacity(0.85), lineWidth: 2)
                                .frame(width: 22, height: 22)
                        }
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }

                // Category & Set Badges
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.category.rawValue)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(item.category.accentColor.opacity(0.85))
                        .clipShape(Capsule())

                    if item.isSet {
                        Text("✨ SET")
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(Color.black)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(WomenLuxuryTheme.champagne)
                            .clipShape(Capsule())
                    }
                }
                .padding(8)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                // Favorite Heart
                Button(action: {
                    womenDataStore.toggleFavorite(for: item)
                }) {
                    Image(systemName: item.isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 14))
                        .foregroundStyle(item.isFavorite ? Color.red : Color.white)
                        .padding(6)
                        .background(Color.black.opacity(0.45))
                        .clipShape(Circle())
                }
                .padding(8)
            }

            // Info Content
            VStack(alignment: .leading, spacing: 4) {
                Text(item.brand.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(item.category.accentColor)

                Text(item.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(WomenLuxuryTheme.textPrimary)
                    .lineLimit(2)
                    .frame(height: 34, alignment: .topLeading)

                Text(item.formattedPrice)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(WomenLuxuryTheme.champagne)

                // Wear count & cost per wear pill
                HStack(spacing: 4) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 9))
                    Text("Worn \(item.timesWorn)x")
                        .font(.system(size: 10, weight: .semibold))
                    Text("•")
                    Text("CPW: \(item.formattedCostPerWear)")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundStyle(WomenLuxuryTheme.textSecondary)
                .padding(.top, 2)
            }
            .padding(10)
        }
        .womenLuxuryCardStyle(cornerRadius: 14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isSelected ? WomenLuxuryTheme.roseGold : Color.clear, lineWidth: 2)
        )
    }

    // MARK: - Bulk Action Bar
    private var bulkActionBar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(selectedItemIds.count) SELECTED")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundStyle(WomenLuxuryTheme.roseGold)
                Text("\(filteredItems.count) total in view")
                    .font(.system(size: 11))
                    .foregroundStyle(WomenLuxuryTheme.textTertiary)
            }

            Spacer()

            Button(action: {
                showDeleteConfirmation = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "trash.fill")
                    Text("Delete (\(selectedItemIds.count))")
                }
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(selectedItemIds.isEmpty ? Color.red.opacity(0.35) : Color.red)
                .clipShape(Capsule())
            }
            .disabled(selectedItemIds.isEmpty)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(white: 0.14))
                .shadow(color: Color.black.opacity(0.7), radius: 16, y: 8)
        )
    }

    // MARK: - Floating Add Button
    private var floatingAddButton: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            showAddItemSheet = true
        }) {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                Text("Add Piece")
                    .font(.system(size: 15, weight: .bold))
            }
            .foregroundStyle(Color.black)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(WomenLuxuryTheme.roseGold)
            .clipShape(Capsule())
            .shadow(color: WomenLuxuryTheme.roseGold.opacity(0.4), radius: 10, y: 5)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(WomenLuxuryTheme.textTertiary)

            Text("No Boutique Pieces Found")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(WomenLuxuryTheme.textPrimary)

            Text("Add your sarees, jewelry, dresses, and luxury bags to curate your boutique.")
                .font(.system(size: 13))
                .foregroundStyle(WomenLuxuryTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
        }
    }

    private func showToast(_ msg: String) {
        withAnimation { toastMessage = msg }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { toastMessage = nil }
        }
    }
}

public enum WomenSortOption: String, CaseIterable, Identifiable {
    case newest = "Newest Added"
    case priceHighToLow = "Valuation: High to Low"
    case priceLowToHigh = "Valuation: Low to High"
    case mostWorn = "Most Worn"

    public var id: String { rawValue }
}
