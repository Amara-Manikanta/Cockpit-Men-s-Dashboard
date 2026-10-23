import SwiftUI

public struct WomenStylistView: View {
    @ObservedObject var womenDataStore: WomenDataStore
    @Binding var activeGenderProfile: String

    @State private var selectedAnchorItem: WomenWardrobeItem? = nil
    @State private var selectedLook: WomenCuratedLook? = nil
    @State private var isGenerating: Bool = false

    public init(womenDataStore: WomenDataStore, activeGenderProfile: Binding<String>) {
        self.womenDataStore = womenDataStore
        self._activeGenderProfile = activeGenderProfile
    }

    private var clothingPieces: [WomenWardrobeItem] {
        womenDataStore.items.filter { $0.category.isClothing }
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Switcher Header
                    profileSwitcherHeader
                        .padding(.horizontal)
                        .padding(.top, 4)

                    // Hero Banner
                    stylistBanner
                        .padding(.horizontal)

                    // Section 1: Choose Outfit Anchor
                    outfitAnchorSection
                        .padding(.horizontal)

                    // Section 2: AI Coordinated Ensemble
                    if let anchor = selectedAnchorItem {
                        coordinatedLookSection(for: anchor)
                            .padding(.horizontal)
                    }

                    // Section 3: Saved Curated Looks
                    savedLooksSection
                        .padding(.horizontal)

                    Spacer(minLength: 80)
                }
            }
            .background(WomenLuxuryTheme.background.ignoresSafeArea())
            .navigationTitle("Stylist Studio")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if selectedAnchorItem == nil {
                    selectedAnchorItem = clothingPieces.first
                }
            }
        }
    }

    private var profileSwitcherHeader: some View {
        HStack {
            HStack(spacing: 6) {
                Text("👗")
                Text("WOMEN'S STYLIST")
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

    private var stylistBanner: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 20))
                    .foregroundStyle(WomenLuxuryTheme.roseGold)
                Text("AI ATELIER STYLIST STUDIO")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .tracking(1.2)
                    .foregroundStyle(WomenLuxuryTheme.champagne)
            }

            Text("Select any saree, lehenga, or gown to automatically pair matching jewelry, clutches, and timepieces from your own collection.")
                .font(.system(size: 13))
                .foregroundStyle(WomenLuxuryTheme.textSecondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .womenLuxuryCardStyle(cornerRadius: 18)
    }

    private var outfitAnchorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("1. CHOOSE ANCHOR OUTFIT")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .tracking(1.2)
                    .foregroundStyle(WomenLuxuryTheme.textTertiary)

                Spacer()

                Text("\(clothingPieces.count) available")
                    .font(.system(size: 11))
                    .foregroundStyle(WomenLuxuryTheme.textTertiary)
            }

            if clothingPieces.isEmpty {
                Text("Add your sarees and dresses to enable AI styling.")
                    .font(.system(size: 13))
                    .foregroundStyle(WomenLuxuryTheme.textSecondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(clothingPieces) { piece in
                            let isSelected = selectedAnchorItem?.id == piece.id
                            VStack(alignment: .leading, spacing: 6) {
                                WomenItemImageView(photoNameOrUrl: piece.primaryPhoto, category: piece.category)
                                    .frame(width: 110, height: 140)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(isSelected ? WomenLuxuryTheme.roseGold : Color.clear, lineWidth: 3)
                                    )

                                Text(piece.brand)
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(piece.category.accentColor)

                                Text(piece.title)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(WomenLuxuryTheme.textPrimary)
                                    .lineLimit(1)
                                    .frame(width: 110, alignment: .leading)
                            }
                            .onTapGesture {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                withAnimation { selectedAnchorItem = piece }
                            }
                        }
                    }
                }
            }
        }
    }

    private func coordinatedLookSection(for anchor: WomenWardrobeItem) -> some View {
        let matchingJewelry = womenDataStore.items.filter { $0.category == .fineJewelry }
        let matchingBags = womenDataStore.items.filter { $0.category == .handbagsClutches }
        let matchingWatches = womenDataStore.items.filter { $0.category == .watches }

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("2. AI COORDINATED ENSEMBLE")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .tracking(1.2)
                    .foregroundStyle(WomenLuxuryTheme.textTertiary)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                    Text("98% HARMONY")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                }
                .foregroundStyle(Color.black)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(WomenLuxuryTheme.champagne)
                .clipShape(Capsule())
            }

            // Grid of paired items
            HStack(spacing: 12) {
                if let j = matchingJewelry.first {
                    pairedMiniCard(item: j, role: "Fine Jewelry")
                }
                if let b = matchingBags.first {
                    pairedMiniCard(item: b, role: "Clutch / Bag")
                }
                if let w = matchingWatches.first {
                    pairedMiniCard(item: w, role: "Timepiece")
                }
            }

            // Stylist narrative advice
            VStack(alignment: .leading, spacing: 4) {
                Text("STYLIST RECOMMENDATION")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(WomenLuxuryTheme.roseGold)
                Text("Pair the \(anchor.title) with warm antique gold jewelry. The weave and tones highlight the natural silhouette perfectly for \(anchor.occasion).")
                    .font(.system(size: 12))
                    .foregroundStyle(WomenLuxuryTheme.textSecondary)
                    .lineSpacing(3)
            }
            .padding(12)
            .background(WomenLuxuryTheme.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(18)
        .womenLuxuryCardStyle(cornerRadius: 18)
    }

    private func pairedMiniCard(item: WomenWardrobeItem, role: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            WomenItemImageView(photoNameOrUrl: item.primaryPhoto, category: item.category)
                .frame(height: 100)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            Text(role.uppercased())
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundStyle(WomenLuxuryTheme.roseGold)

            Text(item.title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(WomenLuxuryTheme.textPrimary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(WomenLuxuryTheme.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var savedLooksSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("SAVED SIGNATURE ENSEMBLES")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .tracking(1.2)
                .foregroundStyle(WomenLuxuryTheme.textTertiary)

            ForEach(womenDataStore.looks) { look in
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(look.name)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(WomenLuxuryTheme.textPrimary)
                            Text(look.occasion)
                                .font(.system(size: 11))
                                .foregroundStyle(WomenLuxuryTheme.roseGold)
                        }

                        Spacer()

                        Text("\(look.harmonyScore)% Score")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(WomenLuxuryTheme.champagne)
                    }

                    Text(look.stylistAdvice)
                        .font(.system(size: 12))
                        .foregroundStyle(WomenLuxuryTheme.textSecondary)
                        .lineSpacing(3)
                }
                .padding(14)
                .womenLuxuryCardStyle(cornerRadius: 14)
            }
        }
    }
}
