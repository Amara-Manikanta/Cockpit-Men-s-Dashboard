import SwiftUI

public struct ItemCardView: View {
    public let item: WardrobeItem
    public var isSelectable: Bool = false
    public var isSelected: Bool = false
    public let onFavoriteToggle: () -> Void

    public init(
        item: WardrobeItem,
        isSelectable: Bool = false,
        isSelected: Bool = false,
        onFavoriteToggle: @escaping () -> Void
    ) {
        self.item = item
        self.isSelectable = isSelectable
        self.isSelected = isSelected
        self.onFavoriteToggle = onFavoriteToggle
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Bounded Image Container (Strictly constrained to prevent grid leakage)
            ZStack(alignment: .topTrailing) {
                Rectangle()
                    .fill(Color(white: 0.12))
                    .frame(height: 175)
                    .overlay(
                        ItemImageView(
                            photoNameOrUrl: item.primaryPhoto,
                            category: item.category,
                            contentMode: .fill
                        )
                    )
                    .clipped()

                // Gradient shadow for badges
                LinearGradient(
                    colors: [Color.black.opacity(0.6), Color.clear],
                    startPoint: .top,
                    endPoint: .center
                )
                .frame(height: 60)

                // Top row badges
                HStack {
                    if isSelectable {
                        // Multi-select Checkbox Badge
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
                    } else {
                        // Category / Luxury Tag
                        Text(item.subcategory.isEmpty ? item.category.rawValue : item.subcategory)
                            .font(.system(size: 10, weight: .bold))
                            .textCase(.uppercase)
                            .tracking(0.8)
                            .foregroundStyle(Color.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(item.category.accentColor)
                            .clipShape(Capsule())
                    }

                    Spacer()

                    if !isSelectable {
                        // Favorite Button
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            onFavoriteToggle()
                        }) {
                            Image(systemName: item.isFavorite ? "heart.fill" : "heart")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(item.isFavorite ? Color.red : Color.white)
                                .padding(7)
                                .background(Color.black.opacity(0.45))
                                .clipShape(Circle())
                        }
                    } else {
                        // Category tag when selecting
                        Text(item.category.rawValue)
                            .font(.system(size: 9, weight: .bold))
                            .textCase(.uppercase)
                            .foregroundStyle(Color.black)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(item.category.accentColor)
                            .clipShape(Capsule())
                    }
                }
                .padding(10)

                // Quantity badge if more than 1 pair / item owned
                if item.quantity > 1 {
                    VStack {
                        Spacer()
                        HStack {
                            HStack(spacing: 4) {
                                Image(systemName: "square.fill.on.square.fill")
                                    .font(.system(size: 9))
                                Text("\(item.quantity) \(item.category == .shoes ? "PAIRS" : "ITEMS")")
                                    .font(.system(size: 9, weight: .black))
                            }
                            .foregroundStyle(Color.black)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(LuxuryTheme.accentAmber)
                            .clipShape(Capsule())
                            .padding(8)
                            Spacer()
                        }
                    }
                }

                // Multi-photo count badge at bottom right of image
                if item.photos.count > 1 {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            HStack(spacing: 4) {
                                Image(systemName: "photo.stack.fill")
                                    .font(.system(size: 10))
                                Text("\(item.photos.count)")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.black.opacity(0.65))
                            .clipShape(Capsule())
                            .padding(8)
                        }
                    }
                }
            }

            // Card Body Details
            VStack(alignment: .leading, spacing: 6) {
                // Brand
                Text(item.brand.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(item.category.accentColor)
                    .lineLimit(1)

                // Name
                Text(item.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(LuxuryTheme.textPrimary)
                    .lineLimit(2)
                    .frame(height: 38, alignment: .topLeading)

                // Price
                Text(item.formattedPrice)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(LuxuryTheme.gold)

                // Wear count & cost per wear pill
                HStack(spacing: 4) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 9))
                    Text("Worn \(item.timesWorn)x")
                        .font(.system(size: 10, weight: .semibold))
                    Text("•")
                    Text("CPW: \(item.formattedCostPerWear)")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundStyle(LuxuryTheme.textSecondary)
                .padding(.top, 1)

                // Key Spec Pill
                HStack(spacing: 4) {
                    Image(systemName: item.category.iconName)
                        .font(.system(size: 10))
                    Text(item.keySpecSummary)
                        .font(.system(size: 11, weight: .medium))
                        .lineLimit(1)
                }
                .foregroundStyle(LuxuryTheme.textSecondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(LuxuryTheme.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: 6))

                // Storage location
                HStack(spacing: 4) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 10))
                        .foregroundStyle(LuxuryTheme.textTertiary)
                    Text(item.storageLocation)
                        .font(.system(size: 10, weight: .regular))
                        .foregroundStyle(LuxuryTheme.textTertiary)
                        .lineLimit(1)
                }
                .padding(.top, 2)
            }
            .padding(12)
        }
        .luxuryCardStyle(cornerRadius: 14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isSelected ? LuxuryTheme.gold : Color.clear, lineWidth: 2)
        )
        .clipped()
    }
}
