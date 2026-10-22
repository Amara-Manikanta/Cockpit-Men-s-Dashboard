import Foundation

public enum WishlistPriority: String, CaseIterable, Codable, Identifiable {
    case high = "High Priority"
    case medium = "Medium"
    case low = "Low"

    public var id: String { rawValue }

    public var badgeLabel: String {
        switch self {
        case .high: return "🔥 High"
        case .medium: return "⭐ Medium"
        case .low: return "💭 Someday"
        }
    }
}

public struct WishlistItem: Identifiable, Codable, Equatable {
    public var id: UUID
    public var name: String
    public var brand: String
    public var category: ItemCategory
    public var targetPrice: Double
    public var photos: [String]
    public var storeUrl: String
    public var priority: WishlistPriority
    public var notes: String
    public var dateAdded: Date

    public init(
        id: UUID = UUID(),
        name: String,
        brand: String,
        category: ItemCategory,
        targetPrice: Double = 0.0,
        photos: [String] = [],
        storeUrl: String = "",
        priority: WishlistPriority = .medium,
        notes: String = "",
        dateAdded: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.category = category
        self.targetPrice = targetPrice
        self.photos = photos
        self.storeUrl = storeUrl
        self.priority = priority
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
}
