import SwiftUI

// MARK: - Women's Categories
public enum WomenCategory: String, CaseIterable, Codable, Identifiable {
    case sareesEthnic = "Sarees & Ethnic"
    case dressesGowns = "Dresses & Gowns"
    case kurtisTops = "Kurtis & Tops"
    case bottomsSkirts = "Bottoms & Skirts"
    case activewear = "Activewear"
    case fineJewelry = "Fine Jewelry"
    case handbagsClutches = "Handbags & Clutches"
    case watches = "Timepieces"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .sareesEthnic: return "sparkles"
        case .dressesGowns: return "hanger"
        case .kurtisTops: return "tshirt.fill"
        case .bottomsSkirts: return "square.2.layers.3d"
        case .activewear: return "figure.run"
        case .fineJewelry: return "suit.diamond.fill"
        case .handbagsClutches: return "handbag.fill"
        case .watches: return "applewatch"
        }
    }

    public var accentColor: Color {
        switch self {
        case .sareesEthnic: return Color(red: 0.89, green: 0.36, blue: 0.44) // Royal Crimson Rose
        case .dressesGowns: return Color(red: 0.85, green: 0.52, blue: 0.65) // Blush Orchid
        case .kurtisTops: return Color(red: 0.94, green: 0.62, blue: 0.48) // Peach Coral
        case .bottomsSkirts: return Color(red: 0.72, green: 0.58, blue: 0.76) // Lavender Iris
        case .activewear: return Color(red: 0.45, green: 0.76, blue: 0.72) // Mint Seaglass
        case .fineJewelry: return Color(red: 0.85, green: 0.68, blue: 0.28) // 22K Champagne Gold
        case .handbagsClutches: return Color(red: 0.78, green: 0.44, blue: 0.52) // Rosewood Leather
        case .watches: return Color(red: 0.92, green: 0.72, blue: 0.56) // 18K Rose Gold
        }
    }

    public var defaultSubcategories: [String] {
        switch self {
        case .sareesEthnic:
            return ["Kanjeevaram & Silk Sarees", "Bridal & Party Lehengas", "Banarasi Weaves", "Anarkalis & Shararas", "Organza & Chiffon"]
        case .dressesGowns:
            return ["Evening & Cocktail Gowns", "Midi & Wrap Dresses", "Maxi Sun Dresses", "Formal Sheath Dresses"]
        case .kurtisTops:
            return ["Handcrafted Kurtis", "Embroidered Tunics", "Silk Tops & Blouses", "Everyday Shirts"]
        case .bottomsSkirts:
            return ["Flared Palazzos", "Lehenga Skirts", "Tailored Trousers", "Draped Dhotis"]
        case .activewear:
            return ["Yoga Sets & Leggings", "Athletic Training Bras", "Seamless Dry-Fit", "Running Jackets"]
        case .fineJewelry:
            return ["Necklaces & Chokers", "Jhumkas & Chandbalis", "Diamond Earrings & Studs", "Bangles & Kadas", "Solitaire & Cocktail Rings", "Chains & Pendants", "Anklets (Payal)"]
        case .handbagsClutches:
            return ["Luxury Totes & Satchels", "Bridal Minaudières & Clutches", "Crossbody Slings", "Shoulder Bags"]
        case .watches:
            return ["Jewelry Watches", "Classic Dress Watches", "Smart Luxury Wearables", "Rose Gold Timepieces"]
        }
    }

    public var isClothing: Bool {
        switch self {
        case .sareesEthnic, .dressesGowns, .kurtisTops, .bottomsSkirts, .activewear:
            return true
        default:
            return false
        }
    }

    public var isJewelryOrWatch: Bool {
        return self == .fineJewelry || self == .watches
    }
}

// MARK: - Metal & Purity
public enum WomenMetalType: String, CaseIterable, Codable, Identifiable {
    case gold24K = "24K Pure Gold"
    case gold22K = "22K Traditional Yellow Gold"
    case gold18KRose = "18K Rose Gold"
    case diamond = "Diamond & Solitaire"
    case platinum = "Platinum"
    case silver925 = "925 Sterling Silver"
    case embellishedZari = "Handcrafted Zari & Zardozi"
    case pureSilk = "Pure Mulberry / Kanjeevaram Silk"
    case organzaChiffon = "Pure Organza / Chiffon"
    case premiumCotton = "Linen & Chanderi Cotton"
    case fineLeather = "Fine Italian Leather"
    case technicalAthletic = "Weightless Activewear Fabric"
    case other = "Other Luxury Material"

    public var id: String { rawValue }
}

