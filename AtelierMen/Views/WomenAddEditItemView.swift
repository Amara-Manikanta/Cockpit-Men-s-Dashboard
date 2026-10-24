import SwiftUI
import PhotosUI

public struct WomenAddEditItemView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var womenDataStore: WomenDataStore
    public let existingItem: WomenWardrobeItem?

    @State private var title: String = ""
    @State private var brand: String = ""
    @State private var category: WomenCategory = .sareesEthnic
    @State private var subcategory: String = "Kanjeevaram & Silk Sarees"
    @State private var priceText: String = ""
    @State private var photos: [String] = []
    @State private var metal: WomenMetalType = .pureSilk
    @State private var purity: String = ""
    @State private var sizeOrDimensions: String = "Free Size"
    @State private var isSet: Bool = false
    @State private var setIncludes: String = ""
    @State private var storageLocation: String = "Main Boutique Closet"
    @State private var occasion: String = "Festive"
    @State private var notes: String = ""
    @State private var storeUrl: String = ""
    @State private var quantity: Int = 1
    @State private var timesWorn: Int = 0
    @State private var selectedCondition: GarmentCondition? = nil
    @State private var qualityRating: Int = 0
    @State private var durabilityRating: Int = 0
    @State private var reviewNotes: String = ""

    @State private var selectedPhotosPickerItems: [PhotosPickerItem] = []
    @State private var showScannerSheet: Bool = false
    @State private var showWebImportSheet: Bool = false

    // AI Background Removal
    @State private var isRemovingBackground: Bool = false
    @State private var removeModelFace: Bool = true
    @State private var backgroundRemovalError: String? = nil
    @State private var lastCutoutResult: SegmentationResult? = nil

    public init(womenDataStore: WomenDataStore, existingItem: WomenWardrobeItem? = nil) {
        self.womenDataStore = womenDataStore
        self.existingItem = existingItem
        if let item = existingItem {
            _title = State(initialValue: item.title)
            _brand = State(initialValue: item.brand)
            _category = State(initialValue: item.category)
            _subcategory = State(initialValue: item.subcategory)
            _priceText = State(initialValue: item.price > 0 ? "\(Int(item.price))" : "")
            _photos = State(initialValue: item.photos)
            _metal = State(initialValue: item.metal)
            _purity = State(initialValue: item.purity)
            _sizeOrDimensions = State(initialValue: item.sizeOrDimensions)
            _isSet = State(initialValue: item.isSet)
            _setIncludes = State(initialValue: item.setIncludes)
            _storageLocation = State(initialValue: item.storageLocation)
            _occasion = State(initialValue: item.occasion)
            _notes = State(initialValue: item.notes)
            _storeUrl = State(initialValue: item.storeUrl)
            _quantity = State(initialValue: max(1, item.quantity))
            _timesWorn = State(initialValue: item.timesWorn)
            _selectedCondition = State(initialValue: item.garmentCondition)
            _qualityRating = State(initialValue: item.qualityRating)
            _durabilityRating = State(initialValue: item.durabilityRating)
            _reviewNotes = State(initialValue: item.reviewNotes)
        }
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    categorySelector

                    photosSection

                    coreDetailsSection

                    ownershipAndWearSection

                    sizingSection

                    materialSection

                    setSection

                    locationAndOccasionSection

                    notesSection

                    // Review & Ratings (Quality & Durability Stars)
                    reviewRatingSection

                    Button(action: savePiece) {
                        Text(existingItem != nil ? "Save Changes ✨" : "Add to Boutique ✨")
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
            .navigationTitle(existingItem != nil ? "Edit Boutique Piece" : "Add New Piece")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(WomenLuxuryTheme.textSecondary)
                }
            }
            .sheet(isPresented: $showScannerSheet) {
                QRCodeScannerView(
                    title: "Scan Boutique Barcode / QR",
                    subtitle: "Scan product box barcode, tag, or store QR code"
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
        VStack(alignment: .leading, spacing: 10) {
            Text("CATEGORY")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(WomenLuxuryTheme.textTertiary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(WomenCategory.allCases) { cat in
                        Button(action: {
                            withAnimation {
                                category = cat
                                subcategory = cat.defaultSubcategories.first ?? ""
                                if cat.isClothing {
                                    sizeOrDimensions = (cat == .sareesEthnic) ? "6.3m Saree with blouse" : "Size M"
                                    metal = .pureSilk
                                } else if cat == .fineJewelry {
                                    metal = .gold22K
                                    sizeOrDimensions = "16\" Choker"
                                } else if cat == .handbagsClutches {
                                    metal = .fineLeather
                                    sizeOrDimensions = "Medium Tote"
                                } else if cat == .watches {
                                    metal = .gold18KRose
                                    sizeOrDimensions = "28mm Dial"
                                }
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
    }

    private var photosSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PHOTOS (\(photos.count))")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(WomenLuxuryTheme.textTertiary)

            if !photos.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(photos.enumerated()), id: \.offset) { index, photo in
                            ZStack(alignment: .topTrailing) {
                                WomenItemImageView(photoNameOrUrl: photo, category: category)
                                    .frame(width: 90, height: 110)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))

                                if index == 0 {
                                    Text("COVER")
                                        .font(.system(size: 8, weight: .black))
                                        .foregroundStyle(Color.black)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 2)
                                        .background(WomenLuxuryTheme.roseGold)
                                        .clipShape(Capsule())
                                        .padding(4)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                }

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

            // On-Device AI Background Removal Card
            if !photos.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Divider()
                        .background(WomenLuxuryTheme.cardBorder)
                        .padding(.vertical, 4)

                    HStack {
                        Image(systemName: "wand.and.stars")
                            .foregroundStyle(WomenLuxuryTheme.roseGold)
                        Text("On-Device AI Cutout")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(WomenLuxuryTheme.textPrimary)
                        Spacer()
                        Text("Vision Neural Engine")
                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                            .foregroundStyle(WomenLuxuryTheme.roseGold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(WomenLuxuryTheme.roseGold.opacity(0.15))
                            .clipShape(Capsule())
                    }

                    Toggle(isOn: $removeModelFace) {
                        HStack(spacing: 6) {
                            Image(systemName: "person.crop.circle.badge.minus")
                                .foregroundStyle(WomenLuxuryTheme.roseGold)
                            Text("Remove Model Head & Face")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(WomenLuxuryTheme.textPrimary)
                        }
                    }
                    .tint(WomenLuxuryTheme.roseGold)
                    .padding(.vertical, 2)

                    if isRemovingBackground {
                        HStack(spacing: 12) {
                            ProgressView()
                                .tint(WomenLuxuryTheme.roseGold)
                            Text("Isolating dress & analyzing color...")
                                .font(.system(size: 12))
                                .foregroundStyle(WomenLuxuryTheme.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 6)
                    } else {
                        Button(action: {
                            runBackgroundRemoval()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "person.crop.artframe")
                                Text(photos.first?.hasPrefix("cutout_") == true ? "Re-Run Background Removal" : "Remove Background (Transparent Cutout)")
                            }
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .background(
                                LinearGradient(
                                    colors: [WomenLuxuryTheme.roseGold, WomenLuxuryTheme.champagne],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }

                    if let err = backgroundRemovalError {
                        Text(err)
                            .font(.system(size: 11))
                            .foregroundStyle(Color.red.opacity(0.85))
                    }

                    if let result = lastCutoutResult {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(white: 0.15))
                                    .frame(width: 50, height: 60)
                                Image(uiImage: result.cutoutImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 44, height: 54)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Color.green)
                                    Text("Cutout Generated & Saved")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(WomenLuxuryTheme.textPrimary)
                                }

                                HStack(spacing: 8) {
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(Color(hex: result.dominantColorHex) ?? .gray)
                                            .frame(width: 12, height: 12)
                                        Text(result.dominantColorHex)
                                            .font(.system(size: 10, design: .monospaced))
                                            .foregroundStyle(WomenLuxuryTheme.textSecondary)
                                    }

                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(Color(hex: result.accentColorHex) ?? .gray)
                                            .frame(width: 12, height: 12)
                                        Text(result.colorName)
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundStyle(WomenLuxuryTheme.roseGold)
                                    }
                                }
                            }
                        }
                        .padding(8)
                        .background(Color(white: 0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(.top, 4)
            }
        }
    }

    private var coreDetailsSection: some View {
        VStack(spacing: 12) {
            field(label: "PIECE TITLE", placeholder: "e.g. Pure Kanjeevaram Silk Saree", text: $title)
            field(label: "BRAND / DESIGNER", placeholder: "e.g. Sabyasachi, Tanishq, Nalli, Cartier", text: $brand)
            field(label: "VALUATION / PRICE (₹)", placeholder: "e.g. 68000", text: $priceText, keyboardType: .numberPad)
        }
    }

    private var sizingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SIZING & DIMENSIONS")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(WomenLuxuryTheme.textTertiary)

            let pills: [String] = {
                if category == .sareesEthnic {
                    return ["6.3m Saree with blouse", "Custom Bridal Lehenga", "Size 36 (S)", "Size 38 (M)", "Free Size"]
                } else if category.isClothing {
                    return ["XS (34)", "S (36)", "M (38)", "L (40)", "XL (42)", "Free Size"]
                } else if category == .fineJewelry {
                    return ["16\" Choker", "18\" Princess", "2.4 Bangle", "2.6 Bangle", "Size 12 Ring", "Drop Earrings"]
                } else {
                    return ["Small Model", "Medium (26cm)", "Large Tote", "One Size"]
                }
            }()

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(pills, id: \.self) { pill in
                        Button(action: { sizeOrDimensions = pill }) {
                            Text(pill)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(sizeOrDimensions == pill ? Color.black : WomenLuxuryTheme.textSecondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(sizeOrDimensions == pill ? WomenLuxuryTheme.roseGold : WomenLuxuryTheme.cardBackground)
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            TextField("Custom dimensions...", text: $sizeOrDimensions)
                .font(.system(size: 13))
                .foregroundStyle(WomenLuxuryTheme.textPrimary)
                .padding(10)
                .background(WomenLuxuryTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(WomenLuxuryTheme.cardBorder, lineWidth: 1))
        }
    }

    private var materialSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("FABRIC / METAL & PURITY")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(WomenLuxuryTheme.textTertiary)

            Picker("Material", selection: $metal) {
                ForEach(WomenMetalType.allCases) { m in
                    Text(m.rawValue).tag(m)
                }
            }
            .pickerStyle(.menu)
            .tint(WomenLuxuryTheme.roseGold)
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(WomenLuxuryTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            field(label: "PURITY / WEAVE DETAILS", placeholder: "e.g. 22K BIS Hallmarked, Pure Mulberry Silk", text: $purity)
        }
    }

    private var setSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: $isSet) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Matching Set or Combo")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(WomenLuxuryTheme.textPrimary)
                    Text("e.g. Choker + Jhumkas, Lehenga + Dupattas, Kurta + Palazzo")
                        .font(.system(size: 11))
                        .foregroundStyle(WomenLuxuryTheme.textTertiary)
                }
            }
            .tint(WomenLuxuryTheme.roseGold)

            if isSet {
                field(label: "SET INCLUDES", placeholder: "e.g. Choker + Jhumkas Set", text: $setIncludes)
            }
        }
        .padding(14)
        .background(WomenLuxuryTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var locationAndOccasionSection: some View {
        VStack(spacing: 12) {
            field(label: "STORAGE LOCATION / VANITY BOX", placeholder: "e.g. Velvet Vanity Box - Slot 1, Master Wardrobe", text: $storageLocation)
            field(label: "OCCASION", placeholder: "e.g. Weddings, Grand Receptions, Everyday Chic", text: $occasion)
            field(label: "STORE WEB LINK (OPTIONAL)", placeholder: "https://...", text: $storeUrl, keyboardType: .URL)
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("STYLING NOTES & STORY")
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

    private func savePiece() {
        let p = Double(priceText.filter("0123456789.".contains)) ?? 0.0
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanBrand = brand.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanLocation = storageLocation.trimmingCharacters(in: .whitespacesAndNewlines)

        if let existing = existingItem {
            var updated = existing
            updated.title = cleanTitle
            updated.brand = cleanBrand
            updated.category = category
            updated.subcategory = subcategory
            updated.price = p
            updated.photos = photos
            updated.metal = metal
            updated.purity = purity
            updated.sizeOrDimensions = sizeOrDimensions
            updated.isSet = isSet
            updated.setIncludes = setIncludes
            updated.storageLocation = cleanLocation.isEmpty ? "Main Boutique Closet" : cleanLocation
            updated.occasion = occasion
            updated.notes = notes
            updated.storeUrl = storeUrl
            updated.quantity = max(1, quantity)
            updated.timesWorn = timesWorn
            updated.garmentCondition = selectedCondition
            updated.qualityRating = qualityRating
            updated.durabilityRating = durabilityRating
            updated.reviewNotes = reviewNotes
            womenDataStore.updateItem(updated)
        } else {
            var item = WomenWardrobeItem(
                title: cleanTitle,
                category: category,
                subcategory: subcategory,
                brand: cleanBrand,
                price: p,
                originalPrice: p,
                photos: photos,
                metal: metal,
                purity: purity,
                sizeOrDimensions: sizeOrDimensions,
                isSet: isSet,
                setIncludes: setIncludes,
                storageLocation: cleanLocation.isEmpty ? "Main Boutique Closet" : cleanLocation,
                occasion: occasion,
                notes: notes,
                storeUrl: storeUrl
            )
            item.quantity = max(1, quantity)
            item.timesWorn = timesWorn
            item.garmentCondition = selectedCondition
            item.qualityRating = qualityRating
            item.durabilityRating = durabilityRating
            item.reviewNotes = reviewNotes
            womenDataStore.addItem(item, ignoreDuplicates: true)
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
                            title = "Scanned Piece \(trimmed)"
                        }
                    }
                }
            }
        }
    }

    private var ownershipAndWearSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Ownership & Wear History")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(WomenLuxuryTheme.textPrimary)

            HStack(spacing: 12) {
                // Number of Pairs / Identical Items Owned
                VStack(alignment: .leading, spacing: 6) {
                    Text("PAIRS / QTY OWNED")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(WomenLuxuryTheme.textTertiary)

                    HStack {
                        Button {
                            if quantity > 1 { quantity -= 1 }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(WomenLuxuryTheme.textSecondary)
                        }

                        Spacer()

                        Text("\(quantity) \(category == .fineJewelry ? "Pairs/Sets" : "Items")")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(WomenLuxuryTheme.textPrimary)
                            .lineLimit(1)

                        Spacer()

                        Button {
                            quantity += 1
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(WomenLuxuryTheme.roseGold)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(WomenLuxuryTheme.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .frame(maxWidth: .infinity)

                // Times Worn
                VStack(alignment: .leading, spacing: 6) {
                    Text("TIMES WORN")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(WomenLuxuryTheme.textTertiary)

                    HStack {
                        Button {
                            if timesWorn > 0 { timesWorn -= 1 }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(WomenLuxuryTheme.textSecondary)
                        }

                        Spacer()

                        Text("\(timesWorn)x")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(WomenLuxuryTheme.textPrimary)

                        Spacer()

                        Button {
                            timesWorn += 1
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(WomenLuxuryTheme.roseGold)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(WomenLuxuryTheme.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .frame(maxWidth: .infinity)
            }

            // Garment Condition Dropdown
            VStack(alignment: .leading, spacing: 6) {
                Text("GARMENT CONDITION")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(WomenLuxuryTheme.textTertiary)

                Menu {
                    Button {
                        selectedCondition = nil
                    } label: {
                        HStack {
                            Text("Auto (Based on \(timesWorn) wears)")
                            if selectedCondition == nil {
                                Image(systemName: "checkmark")
                            }
                        }
                    }

                    Divider()

                    ForEach(GarmentCondition.allCases) { cond in
                        Button {
                            selectedCondition = cond
                        } label: {
                            HStack {
                                Label(cond.displayName, systemImage: cond.iconName)
                                if selectedCondition == cond {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        let current = selectedCondition ?? GarmentCondition.calculateFromWearCount(timesWorn)
                        Image(systemName: current.iconName)
                            .foregroundStyle(current.color)
                        Text(current.displayName)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(WomenLuxuryTheme.textPrimary)

                        Text(selectedCondition != nil ? "(Manual)" : "(Auto: \(timesWorn) wears)")
                            .font(.system(size: 11))
                            .foregroundStyle(WomenLuxuryTheme.textTertiary)

                        Spacer()

                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 12))
                            .foregroundStyle(WomenLuxuryTheme.textTertiary)
                    }
                    .padding(12)
                    .background(WomenLuxuryTheme.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(16)
        .womenLuxuryCardStyle(cornerRadius: 16)
    }

    // MARK: - Review & Verdict Section
    private var reviewRatingSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "star.bubble.fill")
                    .foregroundStyle(WomenLuxuryTheme.roseGold)
                Text("Quality, Durability & Review")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(WomenLuxuryTheme.textPrimary)
            }

            // Quality Star Rating
            StarRatingView(
                rating: $qualityRating,
                title: "Material & Craft Quality",
                subtitle: "Fabric, weave & finish",
                starColor: WomenLuxuryTheme.roseGold
            )

            Divider()
                .background(WomenLuxuryTheme.cardBorder)

            // Durability Star Rating
            StarRatingView(
                rating: $durabilityRating,
                title: "Wear & Longevity Durability",
                subtitle: "Wash resilience & color retention",
                starColor: Color(red: 0.85, green: 0.55, blue: 0.95)
            )

            Divider()
                .background(WomenLuxuryTheme.cardBorder)

            VStack(alignment: .leading, spacing: 6) {
                Text("WEAR & LONGEVITY COMMENTS")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(WomenLuxuryTheme.textTertiary)

                TextField("Add comments on drape, fit, color resilience...", text: $reviewNotes, axis: .vertical)
                    .font(.system(size: 13))
                    .foregroundStyle(WomenLuxuryTheme.textPrimary)
                    .padding(12)
                    .background(WomenLuxuryTheme.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .lineLimit(2...4)
            }
        }
        .padding(16)
        .womenLuxuryCardStyle(cornerRadius: 16)
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

    private func runBackgroundRemoval() {
        guard let sourcePhoto = photos.first(where: { !$0.hasPrefix("cutout_") }) ?? photos.first, !sourcePhoto.isEmpty else {
            backgroundRemovalError = "Please select or add a photo first."
            return
        }

        isRemovingBackground = true
        backgroundRemovalError = nil

        let removeFaceOption = self.removeModelFace

        Task {
            var imageToProcess: UIImage? = ImageManager.shared.loadUIImage(for: sourcePhoto)

            if imageToProcess == nil, let url = URL(string: sourcePhoto), sourcePhoto.hasPrefix("http") {
                if let (data, _) = try? await URLSession.shared.data(from: url) {
                    imageToProcess = UIImage(data: data)
                }
            }

            guard let targetImage = imageToProcess else {
                await MainActor.run {
                    self.backgroundRemovalError = "Could not load image data for processing."
                    self.isRemovingBackground = false
                }
                return
            }

            do {
                let result = try await BackgroundRemovalService.shared.removeBackground(from: targetImage, removeFace: removeFaceOption)
                await MainActor.run {
                    self.lastCutoutResult = result
                    self.photos.removeAll(where: { $0.hasPrefix("cutout_") })
                    self.photos.insert(result.cutoutFilename, at: 0)
                    self.isRemovingBackground = false
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            } catch {
                await MainActor.run {
                    self.backgroundRemovalError = "On-Device AI error: \(error.localizedDescription)"
                    self.isRemovingBackground = false
                }
            }
        }
    }
}
