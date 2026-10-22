import SwiftUI

public enum SortOption: String, CaseIterable, Identifiable {
    case newest = "Newest Added"
    case priceHighToLow = "Valuation: High to Low"
    case priceLowToHigh = "Valuation: Low to High"
    case brandAZ = "Brand: A to Z"

    public var id: String { rawValue }
}

public struct VaultView: View {
    @ObservedObject var dataStore: DataStore

    @State private var searchText: String = ""
    @State private var selectedCategory: ItemCategory? = nil
    @State private var selectedSubcategory: String? = nil
    @State private var sortOption: SortOption = .priceHighToLow

    // Multi-Select & Bulk Delete
    @AppStorage("vault_is_selecting") private var isSelecting = false
    @State private var selectedItemIds: Set<UUID> = []
    @State private var showDeleteConfirmation = false
    @State private var toastMessage: String? = nil

    // Sheets
    @State private var selectedDetailItem: WardrobeItem? = nil
    @State private var itemToEdit: WardrobeItem? = nil
    @State private var showAddItemSheet = false
    @AppStorage("vault_show_import") private var showWebImportSheet = false

    public init(dataStore: DataStore) {
        self.dataStore = dataStore
    }

    private var filteredItems: [WardrobeItem] {
        var result = dataStore.items

        // Category filter
        if let cat = selectedCategory {
            result = result.filter { $0.category == cat }
        }

        // Subcategory filter
        if let sub = selectedSubcategory {
            result = result.filter { $0.subcategory == sub }
        }

        // Search text
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !query.isEmpty {
            result = result.filter { item in
                item.name.lowercased().contains(query) ||
                item.brand.lowercased().contains(query) ||
                item.subcategory.lowercased().contains(query) ||
                item.storageLocation.lowercased().contains(query) ||
                item.keySpecSummary.lowercased().contains(query) ||
                item.notes.lowercased().contains(query)
            }
        }

        // Sorting
        switch sortOption {
        case .newest:
            result.sort { $0.dateAdded > $1.dateAdded }
        case .priceHighToLow:
            result.sort { $0.price > $1.price }
        case .priceLowToHigh:
            result.sort { $0.price < $1.price }
        case .brandAZ:
            result.sort { $0.brand.localizedCompare($1.brand) == .orderedAscending }
        }

        return result
    }

