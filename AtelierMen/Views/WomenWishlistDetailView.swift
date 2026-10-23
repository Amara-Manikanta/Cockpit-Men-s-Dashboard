import SwiftUI

public struct WomenWishlistDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var womenDataStore: WomenDataStore
    public let item: WomenWishlistItem
    public let onEdit: (WomenWishlistItem) -> Void
    public let onMoveToBoutique: (WomenWishlistItem) -> Void

    @State private var selectedPhotoIndex = 0
    @State private var showDeleteConfirmation = false

    public init(
        womenDataStore: WomenDataStore,
        item: WomenWishlistItem,
        onEdit: @escaping (WomenWishlistItem) -> Void,
        onMoveToBoutique: @escaping (WomenWishlistItem) -> Void
    ) {
        self.womenDataStore = womenDataStore
        self.item = item
        self.onEdit = onEdit
        self.onMoveToBoutique = onMoveToBoutique
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Photo Carousel
                    photoCarouselSection

                    // Primary Info Card
                    primaryInfoCard
                        .padding(.horizontal)

                    // Acquisition Metrics Card
                    acquisitionMetricsCard
                        .padding(.horizontal)

                    // Store Link Card
                    if !item.storeUrl.isEmpty {
                        storeLinkCard
                            .padding(.horizontal)
                    }

                    // Notes Card
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
                        ShareLink(item: "\(item.brand) - \(item.title)\nTarget Budget: \(item.formattedPrice)" + (item.storeUrl.isEmpty ? "" : "\n\(item.storeUrl)")) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16))
                                .foregroundStyle(WomenLuxuryTheme.textSecondary)
                        }

                        Button(action: {
                            dismiss()
                            onEdit(item)
                        }) {
                            Text("Edit")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(WomenLuxuryTheme.roseGold)
                        }
                    }
                }
            }
            .alert("Delete Wishlist Item?", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    womenDataStore.deleteWishlistItem(item)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to remove \"\(item.title)\" from your wishlist?")
            }
        }
    }

    private var photoCarouselSection: some View {
        ZStack(alignment: .bottom) {
            if item.photos.isEmpty {
                WomenItemImageView(photoNameOrUrl: "", category: item.category)
                    .frame(height: 340)
                    .frame(maxWidth: .infinity)
            } else {
                TabView(selection: $selectedPhotoIndex) {
                    ForEach(Array(item.photos.enumerated()), id: \.offset) { index, photo in
                        WomenItemImageView(photoNameOrUrl: photo, category: item.category)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 340)

                if item.photos.count > 1 {
                    HStack(spacing: 6) {
                        ForEach(0..<item.photos.count, id: \.self) { i in
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

            Text(item.title)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(WomenLuxuryTheme.textPrimary)

            HStack(alignment: .firstTextBaseline) {
                Text(item.formattedPrice)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(WomenLuxuryTheme.champagne)

                Text("(target budget)")
                    .font(.system(size: 12))
                    .foregroundStyle(WomenLuxuryTheme.textTertiary)

                Spacer()

                Text(item.priorityBadge)
                    .font(.system(size: 12, weight: .bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(WomenLuxuryTheme.secondaryBackground)
                    .foregroundStyle(WomenLuxuryTheme.roseGold)
                    .clipShape(Capsule())
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .womenLuxuryCardStyle(cornerRadius: 16)
    }

    private var acquisitionMetricsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(WomenLuxuryTheme.roseGold)
                Text("ACQUISITION METRICS")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .tracking(1.2)
                    .foregroundStyle(WomenLuxuryTheme.textTertiary)
            }

            VStack(spacing: 10) {
                row(title: "Category", value: item.category.rawValue)
                row(title: "Subcategory", value: item.subcategory)
                row(title: "Target Price", value: item.formattedPrice)
                row(title: "Priority Level", value: item.priority)
                row(title: "Added to Wishlist", value: item.dateAdded.formatted(date: .abbreviated, time: .omitted))
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

    private var storeLinkCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "cart.fill")
                    .foregroundStyle(WomenLuxuryTheme.roseGold)
                Text("BOUTIQUE STORE LINK")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .tracking(1.2)
                    .foregroundStyle(WomenLuxuryTheme.textTertiary)
            }

            if let url = URL(string: item.storeUrl) {
                Link(destination: url) {
                    HStack(spacing: 12) {
                        Image(systemName: "globe")
                            .font(.system(size: 18))
                            .foregroundStyle(WomenLuxuryTheme.roseGold)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(url.host() ?? "Visit Brand Store")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(WomenLuxuryTheme.textPrimary)
                            Text(item.storeUrl)
                                .font(.system(size: 11))
                                .foregroundStyle(WomenLuxuryTheme.textTertiary)
                                .lineLimit(1)
                        }

                        Spacer()

                        Image(systemName: "arrow.up.right.square.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(WomenLuxuryTheme.roseGold)
                    }
                    .padding(14)
                    .background(WomenLuxuryTheme.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .womenLuxuryCardStyle(cornerRadius: 16)
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "note.text")
                    .foregroundStyle(WomenLuxuryTheme.roseGold)
                Text("NOTES & FABRIC DETAILS")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .tracking(1.2)
                    .foregroundStyle(WomenLuxuryTheme.textTertiary)
            }

            Text(item.notes)
                .font(.system(size: 13))
                .foregroundStyle(WomenLuxuryTheme.textSecondary)
                .lineSpacing(4)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .womenLuxuryCardStyle(cornerRadius: 16)
    }

    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                dismiss()
                onMoveToBoutique(item)
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 16))
                    Text("Acquired! Move to Boutique Portfolio ✨")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundStyle(Color.black)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(WomenLuxuryTheme.roseGold)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: WomenLuxuryTheme.roseGold.opacity(0.35), radius: 10, y: 4)
            }

            HStack(spacing: 12) {
                Button(action: {
                    dismiss()
                    onEdit(item)
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
