import SwiftUI

public struct WomenLuxuryTheme {
    // Deep Midnight Plum & Velvet Obsidian
    public static let background = Color(red: 0.063, green: 0.039, blue: 0.055)          // #100A0E - Deep Velvet Noir
    public static let secondaryBackground = Color(red: 0.094, green: 0.059, blue: 0.082) // #180F15 - Deep Amethyst Noir
    public static let cardBackground = Color(red: 0.125, green: 0.075, blue: 0.106)      // #20131B - Velvet Rosewood
    public static let cardBorder = Color(red: 0.239, green: 0.133, blue: 0.196)          // #3D2232 - Antique Rose Border

    // Haute Couture Accents
    public static let roseGold = Color(red: 0.90, green: 0.60, blue: 0.62)               // #E5989B - Lustrous Rose Gold
    public static let roseGoldDeep = Color(red: 0.71, green: 0.40, blue: 0.46)           // #B56576 - Rich Rose Gold
    public static let champagne = Color(red: 0.85, green: 0.68, blue: 0.28)              // #D4AF37 - 22K Royal Champagne Gold
    public static let blushCoral = Color(red: 0.95, green: 0.58, blue: 0.52)             // Soft Blush Coral
    public static let emeraldGreen = Color(red: 0.28, green: 0.72, blue: 0.58)           // Emerald Jewel Green

    // Typography & Contrast
    public static let textPrimary = Color(red: 0.98, green: 0.96, blue: 0.97)            // #FAFAFA - Crisp Pearl White
    public static let textSecondary = Color(red: 0.80, green: 0.70, blue: 0.75)          // #CCB3BF - Soft Rose Silver
    public static let textTertiary = Color(red: 0.54, green: 0.44, blue: 0.50)           // #8A7080 - Muted Plum Grey
}

public struct WomenLuxuryCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 16

    public func body(content: Content) -> some View {
        content
            .background(WomenLuxuryTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(WomenLuxuryTheme.cardBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.4), radius: 10, x: 0, y: 5)
    }
}

public extension View {
    func womenLuxuryCardStyle(cornerRadius: CGFloat = 16) -> some View {
        self.modifier(WomenLuxuryCardModifier(cornerRadius: cornerRadius))
    }
}

public struct WomenItemImageView: View {
    public let photoNameOrUrl: String
    public let category: WomenCategory
    public var contentMode: ContentMode = .fill

    public init(photoNameOrUrl: String, category: WomenCategory, contentMode: ContentMode = .fill) {
        self.photoNameOrUrl = photoNameOrUrl
        self.category = category
        self.contentMode = contentMode
    }

    public var body: some View {
        Group {
            if photoNameOrUrl.isEmpty {
                placeholderView
            } else if let localUrl = ImageManager.shared.localImageUrl(for: photoNameOrUrl),
                      let data = try? Data(contentsOf: localUrl),
                      let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .clipped()
            } else if photoNameOrUrl.hasPrefix("http://") || photoNameOrUrl.hasPrefix("https://") {
                AsyncImage(url: URL(string: photoNameOrUrl)) { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            placeholderView
                            ProgressView()
                                .tint(category.accentColor)
                        }
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: contentMode)
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                            .clipped()
                    case .failure:
                        placeholderView
                    @unknown default:
                        placeholderView
                    }
                }
            } else if UIImage(systemName: photoNameOrUrl) != nil {
                ZStack {
                    LinearGradient(
                        colors: [WomenLuxuryTheme.cardBackground, WomenLuxuryTheme.secondaryBackground],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: photoNameOrUrl)
                        .font(.system(size: 38, weight: .light))
                        .foregroundStyle(category.accentColor)
                }
            } else {
                placeholderView
            }
        }
    }

    private var placeholderView: some View {
        ZStack {
            LinearGradient(
                colors: [WomenLuxuryTheme.cardBackground, WomenLuxuryTheme.secondaryBackground],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            VStack(spacing: 6) {
                Image(systemName: category.iconName)
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(category.accentColor.opacity(0.9))
                Text(category.rawValue.uppercased())
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(WomenLuxuryTheme.textTertiary)
            }
        }
    }
}
