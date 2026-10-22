import SwiftUI

public struct StylistView: View {
    @ObservedObject var dataStore: DataStore

    @State private var showLookBuilder = false
    @State private var suggestedLook: CuratedLook? = nil
    @State private var showSuggestionAlert = false

    public init(dataStore: DataStore) {
        self.dataStore = dataStore
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Banner
                    stylistBanner
                        .padding(.horizontal)
                        .padding(.top, 4)

                    // Curated Looks Feed
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Curated Loadouts")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(LuxuryTheme.textPrimary)

                            Spacer()

                            Button(action: { showLookBuilder = true }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Build Look")
                                }
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(LuxuryTheme.gold)
                            }
                        }
                        .padding(.horizontal)

                        ForEach(dataStore.looks) { look in
                            lookCard(look: look)
                                .padding(.horizontal)
                        }
                    }

                    Spacer(minLength: 40)
                }
            }
            .background(LuxuryTheme.background.ignoresSafeArea())
            .navigationTitle("AI Stylist")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showLookBuilder) {
                LookBuilderSheet(dataStore: dataStore)
            }
            .alert("Today's AI Recommended Look ✨", isPresented: $showSuggestionAlert) {
                Button("Got it", role: .cancel) {}
            } message: {
                if let look = suggestedLook {
                    Text("\(look.title)\n\n\(look.description)")
                } else {
                    Text("Add more items to your vault to generate personalized daily looks.")
                }
            }
        }
    }

    // MARK: - Banner
    private var stylistBanner: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                ZStack {
                    Circle()
                        .fill(LuxuryTheme.gold.opacity(0.18))
                        .frame(width: 44, height: 44)
                    Image(systemName: "sparkles")
                        .font(.system(size: 20))
                        .foregroundStyle(LuxuryTheme.gold)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("GENTLEMAN'S AI STYLIST")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .tracking(1.4)
                        .foregroundStyle(LuxuryTheme.gold)

                    Text("Curated Men's Wardrobe & Gear")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(LuxuryTheme.textPrimary)
                }

                Spacer()
            }

            Text("Pair your tailored jackets and shirts with the right footwear, timepieces, and tech gear based on your agenda.")
                .font(.system(size: 13))
                .foregroundStyle(LuxuryTheme.textSecondary)

            Button(action: generateDailyLook) {
                HStack(spacing: 8) {
                    Image(systemName: "wand.and.stars")
                    Text("Generate Today's Look ✨")
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.black)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(LuxuryTheme.gold)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .luxuryCardStyle(cornerRadius: 18)
    }

    // MARK: - Look Card
    private func lookCard(look: CuratedLook) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                Image(systemName: look.coverSymbol)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(LuxuryTheme.gold)

                Text(look.title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(LuxuryTheme.textPrimary)

                Spacer()

                Text(look.occasion)
                    .font(.system(size: 10, weight: .bold))
                    .textCase(.uppercase)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(LuxuryTheme.secondaryBackground)
                    .foregroundStyle(LuxuryTheme.gold)
                    .clipShape(Capsule())
            }

            Text(look.description)
                .font(.system(size: 13))
                .foregroundStyle(LuxuryTheme.textSecondary)
                .lineLimit(3)

            Divider().background(LuxuryTheme.cardBorder)

            // Items Included Grid
            VStack(alignment: .leading, spacing: 8) {
                Text("LOADOUT PIECES")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .tracking(1.0)
                    .foregroundStyle(LuxuryTheme.textTertiary)

                let allIds = look.clothesItemIds + look.shoesItemIds + look.electronicsItemIds
                let matchingItems = dataStore.items.filter { allIds.contains($0.id) }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(matchingItems) { item in
                            VStack(alignment: .leading, spacing: 4) {
                                ItemImageView(photoNameOrUrl: item.primaryPhoto, category: item.category)
                                    .frame(width: 80, height: 90)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))

                                Text(item.brand.uppercased())
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(item.category.accentColor)
                                    .lineLimit(1)

                                Text(item.name)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(LuxuryTheme.textPrimary)
                                    .lineLimit(1)
                            }
                            .frame(width: 80)
                        }
                    }
                }
            }

            // Tags
            if !look.tags.isEmpty {
                HStack(spacing: 6) {
                    ForEach(look.tags, id: \.self) { tag in
                        Text("#" + tag)
                            .font(.system(size: 11))
                            .foregroundStyle(LuxuryTheme.textTertiary)
                    }
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .luxuryCardStyle(cornerRadius: 16)
    }

    private func generateDailyLook() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        if let randomLook = dataStore.looks.randomElement() {
            suggestedLook = randomLook
            showSuggestionAlert = true
        }
    }
}

