import Foundation

public enum BackupImportMode: String, CaseIterable, Identifiable {
    case merge = "Merge (Keep Existing)"
    case replace = "Replace (Clean Restore)"

    public var id: String { rawValue }
}

public struct ImportSummary: Equatable {
    public var menItems: Int = 0
    public var menWishlist: Int = 0
    public var womenItems: Int = 0
    public var womenWishlist: Int = 0
    public var looksCount: Int = 0
    public var tripsCount: Int = 0

    public init(
        menItems: Int = 0,
        menWishlist: Int = 0,
        womenItems: Int = 0,
        womenWishlist: Int = 0,
        looksCount: Int = 0,
        tripsCount: Int = 0
    ) {
        self.menItems = menItems
        self.menWishlist = menWishlist
        self.womenItems = womenItems
        self.womenWishlist = womenWishlist
        self.looksCount = looksCount
        self.tripsCount = tripsCount
    }

    public var totalCount: Int {
        menItems + menWishlist + womenItems + womenWishlist + looksCount + tripsCount
    }

    public var detailedMessage: String {
        var parts: [String] = []
        if menItems > 0 { parts.append("\(menItems) Men's pieces") }
        if menWishlist > 0 { parts.append("\(menWishlist) Men's wishlist") }
        if womenItems > 0 { parts.append("\(womenItems) Women's pieces") }
        if womenWishlist > 0 { parts.append("\(womenWishlist) Women's wishlist") }
        if looksCount > 0 { parts.append("\(looksCount) outfits/looks") }
        if tripsCount > 0 { parts.append("\(tripsCount) trip plans") }

        if parts.isEmpty {
            return "No items to import."
        }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Unified Archive (Men & Women)
public struct AtelierUnifiedBackup: Codable {
    public var format: String = "AtelierUnifiedBackup"
    public var version: Int = 2
    public var exportDate: Date = Date()
    public var appName: String = "Atelier"

    // Men's collection
    public var menItems: [WardrobeItem]?
    public var menWishlist: [WishlistItem]?
    public var menLooks: [CuratedLook]?
    public var menTripPlans: [TripPlan]?

    // Women's collection
    public var womenItems: [WomenWardrobeItem]?
    public var womenWishlist: [WomenWishlistItem]?
    public var womenLooks: [WomenCuratedLook]?
    public var womenTrips: [WomenTripPlan]?

    public init(
        menItems: [WardrobeItem]? = nil,
        menWishlist: [WishlistItem]? = nil,
        menLooks: [CuratedLook]? = nil,
        menTripPlans: [TripPlan]? = nil,
        womenItems: [WomenWardrobeItem]? = nil,
        womenWishlist: [WomenWishlistItem]? = nil,
        womenLooks: [WomenCuratedLook]? = nil,
        womenTrips: [WomenTripPlan]? = nil
    ) {
        self.menItems = menItems
        self.menWishlist = menWishlist
        self.menLooks = menLooks
        self.menTripPlans = menTripPlans
        self.womenItems = womenItems
        self.womenWishlist = womenWishlist
        self.womenLooks = womenLooks
        self.womenTrips = womenTrips
    }
}

// MARK: - Men's Standalone Archive
public struct AtelierBackup: Codable {
    public var format: String = "AtelierMenBackup"
    public var version: Int = 1
    public var exportDate: Date = Date()
    public var items: [WardrobeItem]
    public var wishlistItems: [WishlistItem]
    public var looks: [CuratedLook]
    public var tripPlans: [TripPlan]

    public init(
        format: String = "AtelierMenBackup",
        version: Int = 1,
        exportDate: Date = Date(),
        items: [WardrobeItem],
        wishlistItems: [WishlistItem] = [],
        looks: [CuratedLook] = [],
        tripPlans: [TripPlan] = []
    ) {
        self.format = format
        self.version = version
        self.exportDate = exportDate
        self.items = items
        self.wishlistItems = wishlistItems
        self.looks = looks
        self.tripPlans = tripPlans
    }

    enum CodingKeys: String, CodingKey {
        case format, version, exportDate, items, wishlistItems, looks, tripPlans
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.format = try container.decodeIfPresent(String.self, forKey: .format) ?? "AtelierMenBackup"
        self.version = try container.decodeIfPresent(Int.self, forKey: .version) ?? 1
        self.exportDate = try container.decodeIfPresent(Date.self, forKey: .exportDate) ?? Date()
        self.items = try container.decodeIfPresent([WardrobeItem].self, forKey: .items) ?? []
        self.wishlistItems = try container.decodeIfPresent([WishlistItem].self, forKey: .wishlistItems) ?? []
        self.looks = try container.decodeIfPresent([CuratedLook].self, forKey: .looks) ?? []
        self.tripPlans = try container.decodeIfPresent([TripPlan].self, forKey: .tripPlans) ?? []
    }
}

// MARK: - Women's Standalone Archive
public struct WomenAtelierBackup: Codable {
    public var format: String = "AtelierWomenBackup"
    public var version: Int = 1
    public var exportDate: Date = Date()
    public var items: [WomenWardrobeItem]
    public var wishlistItems: [WomenWishlistItem]
    public var looks: [WomenCuratedLook]
    public var trips: [WomenTripPlan]

    public init(
        format: String = "AtelierWomenBackup",
        version: Int = 1,
        exportDate: Date = Date(),
        items: [WomenWardrobeItem],
        wishlistItems: [WomenWishlistItem] = [],
        looks: [WomenCuratedLook] = [],
        trips: [WomenTripPlan] = []
    ) {
        self.format = format
        self.version = version
        self.exportDate = exportDate
        self.items = items
        self.wishlistItems = wishlistItems
        self.looks = looks
        self.trips = trips
    }

    enum CodingKeys: String, CodingKey {
        case format, version, exportDate, items, wishlistItems, looks, trips
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.format = try container.decodeIfPresent(String.self, forKey: .format) ?? "AtelierWomenBackup"
        self.version = try container.decodeIfPresent(Int.self, forKey: .version) ?? 1
        self.exportDate = try container.decodeIfPresent(Date.self, forKey: .exportDate) ?? Date()
        self.items = try container.decodeIfPresent([WomenWardrobeItem].self, forKey: .items) ?? []
        self.wishlistItems = try container.decodeIfPresent([WomenWishlistItem].self, forKey: .wishlistItems) ?? []
        self.looks = try container.decodeIfPresent([WomenCuratedLook].self, forKey: .looks) ?? []
        self.trips = try container.decodeIfPresent([WomenTripPlan].self, forKey: .trips) ?? []
    }
}
