import SwiftUI

public struct LuxuryTheme {
    // Deep stealth masculine foundations (Obsidian & Carbon)
    public static let background = Color(red: 0.047, green: 0.059, blue: 0.078)          // #0C0F14 - Deep Stealth Obsidian
    public static let secondaryBackground = Color(red: 0.082, green: 0.106, blue: 0.141) // #151B24 - Gunmetal Slate
    public static let cardBackground = Color(red: 0.098, green: 0.125, blue: 0.165)      // #19202A - Precision Charcoal
    public static let cardBorder = Color(red: 0.165, green: 0.208, blue: 0.275)          // #2A3546 - Milled Steel Border

    // Masculine Statement Accents
    public static let accentAmber = Color(red: 0.88, green: 0.58, blue: 0.30)            // #E0944D - Warm Horween / Cognac Saddle
    public static let titanium = Color(red: 0.70, green: 0.76, blue: 0.84)               // #B3C2D7 - Brushed Aerospace Titanium
    public static let cyberBlue = Color(red: 0.22, green: 0.65, blue: 0.95)              // #38A6F3 - Precision Cyan / Electric Ice
    public static let racingGreen = Color(red: 0.20, green: 0.58, blue: 0.42)            // #33946B - British Racing Green

    // High Contrast Typography
    public static let textPrimary = Color(red: 0.96, green: 0.97, blue: 0.98)            // #F5F7FA - Crisp Titanium White
    public static let textSecondary = Color(red: 0.65, green: 0.72, blue: 0.80)          // #A6B8CC - Matte Slate Silver
    public static let textTertiary = Color(red: 0.42, green: 0.48, blue: 0.56)           // #6B7A8F - Subtle Muted Gunmetal

    // Backwards-compatible alias for existing code
    public static var gold: Color { accentAmber }
}

public struct LuxuryCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 14

    public func body(content: Content) -> some View {
        content
            .background(LuxuryTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(LuxuryTheme.cardBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.45), radius: 8, x: 0, y: 4)
    }
}

public extension View {
    func luxuryCardStyle(cornerRadius: CGFloat = 14) -> some View {
        self.modifier(LuxuryCardModifier(cornerRadius: cornerRadius))
    }
}
