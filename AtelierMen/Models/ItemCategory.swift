import SwiftUI

public enum ItemCategory: String, CaseIterable, Codable, Identifiable {
    case electronics = "Electronics"
    case clothes = "Clothes"
    case sportswear = "Sports Wear"
    case shoes = "Shoes"
    case bags = "Bags"
    case grooming = "Grooming"
    case accessories = "Accessories"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .electronics: return "laptopcomputer.and.iphone"
        case .clothes: return "tshirt.fill"
        case .sportswear: return "figure.run"
        case .shoes: return "shoe.fill"
        case .bags: return "briefcase.fill"
        case .grooming: return "drop.fill"
        case .accessories: return "eyeglasses"
        }
    }

    public var luxuryTag: String {
        switch self {
        case .electronics: return "Tech & EDC"
        case .clothes: return "Tailoring & Apparel"
        case .sportswear: return "Performance & Activewear"
        case .shoes: return "Footwear"
        case .bags: return "Leather & Luggage"
        case .grooming: return "Grooming & Cologne"
        case .accessories: return "Men's Accessories"
        }
    }

    // Masculine, executive category accents
    public var accentColor: Color {
        switch self {
        case .electronics:
            return Color(red: 0.22, green: 0.65, blue: 0.95) // Precision Ice / Electric Blue
        case .clothes:
            return Color(red: 0.85, green: 0.72, blue: 0.52) // Tailored Camel / Muted Sand Khaki
        case .sportswear:
            return Color(red: 0.94, green: 0.38, blue: 0.24) // Performance Crimson Volt / Energetic Ember
        case .shoes:
            return Color(red: 0.82, green: 0.48, blue: 0.28) // Burnished Cognac / Saddle Leather
        case .bags:
            return Color(red: 0.74, green: 0.52, blue: 0.36) // Oxford Bridle Leather / Umber
        case .grooming:
            return Color(red: 0.36, green: 0.68, blue: 0.52) // British Racing Pine / Fresh Sage
        case .accessories:
            return Color(red: 0.78, green: 0.70, blue: 0.58) // Brushed Titanium / Champagne Steel
        }
    }

    public var defaultSubcategories: [String] {
        switch self {
        case .electronics:
            return [
                "Laptops & Computing",
                "Audio & Acoustics",
                "Watches & Wearables",
                "Cameras & Optics",
                "Phones & Tablets",
                "EDC & Accessories"
            ]
        case .clothes:
            return [
                "Suits & Blazers",
                "Shirts & Polos",
                "Jackets & Outerwear",
                "T-Shirts & Knits",
                "Trousers & Chinos",
                "Denim & Jeans"
            ]
        case .sportswear:
            return [
                "Gym & Training Apparel",
                "Running & Marathon Gear",
                "Performance Hoodies & Tracksuits",
                "Athletic Shorts & Joggers",
                "Compression & Base Layers",
                "Sports Jerseys & Kits",
                "Outdoor & Trail Activewear"
            ]
        case .shoes:
            return [
                "Sneakers & Streetwear",
                "Formal Oxfords & Derbies",
                "Loafers & Slip-ons",
                "Boots & Heritage",
                "Casual & Slides"
            ]
        case .bags:
            return [
                "Briefcases & Work Bags",
                "Weekender Duffels",
                "Backpacks & Slings",
                "Carry-On Luggage & Cases",
                "Dopp Kits & Wash Bags",
                "Totes & Messengers"
            ]
        case .grooming:
            return [
                "Fragrances & Colognes",
                "Face & Skincare Serums",
                "Shaving & Beard Care",
                "Hair Styling & Pomades",
                "Body & Shower Essentials",
                "Grooming Tools & Trimmers"
            ]
        case .accessories:
            return [
                "Wallets & Cardholders",
                "Belts & Leather Goods",
                "Sunglasses & Eyewear",
                "Cufflinks & Tie Clips",
                "Hats & Caps",
                "Scarves & Pocket Squares"
            ]
        }
    }
}