    public var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 16) {
                        // Portfolio Valuation Banner
                        portfolioValuationCard
                            .padding(.horizontal)
                            .padding(.top, 4)

                        // Search Bar
                        searchBarSection
                            .padding(.horizontal)

                        // Category Filter Tabs
                        categoryFilterTabs
                            .padding(.horizontal)

                        // Subcategory Chips (if category selected)
                        if let selectedCategory = selectedCategory {
                            subcategoryChips(for: selectedCategory)
                                .padding(.horizontal)
                        }

                        // Grid Controls (Count, Select Toggle & Sort Menu)
                        gridControlsRow
                            .padding(.horizontal)

                        // 2-Column Grid of Items
                        if filteredItems.isEmpty {
                            emptyStateView
                                .padding(.top, 40)
                        } else {
                            LazyVGrid(
                                columns: [
                                    GridItem(.flexible(minimum: 140, maximum: 200), spacing: 14),
                                    GridItem(.flexible(minimum: 140, maximum: 200), spacing: 14)
                                ],
                                spacing: 16
                            ) {
                                ForEach(filteredItems) { item in
                                    ItemCardView(
                                        item: item,
                                        isSelectable: isSelecting,
                                        isSelected: selectedItemIds.contains(item.id)
                                    ) {
                                        dataStore.toggleFavorite(for: item)
                                    }
                                    .onTapGesture {
                                        if isSelecting {
                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                            if selectedItemIds.contains(item.id) {
                                                selectedItemIds.remove(item.id)
                                            } else {
                                                selectedItemIds.insert(item.id)
                                            }
                                        } else {
                                            selectedDetailItem = item
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }

                        Spacer(minLength: 110)
                    }
                }
                .background(LuxuryTheme.background.ignoresSafeArea())
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    if isSelecting {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Done") {
                                withAnimation(.spring(response: 0.3)) {
                                    isSelecting = false
                                    selectedItemIds.removeAll()
                                }
                            }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(LuxuryTheme.gold)
                        }

                        ToolbarItem(placement: .topBarTrailing) {
                            Button(action: {
                                if selectedItemIds.count == filteredItems.count {
                                    selectedItemIds.removeAll()
                                } else {
                                    selectedItemIds = Set(filteredItems.map { $0.id })
                                }
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }) {
                                Text(selectedItemIds.count == filteredItems.count ? "Deselect All" : "Select All")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(LuxuryTheme.accentAmber)
                            }
                        }
                    } else {
                        ToolbarItem(placement: .topBarLeading) {
                            HStack(spacing: 7) {
                                Image(systemName: "gauge.with.dots.needle.bottom.50percent")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(LuxuryTheme.accentAmber)

                                Text("COCKPIT")
                                    .font(.system(size: 15, weight: .black, design: .rounded))
                                    .tracking(1.8)
                                    .foregroundStyle(LuxuryTheme.textPrimary)

                                Text("MEN")
                                    .font(.system(size: 13, weight: .black, design: .rounded))
                                    .tracking(1.4)
                                    .foregroundStyle(LuxuryTheme.accentAmber)
                            }
                        }

                        ToolbarItem(placement: .topBarTrailing) {
                            HStack(spacing: 8) {
                                Button(action: {
                                    withAnimation(.spring(response: 0.3)) {
                                        isSelecting = true
                                        selectedItemIds.removeAll()
                                    }
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark.circle")
                                        Text("Select")
                                            .font(.system(size: 12, weight: .bold))
                                    }
                                    .foregroundStyle(LuxuryTheme.textPrimary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(LuxuryTheme.secondaryBackground)
                                    .clipShape(Capsule())
                                }

                                Menu {
                                    Button(action: { cleanDuplicatesAction() }) {
                                        Label("Remove Duplicates", systemImage: "sparkles")
                                    }
                                    Button(action: { showWebImportSheet = true }) {
                                        Label("Import from Web", systemImage: "globe")
                                    }
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                        .font(.system(size: 18))
                                        .foregroundStyle(LuxuryTheme.accentAmber)
                                        .padding(4)
                                }
                            }
                        }
                    }
                }

                // Toast Notification Overlay
                if let toast = toastMessage {
                    VStack {
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(LuxuryTheme.gold)
                            Text(toast)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(LuxuryTheme.textPrimary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(white: 0.16))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(LuxuryTheme.gold.opacity(0.4), lineWidth: 1))
                        .shadow(color: Color.black.opacity(0.6), radius: 12, y: 6)
                        .padding(.top, 8)

                        Spacer()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(100)
                }

                // Bottom Action Bar: Multi-Select Delete vs Floating Add Button
                if isSelecting {
                    bulkActionBar
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(90)
                } else {
                    HStack {
                        Spacer()
                        floatingActionButton
                    }
                    .padding(20)
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(80)
                }
            }
            .alert("Delete \(selectedItemIds.count) Pieces?", isPresented: $showDeleteConfirmation) {
                Button("Delete (\(selectedItemIds.count))", role: .destructive) {
                    let count = selectedItemIds.count
                    dataStore.deleteItems(ids: selectedItemIds)
                    withAnimation {
                        selectedItemIds.removeAll()
                        isSelecting = false
                    }
                    showToast("Permanently removed \(count) pieces from Vault")
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to permanently delete \(selectedItemIds.count) selected items from your vault? This action cannot be undone.")
            }
            .sheet(item: $selectedDetailItem) { item in
                ItemDetailView(dataStore: dataStore, item: item) { itemToEdit in
                    self.itemToEdit = itemToEdit
                }
            }
            .sheet(item: $itemToEdit) { item in
                AddEditItemView(dataStore: dataStore, existingItem: item)
            }
            .sheet(isPresented: $showAddItemSheet) {
                AddEditItemView(dataStore: dataStore)
            }
            .sheet(isPresented: $showWebImportSheet) {
                WebImportSheet { imported in
                    let newItem = WardrobeItem(
                        name: imported.name,
                        brand: imported.brand,
                        category: imported.category,
                        subcategory: imported.subcategory,
                        price: imported.price,
                        photos: imported.photoFilenames,
                        occasion: imported.occasion,
                        notes: imported.notes,
                        size: imported.size,
                        fabricMaterial: imported.fabricMaterial,
                        shoeSize: imported.shoeSize,
                        modelSpecs: imported.modelSpecs,
                        bagCapacity: imported.bagCapacity,
                        volumeSize: imported.volumeSize,
                        accessoryMaterial: imported.accessoryMaterial
                    )
                    let added = dataStore.addItem(newItem, ignoreDuplicates: true)
                    if added {
                        showToast("Added \(newItem.name) to Vault")
                    } else {
                        showToast("Piece already in Vault — duplicates ignored & merged")
                    }
                }
            }
            .onAppear {
                if isSelecting && selectedItemIds.isEmpty {
                    selectedItemIds = Set(dataStore.items.prefix(3).map { $0.id })
                }
            }
        }
    }

    // MARK: - Bulk Action Bar
    private var bulkActionBar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(selectedItemIds.count) SELECTED")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .tracking(1.2)
                    .foregroundStyle(LuxuryTheme.gold)

                Text("\(filteredItems.count) total in view")
                    .font(.system(size: 11))
                    .foregroundStyle(LuxuryTheme.textTertiary)
            }

            Spacer()

            Button(action: {
                if selectedItemIds.count == filteredItems.count {
                    selectedItemIds.removeAll()
                } else {
                    selectedItemIds = Set(filteredItems.map { $0.id })
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }) {
                Text(selectedItemIds.count == filteredItems.count ? "Deselect All" : "Select All")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(LuxuryTheme.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(LuxuryTheme.secondaryBackground)
                    .clipShape(Capsule())
            }

            Button(action: {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                showDeleteConfirmation = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 12))
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
                .shadow(color: Color.black.opacity(0.7), radius: 16, x: 0, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(LuxuryTheme.cardBorder, lineWidth: 1)
        )
    }

    private func cleanDuplicatesAction() {
        let removed = dataStore.removeDuplicates()
        if removed > 0 {
            showToast("✨ Cleaned \(removed) duplicate piece(s) from Vault")
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else {
            showToast("✨ Vault is clean — no duplicate pieces found")
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        }
    }

    private func showToast(_ msg: String) {
        withAnimation { toastMessage = msg }
        Task {
            try? await Task.sleep(nanoseconds: 2_600_000_000)
            await MainActor.run {
                withAnimation {
                    if toastMessage == msg {
                        toastMessage = nil
                    }
                }
            }
        }
    }

    // MARK: - Portfolio Valuation Card
    private var portfolioValuationCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("TOTAL VAULT PORTFOLIO")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .tracking(1.4)
                        .foregroundStyle(LuxuryTheme.textTertiary)

                    Text(dataStore.formattedTotalValuation)
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(LuxuryTheme.gold)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(dataStore.items.count)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(LuxuryTheme.textPrimary)

                    Text("PIECES")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .tracking(1.2)
                        .foregroundStyle(LuxuryTheme.textTertiary)
                }
            }

            Divider().background(LuxuryTheme.cardBorder)

            // Category breakdown scrollable pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ItemCategory.allCases) { cat in
                        categoryStatPill(category: cat)
                    }
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .luxuryCardStyle(cornerRadius: 18)
    }

    private func categoryStatPill(category: ItemCategory) -> some View {
        let count = dataStore.itemCount(for: category)
        let val = dataStore.formattedValuation(for: category)

        return HStack(spacing: 8) {
            Circle()
                .fill(category.accentColor)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(category.rawValue)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(LuxuryTheme.textSecondary)

                Text(val)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(LuxuryTheme.textPrimary)
            }

            if count > 0 {
                Text("\(count)")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(LuxuryTheme.secondaryBackground)
                    .clipShape(Capsule())
                    .foregroundStyle(LuxuryTheme.textTertiary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(LuxuryTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(selectedCategory == category ? category.accentColor : LuxuryTheme.cardBorder, lineWidth: 1)
        )
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                if selectedCategory == category {
                    selectedCategory = nil
                    selectedSubcategory = nil
                } else {
                    selectedCategory = category
                    selectedSubcategory = nil
                }
            }
        }
    }

    // MARK: - Search Bar Section
    private var searchBarSection: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundStyle(LuxuryTheme.textTertiary)

            TextField("Search sneakers, watches, suits, lenses...", text: $searchText)
                .font(.system(size: 14))
                .foregroundStyle(LuxuryTheme.textPrimary)
                .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(LuxuryTheme.textTertiary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(LuxuryTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(LuxuryTheme.cardBorder, lineWidth: 1)
        )
    }

    // MARK: - Category Filter Tabs
    private var categoryFilterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // "All" Tab
                filterButton(title: "All Vault", count: dataStore.items.count, isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                    selectedSubcategory = nil
                }

                // Category Tabs
                ForEach(ItemCategory.allCases) { cat in
                    filterButton(
                        title: cat.rawValue,
                        count: dataStore.itemCount(for: cat),
                        icon: cat.iconName,
                        accentColor: cat.accentColor,
                        isSelected: selectedCategory == cat
                    ) {
                        if selectedCategory == cat {
                            selectedCategory = nil
                            selectedSubcategory = nil
                        } else {
                            selectedCategory = cat
                            selectedSubcategory = nil
                        }
                    }
                }
            }
        }
    }

    private func filterButton(title: String, count: Int, icon: String? = nil, accentColor: Color = LuxuryTheme.gold, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .bold))
                }
                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .bold : .semibold))
                Text("(\(count))")
                    .font(.system(size: 11, weight: .regular))
                    .opacity(0.7)
            }
            .foregroundStyle(isSelected ? Color.black : LuxuryTheme.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? accentColor : LuxuryTheme.cardBackground)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : LuxuryTheme.cardBorder, lineWidth: 1)
            )
        }
    }

    // MARK: - Subcategory Chips
    private func subcategoryChips(for category: ItemCategory) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // All Subcategories
                Button(action: { selectedSubcategory = nil }) {
                    Text("All \(category.rawValue)")
                        .font(.system(size: 11, weight: selectedSubcategory == nil ? .bold : .medium))
                        .foregroundStyle(selectedSubcategory == nil ? LuxuryTheme.textPrimary : LuxuryTheme.textTertiary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(selectedSubcategory == nil ? LuxuryTheme.secondaryBackground : Color.clear)
                        .clipShape(Capsule())
                }

                ForEach(category.defaultSubcategories, id: \.self) { sub in
                    Button(action: {
                        if selectedSubcategory == sub {
                            selectedSubcategory = nil
                        } else {
                            selectedSubcategory = sub
                        }
                    }) {
                        Text(sub)
                            .font(.system(size: 11, weight: selectedSubcategory == sub ? .bold : .medium))
                            .foregroundStyle(selectedSubcategory == sub ? Color.black : LuxuryTheme.textSecondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(selectedSubcategory == sub ? category.accentColor : LuxuryTheme.cardBackground)
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
                .foregroundStyle(LuxuryTheme.textSecondary)

            Spacer()

            Menu {
                ForEach(SortOption.allCases) { opt in
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
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 11))
                    Text(sortOption.rawValue)
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(LuxuryTheme.gold)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(LuxuryTheme.secondaryBackground)
                .clipShape(Capsule())
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(LuxuryTheme.textTertiary)

            Text("No Pieces Found")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(LuxuryTheme.textPrimary)

            Text("Try clearing your search or category filters, or tap + Add Item to add new menswear or tech gear.")
                .font(.system(size: 13))
                .foregroundStyle(LuxuryTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
        }
    }

    // MARK: - Floating Action Button
    private var floatingActionButton: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            showAddItemSheet = true
        }) {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                Text("Add Item")
                    .font(.system(size: 15, weight: .bold))
            }
            .foregroundStyle(Color.black)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(LuxuryTheme.gold)
            .clipShape(Capsule())
            .shadow(color: LuxuryTheme.gold.opacity(0.35), radius: 10, x: 0, y: 5)
        }
    }
}
