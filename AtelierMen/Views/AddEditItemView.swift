import SwiftUI
import PhotosUI

public struct AddEditItemView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var dataStore: DataStore

    public var existingItem: WardrobeItem?

    @State private var name: String = ""
    @State private var brand: String = ""
    @State private var category: ItemCategory = .electronics
    @State private var subcategory: String = ""
    @State private var priceText: String = ""
    @State private var storageLocation: String = "Main Closet"
    @State private var occasion: String = "Everyday"
    @State private var notes: String = ""

    // Photos
    @State private var photos: [String] = []
    @State private var selectedPhotosPickerItems: [PhotosPickerItem] = []
    @State private var showWebImportSheet = false
    @State private var showScannerSheet = false

    // Clothes
    @State private var size: String = ""
    @State private var fabricMaterial: String = ""
    @State private var color: String = ""

    // Shoes
    @State private var shoeSize: String = ""
    @State private var leatherSoleType: String = ""

    // Electronics
    @State private var modelSpecs: String = ""
    @State private var serialNumber: String = ""
    @State private var warrantyInfo: String = ""
    @State private var techCondition: String = "Pristine"

    // Bags
    @State private var bagCapacity: String = ""
    @State private var bagMaterialHardware: String = ""

    // Grooming
    @State private var volumeSize: String = ""
    @State private var scentIngredients: String = ""

    // Accessories
    @State private var accessoryMaterial: String = ""

    // Usage & Ownership (Pairs & Wear Count)
    @State private var quantity: Int = 1
    @State private var timesWorn: Int = 0
    @State private var selectedCondition: GarmentCondition? = nil

    // Quality, Durability & Review
    @State private var qualityRating: Int = 0
    @State private var durabilityRating: Int = 0
    @State private var reviewNotes: String = ""

    public init(dataStore: DataStore, existingItem: WardrobeItem? = nil) {
        self.dataStore = dataStore
        self.existingItem = existingItem
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Category Selector
                    categorySegmentedPicker

                    // Photos Section
                    photosSection

                    // Basic Details
                    basicDetailsSection

                    // Category Specific Specs
                    categorySpecsSection

                    // Ownership & Wear History (Pairs & Times Worn)
                    usageAndPairsSection

                    // Valuation & Location
                    valuationAndLocationSection

                    // Notes
                    notesSection

                    // Owner Review & Ratings (Quality & Durability Stars)
                    reviewRatingSection

                    // Submit Button
                    saveButton
                        .padding(.top, 10)
                        .padding(.bottom, 30)
                }
                .padding(.horizontal)
                .padding(.vertical, 16)
            }
            .background(LuxuryTheme.background.ignoresSafeArea())
            .navigationTitle(existingItem == nil ? "Add to Vault" : "Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(LuxuryTheme.textSecondary)
                }
            }
            .sheet(isPresented: $showWebImportSheet) {
                WebImportSheet { imported in
                    applyImportedData(imported)
                }
            }
            .sheet(isPresented: $showScannerSheet) {
                QRCodeScannerView(
                    title: "Scan Product Barcode / QR",
                    subtitle: "Scan box barcode to auto-fill SKU, or QR code to import product details"
                ) { code in
                    handleScannedCode(code)
                }
            }
            .onAppear {
                loadExistingDataIfNeeded()
            }
        }
    }

    // MARK: - Category Picker (Scrollable 6 Categories)
    private var categorySegmentedPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ItemCategory.allCases) { cat in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            category = cat
                            if !cat.defaultSubcategories.contains(subcategory) {
                                subcategory = cat.defaultSubcategories.first ?? ""
                            }
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: cat.iconName)
                                .font(.system(size: 12, weight: .bold))
                            Text(cat.rawValue)
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundStyle(category == cat ? Color.black : LuxuryTheme.textSecondary)
                        .padding(.horizontal, 14)
                        .frame(height: 42)
                        .background(category == cat ? cat.accentColor : LuxuryTheme.cardBackground)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(category == cat ? Color.clear : LuxuryTheme.cardBorder, lineWidth: 1)
                        )
                    }
                }
            }
        }
    }

    // MARK: - Photos Section
    private var photosSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Product Photos (\(photos.count))")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(LuxuryTheme.textPrimary)

                Spacer()

                if !photos.isEmpty {
                    Text("First photo is cover")
                        .font(.system(size: 11))
                        .foregroundStyle(LuxuryTheme.textTertiary)
                }
            }

            // Photo Carousels / Thumbnails
            if !photos.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(photos.enumerated()), id: \.offset) { index, photo in
                            ZStack(alignment: .topTrailing) {
                                ItemImageView(photoNameOrUrl: photo, category: category)
                                    .frame(width: 100, height: 120)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(index == 0 ? LuxuryTheme.accentAmber : LuxuryTheme.cardBorder, lineWidth: index == 0 ? 2 : 1)
                                    )

                                if index == 0 {
                                    Text("COVER")
                                        .font(.system(size: 9, weight: .black))
                                        .foregroundStyle(Color.black)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 2)
                                        .background(LuxuryTheme.accentAmber)
                                        .clipShape(Capsule())
                                        .padding(4)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                }

                                Button(action: {
                                    photos.remove(at: index)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundStyle(Color.white, Color.black.opacity(0.7))
                                        .padding(4)
                                }
                            }
                        }
                    }
                }
            }

            // Add Photos Actions
            HStack(spacing: 10) {
                // Photos Library
                PhotosPicker(
                    selection: $selectedPhotosPickerItems,
                    maxSelectionCount: 6,
                    matching: .images
                ) {
                    HStack(spacing: 6) {
                        Image(systemName: "photo.on.rectangle")
                        Text("Gallery")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(LuxuryTheme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(LuxuryTheme.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .onChange(of: selectedPhotosPickerItems) { newItems in
                    Task {
                        for item in newItems {
                            if let data = try? await item.loadTransferable(type: Data.self),
                               let savedFilename = ImageManager.shared.saveImageData(data) {
                                await MainActor.run {
                                    photos.append(savedFilename)
                                }
                            }
                        }
                        selectedPhotosPickerItems = []
                    }
                }

                HStack(spacing: 10) {
                    // QR / Barcode Scan Button
                    Button(action: { showScannerSheet = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "barcode.viewfinder")
                            Text("Scan Barcode / QR")
                        }
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(LuxuryTheme.accentGold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                        .background(LuxuryTheme.accentGold.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(LuxuryTheme.accentGold.opacity(0.4), lineWidth: 1)
                        )
                    }

                    // Web Import Button
                    Button(action: { showWebImportSheet = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "globe")
                            Text("Amazon / Web")
                        }
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(LuxuryTheme.accentAmber)
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                        .background(LuxuryTheme.accentAmber.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(LuxuryTheme.accentAmber.opacity(0.4), lineWidth: 1)
                        )
                    }
                }
            }
        }
        .padding(16)
        .luxuryCardStyle(cornerRadius: 16)
    }

    // MARK: - Basic Details Section
    private var basicDetailsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Core Details")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(LuxuryTheme.textPrimary)

            customTextField(title: "Item Title *", placeholder: "e.g. Nike Downshifter 14, Creed Aventus", text: $name)
            customTextField(title: "Brand / Maker", placeholder: "e.g. Nike, Rimowa, Creed, Montblanc", text: $brand)

            // Subcategory Selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Subcategory")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(LuxuryTheme.textSecondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(category.defaultSubcategories, id: \.self) { sub in
                            Button(action: { subcategory = sub }) {
                                Text(sub)
                                    .font(.system(size: 12, weight: subcategory == sub ? .bold : .regular))
                                    .foregroundStyle(subcategory == sub ? Color.black : LuxuryTheme.textSecondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(subcategory == sub ? category.accentColor : LuxuryTheme.secondaryBackground)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .luxuryCardStyle(cornerRadius: 16)
    }

    // MARK: - Category Specs Section (All 6 Categories)
    private var categorySpecsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("\(category.rawValue) Specifications")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(category.accentColor)

            switch category {
            case .electronics:
                customTextField(title: "Chipset / Model Specs", placeholder: "e.g. M3 Max • 64GB Unified Memory • 1TB", text: $modelSpecs)
                customTextField(title: "Serial Number", placeholder: "e.g. C02G9012L4X9", text: $serialNumber)
                customTextField(title: "Warranty & Coverage", placeholder: "e.g. AppleCare+ until Nov 2027", text: $warrantyInfo)
                customTextField(title: "Hardware Condition", placeholder: "e.g. Pristine, Mint, Daily Driver", text: $techCondition)

            case .clothes:
                customTextField(title: "Size / Fit", placeholder: "e.g. 40R (Drop 7), Slim Medium, 32W 32L", text: $size)
                customTextField(title: "Fabric / Material", placeholder: "e.g. Super 150s Pure Wool, 100% Giza Cotton", text: $fabricMaterial)
                customTextField(title: "Colorway", placeholder: "e.g. Midnight Navy, French Blue", text: $color)

            case .sportswear:
                customTextField(title: "Size / Fit", placeholder: "e.g. Medium, Athletic Fit, Compression L", text: $size)
                customTextField(title: "Performance Tech & Fabric", placeholder: "e.g. Dri-FIT ADV, 4-Way Stretch, Moisture-Wicking", text: $fabricMaterial)
                customTextField(title: "Colorway", placeholder: "e.g. Stealth Black, Electric Crimson", text: $color)

            case .shoes:
                customTextField(title: "Shoe Size", placeholder: "e.g. 9 UK / US 10 / EU 43", text: $shoeSize)
                customTextField(title: "Sole & Construction", placeholder: "e.g. Foam Midsole • Rubber Outsole, Goodyear Welt", text: $leatherSoleType)

            case .bags:
                customTextField(title: "Capacity / Dimensions", placeholder: "e.g. 36L Cabin, Fits 16\" MacBook", text: $bagCapacity)
                customTextField(title: "Material & Hardware", placeholder: "e.g. Anodized Aluminum Alloy, Bridle Leather", text: $bagMaterialHardware)

            case .grooming:
                customTextField(title: "Volume / Bottle Size", placeholder: "e.g. 100ml / 3.4 oz, 60ml Dropper", text: $volumeSize)
                customTextField(title: "Scent Profile / Key Active Ingredients", placeholder: "e.g. Bergamot, Birch, Ambergris, Red Algae", text: $scentIngredients)

            case .accessories:
                customTextField(title: "Material & Finish", placeholder: "e.g. European Calfskin, 10mm Cured Acetate", text: $accessoryMaterial)
            }

            customTextField(title: "Occasion / Use Case", placeholder: "e.g. Everyday Running, Boardroom, Travel", text: $occasion)
        }
        .padding(16)
        .luxuryCardStyle(cornerRadius: 16)
    }

    // MARK: - Valuation & Location
    private var valuationAndLocationSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Valuation & Storage")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(LuxuryTheme.textPrimary)

            customTextField(title: "Price / Value (₹)", placeholder: "e.g. 4895", text: $priceText, keyboardType: .numberPad)
            customTextField(title: "Storage Location", placeholder: "e.g. Shoe Wall #2, Dressing Console, Safe", text: $storageLocation)
        }
        .padding(16)
        .luxuryCardStyle(cornerRadius: 16)
    }

    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Personal Notes & Details")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(LuxuryTheme.textPrimary)

            TextEditor(text: $notes)
                .frame(height: 80)
                .scrollContentBackground(.hidden)
                .padding(10)
                .background(LuxuryTheme.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .foregroundStyle(LuxuryTheme.textPrimary)
        }
        .padding(16)
        .luxuryCardStyle(cornerRadius: 16)
    }

    // MARK: - Save Button
    private var saveButton: some View {
        Button(action: saveItem) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                Text(existingItem == nil ? "Add to My Vault ✨" : "Update Vault Item")
            }
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(Color.black)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? LuxuryTheme.accentAmber.opacity(0.4) : LuxuryTheme.accentAmber)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    // MARK: - Helpers
    private func customTextField(title: String, placeholder: String, text: Binding<String>, keyboardType: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(LuxuryTheme.textSecondary)

            TextField(placeholder, text: text)
                .keyboardType(keyboardType)
                .font(.system(size: 14))
                .foregroundStyle(LuxuryTheme.textPrimary)
                .padding(12)
                .background(LuxuryTheme.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private func applyImportedData(_ data: ImportedProductData) {
        if !data.name.isEmpty { self.name = data.name }
        if !data.brand.isEmpty { self.brand = data.brand }
        if data.price > 0 { self.priceText = "\(Int(data.price))" }
        self.category = data.category
        if !data.subcategory.isEmpty { self.subcategory = data.subcategory }
        if !data.size.isEmpty { self.size = data.size }
        if !data.fabricMaterial.isEmpty { self.fabricMaterial = data.fabricMaterial }
        if !data.modelSpecs.isEmpty { self.modelSpecs = data.modelSpecs }
        if !data.shoeSize.isEmpty { self.shoeSize = data.shoeSize }
        if !data.bagCapacity.isEmpty { self.bagCapacity = data.bagCapacity }
        if !data.volumeSize.isEmpty { self.volumeSize = data.volumeSize }
        if !data.accessoryMaterial.isEmpty { self.accessoryMaterial = data.accessoryMaterial }
        if !data.occasion.isEmpty { self.occasion = data.occasion }
        if !data.notes.isEmpty { self.notes = data.notes }
        if !data.photoFilenames.isEmpty { self.photos = data.photoFilenames }
    }

    private func loadExistingDataIfNeeded() {
        guard let item = existingItem else {
            subcategory = category.defaultSubcategories.first ?? ""
            return
        }
        name = item.name
        brand = item.brand
        category = item.category
        subcategory = item.subcategory
        priceText = item.price > 0 ? "\(Int(item.price))" : ""
        photos = item.photos
        storageLocation = item.storageLocation
        occasion = item.occasion
        notes = item.notes
        size = item.size
        fabricMaterial = item.fabricMaterial
        color = item.color
        shoeSize = item.shoeSize
        leatherSoleType = item.leatherSoleType
        modelSpecs = item.modelSpecs
        serialNumber = item.serialNumber
        warrantyInfo = item.warrantyInfo
        techCondition = item.techCondition
        bagCapacity = item.bagCapacity
        bagMaterialHardware = item.bagMaterialHardware
        volumeSize = item.volumeSize
        scentIngredients = item.scentIngredients
        accessoryMaterial = item.accessoryMaterial
        quantity = item.quantity
        timesWorn = item.timesWorn
        selectedCondition = item.garmentCondition
        qualityRating = item.qualityRating
        durabilityRating = item.durabilityRating
        reviewNotes = item.reviewNotes
    }

    // MARK: - Usage & Pairs Section
    private var usageAndPairsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Ownership, Condition & Lifespan")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(LuxuryTheme.textPrimary)

            HStack(spacing: 12) {
                // Number of Pairs / Identical Items Owned
                VStack(alignment: .leading, spacing: 6) {
                    Text("PAIRS / QTY OWNED")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(LuxuryTheme.textTertiary)

                    HStack {
                        Button {
                            if quantity > 1 { quantity -= 1 }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(LuxuryTheme.textSecondary)
                        }

                        Spacer()

                        Text("\(quantity) \(category == .shoes ? "Pairs" : "Items")")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(LuxuryTheme.textPrimary)

                        Spacer()

                        Button {
                            quantity += 1
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(LuxuryTheme.accentAmber)
                        }
                    }
                    .padding(10)
                    .background(LuxuryTheme.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .frame(maxWidth: .infinity)

                // Times Worn
                VStack(alignment: .leading, spacing: 6) {
                    Text("TIMES WORN")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(LuxuryTheme.textTertiary)

                    HStack {
                        Button {
                            if timesWorn > 0 { timesWorn -= 1 }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(LuxuryTheme.textSecondary)
                        }

                        Spacer()

                        Text("\(timesWorn)x")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(LuxuryTheme.accentAmber)

                        Spacer()

                        Button {
                            timesWorn += 1
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(LuxuryTheme.accentAmber)
                        }
                    }
                    .padding(10)
                    .background(LuxuryTheme.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .frame(maxWidth: .infinity)
            }

            // Garment Condition Dropdown
            VStack(alignment: .leading, spacing: 6) {
                Text("GARMENT CONDITION")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(LuxuryTheme.textTertiary)

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
                            .foregroundStyle(LuxuryTheme.textPrimary)

                        Text(selectedCondition != nil ? "(Manual)" : "(Auto: \(timesWorn) wears)")
                            .font(.system(size: 11))
                            .foregroundStyle(LuxuryTheme.textTertiary)

                        Spacer()

                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 12))
                            .foregroundStyle(LuxuryTheme.textTertiary)
                    }
                    .padding(12)
                    .background(LuxuryTheme.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(16)
        .luxuryCardStyle(cornerRadius: 16)
    }

    // MARK: - Review & Verdict Section
    private var reviewRatingSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "star.bubble.fill")
                    .foregroundStyle(LuxuryTheme.gold)
                Text("Quality, Durability & Review")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(LuxuryTheme.textPrimary)
            }

            // Quality Star Rating
            StarRatingView(
                rating: $qualityRating,
                title: "Material & Craft Quality",
                subtitle: "Fabric, stitching & finish",
                starColor: LuxuryTheme.gold
            )

            Divider()
                .background(LuxuryTheme.cardBorder)

            // Durability Star Rating
            StarRatingView(
                rating: $durabilityRating,
                title: "Wear & Longevity Durability",
                subtitle: "Wash resilience & color retention",
                starColor: Color(red: 0.25, green: 0.65, blue: 0.98)
            )

            Divider()
                .background(LuxuryTheme.cardBorder)

            VStack(alignment: .leading, spacing: 6) {
                Text("WEAR & LONGEVITY COMMENTS")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(LuxuryTheme.textTertiary)

                TextField("Add comments on how it feels, shrinks or fades...", text: $reviewNotes, axis: .vertical)
                    .font(.system(size: 13))
                    .foregroundStyle(LuxuryTheme.textPrimary)
                    .padding(12)
                    .background(LuxuryTheme.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .lineLimit(2...4)
            }
        }
        .padding(16)
        .luxuryCardStyle(cornerRadius: 16)
    }

    private func saveItem() {
        let priceVal = Double(priceText.filter("0123456789.".contains)) ?? 0.0

        var item = existingItem ?? WardrobeItem(
            name: name,
            brand: brand,
            category: category,
            subcategory: subcategory,
            price: priceVal
        )

        item.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        item.brand = brand.trimmingCharacters(in: .whitespacesAndNewlines)
        item.category = category
        item.subcategory = subcategory
        item.price = priceVal
        item.photos = photos
        item.storageLocation = storageLocation
        item.occasion = occasion
        item.notes = notes
        item.size = size
        item.fabricMaterial = fabricMaterial
        item.color = color
        item.shoeSize = shoeSize
        item.leatherSoleType = leatherSoleType
        item.modelSpecs = modelSpecs
        item.serialNumber = serialNumber
        item.warrantyInfo = warrantyInfo
        item.techCondition = techCondition
        item.bagCapacity = bagCapacity
        item.bagMaterialHardware = bagMaterialHardware
        item.volumeSize = volumeSize
        item.scentIngredients = scentIngredients
        item.accessoryMaterial = accessoryMaterial
        item.quantity = max(1, quantity)
        item.timesWorn = timesWorn
        item.garmentCondition = selectedCondition
        item.qualityRating = qualityRating
        item.durabilityRating = durabilityRating
        item.reviewNotes = reviewNotes

        if existingItem == nil {
            dataStore.addItem(item)
        } else {
            dataStore.updateItem(item)
        }

        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }

    private func handleScannedCode(_ code: String) {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            // It is a web product link (Amazon, Nike, Zara, etc.)
            Task {
                if let imported = try? await WebProductImporter.shared.importFromUrl(trimmed) {
                    await MainActor.run {
                        applyImportedData(imported)
                    }
                } else {
                    await MainActor.run {
                        notes = (notes.isEmpty ? "" : notes + "\n") + "Source: " + trimmed
                    }
                }
            }
        } else {
            // It is a barcode / UPC / SKU / Serial Number
            serialNumber = trimmed
            if notes.isEmpty {
                notes = "Barcode: \(trimmed)"
            } else if !notes.contains(trimmed) {
                notes += "\nBarcode: \(trimmed)"
            }

            // AUTOMATIC SEARCH: Search online product databases for this barcode
            Task {
                if let product = await WebProductImporter.shared.searchProductByBarcode(trimmed) {
                    await MainActor.run {
                        applyImportedData(product)
                    }
                } else {
                    await MainActor.run {
                        if name.isEmpty {
                            name = "Scanned Item \(trimmed)"
                        }
                    }
                }
            }
        }
    }
}
