import SwiftUI
import PhotosUI

public struct WomenWishlistView: View {
    @ObservedObject var womenDataStore: WomenDataStore
    @Binding var activeGenderProfile: String

    @State private var selectedCategory: WomenCategory? = nil
    @State private var showAddWishlistSheet = false
    @State private var itemToMoveToBoutique: WomenWishlistItem? = nil
    @State private var storageLocationForMove = "Boutique Vanity Box"

    @State private var selectedDetailItem: WomenWishlistItem? = nil
    @State private var itemToEdit: WomenWishlistItem? = nil

    // Multi-Select
    @State private var isSelecting = false
    @State private var selectedItemIds: Set<UUID> = []
    @State private var showDeleteConfirmation = false
    @State private var toastMessage: String? = nil

    public init(womenDataStore: WomenDataStore, activeGenderProfile: Binding<String>) {
        self.womenDataStore = womenDataStore
        self._activeGenderProfile = activeGenderProfile
    }

    private var filteredWishlist: [WomenWishlistItem] {
        var list = womenDataStore.wishlistItems
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
                        // Profile Switcher Header
                        profileSwitcherHeader
                            .padding(.horizontal)
                            .padding(.top, 4)

                        // Hero Valuation Card
                        wishlistHeroBanner
                            .padding(.horizontal)

                        // Category Filter Scroll
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
                .navigationTitle("Wishlist")
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
                                if selectedItemIds.count == filteredWishlist.count {
                                    selectedItemIds.removeAll()
                                } else {
                                    selectedItemIds = Set(filteredWishlist.map { $0.id })
                                }
                            }) {
                                Text(selectedItemIds.count == filteredWishlist.count ? "Deselect All" : "Select All")
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
                                Button(action: { showAddWishlistSheet = true }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundStyle(WomenLuxuryTheme.roseGold)
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

                if isSelecting {
                    bulkActionBar
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(90)
                }
            }
            .alert("Delete \(selectedItemIds.count) Wishlist Items?", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    womenDataStore.deleteWishlistItems(ids: selectedItemIds)
                    selectedItemIds.removeAll()
                    isSelecting = false
                    showToast("Removed from wishlist")
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to remove the selected goals from your wishlist?")
            }
            .sheet(item: $selectedDetailItem) { item in
                WomenWishlistDetailView(
                    womenDataStore: womenDataStore,
                    item: item,
                    onEdit: { editItem in self.itemToEdit = editItem },
                    onMoveToBoutique: { moveItem in self.itemToMoveToBoutique = moveItem }
                )
            }
            .sheet(item: $itemToEdit) { item in
                WomenAddWishlistItemSheet(womenDataStore: womenDataStore, existingItem: item)
            }
            .sheet(isPresented: $showAddWishlistSheet) {
                WomenAddWishlistItemSheet(womenDataStore: womenDataStore)
            }
            .sheet(item: $itemToMoveToBoutique) { item in
                moveToBoutiqueSheet(item: item)
            }
        }
    }

    private var profileSwitcherHeader: some View {
        HStack {
            HStack(spacing: 6) {
                Text("👗")
                Text("WOMEN'S WISHLIST")
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

    private var wishlistHeroBanner: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("TARGET WISHLIST BUDGET")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .tracking(1.4)
                        .foregroundStyle(WomenLuxuryTheme.textTertiary)

                    Text(womenDataStore.formattedWishlistValuation)
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(WomenLuxuryTheme.champagne)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(womenDataStore.wishlistItems.count)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(WomenLuxuryTheme.textPrimary)

                    Text("GOALS")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .tracking(1.2)
                        .foregroundStyle(WomenLuxuryTheme.textTertiary)
                }
            }

            Text("Curate your dream bridal couture, high jewelry, designer bags, and beauty essentials before buying.")
                .font(.system(size: 12))
                .foregroundStyle(WomenLuxuryTheme.textSecondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .womenLuxuryCardStyle(cornerRadius: 18)
    }

    private var categoryFilterScroll: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button(action: { selectedCategory = nil }) {
                    Text("All (\(womenDataStore.wishlistItems.count))")
                        .font(.system(size: 12, weight: selectedCategory == nil ? .bold : .medium))
                        .foregroundStyle(selectedCategory == nil ? Color.black : WomenLuxuryTheme.textSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(selectedCategory == nil ? WomenLuxuryTheme.roseGold : WomenLuxuryTheme.cardBackground)
                        .clipShape(Capsule())
                }

                ForEach(WomenCategory.allCases) { cat in
                    let count = womenDataStore.wishlistItems.filter { $0.category == cat }.count
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
                        .foregroundStyle(selectedCategory == cat ? Color.black : WomenLuxuryTheme.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(selectedCategory == cat ? cat.accentColor : WomenLuxuryTheme.cardBackground)
                        .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private func wishlistCard(item: WomenWishlistItem) -> some View {
        let isSelected = selectedItemIds.contains(item.id)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 14) {
                if isSelecting {
                    ZStack {
                        Circle()
                            .fill(isSelected ? WomenLuxuryTheme.roseGold : Color.black.opacity(0.6))
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

                WomenItemImageView(photoNameOrUrl: item.primaryPhoto, category: item.category)
                    .frame(width: 90, height: 110)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(item.brand.uppercased())
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(item.category.accentColor)

                        Spacer()

                        Text(item.priorityBadge)
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(WomenLuxuryTheme.secondaryBackground)
                            .foregroundStyle(WomenLuxuryTheme.roseGold)
                            .clipShape(Capsule())

                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(WomenLuxuryTheme.textTertiary)
                    }

                    Text(item.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(WomenLuxuryTheme.textPrimary)
                        .lineLimit(2)

                    Text(item.formattedPrice)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(WomenLuxuryTheme.champagne)

                    if !item.notes.isEmpty {
                        Text(item.notes)
                            .font(.system(size: 11))
                            .foregroundStyle(WomenLuxuryTheme.textTertiary)
                            .lineLimit(1)
                    }
                }
            }

            if !isSelecting {
                Divider().background(WomenLuxuryTheme.cardBorder)

                HStack(spacing: 10) {
                    if !item.storeUrl.isEmpty, let url = URL(string: item.storeUrl) {
                        Link(destination: url) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.up.right.square")
                                Text("Store")
                            }
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(WomenLuxuryTheme.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(WomenLuxuryTheme.secondaryBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }

                    Button(action: {
                        womenDataStore.deleteWishlistItem(item)
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.red.opacity(0.8))
                            .padding(9)
                            .background(Color.red.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    Spacer()

                    Button(action: {
                        itemToMoveToBoutique = item
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.seal.fill")
                            Text("Acquired ✨ Move to Boutique")
                        }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(WomenLuxuryTheme.roseGold)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
        .padding(14)
        .womenLuxuryCardStyle(cornerRadius: 16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? WomenLuxuryTheme.roseGold : Color.clear, lineWidth: 2)
        )
    }

    private func moveToBoutiqueSheet(item: WomenWishlistItem) -> some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("Congratulations on acquiring \"\(item.title)\"!")
                    .font(.system(size: 15))
                    .foregroundStyle(WomenLuxuryTheme.textSecondary)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Storage Location in Your Boutique")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(WomenLuxuryTheme.textPrimary)

                    TextField("e.g. Master Closet - Top Shelf, Velvet Vanity Box 1", text: $storageLocationForMove)
                        .font(.system(size: 14))
                        .padding(12)
                        .background(WomenLuxuryTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .foregroundStyle(WomenLuxuryTheme.textPrimary)
                }

                Button(action: {
                    womenDataStore.moveToBoutique(wishlistItem: item, storageLocation: storageLocationForMove)
                    itemToMoveToBoutique = nil
                    showToast("Added to Boutique Portfolio ✨")
                }) {
                    Text("Save to Boutique Portfolio ✨")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(WomenLuxuryTheme.roseGold)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Spacer()
            }
            .padding(20)
            .background(WomenLuxuryTheme.background.ignoresSafeArea())
            .navigationTitle("Transfer to Boutique")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { itemToMoveToBoutique = nil }
                        .foregroundStyle(WomenLuxuryTheme.textSecondary)
                }
            }
        }
    }

    private var bulkActionBar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(selectedItemIds.count) SELECTED")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundStyle(WomenLuxuryTheme.roseGold)
                Text("\(filteredWishlist.count) total in view")
                    .font(.system(size: 11))
                    .foregroundStyle(WomenLuxuryTheme.textTertiary)
            }

            Spacer()

            Button(action: { showDeleteConfirmation = true }) {
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

    private var emptyWishlistView: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(WomenLuxuryTheme.textTertiary)

            Text("Your Wishlist is Empty")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(WomenLuxuryTheme.textPrimary)

            Text("Plan future couture gowns, diamond sets, or designer bags.")
                .font(.system(size: 13))
                .foregroundStyle(WomenLuxuryTheme.textSecondary)
        }
    }

    private func showToast(_ msg: String) {
        withAnimation { toastMessage = msg }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { toastMessage = nil }
        }
    }
}
