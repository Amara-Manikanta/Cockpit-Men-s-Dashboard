import SwiftUI

public struct LogTodayOutfitSheet: View {
    @Environment(\.dismiss) private var dismiss

    private let menDataStore: DataStore?
    private let womenDataStore: WomenDataStore?
    private let isWomen: Bool
    public let onComplete: ((Int) -> Void)?

    @State private var selectedDate: Date = Date()
    @State private var selectedItemIds: Set<UUID> = []
    @State private var selectedMenCategory: ItemCategory? = nil
    @State private var selectedWomenCategory: WomenCategory? = nil
    @State private var searchQuery: String = ""

    public init(dataStore: DataStore, onComplete: ((Int) -> Void)? = nil) {
        self.menDataStore = dataStore
        self.womenDataStore = nil
        self.isWomen = false
        self.onComplete = onComplete
    }

    public init(womenDataStore: WomenDataStore, onComplete: ((Int) -> Void)? = nil) {
        self.menDataStore = nil
        self.womenDataStore = womenDataStore
        self.isWomen = true
        self.onComplete = onComplete
    }

    private var accentColor: Color {
        isWomen ? WomenLuxuryTheme.roseGold : LuxuryTheme.accentAmber
    }

    private var cardBackground: Color {
        isWomen ? WomenLuxuryTheme.cardBackground : LuxuryTheme.cardBackground
    }

    private var background: Color {
        isWomen ? WomenLuxuryTheme.background : LuxuryTheme.background
    }

    // MARK: - Filtered Items
    private var menItems: [WardrobeItem] {
        guard let ds = menDataStore else { return [] }
        var list = ds.items
        if let cat = selectedMenCategory {
            list = list.filter { $0.category == cat }
        }
        let q = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !q.isEmpty {
            list = list.filter { $0.name.lowercased().contains(q) || $0.brand.lowercased().contains(q) }
        }
        return list
    }

    private var womenItems: [WomenWardrobeItem] {
        guard let ds = womenDataStore else { return [] }
        var list = ds.items
        if let cat = selectedWomenCategory {
            list = list.filter { $0.category == cat }
        }
        let q = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !q.isEmpty {
            list = list.filter { $0.title.lowercased().contains(q) || $0.brand.lowercased().contains(q) }
        }
        return list
    }

    // MARK: - Repeat Wear Warnings Among Selected Items
    private var repeatedSelectedItems: [(name: String, status: RepeatWearStatus)] {
        if isWomen {
            guard let ds = womenDataStore else { return [] }
            return ds.items
                .filter { selectedItemIds.contains($0.id) && $0.repeatWearStatus.isRepeatWarning }
                .map { ($0.title, $0.repeatWearStatus) }
        } else {
            guard let ds = menDataStore else { return [] }
            return ds.items
                .filter { selectedItemIds.contains($0.id) && $0.repeatWearStatus.isRepeatWarning }
                .map { ($0.name, $0.repeatWearStatus) }
        }
    }

