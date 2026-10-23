import SwiftUI
import PhotosUI

public struct WomenAddWishlistItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var womenDataStore: WomenDataStore
    public let existingItem: WomenWishlistItem?

    @State private var title: String = ""
    @State private var brand: String = ""
    @State private var category: WomenCategory = .fineJewelry
    @State private var subcategory: String = ""
    @State private var priceText: String = ""
    @State private var storeUrl: String = ""
    @State private var priority: String = "HIGH"
    @State private var notes: String = ""
    @State private var photos: [String] = []
    @State private var selectedPhotosPickerItems: [PhotosPickerItem] = []
    @State private var showScannerSheet: Bool = false
    @State private var showWebImportSheet: Bool = false

    public init(womenDataStore: WomenDataStore, existingItem: WomenWishlistItem? = nil) {
        self.womenDataStore = womenDataStore
        self.existingItem = existingItem
        if let item = existingItem {
            _title = State(initialValue: item.title)
            _brand = State(initialValue: item.brand)
            _category = State(initialValue: item.category)
            _subcategory = State(initialValue: item.subcategory)
            _priceText = State(initialValue: item.targetPrice > 0 ? "\(Int(item.targetPrice))" : "")
            _storeUrl = State(initialValue: item.storeUrl)
            _priority = State(initialValue: item.priority)
            _notes = State(initialValue: item.notes)
            _photos = State(initialValue: item.photos)
        }
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    categorySelector

                    photosSection

                    coreDetailsSection

                    priceAndStoreSection

                    prioritySection

                    notesSection

                    Button(action: saveWishlist) {
                        Text(existingItem != nil ? "Save Changes ✨" : "Add to Wishlist ✨")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Color.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(title.isEmpty ? WomenLuxuryTheme.roseGold.opacity(0.4) : WomenLuxuryTheme.roseGold)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(title.isEmpty)
                    .padding(.top, 10)
                    .padding(.bottom, 30)
                }
                .padding(.horizontal)
                .padding(.vertical, 16)
            }
            .background(WomenLuxuryTheme.background.ignoresSafeArea())
            .navigationTitle(existingItem != nil ? "Edit Wishlist Goal" : "New Wishlist Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(WomenLuxuryTheme.textSecondary)
                }
            }
            .sheet(isPresented: $showScannerSheet) {
                QRCodeScannerView(
                    title: "Scan Wishlist Barcode / QR",
                    subtitle: "Scan dress tag barcode or shopping QR code to add goal"
                ) { code in
                    handleScannedCode(code)
                }
            }
            .sheet(isPresented: $showWebImportSheet) {
                WebImportSheet { imported in
                    applyImportedData(imported)
                }
            }
        }
    }

    private var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(WomenCategory.allCases) { cat in
                    Button(action: {
                        withAnimation {
                            category = cat
                            subcategory = cat.defaultSubcategories.first ?? ""
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: cat.iconName)
                                .font(.system(size: 11, weight: .bold))
                            Text(cat.rawValue)
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundStyle(category == cat ? Color.black : WomenLuxuryTheme.textSecondary)
                        .padding(.horizontal, 14)
                        .frame(height: 40)
                        .background(category == cat ? cat.accentColor : WomenLuxuryTheme.cardBackground)
                        .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private var photosSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Product Photos (\(photos.count))")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(WomenLuxuryTheme.textPrimary)

            if !photos.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(photos.enumerated()), id: \.offset) { index, photo in
                            ZStack(alignment: .topTrailing) {
                                WomenItemImageView(photoNameOrUrl: photo, category: category)
                                    .frame(width: 90, height: 110)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))

                                Button(action: { photos.remove(at: index) }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(Color.white, Color.black.opacity(0.7))
                                        .padding(4)
                                }
                            }
                        }
                    }
                }
            }

            HStack(spacing: 8) {
                PhotosPicker(
                    selection: $selectedPhotosPickerItems,
                    maxSelectionCount: 6,
                    matching: .images
                ) {
                    HStack(spacing: 4) {
                        Image(systemName: "photo.on.rectangle")
                        Text("Gallery")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(WomenLuxuryTheme.roseGold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(WomenLuxuryTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(WomenLuxuryTheme.cardBorder, lineWidth: 1))
                }
                .onChange(of: selectedPhotosPickerItems) {
                    Task {
                        for item in selectedPhotosPickerItems {
                            if let data = try? await item.loadTransferable(type: Data.self),
                               let filename = ImageManager.shared.saveImageData(data) {
                                await MainActor.run {
                                    photos.append(filename)
                                }
                            }
                        }
                        await MainActor.run {
                            selectedPhotosPickerItems.removeAll()
                        }
                    }
                }

                Button(action: { showScannerSheet = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "barcode.viewfinder")
                        Text("Scan QR")
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(WomenLuxuryTheme.champagne)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(WomenLuxuryTheme.champagne.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(WomenLuxuryTheme.champagne.opacity(0.4), lineWidth: 1))
                }

                Button(action: { showWebImportSheet = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "globe")
                        Text("Import")
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(WomenLuxuryTheme.roseGold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(WomenLuxuryTheme.roseGold.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(WomenLuxuryTheme.roseGold.opacity(0.4), lineWidth: 1))
                }
            }
        }
    }

    private var coreDetailsSection: some View {
        VStack(spacing: 12) {
            field(label: "PIECE TITLE", placeholder: "e.g. Sabyasachi Velvet Lehenga", text: $title)
            field(label: "BRAND / DESIGNER", placeholder: "e.g. Sabyasachi, Tanishq, Cartier", text: $brand)
        }
    }

    private var priceAndStoreSection: some View {
        VStack(spacing: 12) {
            field(label: "TARGET BUDGET (₹)", placeholder: "e.g. 150000", text: $priceText, keyboardType: .numberPad)
            field(label: "STORE / WEB LINK", placeholder: "https://...", text: $storeUrl, keyboardType: .URL)
        }
    }

    private var prioritySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PRIORITY GOAL")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(WomenLuxuryTheme.textTertiary)

            HStack(spacing: 10) {
                ForEach(["HIGH", "MEDIUM", "LOW"], id: \.self) { p in
                    Button(action: { priority = p }) {
                        Text(p == "HIGH" ? "🔥 High" : (p == "MEDIUM" ? "⭐ Target" : "💭 Aspirational"))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(priority == p ? Color.black : WomenLuxuryTheme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .background(priority == p ? WomenLuxuryTheme.roseGold : WomenLuxuryTheme.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("NOTES & FABRIC SPECS")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(WomenLuxuryTheme.textTertiary)

            TextEditor(text: $notes)
                .frame(height: 80)
                .font(.system(size: 13))
                .padding(8)
                .background(WomenLuxuryTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(WomenLuxuryTheme.cardBorder, lineWidth: 1))
        }
    }

    private func field(label: String, placeholder: String, text: Binding<String>, keyboardType: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(WomenLuxuryTheme.textTertiary)

            TextField(placeholder, text: text)
                .keyboardType(keyboardType)
                .font(.system(size: 14))
                .foregroundStyle(WomenLuxuryTheme.textPrimary)
                .padding(12)
                .background(WomenLuxuryTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(WomenLuxuryTheme.cardBorder, lineWidth: 1))
        }
    }

    private func saveWishlist() {
        let p = Double(priceText.filter("0123456789.".contains)) ?? 0.0
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanBrand = brand.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanUrl = storeUrl.trimmingCharacters(in: .whitespacesAndNewlines)

        if let existing = existingItem {
            var updated = existing
            updated.title = cleanTitle
            updated.brand = cleanBrand
            updated.category = category
            updated.subcategory = subcategory
            updated.targetPrice = p
            updated.photos = photos
            updated.storeUrl = cleanUrl
            updated.priority = priority
            updated.notes = notes
            womenDataStore.updateWishlistItem(updated)
        } else {
            let item = WomenWishlistItem(
                title: cleanTitle,
                category: category,
                subcategory: subcategory,
                brand: cleanBrand,
                targetPrice: p,
                photos: photos,
                priority: priority,
                storeUrl: cleanUrl,
                notes: notes
            )
            womenDataStore.addWishlistItem(item, ignoreDuplicates: true)
        }
        dismiss()
    }

    private func handleScannedCode(_ code: String) {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            storeUrl = trimmed
            Task {
                if let imported = try? await WebProductImporter.shared.importFromUrl(trimmed) {
                    await MainActor.run {
                        applyImportedData(imported)
                    }
                }
            }
        } else {
            if notes.isEmpty {
                notes = "Barcode / SKU: \(trimmed)"
            } else if !notes.contains(trimmed) {
                notes += "\nBarcode: \(trimmed)"
            }

            // AUTOMATIC SEARCH: Search online product databases for barcode
            Task {
                if let product = await WebProductImporter.shared.searchProductByBarcode(trimmed) {
                    await MainActor.run {
                        applyImportedData(product)
                    }
                } else {
                    await MainActor.run {
                        if title.isEmpty {
                            title = "Scanned Goal \(trimmed)"
                        }
                    }
                }
            }
        }
    }

    private func applyImportedData(_ imported: ImportedProductData) {
        if !imported.name.isEmpty { title = imported.name }
        if !imported.brand.isEmpty { brand = imported.brand }
        if imported.price > 0 { priceText = "\(Int(imported.price))" }
        for photo in imported.photoFilenames {
            if !photos.contains(photo) {
                photos.append(photo)
            }
        }
        if !imported.sourceUrl.isEmpty { storeUrl = imported.sourceUrl }
        if !imported.notes.isEmpty {
            notes = notes.isEmpty ? imported.notes : (notes + "\n" + imported.notes)
        }
    }
}
