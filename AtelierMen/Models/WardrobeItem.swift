import Foundation

public struct WardrobeItem: Identifiable, Codable, Equatable {
    public var id: UUID
    public var name: String
    public var brand: String
    public var category: ItemCategory
    public var subcategory: String
    public var price: Double // In INR (₹)
    public var photos: [String] // Local file names, system symbol names, or web URLs
    public var isFavorite: Bool
    public var storageLocation: String
    public var occasion: String
    public var notes: String
    public var dateAdded: Date

    // Apparel specific
    public var size: String // e.g. "40R", "L", "32W 32L"
    public var fabricMaterial: String // e.g. "100% Merino Wool", "Super 150s"
    public var color: String

    // Footwear specific
    public var shoeSize: String // e.g. "UK 9 / US 10 / EU 43"
    public var leatherSoleType: String // e.g. "Goodyear Welted Calfskin", "Vibram Lug Sole"

    // Electronics specific
    public var modelSpecs: String // e.g. "M3 Max • 64GB • 1TB", "ANC • 30h Battery"
    public var serialNumber: String
    public var warrantyInfo: String // e.g. "AppleCare+ until 2027"
    public var techCondition: String // e.g. "Pristine", "Mint", "Daily Driver"

    // Bags & Luggage specific
    public var bagCapacity: String // e.g. "36L Cabin", "Fits 16\" MacBook"
    public var bagMaterialHardware: String // e.g. "Anodized Aluminum • TSA Locks"

    // Grooming & Skincare specific
    public var volumeSize: String // e.g. "100ml / 3.4 oz", "50ml Pump"
    public var scentIngredients: String // e.g. "Birch, Bergamot, Blackcurrant"

    // Accessories specific
    public var accessoryMaterial: String // e.g. "Full Grain European Cowhide", "Titanium Frame"

    public init(
        id: UUID = UUID(),
        name: String,
        brand: String,
        category: ItemCategory,
        subcategory: String = "",
        price: Double = 0.0,
        photos: [String] = [],
        isFavorite: Bool = false,
        storageLocation: String = "Main Closet",
        occasion: String = "Everyday",
        notes: String = "",
        dateAdded: Date = Date(),
        size: String = "",
        fabricMaterial: String = "",
        color: String = "",
        shoeSize: String = "",
        leatherSoleType: String = "",
        modelSpecs: String = "",
        serialNumber: String = "",
        warrantyInfo: String = "",
        techCondition: String = "Pristine",
        bagCapacity: String = "",
        bagMaterialHardware: String = "",
        volumeSize: String = "",
        scentIngredients: String = "",
        accessoryMaterial: String = ""
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.category = category
        self.subcategory = subcategory.isEmpty ? (category.defaultSubcategories.first ?? "") : subcategory
        self.price = price
        self.photos = photos
        self.isFavorite = isFavorite
        self.storageLocation = storageLocation
        self.occasion = occasion
        self.notes = notes
        self.dateAdded = dateAdded
        self.size = size
        self.fabricMaterial = fabricMaterial
        self.color = color
        self.shoeSize = shoeSize
        self.leatherSoleType = leatherSoleType
        self.modelSpecs = modelSpecs
        self.serialNumber = serialNumber
        self.warrantyInfo = warrantyInfo
        self.techCondition = techCondition
        self.bagCapacity = bagCapacity
        self.bagMaterialHardware = bagMaterialHardware
        self.volumeSize = volumeSize
        self.scentIngredients = scentIngredients
        self.accessoryMaterial = accessoryMaterial
    }

    public var primaryPhoto: String {
        photos.first ?? ""
    }

    public var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₹"
        formatter.maximumFractionDigits = 0
        formatter.locale = Locale(identifier: "en_IN")
        return formatter.string(from: NSNumber(value: price)) ?? "₹\(Int(price))"
    }

    public var keySpecSummary: String {
        switch category {
        case .electronics:
            if !modelSpecs.isEmpty { return modelSpecs }
            if !techCondition.isEmpty { return techCondition }
            return subcategory
        case .clothes:
            var parts: [String] = []
            if !size.isEmpty { parts.append(size) }
            if !fabricMaterial.isEmpty { parts.append(fabricMaterial) }
            return parts.isEmpty ? subcategory : parts.joined(separator: " • ")
        case .sportswear:
            var parts: [String] = []
            if !size.isEmpty { parts.append(size) }
            if !fabricMaterial.isEmpty { parts.append(fabricMaterial) }
            return parts.isEmpty ? subcategory : parts.joined(separator: " • ")
        case .shoes:
            var parts: [String] = []
            if !shoeSize.isEmpty { parts.append(shoeSize) }
            if !leatherSoleType.isEmpty { parts.append(leatherSoleType) }
            return parts.isEmpty ? subcategory : parts.joined(separator: " • ")
        case .bags:
            var parts: [String] = []
            if !bagCapacity.isEmpty { parts.append(bagCapacity) }
            if !bagMaterialHardware.isEmpty { parts.append(bagMaterialHardware) }
            return parts.isEmpty ? subcategory : parts.joined(separator: " • ")
        case .grooming:
            var parts: [String] = []
            if !volumeSize.isEmpty { parts.append(volumeSize) }
            if !scentIngredients.isEmpty { parts.append(scentIngredients) }
            return parts.isEmpty ? subcategory : parts.joined(separator: " • ")
        case .accessories:
            return !accessoryMaterial.isEmpty ? accessoryMaterial : subcategory
        }
    }
}
