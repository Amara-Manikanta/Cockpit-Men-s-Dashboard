import SwiftUI

public struct WishlistDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var dataStore: DataStore
    public let item: WishlistItem
    public let onEdit: (WishlistItem) -> Void
    public let onMoveToVault: (WishlistItem) -> Void

    @State private var selectedPhotoIndex = 0
    @State private var showDeleteConfirmation = false

    public init(
        dataStore: DataStore,
        item: WishlistItem,
        onEdit: @escaping (WishlistItem) -> Void,
        onMoveToVault: @escaping (WishlistItem) -> Void
    ) {
        self.dataStore = dataStore
        self.item = item
        self.onEdit = onEdit
        self.onMoveToVault = onMoveToVault
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

                    // Target Budget & Priority Card
                    acquisitionMetricsCard
                        .padding(.horizontal)

                    // Store Link Card
                    if !item.storeUrl.isEmpty {
                        storeLinkCard
                            .padding(.horizontal)
                    }

                    // Notes / Specs Card
                    if !item.notes.isEmpty {
                        notesCard
                            .padding(.horizontal)
                    }

                    // Action Buttons (Move to Vault, Edit, Delete)
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
                        ShareLink(
                            item: "\(item.brand) - \(item.name)\nTarget Price: \(item.formattedPrice)" + (item.storeUrl.isEmpty ? "" : "\n\(item.storeUrl)")
                        ) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16))
                                .foregroundStyle(LuxuryTheme.textSecondary)
                        }

                        Button(action: {
                            dismiss()
                            onEdit(item)
                        }) {
                            Text("Edit")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(LuxuryTheme.accentAmber)
                        }
                    }
                }
            }
            .alert("Delete Wishlist Item?", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    dataStore.deleteWishlistItem(item)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to permanently remove \"\(item.name)\" from your wishlist?")
            }
        }
    }

    // MARK: - Photo Carousel
    private var photoCarouselSection: some View {
        ZStack(alignment: .bottom) {
            if item.photos.isEmpty {
                ItemImageView(photoNameOrUrl: "", category: item.category)
                    .frame(height: 340)
                    .frame(maxWidth: .infinity)
            } else {
                TabView(selection: $selectedPhotoIndex) {
                    ForEach(Array(item.photos.enumerated()), id: \.offset) { index, photo in
                        ItemImageView(photoNameOrUrl: photo, category: item.category)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 340)

                if item.photos.count > 1 {
                    HStack(spacing: 6) {
                        ForEach(0..<item.photos.count, id: \.self) { i in
                            Circle()
                                .fill(selectedPhotoIndex == i ? LuxuryTheme.accentAmber : Color.white.opacity(0.35))
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
                Text(item.brand.uppercased())
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .tracking(1.4)
                    .foregroundStyle(item.category.accentColor)

                Spacer()

                HStack(spacing: 6) {
                    Image(systemName: item.category.iconName)
                        .font(.system(size: 10))
                    Text(item.category.rawValue)
                        .font(.system(size: 11, weight: .semibold))
                }
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
                    .foregroundStyle(LuxuryTheme.accentAmber)

                Text("(target budget)")
                    .font(.system(size: 12))
                    .foregroundStyle(LuxuryTheme.textTertiary)

                Spacer()

                Text(item.priority.badgeLabel)
                    .font(.system(size: 12, weight: .bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(LuxuryTheme.secondaryBackground)
                    .foregroundStyle(LuxuryTheme.accentAmber)
                    .clipShape(Capsule())
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .luxuryCardStyle(cornerRadius: 16)
    }

    // MARK: - Acquisition Metrics Card
    private var acquisitionMetricsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .foregroundStyle(LuxuryTheme.accentAmber)
                Text("ACQUISITION METRICS")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .tracking(1.2)
                    .foregroundStyle(LuxuryTheme.textTertiary)
            }

            VStack(spacing: 10) {
                metricRow(title: "Category", value: item.category.rawValue)
                metricRow(title: "Target Price", value: item.formattedPrice)
                metricRow(title: "Priority Level", value: item.priority.rawValue)
                metricRow(title: "Added to Wishlist", value: item.dateAdded.formatted(date: .abbreviated, time: .omitted))
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .luxuryCardStyle(cornerRadius: 16)
    }

    private func metricRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13))
                .foregroundStyle(LuxuryTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(LuxuryTheme.textPrimary)
        }
    }

    // MARK: - Store Link Card
    private var storeLinkCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "cart.fill")
                    .foregroundStyle(LuxuryTheme.accentAmber)
                Text("STORE & PURCHASE LINK")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .tracking(1.2)
                    .foregroundStyle(LuxuryTheme.textTertiary)
            }

            if let url = URL(string: item.storeUrl) {
                Link(destination: url) {
                    HStack(spacing: 12) {
                        Image(systemName: "globe")
                            .font(.system(size: 18))
                            .foregroundStyle(LuxuryTheme.accentAmber)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(url.host() ?? "Visit Store Page")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(LuxuryTheme.textPrimary)
                            Text(item.storeUrl)
                                .font(.system(size: 11))
                                .foregroundStyle(LuxuryTheme.textTertiary)
                                .lineLimit(1)
                        }

                        Spacer()

                        Image(systemName: "arrow.up.right.square.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(LuxuryTheme.accentAmber)
                    }
                    .padding(14)
                    .background(LuxuryTheme.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .luxuryCardStyle(cornerRadius: 16)
    }

    // MARK: - Notes Card
    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "note.text")
                    .foregroundStyle(LuxuryTheme.accentAmber)
                Text("NOTES & PRODUCT DETAILS")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .tracking(1.2)
                    .foregroundStyle(LuxuryTheme.textTertiary)
            }

            Text(item.notes)
                .font(.system(size: 13))
                .foregroundStyle(LuxuryTheme.textSecondary)
                .lineSpacing(4)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .luxuryCardStyle(cornerRadius: 16)
    }

    // MARK: - Action Buttons
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            // Acquired -> Move to Vault
            Button(action: {
                dismiss()
                onMoveToVault(item)
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 16))
                    Text("Acquired! Move to Vault Portfolio ✨")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundStyle(Color.black)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(LuxuryTheme.accentAmber)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: LuxuryTheme.accentAmber.opacity(0.35), radius: 10, y: 4)
            }

            HStack(spacing: 12) {
                // Edit Button
                Button(action: {
                    dismiss()
                    onEdit(item)
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "pencil")
                        Text("Edit Piece")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(LuxuryTheme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(LuxuryTheme.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Delete Button
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
