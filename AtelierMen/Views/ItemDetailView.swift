import SwiftUI

public struct ItemDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var dataStore: DataStore
    public let item: WardrobeItem
    public let onEdit: (WardrobeItem) -> Void

    @State private var selectedPhotoIndex = 0
    @State private var showDeleteConfirmation = false

    public init(dataStore: DataStore, item: WardrobeItem, onEdit: @escaping (WardrobeItem) -> Void) {
        self.dataStore = dataStore
        self.item = item
        self.onEdit = onEdit
    }

    private var currentItem: WardrobeItem {
        dataStore.items.first { $0.id == item.id } ?? item
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Photo Carousel Header
                    photoCarouselSection

                    // Primary Info Card
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(currentItem.brand.uppercased())
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .tracking(1.4)
                                .foregroundStyle(currentItem.category.accentColor)

                            Spacer()

                            Text(currentItem.category.rawValue)
                                .font(.system(size: 11, weight: .semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(currentItem.category.accentColor.opacity(0.18))
                                .foregroundStyle(currentItem.category.accentColor)
                                .clipShape(Capsule())
                        }

                        Text(currentItem.name)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(LuxuryTheme.textPrimary)

                        HStack(alignment: .firstTextBaseline) {
                            Text(currentItem.formattedPrice)
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundStyle(LuxuryTheme.gold)

                            Text("(est. valuation)")
                                .font(.system(size: 12))
                                .foregroundStyle(LuxuryTheme.textTertiary)
                        }
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .luxuryCardStyle(cornerRadius: 16)
                    .padding(.horizontal)

                    // Wear Intelligence & Ownership Card
                    wearAndPairsCard
                        .padding(.horizontal)

                    // Specifications Card
                    specificationsCard
                        .padding(.horizontal)

                    // Storage Location Card
                    storageLocationCard
                        .padding(.horizontal)

                    // Notes & Story Card
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
            .background(LuxuryTheme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(LuxuryTheme.textSecondary)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        // Share
                        ShareLink(item: "\(currentItem.brand) - \(currentItem.name)\nPrice: \(currentItem.formattedPrice)\nCost-per-wear: \(currentItem.formattedCostPerWear)") {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16))
                                .foregroundStyle(LuxuryTheme.textSecondary)
                        }

                        // Favorite
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            dataStore.toggleFavorite(for: currentItem)
                        }) {
                            Image(systemName: currentItem.isFavorite ? "heart.fill" : "heart")
                                .font(.system(size: 18))
                                .foregroundStyle(currentItem.isFavorite ? Color.red : LuxuryTheme.textSecondary)
                        }
                    }
                }
            }
            .alert("Delete Item?", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    dataStore.deleteItem(currentItem)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to remove \(currentItem.name) from your vault? This action cannot be undone.")
            }
        }
    }

    // MARK: - Wear & Pairs Intelligence Card
    private var wearAndPairsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundStyle(LuxuryTheme.accentAmber)
                Text("WEAR INTELLIGENCE & OWNERSHIP")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .tracking(1.2)
                    .foregroundStyle(LuxuryTheme.textTertiary)

                Spacer()

                HStack(spacing: 6) {
                    repeatStatusBadge(currentItem.repeatWearStatus)

                    Text("CPW: \(currentItem.formattedCostPerWear)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(LuxuryTheme.accentAmber)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(LuxuryTheme.accentAmber.opacity(0.15))
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
                            .foregroundStyle(LuxuryTheme.textPrimary)
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
                // Cost per wear & Wear count
                VStack(alignment: .leading, spacing: 2) {
                    Text("COST PER WEAR")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(LuxuryTheme.textTertiary)
                    Text(currentItem.formattedCostPerWear)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(LuxuryTheme.gold)
                    Text("Worn \(currentItem.timesWorn) \(currentItem.timesWorn == 1 ? "time" : "times")")
                        .font(.system(size: 11))
                        .foregroundStyle(LuxuryTheme.textSecondary)
                }

                Spacer()

                // Wear Stepper (+ / -)
                HStack(spacing: 8) {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        dataStore.decrementWearCount(for: currentItem)
                    }) {
                        Image(systemName: "minus")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(LuxuryTheme.textPrimary)
                            .frame(width: 34, height: 34)
                            .background(LuxuryTheme.secondaryBackground)
                            .clipShape(Circle())
                    }

                    Text("\(currentItem.timesWorn)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(LuxuryTheme.textPrimary)
                        .frame(minWidth: 26)

                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        dataStore.incrementWearCount(for: currentItem)
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color.black)
                            .frame(width: 34, height: 34)
                            .background(LuxuryTheme.accentAmber)
                            .clipShape(Circle())
                    }
                }
            }

            // "Wore Today" Button
            Button(action: {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                dataStore.markWoreToday(for: currentItem)
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                    Text("Wore Today (+1)")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundStyle(Color.black)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(LuxuryTheme.accentAmber)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            Divider()
                .background(LuxuryTheme.cardBorder)

            // Duplicate pieces / pairs owned
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("PAIRS / PIECES OWNED")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(LuxuryTheme.textTertiary)
                    Text("\(currentItem.quantity) \(currentItem.category == .shoes ? "Pairs" : "Items")")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(LuxuryTheme.textPrimary)
                }

                Spacer()

                HStack(spacing: 8) {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        dataStore.decrementQuantity(for: currentItem)
                    }) {
                        Image(systemName: "minus")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(LuxuryTheme.textPrimary)
                            .frame(width: 34, height: 34)
                            .background(LuxuryTheme.secondaryBackground)
                            .clipShape(Circle())
                    }

                    Text("\(currentItem.quantity)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(LuxuryTheme.textPrimary)
                        .frame(minWidth: 26)

                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        dataStore.incrementQuantity(for: currentItem)
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color.black)
                            .frame(width: 34, height: 34)
                            .background(LuxuryTheme.accentAmber)
                            .clipShape(Circle())
                    }
                }
            }

            if let last = currentItem.lastWornDate {
                Text("Last worn on: \(last.formatted(date: .abbreviated, time: .omitted))")
                    .font(.system(size: 11))
                    .foregroundStyle(LuxuryTheme.textTertiary)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .luxuryCardStyle(cornerRadius: 16)
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

    // MARK: - Photo Carousel
    private var photoCarouselSection: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedPhotoIndex) {
                if currentItem.photos.isEmpty {
                    ItemImageView(photoNameOrUrl: "", category: currentItem.category)
                        .tag(0)
                } else {
                    ForEach(Array(currentItem.photos.enumerated()), id: \.offset) { index, photo in
                        ItemImageView(photoNameOrUrl: photo, category: currentItem.category)
                            .tag(index)
                    }
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 380)

            // Pager dots and counter overlay
            if currentItem.photos.count > 1 {
                HStack {
                    // Dots
                    HStack(spacing: 6) {
                        ForEach(0..<currentItem.photos.count, id: \.self) { idx in
                            Circle()
                                .fill(idx == selectedPhotoIndex ? LuxuryTheme.gold : Color.white.opacity(0.35))
                                .frame(width: idx == selectedPhotoIndex ? 8 : 6, height: idx == selectedPhotoIndex ? 8 : 6)
                        }
                    }

                    Spacer()

                    // Counter
                    Text("\(selectedPhotoIndex + 1)/\(currentItem.photos.count)")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 14)
            }
        }
    }

    // MARK: - Specifications Card
    private var specificationsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Specifications & Details")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .tracking(0.5)
                .foregroundStyle(LuxuryTheme.textPrimary)

            Divider().background(LuxuryTheme.cardBorder)

            Group {
                SpecRow(icon: "tag.fill", label: "Category", value: currentItem.category.rawValue, accentColor: currentItem.category.accentColor)
                SpecRow(icon: "folder.fill", label: "Subcategory", value: currentItem.subcategory, accentColor: currentItem.category.accentColor)
                SpecRow(icon: "calendar", label: "Occasion", value: currentItem.occasion, accentColor: currentItem.category.accentColor)

                // Category-specific rows
                switch currentItem.category {
                case .electronics:
                    if !currentItem.modelSpecs.isEmpty {
                        SpecRow(icon: "cpu.fill", label: "Model & Specs", value: currentItem.modelSpecs, accentColor: currentItem.category.accentColor)
                    }
                    if !currentItem.serialNumber.isEmpty {
                        SpecRow(icon: "barcode", label: "Serial Number", value: currentItem.serialNumber, accentColor: currentItem.category.accentColor)
                    }
                    if !currentItem.warrantyInfo.isEmpty {
                        SpecRow(icon: "checkmark.shield.fill", label: "Warranty", value: currentItem.warrantyInfo, accentColor: currentItem.category.accentColor)
                    }
                    if !currentItem.techCondition.isEmpty {
                        SpecRow(icon: "sparkles", label: "Condition", value: currentItem.techCondition, accentColor: currentItem.category.accentColor)
                    }

                case .clothes:
                    if !currentItem.size.isEmpty {
                        SpecRow(icon: "ruler.fill", label: "Size & Fit", value: currentItem.size, accentColor: currentItem.category.accentColor)
                    }
                    if !currentItem.fabricMaterial.isEmpty {
                        SpecRow(icon: "leaf.fill", label: "Material / Fabric", value: currentItem.fabricMaterial, accentColor: currentItem.category.accentColor)
                    }
                    if !currentItem.color.isEmpty {
                        SpecRow(icon: "paintpalette.fill", label: "Colorway", value: currentItem.color, accentColor: currentItem.category.accentColor)
                    }

                case .sportswear:
                    if !currentItem.size.isEmpty {
                        SpecRow(icon: "ruler.fill", label: "Size & Fit", value: currentItem.size, accentColor: currentItem.category.accentColor)
                    }
                    if !currentItem.fabricMaterial.isEmpty {
                        SpecRow(icon: "bolt.fill", label: "Performance Tech", value: currentItem.fabricMaterial, accentColor: currentItem.category.accentColor)
                    }
                    if !currentItem.color.isEmpty {
                        SpecRow(icon: "paintpalette.fill", label: "Colorway", value: currentItem.color, accentColor: currentItem.category.accentColor)
                    }

                case .shoes:
                    if !currentItem.shoeSize.isEmpty {
                        SpecRow(icon: "ruler.fill", label: "Shoe Size", value: currentItem.shoeSize, accentColor: currentItem.category.accentColor)
                    }
                    if !currentItem.leatherSoleType.isEmpty {
                        SpecRow(icon: "shield.lefthalf.filled", label: "Sole & Construction", value: currentItem.leatherSoleType, accentColor: currentItem.category.accentColor)
                    }

                case .bags:
                    if !currentItem.bagCapacity.isEmpty {
                        SpecRow(icon: "archivebox.fill", label: "Capacity & Size", value: currentItem.bagCapacity, accentColor: currentItem.category.accentColor)
                    }
                    if !currentItem.bagMaterialHardware.isEmpty {
                        SpecRow(icon: "shield.fill", label: "Material & Hardware", value: currentItem.bagMaterialHardware, accentColor: currentItem.category.accentColor)
                    }

                case .grooming:
                    if !currentItem.volumeSize.isEmpty {
                        SpecRow(icon: "drop.fill", label: "Volume / Size", value: currentItem.volumeSize, accentColor: currentItem.category.accentColor)
                    }
                    if !currentItem.scentIngredients.isEmpty {
                        SpecRow(icon: "sparkles", label: "Notes / Ingredients", value: currentItem.scentIngredients, accentColor: currentItem.category.accentColor)
                    }

                case .accessories:
                    if !currentItem.accessoryMaterial.isEmpty {
                        SpecRow(icon: "sparkle", label: "Material & Finish", value: currentItem.accessoryMaterial, accentColor: currentItem.category.accentColor)
                    }
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .luxuryCardStyle(cornerRadius: 16)
    }

    // MARK: - Storage Location Card
    private var storageLocationCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(currentItem.category.accentColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(currentItem.category.accentColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("KEPT IN / LOCATION")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.0)
                    .foregroundStyle(LuxuryTheme.textTertiary)

                Text(currentItem.storageLocation)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(LuxuryTheme.textPrimary)
            }

            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .luxuryCardStyle(cornerRadius: 16)
    }

    // MARK: - Notes Card
    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "note.text")
                    .foregroundStyle(LuxuryTheme.gold)
                Text("Notes & Details")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(LuxuryTheme.textPrimary)
            }

            Text(currentItem.notes)
                .font(.system(size: 14))
                .foregroundStyle(LuxuryTheme.textSecondary)
                .lineSpacing(4)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .luxuryCardStyle(cornerRadius: 16)
    }

    // MARK: - Action Buttons
    private var actionButtonsSection: some View {
        HStack(spacing: 12) {
            // Edit
            Button(action: {
                dismiss()
                onEdit(currentItem)
            }) {
                HStack {
                    Image(systemName: "pencil")
                    Text("Edit Details")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.black)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(LuxuryTheme.gold)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Delete
            Button(action: {
                showDeleteConfirmation = true
            }) {
                HStack {
                    Image(systemName: "trash")
                    Text("Delete")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.red)
                .frame(width: 120)
                .frame(height: 50)
                .background(Color.red.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}
