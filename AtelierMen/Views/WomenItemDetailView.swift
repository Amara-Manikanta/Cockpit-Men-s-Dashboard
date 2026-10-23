import SwiftUI

public struct WomenItemDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var womenDataStore: WomenDataStore
    public let item: WomenWardrobeItem
    public let onEdit: (WomenWardrobeItem) -> Void

    @State private var selectedPhotoIndex = 0
    @State private var showDeleteConfirmation = false

    public init(
        womenDataStore: WomenDataStore,
        item: WomenWardrobeItem,
        onEdit: @escaping (WomenWardrobeItem) -> Void
    ) {
        self.womenDataStore = womenDataStore
        self.item = item
        self.onEdit = onEdit
    }

    private var currentItem: WomenWardrobeItem {
        womenDataStore.items.first { $0.id == item.id } ?? item
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Photo Carousel Header
                    photoCarouselSection

                    // Primary Info Card
                    primaryInfoCard
                        .padding(.horizontal)

                    // Wear & Aging Intelligence Card
                    wearAndAgingCard
                        .padding(.horizontal)

                    // Garment Condition & Wear Aging Card
                    garmentConditionAndAgingCard
                        .padding(.horizontal)

                    // Specifications & Metal Card
                    specificationsCard
                        .padding(.horizontal)

                    // Storage Location Card
                    storageLocationCard
                        .padding(.horizontal)

                    // Notes Card
                    if !currentItem.notes.isEmpty {
                        notesCard
                            .padding(.horizontal)
                    }

                    // Action Buttons
                    actionButtonsSection
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                }
            }
            .background(WomenLuxuryTheme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(WomenLuxuryTheme.textSecondary)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        ShareLink(item: "\(currentItem.brand) - \(currentItem.title)\nValuation: \(currentItem.formattedPrice)\nCost-per-wear: \(currentItem.formattedCostPerWear)") {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16))
                                .foregroundStyle(WomenLuxuryTheme.textSecondary)
                        }

                        Button(action: {
                            dismiss()
                            onEdit(currentItem)
                        }) {
                            Text("Edit")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(WomenLuxuryTheme.roseGold)
                        }
                    }
                }
            }
            .alert("Delete Piece from Boutique?", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    womenDataStore.deleteItem(currentItem)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to permanently delete \"\(currentItem.title)\"?")
            }
        }
    }

    // MARK: - Photo Carousel
    private var photoCarouselSection: some View {
        ZStack(alignment: .bottom) {
            if currentItem.photos.isEmpty {
                WomenItemImageView(photoNameOrUrl: "", category: item.category)
                    .frame(height: 340)
                    .frame(maxWidth: .infinity)
            } else {
                TabView(selection: $selectedPhotoIndex) {
                    ForEach(Array(currentItem.photos.enumerated()), id: \.offset) { index, photo in
                        WomenItemImageView(photoNameOrUrl: photo, category: item.category)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 340)

                if currentItem.photos.count > 1 {
                    HStack(spacing: 6) {
                        ForEach(0..<currentItem.photos.count, id: \.self) { i in
                            Circle()
                                .fill(selectedPhotoIndex == i ? WomenLuxuryTheme.roseGold : Color.white.opacity(0.35))
                                .frame(width: 7, height: 7)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Capsule())
                    .padding(.bottom, 12)
                }
            }
        }
    }

    // MARK: - Primary Info Card
    private var primaryInfoCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(currentItem.brand.uppercased())
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .tracking(1.4)
                    .foregroundStyle(currentItem.category.accentColor)

                Spacer()

                HStack(spacing: 6) {
                    Image(systemName: currentItem.category.iconName)
                        .font(.system(size: 10))
                    Text(currentItem.category.rawValue)
                        .font(.system(size: 11, weight: .semibold))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(currentItem.category.accentColor.opacity(0.18))
                .foregroundStyle(currentItem.category.accentColor)
                .clipShape(Capsule())

                if currentItem.isSet {
                    Text("✨ SET")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(Color.black)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(WomenLuxuryTheme.champagne)
                        .clipShape(Capsule())
                }
            }

            Text(currentItem.title)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(WomenLuxuryTheme.textPrimary)

            HStack(alignment: .firstTextBaseline) {
                Text(currentItem.formattedPrice)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(WomenLuxuryTheme.champagne)

                Text("(est. valuation)")
                    .font(.system(size: 12))
                    .foregroundStyle(WomenLuxuryTheme.textTertiary)

                Spacer()

                Button(action: {
                    womenDataStore.toggleFavorite(for: currentItem)
                }) {
                    Image(systemName: currentItem.isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 20))
                        .foregroundStyle(currentItem.isFavorite ? Color.red : WomenLuxuryTheme.textSecondary)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .womenLuxuryCardStyle(cornerRadius: 16)
    }

    private func repeatStatusBadge(_ status: RepeatWearStatus) -> some View {
        HStack(spacing: 4) {
            Image(systemName: status.iconName)
                .font(.system(size: 9))
            Text(status.badgeText)
                .font(.system(size: 9, weight: .bold))
        }
        .foregroundStyle(status.isRepeatWarning ? Color.white : Color.black)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(status.color.opacity(status.isRepeatWarning ? 0.95 : 0.85))
        .clipShape(Capsule())
    }

    // MARK: - Wear & Aging Card
    private var wearAndAgingCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundStyle(WomenLuxuryTheme.roseGold)
                Text("WEAR & AGING INTELLIGENCE")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .tracking(1.2)
                    .foregroundStyle(WomenLuxuryTheme.textTertiary)

                Spacer()

                HStack(spacing: 6) {
                    repeatStatusBadge(currentItem.repeatWearStatus)

                    Text(currentItem.wearAgingStatus.label)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(currentItem.wearAgingStatus.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(currentItem.wearAgingStatus.color.opacity(0.15))
                        .clipShape(Capsule())
                }
            }

            // Repeat Wear Warning Alert
            if let warning = currentItem.repeatWearStatus.warningBannerMessage {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(currentItem.repeatWearStatus.color)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(currentItem.repeatWearStatus.badgeText)
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundStyle(currentItem.repeatWearStatus.color)

                        Text(warning)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(WomenLuxuryTheme.textPrimary)
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(currentItem.repeatWearStatus.color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(currentItem.repeatWearStatus.color.opacity(0.35), lineWidth: 1)
                )
            }

            HStack(spacing: 16) {
                // Cost per wear
                VStack(alignment: .leading, spacing: 2) {
                    Text("COST PER WEAR")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(WomenLuxuryTheme.textTertiary)
                    Text(currentItem.formattedCostPerWear)
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(WomenLuxuryTheme.roseGold)
                }

                Spacer()

                // Stepper (+ / -)
                HStack(spacing: 8) {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        womenDataStore.decrementWearCount(for: currentItem)
                    }) {
                        Image(systemName: "minus")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(WomenLuxuryTheme.textPrimary)
                            .frame(width: 34, height: 34)
                            .background(WomenLuxuryTheme.secondaryBackground)
                            .clipShape(Circle())
                    }

                    Text("\(currentItem.timesWorn)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(WomenLuxuryTheme.textPrimary)
                        .frame(minWidth: 26)

                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        womenDataStore.incrementWearCount(for: currentItem)
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color.black)
                            .frame(width: 34, height: 34)
                            .background(WomenLuxuryTheme.roseGold)
                            .clipShape(Circle())
                    }
                }
            }

            // "Wore Today" Button
            Button(action: {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                womenDataStore.markWoreToday(for: currentItem)
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                    Text("Styled / Wore Today ✨")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundStyle(Color.black)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(WomenLuxuryTheme.roseGold)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            Divider()
                .background(WomenLuxuryTheme.cardBorder)

            // Duplicate pieces / pairs owned
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("PAIRS / PIECES OWNED")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(WomenLuxuryTheme.textTertiary)
                    Text("\(currentItem.quantity) \(currentItem.category == .fineJewelry ? "Pairs/Sets" : "Items")")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(WomenLuxuryTheme.textPrimary)
                }

                Spacer()

                HStack(spacing: 8) {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        womenDataStore.decrementQuantity(for: currentItem)
                    }) {
                        Image(systemName: "minus")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(WomenLuxuryTheme.textPrimary)
                            .frame(width: 34, height: 34)
                            .background(WomenLuxuryTheme.secondaryBackground)
                            .clipShape(Circle())
                    }

                    Text("\(currentItem.quantity)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(WomenLuxuryTheme.textPrimary)
                        .frame(minWidth: 26)

                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        womenDataStore.incrementQuantity(for: currentItem)
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color.black)
                            .frame(width: 34, height: 34)
                            .background(WomenLuxuryTheme.roseGold)
                            .clipShape(Circle())
                    }
                }
            }

            if let last = currentItem.lastWornDate {
                Text("Last styled on: \(last.formatted(date: .abbreviated, time: .omitted))")
                    .font(.system(size: 11))
                    .foregroundStyle(WomenLuxuryTheme.textTertiary)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .womenLuxuryCardStyle(cornerRadius: 16)
    }

    // MARK: - Garment Condition & Aging Card
    private var garmentConditionAndAgingCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header with Condition Dropdown Menu
            HStack {
                Image(systemName: "tshirt.fill")
                    .foregroundStyle(currentItem.effectiveCondition.color)
                Text("GARMENT CONDITION & WEAR AGING")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(WomenLuxuryTheme.textTertiary)

                Spacer()

                // Condition Dropdown Menu
                Menu {
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        womenDataStore.updateGarmentCondition(nil, for: currentItem)
                    } label: {
                        HStack {
                            Text("Auto (Based on \(currentItem.timesWorn) wears)")
                            if !currentItem.isManuallySetCondition {
                                Image(systemName: "checkmark")
                            }
                        }
                    }

                    Divider()

                    ForEach(GarmentCondition.allCases) { condition in
                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            womenDataStore.updateGarmentCondition(condition, for: currentItem)
                        } label: {
                            HStack {
                                Label(condition.displayName, systemImage: condition.iconName)
                                if currentItem.garmentCondition == condition {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: currentItem.effectiveCondition.iconName)
                            .font(.system(size: 10))
                        Text(currentItem.effectiveCondition.displayName)
                            .font(.system(size: 11, weight: .bold))
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 9))
                    }
                    .foregroundStyle(currentItem.effectiveCondition.color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(currentItem.effectiveCondition.color.opacity(0.16))
                    .clipShape(Capsule())
                }
            }

            // Status Banner with Icon and Explanation
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(currentItem.effectiveCondition.color.opacity(0.18))
                        .frame(width: 44, height: 44)

                    Image(systemName: currentItem.effectiveCondition.iconName)
                        .font(.system(size: 20))
                        .foregroundStyle(currentItem.effectiveCondition.color)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(currentItem.effectiveCondition.badgeText)
                            .font(.system(size: 13, weight: .black))
                            .foregroundStyle(currentItem.effectiveCondition.color)

                        Text(currentItem.isManuallySetCondition ? "• Manual" : "• Auto-Tracked")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundStyle(WomenLuxuryTheme.textTertiary)
                    }

                    Text(currentItem.effectiveCondition.description)
                        .font(.system(size: 12))
                        .foregroundStyle(WomenLuxuryTheme.textSecondary)
                }
            }

            Divider()
                .background(WomenLuxuryTheme.cardBorder)

            // Wear Lifecycle Progress Indicator
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Wear Aging Lifespan")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(WomenLuxuryTheme.textSecondary)
                    Spacer()
                    Text("\(currentItem.timesWorn) / 50 typical wears (\(Int(GarmentCondition.wearProgressRatio(currentItem.timesWorn) * 100))%)")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(currentItem.effectiveCondition.color)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(WomenLuxuryTheme.secondaryBackground)
                            .frame(height: 7)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.green, Color.blue, Color.orange, Color.red],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * CGFloat(GarmentCondition.wearProgressRatio(currentItem.timesWorn)), height: 7)
                    }
                }
                .frame(height: 7)
            }

            // Advisory / Retirement Warning Recommendation
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: currentItem.effectiveCondition.isOldOrFaded ? "exclamationmark.triangle.fill" : "checkmark.seal.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(currentItem.effectiveCondition.color)

                Text(currentItem.effectiveCondition.wearRecommendation)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(currentItem.effectiveCondition.isOldOrFaded ? WomenLuxuryTheme.textPrimary : WomenLuxuryTheme.textSecondary)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(currentItem.effectiveCondition.color.opacity(currentItem.effectiveCondition.isOldOrFaded ? 0.14 : 0.08))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .womenLuxuryCardStyle(cornerRadius: 16)
    }

    // MARK: - Specifications Card
    private var specificationsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "sparkle")
                    .foregroundStyle(WomenLuxuryTheme.roseGold)
                Text("SPECIFICATIONS & PURITY")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .tracking(1.2)
                    .foregroundStyle(WomenLuxuryTheme.textTertiary)
            }

            VStack(spacing: 10) {
                row(title: "Subcategory", value: currentItem.subcategory)
                row(title: "Material / Metal", value: currentItem.metal.rawValue)
                if !currentItem.purity.isEmpty {
                    row(title: "Purity & Hallmark", value: currentItem.purity)
                }
                row(title: "Size / Dimensions", value: currentItem.sizeOrDimensions)
                if currentItem.isSet && !currentItem.setIncludes.isEmpty {
                    row(title: "Set Includes", value: currentItem.setIncludes)
                }
                row(title: "Occasion", value: currentItem.occasion)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .womenLuxuryCardStyle(cornerRadius: 16)
    }

    private func row(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13))
                .foregroundStyle(WomenLuxuryTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(WomenLuxuryTheme.textPrimary)
        }
    }

    // MARK: - Storage Location Card
    private var storageLocationCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "shippingbox.fill")
                    .foregroundStyle(WomenLuxuryTheme.roseGold)
                Text("STORAGE & VANITY PLACEMENT")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .tracking(1.2)
                    .foregroundStyle(WomenLuxuryTheme.textTertiary)
            }

            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundStyle(WomenLuxuryTheme.champagne)
                Text(currentItem.storageLocation)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(WomenLuxuryTheme.textPrimary)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .womenLuxuryCardStyle(cornerRadius: 16)
    }

    // MARK: - Notes Card
    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "note.text")
                    .foregroundStyle(WomenLuxuryTheme.roseGold)
                Text("STYLING NOTES & STORY")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .tracking(1.2)
                    .foregroundStyle(WomenLuxuryTheme.textTertiary)
            }

            Text(currentItem.notes)
                .font(.system(size: 13))
                .foregroundStyle(WomenLuxuryTheme.textSecondary)
                .lineSpacing(4)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .womenLuxuryCardStyle(cornerRadius: 16)
    }

    // MARK: - Action Buttons
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            if !currentItem.storeUrl.isEmpty, let url = URL(string: currentItem.storeUrl) {
                Link(destination: url) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.up.right.square.fill")
                        Text("Visit Brand Store Page")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(WomenLuxuryTheme.roseGold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(WomenLuxuryTheme.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            HStack(spacing: 12) {
                Button(action: {
                    dismiss()
                    onEdit(currentItem)
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "pencil")
                        Text("Edit Piece")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(WomenLuxuryTheme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(WomenLuxuryTheme.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button(action: {
                    showDeleteConfirmation = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                        Text("Delete")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.red)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(Color.red.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
}