// MARK: - Women's Wardrobe Item
public struct WomenWardrobeItem: Identifiable, Codable, Equatable {
    public var id: UUID
    public var title: String
    public var category: WomenCategory
    public var subcategory: String
    public var brand: String
    public var price: Double
    public var originalPrice: Double
    public var photos: [String]
    public var metal: WomenMetalType
    public var purity: String
    public var sizeOrDimensions: String
    public var isSet: Bool
    public var setIncludes: String
    public var storageLocation: String
    public var occasion: String
    public var notes: String
    public var storeUrl: String
    public var timesWorn: Int
    public var lastWornDate: Date?
    public var dateAdded: Date
    public var isFavorite: Bool
    public var quantity: Int // No of pairs / identical pieces owned (default 1)
    public var wearHistory: [Date]
    public var garmentCondition: GarmentCondition? // Manual condition override: New, Medium, Old, Faded

    public init(
        id: UUID = UUID(),
        title: String,
        category: WomenCategory,
        subcategory: String = "",
        brand: String,
        price: Double,
        originalPrice: Double = 0.0,
        photos: [String] = [],
        metal: WomenMetalType = .other,
        purity: String = "",
        sizeOrDimensions: String = "Free Size",
        isSet: Bool = false,
        setIncludes: String = "",
        storageLocation: String = "Main Boutique Closet",
        occasion: String = "Everyday",
        notes: String = "",
        storeUrl: String = "",
        timesWorn: Int = 0,
        lastWornDate: Date? = nil,
        dateAdded: Date = Date(),
        isFavorite: Bool = false,
        quantity: Int = 1,
        wearHistory: [Date] = [],
        garmentCondition: GarmentCondition? = nil
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.subcategory = subcategory.isEmpty ? (category.defaultSubcategories.first ?? "") : subcategory
        self.brand = brand
        self.price = price
        self.originalPrice = originalPrice > 0 ? originalPrice : price
        self.photos = photos
        self.metal = metal
        self.purity = purity
        self.sizeOrDimensions = sizeOrDimensions
        self.isSet = isSet
        self.setIncludes = setIncludes
        self.storageLocation = storageLocation
        self.occasion = occasion
        self.notes = notes
        self.storeUrl = storeUrl
        self.timesWorn = timesWorn
        self.lastWornDate = lastWornDate
        self.dateAdded = dateAdded
        self.isFavorite = isFavorite
        self.quantity = max(1, quantity)
        self.wearHistory = wearHistory
        self.garmentCondition = garmentCondition
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        category = try container.decodeIfPresent(WomenCategory.self, forKey: .category) ?? .sareesEthnic
        subcategory = try container.decodeIfPresent(String.self, forKey: .subcategory) ?? ""
        brand = try container.decodeIfPresent(String.self, forKey: .brand) ?? ""
        price = try container.decodeIfPresent(Double.self, forKey: .price) ?? 0.0
        originalPrice = try container.decodeIfPresent(Double.self, forKey: .originalPrice) ?? price
        photos = try container.decodeIfPresent([String].self, forKey: .photos) ?? []
        metal = try container.decodeIfPresent(WomenMetalType.self, forKey: .metal) ?? .other
        purity = try container.decodeIfPresent(String.self, forKey: .purity) ?? ""
        sizeOrDimensions = try container.decodeIfPresent(String.self, forKey: .sizeOrDimensions) ?? "Free Size"
        isSet = try container.decodeIfPresent(Bool.self, forKey: .isSet) ?? false
        setIncludes = try container.decodeIfPresent(String.self, forKey: .setIncludes) ?? ""
        storageLocation = try container.decodeIfPresent(String.self, forKey: .storageLocation) ?? "Main Boutique Closet"
        occasion = try container.decodeIfPresent(String.self, forKey: .occasion) ?? "Everyday"
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        storeUrl = try container.decodeIfPresent(String.self, forKey: .storeUrl) ?? ""
        timesWorn = try container.decodeIfPresent(Int.self, forKey: .timesWorn) ?? 0
        lastWornDate = try container.decodeIfPresent(Date.self, forKey: .lastWornDate)
        dateAdded = try container.decodeIfPresent(Date.self, forKey: .dateAdded) ?? Date()
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        quantity = try container.decodeIfPresent(Int.self, forKey: .quantity) ?? 1
        wearHistory = try container.decodeIfPresent([Date].self, forKey: .wearHistory) ?? []
        garmentCondition = try container.decodeIfPresent(GarmentCondition.self, forKey: .garmentCondition)
    }

    // MARK: - Condition & Aging Intelligence
    public var effectiveCondition: GarmentCondition {
        if let manual = garmentCondition {
            return manual
        }
        return GarmentCondition.calculateFromWearCount(timesWorn)
    }

    public var isManuallySetCondition: Bool {
        return garmentCondition != nil
    }

