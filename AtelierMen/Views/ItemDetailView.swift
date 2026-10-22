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

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Photo Carousel Header
                    photoCarouselSection

                    // Primary Info Card
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(item.brand.uppercased())
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .tracking(1.4)
                                .foregroundStyle(item.category.accentColor)

                            Spacer()

                            Text(item.category.rawValue)
                                .font(.system(size: 11, weight: .semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(item.category.accentColor.opacity(0.18))
                                .foregroundStyle(item.category.accentColor)
                                .clipShape(Capsule())
                        }

                        Text(item.name)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(LuxuryTheme.textPrimary)

                        HStack(alignment: .firstTextBaseline) {
                            Text(item.formattedPrice)
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

                    // Specifications Card
                    specificationsCard
                        .padding(.horizontal)

                    // Storage Location Card
                    storageLocationCard
                        .padding(.horizontal)

                    // Notes & Story Card
                    if !item.notes.isEmpty {
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
                        ShareLink(item: "\(item.brand) - \(item.name)\nPrice: \(item.formattedPrice)") {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16))
                                .foregroundStyle(LuxuryTheme.textSecondary)
                        }

                        // Favorite
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            dataStore.toggleFavorite(for: item)
                        }) {
                            Image(systemName: item.isFavorite ? "heart.fill" : "heart")
                                .font(.system(size: 18))
                                .foregroundStyle(item.isFavorite ? Color.red : LuxuryTheme.textSecondary)
                        }
                    }
                }
            }
            .alert("Delete Item?", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    dataStore.deleteItem(item)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to remove \(item.name) from your vault? This action cannot be undone.")
            }
        }
    }

    // MARK: - Photo Carousel
    private var photoCarouselSection: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedPhotoIndex) {
                if item.photos.isEmpty {
                    ItemImageView(photoNameOrUrl: "", category: item.category)
                        .tag(0)
                } else {
                    ForEach(Array(item.photos.enumerated()), id: \.offset) { index, photo in
                        ItemImageView(photoNameOrUrl: photo, category: item.category)
                            .tag(index)
                    }
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 380)

            // Pager dots and counter overlay
            if item.photos.count > 1 {
                HStack {
                    // Dots
                    HStack(spacing: 6) {
                        ForEach(0..<item.photos.count, id: \.self) { idx in
                            Circle()
                                .fill(idx == selectedPhotoIndex ? LuxuryTheme.gold : Color.white.opacity(0.35))
                                .frame(width: idx == selectedPhotoIndex ? 8 : 6, height: idx == selectedPhotoIndex ? 8 : 6)
                        }
                    }

                    Spacer()

                    // Counter
                    Text("\(selectedPhotoIndex + 1)/\(item.photos.count)")
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
                SpecRow(icon: "tag.fill", label: "Category", value: item.category.rawValue, accentColor: item.category.accentColor)
                SpecRow(icon: "folder.fill", label: "Subcategory", value: item.subcategory, accentColor: item.category.accentColor)
                SpecRow(icon: "calendar", label: "Occasion", value: item.occasion, accentColor: item.category.accentColor)

                // Category-specific rows
                switch item.category {
                case .electronics:
                    if !item.modelSpecs.isEmpty {
                        SpecRow(icon: "cpu.fill", label: "Model & Specs", value: item.modelSpecs, accentColor: item.category.accentColor)
                    }
                    if !item.serialNumber.isEmpty {
                        SpecRow(icon: "barcode", label: "Serial Number", value: item.serialNumber, accentColor: item.category.accentColor)
                    }
                    if !item.warrantyInfo.isEmpty {
                        SpecRow(icon: "checkmark.shield.fill", label: "Warranty", value: item.warrantyInfo, accentColor: item.category.accentColor)
                    }
                    if !item.techCondition.isEmpty {
                        SpecRow(icon: "sparkles", label: "Condition", value: item.techCondition, accentColor: item.category.accentColor)
                    }

                case .clothes:
                    if !item.size.isEmpty {
                        SpecRow(icon: "ruler.fill", label: "Size & Fit", value: item.size, accentColor: item.category.accentColor)
                    }
                    if !item.fabricMaterial.isEmpty {
                        SpecRow(icon: "leaf.fill", label: "Material / Fabric", value: item.fabricMaterial, accentColor: item.category.accentColor)
                    }
                    if !item.color.isEmpty {
                        SpecRow(icon: "paintpalette.fill", label: "Colorway", value: item.color, accentColor: item.category.accentColor)
                    }

                case .sportswear:
                    if !item.size.isEmpty {
                        SpecRow(icon: "ruler.fill", label: "Size & Fit", value: item.size, accentColor: item.category.accentColor)
                    }
                    if !item.fabricMaterial.isEmpty {
                        SpecRow(icon: "bolt.fill", label: "Performance Tech", value: item.fabricMaterial, accentColor: item.category.accentColor)
                    }
                    if !item.color.isEmpty {
                        SpecRow(icon: "paintpalette.fill", label: "Colorway", value: item.color, accentColor: item.category.accentColor)
                    }

                case .shoes:
                    if !item.shoeSize.isEmpty {
                        SpecRow(icon: "ruler.fill", label: "Shoe Size", value: item.shoeSize, accentColor: item.category.accentColor)
                    }
                    if !item.leatherSoleType.isEmpty {
                        SpecRow(icon: "shield.lefthalf.filled", label: "Sole & Construction", value: item.leatherSoleType, accentColor: item.category.accentColor)
                    }

                case .bags:
                    if !item.bagCapacity.isEmpty {
                        SpecRow(icon: "archivebox.fill", label: "Capacity & Size", value: item.bagCapacity, accentColor: item.category.accentColor)
                    }
                    if !item.bagMaterialHardware.isEmpty {
                        SpecRow(icon: "shield.fill", label: "Material & Hardware", value: item.bagMaterialHardware, accentColor: item.category.accentColor)
                    }

                case .grooming:
                    if !item.volumeSize.isEmpty {
                        SpecRow(icon: "drop.fill", label: "Volume / Size", value: item.volumeSize, accentColor: item.category.accentColor)
                    }
                    if !item.scentIngredients.isEmpty {
                        SpecRow(icon: "sparkles", label: "Notes / Ingredients", value: item.scentIngredients, accentColor: item.category.accentColor)
                    }

                case .accessories:
                    if !item.accessoryMaterial.isEmpty {
                        SpecRow(icon: "sparkle", label: "Material & Finish", value: item.accessoryMaterial, accentColor: item.category.accentColor)
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
                    .fill(item.category.accentColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(item.category.accentColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("KEPT IN / LOCATION")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.0)
                    .foregroundStyle(LuxuryTheme.textTertiary)

                Text(item.storageLocation)
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

            Text(item.notes)
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
                onEdit(item)
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
