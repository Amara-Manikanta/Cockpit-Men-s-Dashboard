import SwiftUI

public enum RepeatWearStatus: Equatable {
    case wornToday
    case wornYesterday
    case wornRecently(daysAgo: Int)
    case frequentlyWorn
    case balancedRotation(daysAgo: Int)
    case longTimeUnworn(daysAgo: Int)
    case neverWorn

    public static func calculate(timesWorn: Int, lastWornDate: Date?) -> RepeatWearStatus {
        guard let last = lastWornDate else {
            return .neverWorn
        }
        let calendar = Calendar.current
        let startLast = calendar.startOfDay(for: last)
        let startToday = calendar.startOfDay(for: Date())
        let daysAgo = calendar.dateComponents([.day], from: startLast, to: startToday).day ?? 999

        if daysAgo <= 0 {
            return .wornToday
        } else if daysAgo == 1 {
            return .wornYesterday
        } else if daysAgo <= 3 {
            return .wornRecently(daysAgo: daysAgo)
        } else if timesWorn >= 15 {
            return .frequentlyWorn
        } else if daysAgo >= 30 {
            return .longTimeUnworn(daysAgo: daysAgo)
        } else {
            return .balancedRotation(daysAgo: daysAgo)
        }
    }

    public var isRepeatWarning: Bool {
        switch self {
        case .wornToday, .wornYesterday, .wornRecently:
            return true
        default:
            return false
        }
    }

    public var badgeText: String {
        switch self {
        case .wornToday:
            return "🔁 WORN TODAY"
        case .wornYesterday:
            return "⚠️ WORN YESTERDAY"
        case .wornRecently(let days):
            return "⚠️ WORN \(days)D AGO"
        case .frequentlyWorn:
            return "🔥 HIGH REPEAT"
        case .balancedRotation:
            return "✨ FRESH ROTATION"
        case .longTimeUnworn:
            return "💎 CLOSET GEM"
        case .neverWorn:
            return "🆕 UNWORN"
        }
    }

    public var shortLabel: String {
        switch self {
        case .wornToday:
            return "Worn Today"
        case .wornYesterday:
            return "Worn Yesterday"
        case .wornRecently(let days):
            return "\(days) days ago"
        case .frequentlyWorn:
            return "High Repeat"
        case .balancedRotation(let days):
            return "\(days)d ago"
        case .longTimeUnworn(let days):
            return "\(days)d ago"
        case .neverWorn:
            return "Never"
        }
    }

    public var warningBannerMessage: String? {
        switch self {
        case .wornToday:
            return "You already wore this piece today! Consider rotating to maintain garment freshness."
        case .wornYesterday:
            return "Repeated Wear Notice: You wore this yesterday! Rotating clothes allows fabrics to rest and keeps your style diverse."
        case .wornRecently(let days):
            return "Repeated Wear Notice: You wore this just \(days) days ago. Consider wearing an alternative from your collection!"
        case .frequentlyWorn:
            return "High Wear Frequency: This piece has been worn over 15 times. Great value, but consider rotating with less-worn pieces!"
        default:
            return nil
        }
    }

    public var color: Color {
        switch self {
        case .wornToday:
            return Color.orange
        case .wornYesterday, .wornRecently:
            return Color(red: 0.95, green: 0.35, blue: 0.35)
        case .frequentlyWorn:
            return Color(red: 0.95, green: 0.65, blue: 0.20)
        case .balancedRotation:
            return Color(red: 0.35, green: 0.78, blue: 0.55)
        case .longTimeUnworn:
            return Color(red: 0.40, green: 0.65, blue: 0.95)
        case .neverWorn:
            return Color(red: 0.75, green: 0.55, blue: 0.90)
        }
    }

    public var iconName: String {
        switch self {
        case .wornToday:
            return "arrow.triangle.2.circlepath"
        case .wornYesterday, .wornRecently:
            return "exclamationmark.triangle.fill"
        case .frequentlyWorn:
            return "flame.fill"
        case .balancedRotation:
            return "sparkles"
        case .longTimeUnworn:
            return "diamond.fill"
        case .neverWorn:
            return "tag.fill"
        }
    }
}