    // MARK: - Repeat Wear Intelligence
    public var repeatWearStatus: RepeatWearStatus {
        RepeatWearStatus.calculate(timesWorn: timesWorn, lastWornDate: lastWornDate)
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

    public var costPerWear: Double {
        let count = max(timesWorn, 1)
        return price / Double(count)
    }

    public var formattedCostPerWear: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₹"
        formatter.maximumFractionDigits = 0
        formatter.locale = Locale(identifier: "en_IN")
        return formatter.string(from: NSNumber(value: costPerWear)) ?? "₹\(Int(costPerWear))"
    }

    public var hasPriceDrop: Bool {
        originalPrice > price && price > 0
    }

    public var discountPercentage: Int {
        guard hasPriceDrop, originalPrice > 0 else { return 0 }
        return Int(round(((originalPrice - price) / originalPrice) * 100))
    }

    public var savingsAmount: Double {
        guard hasPriceDrop else { return 0.0 }
        return originalPrice - price
    }

    public var wearAgingStatus: (label: String, color: Color) {
        if timesWorn == 0 {
            return ("Pristine / Unworn", Color(red: 0.90, green: 0.45, blue: 0.55))
        } else if timesWorn < 4 {
            return ("Freshly Styled", Color(red: 0.45, green: 0.78, blue: 0.65))
        } else if timesWorn < 12 {
            return ("Wardrobe Favorite", Color(red: 0.85, green: 0.68, blue: 0.28))
        } else {
            return ("Signature Classic", Color(red: 0.78, green: 0.60, blue: 0.88))
        }
    }
}

// MARK: - Women's Wishlist Item
public struct WomenWishlistItem: Identifiable, Codable, Equatable {
    public var id: UUID
    public var title: String
    public var category: WomenCategory
    public var subcategory: String
    public var brand: String
    public var targetPrice: Double
    public var originalPrice: Double
    public var photos: [String]
    public var priority: String // "HIGH", "MEDIUM", "LOW"
    public var storeUrl: String
    public var notes: String
    public var dateAdded: Date

    public init(
        id: UUID = UUID(),
        title: String,
        category: WomenCategory,
        subcategory: String = "",
        brand: String,
        targetPrice: Double,
        originalPrice: Double = 0.0,
        photos: [String] = [],
        priority: String = "HIGH",
        storeUrl: String = "",
        notes: String = "",
        dateAdded: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.subcategory = subcategory.isEmpty ? (category.defaultSubcategories.first ?? "") : subcategory
        self.brand = brand
        self.targetPrice = targetPrice
        self.originalPrice = originalPrice > 0 ? originalPrice : targetPrice
        self.photos = photos
        self.priority = priority
        self.storeUrl = storeUrl
        self.notes = notes
        self.dateAdded = dateAdded
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
        return formatter.string(from: NSNumber(value: targetPrice)) ?? "₹\(Int(targetPrice))"
    }

    public var priorityBadge: String {
        switch priority.uppercased() {
        case "HIGH": return "🔥 High Goal"
        case "MEDIUM": return "⭐ Target"
        default: return "💭 Aspirational"
        }
    }
}

// MARK: - Women's Curated Look
public struct WomenCuratedLook: Identifiable, Codable, Equatable {
    public var id: UUID
    public var name: String
    public var occasion: String
    public var anchorItemId: UUID?
    public var itemIds: [UUID]
    public var harmonyScore: Int
    public var stylistAdvice: String
    public var dateCreated: Date

    public init(
        id: UUID = UUID(),
        name: String,
        occasion: String,
        anchorItemId: UUID? = nil,
        itemIds: [UUID],
        harmonyScore: Int = 95,
        stylistAdvice: String,
        dateCreated: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.occasion = occasion
        self.anchorItemId = anchorItemId
        self.itemIds = itemIds
        self.harmonyScore = harmonyScore
        self.stylistAdvice = stylistAdvice
        self.dateCreated = dateCreated
    }
}

// MARK: - Women's Trip Packing Plan
public struct WomenTripPlan: Identifiable, Codable, Equatable {
    public var id: UUID
    public var destination: String
    public var travelDate: String
    public var packedItemIds: Set<UUID>
    public var returnedItemIds: Set<UUID>
    public var notes: String
    public var isCompleted: Bool

    public init(
        id: UUID = UUID(),
        destination: String,
        travelDate: String,
        packedItemIds: Set<UUID> = [],
        returnedItemIds: Set<UUID> = [],
        notes: String = "",
        isCompleted: Bool = false
    ) {
        self.id = id
        self.destination = destination
        self.travelDate = travelDate
        self.packedItemIds = packedItemIds
        self.returnedItemIds = returnedItemIds
        self.notes = notes
        self.isCompleted = isCompleted
    }
}
