import SwiftUI

public struct WishlistView: View {
    @ObservedObject var dataStore: DataStore

    @State private var selectedCategory: ItemCategory? = nil
    @State private var showAddWishlistSheet = false
    @State private var showWebImportSheet = false
    @State private var itemToMoveToVault: WishlistItem? = nil
    @State private var storageLocationForMove = "Main Closet"

    // Multi-Select & Bulk Delete
    @State private var isSelecting = false
    @State private var selectedItemIds: Set<UUID> = []
    @State private var showDeleteConfirmation = false
    @State private var toastMessage: String? = nil

    public init(dataStore: DataStore) {
        self.dataStore = dataStore
    }

    private var filteredWishlist: [WishlistItem] {
        var list = dataStore.wishlistItems
        if let cat = selectedCategory {
            list = list.filter { $0.category == cat }
        }
        return list
    }

    public var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 16) {
                        // Header Banner
                        wishlistHeroBanner
                            .padding(.horizontal)
                            .padding(.top, 4)

                        // Category Filter Pills
                        categoryFilterScroll
                            .padding(.horizontal)

                        // Wishlist Cards Grid
                        if filteredWishlist.isEmpty {
                            emptyWishlistView
                                .padding(.top, 40)
                        } else {
                            VStack(spacing: 14) {
                                ForEach(filteredWishlist) { item in
                                    wishlistCard(item: item)
                                        .onTapGesture {
                                            if isSelecting {
                                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                if selectedItemIds.contains(item.id) {
                                                    selectedItemIds.remove(item.id)
                                                } else {
                                                    selectedItemIds.insert(item.id)
                                                }
                                            }
                                        }
                                }
                            }
                            .padding(.horizontal)
                        }

                        Spacer(minLength: 100)
                    }
                }
                .background(LuxuryTheme.background.ignoresSafeArea())
                .navigationTitle("Wishlist")
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
                                if selectedItemIds.count == filteredWishlist.count {
                                    selectedItemIds.removeAll()
                                } else {
                                    selectedItemIds = Set(filteredWishlist.map { $0.id })
                                }
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }) {
                                Text(selectedItemIds.count == filteredWishlist.count ? "Deselect All" : "Select All")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(LuxuryTheme.accentAmber)
                            }
                        }
                    } else {
                        ToolbarItem(placement: .topBarLeading) {
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
                        }

                        ToolbarItem(placement: .topBarTrailing) {
                            HStack(spacing: 8) {
                                Button(action: { showAddWishlistSheet = true }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundStyle(LuxuryTheme.accentAmber)
                                }

                                Menu {
                                    Button(action: { cleanWishlistDuplicatesAction() }) {
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

                // Toast Feedback
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

                // Floating Bulk Action Bar
                if isSelecting {
                    bulkActionBar
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(90)
                }
            }
            .alert("Delete \(selectedItemIds.count) Wishlist Items?", isPresented: $showDeleteConfirmation) {
                Button("Delete (\(selectedItemIds.count))", role: .destructive) {
                    let count = selectedItemIds.count
                    dataStore.deleteWishlistItems(ids: selectedItemIds)
                    withAnimation {
                        selectedItemIds.removeAll()
                        isSelecting = false
                    }
                    showToast("Removed \(count) items from Wishlist")
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to permanently delete \(selectedItemIds.count) items from your wishlist?")
            }
            .sheet(isPresented: $showWebImportSheet) {
                WebImportSheet { imported in
                    let wish = WishlistItem(
                        name: imported.name,
                        brand: imported.brand,
                        category: imported.category,
                        targetPrice: imported.price,
                        photos: imported.photoFilenames,
                        storeUrl: imported.sourceUrl,
                        priority: .high,
                        notes: imported.notes
                    )
                    let added = dataStore.addWishlistItem(wish, ignoreDuplicates: true)
                    if added {
                        showToast("Added \(wish.name) to Wishlist")
                    } else {
                        showToast("Item already in Wishlist — duplicate ignored & merged")
                    }
                }
            }
            .sheet(isPresented: $showAddWishlistSheet) {
                AddWishlistItemSheet(dataStore: dataStore)
            }
            .sheet(item: $itemToMoveToVault) { item in
                moveToVaultSheet(item: item)
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

                Text("\(filteredWishlist.count) total in view")
                    .font(.system(size: 11))
                    .foregroundStyle(LuxuryTheme.textTertiary)
            }

            Spacer()

            Button(action: {
                if selectedItemIds.count == filteredWishlist.count {
                    selectedItemIds.removeAll()
                } else {
                    selectedItemIds = Set(filteredWishlist.map { $0.id })
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }) {
                Text(selectedItemIds.count == filteredWishlist.count ? "Deselect All" : "Select All")
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

    private func cleanWishlistDuplicatesAction() {
        let removed = dataStore.removeWishlistDuplicates()
        if removed > 0 {
            showToast("✨ Cleaned \(removed) duplicate(s) from Wishlist")
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else {
            showToast("✨ Wishlist is clean — no duplicates found")
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

    // MARK: - Hero Banner
    private var wishlistHeroBanner: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("TARGET ACQUISITIONS")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .tracking(1.4)
                        .foregroundStyle(LuxuryTheme.textTertiary)

                    Text(dataStore.formattedWishlistValuation)
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundStyle(LuxuryTheme.accentAmber)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(dataStore.wishlistItems.count)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(LuxuryTheme.textPrimary)

                    Text("PIECES")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .tracking(1.2)
                        .foregroundStyle(LuxuryTheme.textTertiary)
                }
            }

            Text("Curate your planned wardrobe upgrades, footwear drops, tech gadgets, and luxury essentials before buying.")
                .font(.system(size: 12))
                .foregroundStyle(LuxuryTheme.textSecondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .luxuryCardStyle(cornerRadius: 16)
    }

    // MARK: - Category Filter Scroll
    private var categoryFilterScroll: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button(action: { selectedCategory = nil }) {
                    Text("All (\(dataStore.wishlistItems.count))")
                        .font(.system(size: 12, weight: selectedCategory == nil ? .bold : .medium))
                        .foregroundStyle(selectedCategory == nil ? Color.black : LuxuryTheme.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(selectedCategory == nil ? LuxuryTheme.accentAmber : LuxuryTheme.cardBackground)
                        .clipShape(Capsule())
                }

                ForEach(ItemCategory.allCases) { cat in
                    let count = dataStore.wishlistItems.filter { $0.category == cat }.count
                    Button(action: {
                        selectedCategory = (selectedCategory == cat) ? nil : cat
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: cat.iconName)
                                .font(.system(size: 11))
                            Text(cat.rawValue)
                            Text("(\(count))")
                                .opacity(0.7)
                        }
                        .font(.system(size: 12, weight: selectedCategory == cat ? .bold : .medium))
                        .foregroundStyle(selectedCategory == cat ? Color.black : LuxuryTheme.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(selectedCategory == cat ? cat.accentColor : LuxuryTheme.cardBackground)
                        .clipShape(Capsule())
                    }
                }
            }
        }
    }

    // MARK: - Wishlist Card
    private func wishlistCard(item: WishlistItem) -> some View {
        let isSelected = selectedItemIds.contains(item.id)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 14) {
                // Checkbox when selecting
                if isSelecting {
                    ZStack {
                        Circle()
                            .fill(isSelected ? LuxuryTheme.gold : Color.black.opacity(0.55))
                            .frame(width: 26, height: 26)
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .black))
                                .foregroundStyle(Color.black)
                        } else {
                            Circle()
                                .stroke(Color.white.opacity(0.85), lineWidth: 1.8)
                                .frame(width: 20, height: 20)
                        }
                    }
                    .padding(.top, 4)
                }

                // Photo
                ItemImageView(photoNameOrUrl: item.primaryPhoto, category: item.category)
                    .frame(width: 90, height: 110)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(item.brand.uppercased())
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(item.category.accentColor)

                        Spacer()

                        Text(item.priority.badgeLabel)
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(LuxuryTheme.secondaryBackground)
                            .foregroundStyle(LuxuryTheme.accentAmber)
                            .clipShape(Capsule())
                    }

                    Text(item.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(LuxuryTheme.textPrimary)
                        .lineLimit(2)

                    Text(item.formattedPrice)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(LuxuryTheme.accentAmber)

                    if !item.notes.isEmpty {
                        Text(item.notes)
                            .font(.system(size: 11))
                            .foregroundStyle(LuxuryTheme.textTertiary)
                            .lineLimit(1)
                    }
                }
            }

            if !isSelecting {
                Divider().background(LuxuryTheme.cardBorder)

                // Actions Row
                HStack(spacing: 10) {
                    // Store Link
                    if !item.storeUrl.isEmpty, let url = URL(string: item.storeUrl) {
                        Link(destination: url) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.up.right.square")
                                Text("Store")
                            }
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(LuxuryTheme.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(LuxuryTheme.secondaryBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }

                    // Delete Single
                    Button(action: {
                        dataStore.deleteWishlistItem(item)
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.red.opacity(0.8))
                            .padding(9)
                            .background(Color.red.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    Spacer()

                    // "Purchased / Move to Vault"
                    Button(action: {
                        itemToMoveToVault = item
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.seal.fill")
                            Text("Moved to Vault ✨")
                        }
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(LuxuryTheme.accentAmber)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
        .padding(14)
        .luxuryCardStyle(cornerRadius: 16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? LuxuryTheme.gold : Color.clear, lineWidth: 2)
        )
    }

    // MARK: - Move to Vault Sheet
    private func moveToVaultSheet(item: WishlistItem) -> some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("Congratulations on acquiring \(item.name)!")
                    .font(.system(size: 15))
                    .foregroundStyle(LuxuryTheme.textSecondary)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Storage Location in Your Wardrobe")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(LuxuryTheme.textPrimary)

                    TextField("e.g. Shoe Rack B, Studio Desk, Master Closet", text: $storageLocationForMove)
                        .font(.system(size: 14))
                        .padding(12)
                        .background(LuxuryTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .foregroundStyle(LuxuryTheme.textPrimary)
                }

                Button(action: {
                    dataStore.moveToVault(wishlistItem: item, storageLocation: storageLocationForMove)
                    itemToMoveToVault = nil
                }) {
                    Text("Save to Vault Portfolio ✨")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(LuxuryTheme.accentAmber)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Spacer()
            }
            .padding(20)
            .background(LuxuryTheme.background.ignoresSafeArea())
            .navigationTitle("Transfer to Vault")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { itemToMoveToVault = nil }
                        .foregroundStyle(LuxuryTheme.textSecondary)
                }
            }
        }
    }

    private var emptyWishlistView: some View {
        VStack(spacing: 12) {
            Image(systemName: "bookmark")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(LuxuryTheme.textTertiary)

            Text("Your Wishlist is Empty")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(LuxuryTheme.textPrimary)

            Text("Paste a product link from Amazon, Nike, Myntra, or tap + to save your dream menswear, shoes, and gear.")
                .font(.system(size: 13))
                .foregroundStyle(LuxuryTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
        }
    }
}

// MARK: - Add Wishlist Item Sheet
public struct AddWishlistItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var dataStore: DataStore

    @State private var name: String = ""
    @State private var brand: String = ""
    @State private var category: ItemCategory = .shoes
    @State private var priceText: String = ""
    @State private var storeUrl: String = ""
    @State private var priority: WishlistPriority = .high
    @State private var notes: String = ""

    public init(dataStore: DataStore) {
        self.dataStore = dataStore
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    TextField("Product Name (e.g. Nike Downshifter 14)", text: $name)
                        .font(.system(size: 15))
                        .padding(12)
                        .background(LuxuryTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .foregroundStyle(LuxuryTheme.textPrimary)

                    TextField("Brand / Maker (e.g. Nike, Rimowa)", text: $brand)
                        .font(.system(size: 15))
                        .padding(12)
                        .background(LuxuryTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .foregroundStyle(LuxuryTheme.textPrimary)

                    Picker("Category", selection: $category) {
                        ForEach(ItemCategory.allCases) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    TextField("Target Price (₹)", text: $priceText)
                        .keyboardType(.numberPad)
                        .font(.system(size: 15))
                        .padding(12)
                        .background(LuxuryTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .foregroundStyle(LuxuryTheme.textPrimary)

                    TextField("Store URL (e.g. https://amazon.in/...)", text: $storeUrl)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .font(.system(size: 15))
                        .padding(12)
                        .background(LuxuryTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .foregroundStyle(LuxuryTheme.textPrimary)

                    Picker("Priority", selection: $priority) {
                        ForEach(WishlistPriority.allCases) { p in
                            Text(p.rawValue).tag(p)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    TextField("Notes & Why You Want It", text: $notes)
                        .font(.system(size: 15))
                        .padding(12)
                        .background(LuxuryTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .foregroundStyle(LuxuryTheme.textPrimary)

                    Button(action: saveWishlist) {
                        Text("Add to Wishlist ✨")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Color.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(name.isEmpty ? LuxuryTheme.accentAmber.opacity(0.4) : LuxuryTheme.accentAmber)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(name.isEmpty)
                }
                .padding(20)
            }
            .background(LuxuryTheme.background.ignoresSafeArea())
            .navigationTitle("New Wishlist Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(LuxuryTheme.textSecondary)
                }
            }
        }
    }

    private func saveWishlist() {
        let p = Double(priceText.filter("0123456789.".contains)) ?? 0.0
        let item = WishlistItem(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            brand: brand.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category,
            targetPrice: p,
            storeUrl: storeUrl,
            priority: priority,
            notes: notes
        )
        dataStore.addWishlistItem(item, ignoreDuplicates: true)
        dismiss()
    }
}