// MARK: - Look Builder Sheet
public struct LookBuilderSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var dataStore: DataStore

    @State private var title: String = ""
    @State private var occasion: String = "Smart Casual"
    @State private var description: String = ""
    @State private var selectedClothesId: UUID? = nil
    @State private var selectedShoesId: UUID? = nil
    @State private var selectedTechId: UUID? = nil

    public init(dataStore: DataStore) {
        self.dataStore = dataStore
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Title & Occasion
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Look Name")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(LuxuryTheme.textSecondary)

                        TextField("e.g. Modern Minimalist Executive", text: $title)
                            .font(.system(size: 15))
                            .padding(12)
                            .background(LuxuryTheme.secondaryBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .foregroundStyle(LuxuryTheme.textPrimary)

                        Text("Occasion")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(LuxuryTheme.textSecondary)

                        TextField("e.g. Boardroom, Weekend Flight", text: $occasion)
                            .font(.system(size: 15))
                            .padding(12)
                            .background(LuxuryTheme.secondaryBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .foregroundStyle(LuxuryTheme.textPrimary)
                    }
                    .padding(16)
                    .luxuryCardStyle(cornerRadius: 16)
                    .padding(.horizontal)

                    // Pick Clothes
                    pickerSection(
                        title: "1. Select Apparel / Clothes",
                        category: .clothes,
                        selectedId: $selectedClothesId
                    )
                    .padding(.horizontal)

                    // Pick Shoes
                    pickerSection(
                        title: "2. Select Footwear",
                        category: .shoes,
                        selectedId: $selectedShoesId
                    )
                    .padding(.horizontal)

                    // Pick Tech / Watch
                    pickerSection(
                        title: "3. Select Tech & Watch EDC",
                        category: .electronics,
                        selectedId: $selectedTechId
                    )
                    .padding(.horizontal)

                    // Save
                    Button(action: saveLook) {
                        Text("Create Look ✨")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(title.isEmpty ? LuxuryTheme.gold.opacity(0.4) : LuxuryTheme.gold)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(title.isEmpty)
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
                .padding(.vertical)
            }
            .background(LuxuryTheme.background.ignoresSafeArea())
            .navigationTitle("New Curated Look")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(LuxuryTheme.textSecondary)
                }
            }
        }
    }

    private func pickerSection(title: String, category: ItemCategory, selectedId: Binding<UUID?>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(category.accentColor)

            let categoryItems = dataStore.items.filter { $0.category == category }

            if categoryItems.isEmpty {
                Text("No items in \(category.rawValue)")
                    .font(.system(size: 12))
                    .foregroundStyle(LuxuryTheme.textTertiary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(categoryItems) { item in
                            let isSelected = selectedId.wrappedValue == item.id
                            Button(action: {
                                selectedId.wrappedValue = isSelected ? nil : item.id
                            }) {
                                VStack(alignment: .leading, spacing: 4) {
                                    ItemImageView(photoNameOrUrl: item.primaryPhoto, category: item.category)
                                        .frame(width: 80, height: 95)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(isSelected ? category.accentColor : Color.clear, lineWidth: 2)
                                        )

                                    Text(item.name)
                                        .font(.system(size: 10, weight: isSelected ? .bold : .regular))
                                        .foregroundStyle(isSelected ? category.accentColor : LuxuryTheme.textPrimary)
                                        .lineLimit(1)
                                }
                                .frame(width: 80)
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .luxuryCardStyle(cornerRadius: 16)
    }

    private func saveLook() {
        var clothes: [UUID] = []
        if let id = selectedClothesId { clothes.append(id) }

        var shoes: [UUID] = []
        if let id = selectedShoesId { shoes.append(id) }

        var tech: [UUID] = []
        if let id = selectedTechId { tech.append(id) }

        let newLook = CuratedLook(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            occasion: occasion,
            description: "Custom curated outfit combining \(clothes.count + shoes.count + tech.count) vault pieces.",
            clothesItemIds: clothes,
            shoesItemIds: shoes,
            electronicsItemIds: tech,
            tags: ["Custom", occasion]
        )

        dataStore.addLook(newLook)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }
}
