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

    @State private var selectedPhotosPickerItems: [PhotosPickerItem] = []
    @State private var showScannerSheet: Bool = false
    @State private var showWebImportSheet: Bool = false

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
