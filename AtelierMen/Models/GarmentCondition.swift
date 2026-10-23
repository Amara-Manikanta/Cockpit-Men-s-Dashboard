import Foundation
import SwiftUI

public enum GarmentCondition: String, Codable, CaseIterable, Identifiable {
    case brandNew = "New"
    case medium = "Medium"
    case old = "Old"
    case faded = "Faded"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .brandNew: return "New"
        case .medium: return "Medium"
        case .old: return "Old"
        case .faded: return "Faded"
        }
    }

    public var badgeText: String {
        switch self {
        case .brandNew: return "✨ NEW"
        case .medium: return "👌 MEDIUM"
        case .old: return "⏳ OLD"
        case .faded: return "🧺 FADED"
        }
    }

    public var iconName: String {
        switch self {
        case .brandNew: return "sparkles"
        case .medium: return "hand.thumbsup.fill"
        case .old: return "clock.arrow.circlepath"
        case .faded: return "sun.dust.fill"
        }
    }

    public var color: Color {
        switch self {
        case .brandNew: return Color(red: 0.15, green: 0.82, blue: 0.55) // Emerald
        case .medium: return Color(red: 0.25, green: 0.55, blue: 0.98) // Royal Sky Blue
        case .old: return Color(red: 0.96, green: 0.58, blue: 0.19) // Amber Warning
        case .faded: return Color(red: 0.90, green: 0.38, blue: 0.38) // Dusty Coral / Faded Red
        }
    }

    public var description: String {
        switch self {
        case .brandNew: return "Pristine & fresh, like-new condition"
        case .medium: return "Gently worn, strong fabric & color"
        case .old: return "Well-worn, aged piece from frequent use"
        case .faded: return "Faded colors or distressed fabric texture"
        }
    }

    public var wearRecommendation: String {
        switch self {
        case .brandNew:
            return "In prime condition. Ideal for formal events, meetings, and standout occasions."
        case .medium:
            return "Balanced rotation. Fabric and colors remain strong for everyday office and smart casual wear."
        case .old:
            return "This item is showing clear signs of aging. Best rotated into casual weekend or home wear."
        case .faded:
            return "Noticeable fading or softening. Consider retiring from public rotation or repurposing as loungewear."
        }
    }

    public var isOldOrFaded: Bool {
        return self == .old || self == .faded
    }

    /// Automatic calculation based on wear count when user leaves on Auto
    public static func calculateFromWearCount(_ wears: Int) -> GarmentCondition {
        switch wears {
        case 0...5:
            return .brandNew
        case 6...25:
            return .medium
        case 26...50:
            return .old
        default:
            return .faded
        }
    }

    /// Lifecycle progress ratio towards typical garment wear limit (default 50 wears)
    public static func wearProgressRatio(_ wears: Int, targetLifetime: Int = 50) -> Double {
        return min(1.0, max(0.0, Double(wears) / Double(targetLifetime)))
    }
}