    public var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 16) {
                        // Header Intro
                        headerCard

                        // Date Selector Row
                        datePickerCard

                        // Repeat Wear Warning Alert if any selected item is repeated!
                        if !repeatedSelectedItems.isEmpty {
                            repeatWearAlertBanner
                        }

                        // Category Filters
                        categoryFilterRow

                        // Search Field
                        searchBar

                        // Item Grid
                        itemsGrid
                            .padding(.bottom, 90)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
                .background(background.ignoresSafeArea())

                // Bottom Floating Confirm Button
                bottomActionBar
            }
            .navigationTitle("What Did You Wear?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(LuxuryTheme.textSecondary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if !selectedItemIds.isEmpty {
                        Button("Clear (\(selectedItemIds.count))") {
                            withAnimation { selectedItemIds.removeAll() }
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.red)
                    }
                }
            }
        }
    }

    // MARK: - Header Card
    private var headerCard: some View {
        VStack(spacing: 8) {
            HStack {
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.18))
                        .frame(width: 44, height: 44)
                    Image(systemName: "sparkles")
                        .font(.system(size: 20))
                        .foregroundStyle(accentColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("DAILY OUTFIT LOG & WEAR INTELLIGENCE")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .tracking(1.2)
                        .foregroundStyle(LuxuryTheme.textTertiary)
                    Text("Select what you wore today")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(LuxuryTheme.textPrimary)
                }

                Spacer()
            }

            Text("We'll log wear counts, compute cost-per-wear, and alert you if you're wearing pieces repeatedly too soon!")
                .font(.system(size: 12))
                .foregroundStyle(LuxuryTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(LuxuryTheme.cardBorder, lineWidth: 1)
        )
    }

    // MARK: - Date Picker Card
    private var datePickerCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("OUTFIT DATE")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(LuxuryTheme.textTertiary)
                Text(selectedDate.formatted(date: .complete, time: .omitted))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(LuxuryTheme.textPrimary)
            }

            Spacer()

            DatePicker("", selection: $selectedDate, in: ...Date(), displayedComponents: .date)
                .labelsHidden()
                .tint(accentColor)
        }
        .padding(12)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(LuxuryTheme.cardBorder, lineWidth: 1)
        )
    }

    // MARK: - Repeat Wear Alert Banner
    private var repeatWearAlertBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color.red)
                Text("REPEAT WEAR ALERT")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .tracking(1.2)
                    .foregroundStyle(Color.red)
            }

            Text("You are repeating garments worn very recently:")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(LuxuryTheme.textPrimary)

            VStack(alignment: .leading, spacing: 4) {
                ForEach(repeatedSelectedItems, id: \.name) { item in
                    HStack(spacing: 6) {
                        Text("•")
                            .foregroundStyle(Color.red)
                        Text(item.name)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(LuxuryTheme.textPrimary)
                            .lineLimit(1)
                        Text("— \(item.status.shortLabel)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.red)
                    }
                }
            }

            Text("Tip: Letting garments rest 24-48 hours preserves fabrics and keeps your daily outfits feeling diverse.")
                .font(.system(size: 11))
                .foregroundStyle(LuxuryTheme.textTertiary)
                .padding(.top, 2)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red.opacity(0.4), lineWidth: 1)
        )
    }

    // MARK: - Category Filter Row
    private var categoryFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if isWomen {
                    Button(action: { selectedWomenCategory = nil }) {
                        Text("All Pieces")
                            .font(.system(size: 12, weight: selectedWomenCategory == nil ? .bold : .medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedWomenCategory == nil ? accentColor : cardBackground)
                            .foregroundStyle(selectedWomenCategory == nil ? Color.black : LuxuryTheme.textSecondary)
                            .clipShape(Capsule())
                    }

                    ForEach(WomenCategory.allCases) { cat in
                        Button(action: { selectedWomenCategory = cat }) {
                            Text(cat.rawValue)
                                .font(.system(size: 12, weight: selectedWomenCategory == cat ? .bold : .medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedWomenCategory == cat ? accentColor : cardBackground)
                                .foregroundStyle(selectedWomenCategory == cat ? Color.black : LuxuryTheme.textSecondary)
                                .clipShape(Capsule())
                        }
                    }
                } else {
                    Button(action: { selectedMenCategory = nil }) {
                        Text("All Vault")
                            .font(.system(size: 12, weight: selectedMenCategory == nil ? .bold : .medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedMenCategory == nil ? accentColor : cardBackground)
                            .foregroundStyle(selectedMenCategory == nil ? Color.black : LuxuryTheme.textSecondary)
                            .clipShape(Capsule())
                    }

                    ForEach(ItemCategory.allCases) { cat in
                        Button(action: { selectedMenCategory = cat }) {
                            Text(cat.rawValue)
                                .font(.system(size: 12, weight: selectedMenCategory == cat ? .bold : .medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedMenCategory == cat ? accentColor : cardBackground)
                                .foregroundStyle(selectedMenCategory == cat ? Color.black : LuxuryTheme.textSecondary)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }

    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(LuxuryTheme.textTertiary)
            TextField("Search piece by name or brand...", text: $searchQuery)
                .font(.system(size: 13))
                .foregroundStyle(LuxuryTheme.textPrimary)
            if !searchQuery.isEmpty {
                Button(action: { searchQuery = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(LuxuryTheme.textTertiary)
                }
            }
        }
        .padding(10)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Items Grid
    private var itemsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            if isWomen {
                ForEach(womenItems) { item in
                    let isSelected = selectedItemIds.contains(item.id)
                    womenSelectableCard(item: item, isSelected: isSelected)
                        .onTapGesture {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            if isSelected {
                                selectedItemIds.remove(item.id)
                            } else {
                                selectedItemIds.insert(item.id)
                            }
                        }
                }
            } else {
                ForEach(menItems) { item in
                    let isSelected = selectedItemIds.contains(item.id)
                    menSelectableCard(item: item, isSelected: isSelected)
                        .onTapGesture {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            if isSelected {
                                selectedItemIds.remove(item.id)
                            } else {
                                selectedItemIds.insert(item.id)
                            }
                        }
                }
            }
        }
    }

    // MARK: - Men's Selectable Card
    private func menSelectableCard(item: WardrobeItem, isSelected: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .topTrailing) {
                ItemImageView(photoNameOrUrl: item.primaryPhoto, category: item.category)
                    .frame(height: 140)
                    .frame(maxWidth: .infinity)
                    .clipped()

                // Checkbox top right
                ZStack {
                    Circle()
                        .fill(isSelected ? accentColor : Color.black.opacity(0.6))
                        .frame(width: 26, height: 26)
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .black))
                            .foregroundStyle(Color.black)
                    } else {
                        Circle()
                            .stroke(Color.white.opacity(0.85), lineWidth: 1.8)
                            .frame(width: 18, height: 18)
                    }
                }
                .padding(8)

                // Repeat status badge top left
                VStack {
                    HStack {
                        repeatBadge(item.repeatWearStatus)
                        Spacer()
                    }
                    Spacer()
                }
                .padding(6)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(item.brand.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(item.category.accentColor)
                    .lineLimit(1)

                Text(item.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(LuxuryTheme.textPrimary)
                    .lineLimit(1)

                HStack {
                    Text("Worn \(item.timesWorn)x")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(LuxuryTheme.textTertiary)
                    Spacer()
                    Text(item.formattedCostPerWear)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(LuxuryTheme.gold)
                }
            }
            .padding(8)
        }
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? accentColor : LuxuryTheme.cardBorder, lineWidth: isSelected ? 2 : 1)
        )
    }

    // MARK: - Women's Selectable Card
    private func womenSelectableCard(item: WomenWardrobeItem, isSelected: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .topTrailing) {
                WomenItemImageView(photoNameOrUrl: item.primaryPhoto, category: item.category)
                    .frame(height: 140)
                    .frame(maxWidth: .infinity)
                    .clipped()

                // Checkbox top right
                ZStack {
                    Circle()
                        .fill(isSelected ? accentColor : Color.black.opacity(0.6))
                        .frame(width: 26, height: 26)
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .black))
                            .foregroundStyle(Color.black)
                    } else {
                        Circle()
                            .stroke(Color.white.opacity(0.85), lineWidth: 1.8)
                            .frame(width: 18, height: 18)
                    }
                }
                .padding(8)

                // Repeat status badge top left
                VStack {
                    HStack {
                        repeatBadge(item.repeatWearStatus)
                        Spacer()
                    }
                    Spacer()
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
                    .foregroundStyle(LuxuryTheme.textPrimary)
                    .lineLimit(1)

                HStack {
                    Text("Worn \(item.timesWorn)x")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(LuxuryTheme.textTertiary)
                    Spacer()
                    Text(item.formattedCostPerWear)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(WomenLuxuryTheme.champagne)
                }
            }
            .padding(8)
        }
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? accentColor : LuxuryTheme.cardBorder, lineWidth: isSelected ? 2 : 1)
        )
    }

    // MARK: - Repeat Badge
    private func repeatBadge(_ status: RepeatWearStatus) -> some View {
        HStack(spacing: 3) {
            Image(systemName: status.iconName)
                .font(.system(size: 8))
            Text(status.badgeText)
                .font(.system(size: 8, weight: .bold))
        }
        .foregroundStyle(status.isRepeatWarning ? Color.white : Color.black)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(status.color.opacity(status.isRepeatWarning ? 0.95 : 0.85))
        .clipShape(Capsule())
    }

    // MARK: - Bottom Action Bar
    private var bottomActionBar: some View {
        VStack {
            Button(action: confirmLogWorn) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                    Text(selectedItemIds.isEmpty ? "Select Pieces Worn" : "Confirm Outfit Worn (\(selectedItemIds.count)) ✨")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundStyle(Color.black)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(selectedItemIds.isEmpty ? accentColor.opacity(0.4) : accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: Color.black.opacity(0.3), radius: 8, y: 4)
            }
            .disabled(selectedItemIds.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .background(
            LinearGradient(colors: [background.opacity(0), background.opacity(0.95), background], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
    }

    private func confirmLogWorn() {
        let count = selectedItemIds.count
        guard count > 0 else { return }

        if isWomen {
            womenDataStore?.logOutfitWorn(itemIds: selectedItemIds, date: selectedDate)
        } else {
            menDataStore?.logOutfitWorn(itemIds: selectedItemIds, date: selectedDate)
        }

        UINotificationFeedbackGenerator().notificationOccurred(.success)
        onComplete?(count)
        dismiss()
    }
}
