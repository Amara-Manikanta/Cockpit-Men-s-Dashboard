import SwiftUI

public struct WomenWardrobeItemPickerSheet: View {
    @ObservedObject var womenDataStore: WomenDataStore
    public let onSelectItems: ([WomenWardrobeItem]) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var searchQuery = ""
    @State private var selectedCategory: WomenCategory? = nil
    @State private var selectedIds: Set<UUID> = []

    public init(womenDataStore: WomenDataStore, onSelectItems: @escaping ([WomenWardrobeItem]) -> Void) {
        self.womenDataStore = womenDataStore
        self.onSelectItems = onSelectItems
    }

    private var filteredItems: [WomenWardrobeItem] {
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
                    VStack(alignment: .leading, spacing: 14) {
                        // Search Bar
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(WomenLuxuryTheme.textTertiary)
                            TextField("Search sarees, dresses, jewelry...", text: $searchQuery)
                                .font(.system(size: 14))
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

                        // Category Tabs
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                Button {
                                    selectedCategory = nil
                                } label: {
                                    Text("All (\(womenDataStore.items.count))")
                                        .font(.system(size: 12, weight: selectedCategory == nil ? .bold : .medium))
                                        .foregroundStyle(selectedCategory == nil ? Color.black : WomenLuxuryTheme.textSecondary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(selectedCategory == nil ? WomenLuxuryTheme.roseGold : WomenLuxuryTheme.secondaryBackground)
                                        .clipShape(Capsule())
                                }

                                ForEach(WomenCategory.allCases) { cat in
                                    let count = womenDataStore.itemCount(for: cat)
                                    Button {
                                        selectedCategory = (selectedCategory == cat) ? nil : cat
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: cat.iconName)
                                                .font(.system(size: 10))
                                            Text(cat.rawValue)
                                            Text("(\(count))")
                                                .opacity(0.7)
                                        }
                                        .font(.system(size: 12, weight: selectedCategory == cat ? .bold : .medium))
                                        .foregroundStyle(selectedCategory == cat ? Color.black : WomenLuxuryTheme.textSecondary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(selectedCategory == cat ? cat.accentColor : WomenLuxuryTheme.secondaryBackground)
                                        .clipShape(Capsule())
                                    }
                                }
                            }
                        }

                        // Counter & Select All
                        HStack {
                            Text("\(selectedIds.count) of \(filteredItems.count) Selected")
                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                .foregroundStyle(WomenLuxuryTheme.roseGold)

                            Spacer()

                            Button(selectedIds.count == filteredItems.count && !filteredItems.isEmpty ? "Deselect All" : "Select All in View") {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                if selectedIds.count == filteredItems.count && !filteredItems.isEmpty {
                                    selectedIds.removeAll()
                                } else {
                                    for item in filteredItems {
                                        selectedIds.insert(item.id)
                                    }
                                }
                            }
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(WomenLuxuryTheme.textSecondary)
                        }

                        // 2-Column Grid
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                            ForEach(filteredItems) { item in
                                let isSelected = selectedIds.contains(item.id)
                                Button {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    if isSelected {
                                        selectedIds.remove(item.id)
                                    } else {
                                        selectedIds.insert(item.id)
                                    }
                                } label: {
                                    VStack(alignment: .leading, spacing: 0) {
                                        ZStack(alignment: .topTrailing) {
                                            WomenItemImageView(photoNameOrUrl: item.primaryPhoto, category: item.category)
                                                .frame(height: 120)
                                                .frame(maxWidth: .infinity)
                                                .clipped()

                                            ZStack {
                                                Circle()
                                                    .fill(isSelected ? WomenLuxuryTheme.roseGold : Color.black.opacity(0.5))
                                                    .frame(width: 26, height: 26)

                                                Image(systemName: isSelected ? "checkmark" : "plus")
                                                    .font(.system(size: 12, weight: .bold))
                                                    .foregroundStyle(isSelected ? Color.black : Color.white)
                                            }
                                            .padding(6)
                                        }

                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(item.brand.uppercased())
                                                .font(.system(size: 9, weight: .bold))
                                                .foregroundStyle(item.category.accentColor)
                                                .lineLimit(1)

                                            Text(item.title)
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundStyle(WomenLuxuryTheme.textPrimary)
                                                .lineLimit(2)
                                                .frame(height: 30, alignment: .topLeading)

                                            Text(item.formattedPrice)
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

                        Spacer(minLength: 80)
                    }
                    .padding(16)
                }

                // Bottom Action Button
                VStack {
                    Button {
                        let selectedItems = womenDataStore.items.filter { selectedIds.contains($0.id) }
                        onSelectItems(selectedItems)
                        dismiss()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "briefcase.fill")
                            Text("Add Selected Pieces (\(selectedIds.count)) ✨")
                        }
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(selectedIds.isEmpty ? WomenLuxuryTheme.roseGold.opacity(0.4) : WomenLuxuryTheme.roseGold)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(selectedIds.isEmpty)
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
            .navigationTitle("Select Boutique Pieces")
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
