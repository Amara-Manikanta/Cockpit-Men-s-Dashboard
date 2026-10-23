import SwiftUI

public struct StarRatingView: View {
    @Binding var rating: Int
    var maxRating: Int = 5
    var title: String
    var subtitle: String = ""
    var starColor: Color = LuxuryTheme.gold
    var interactive: Bool = true
    var size: CGFloat = 22

    public init(
        rating: Binding<Int>,
        maxRating: Int = 5,
        title: String,
        subtitle: String = "",
        starColor: Color = LuxuryTheme.gold,
        interactive: Bool = true,
        size: CGFloat = 22
    ) {
        self._rating = rating
        self.maxRating = maxRating
        self.title = title
        self.subtitle = subtitle
        self.starColor = starColor
        self.interactive = interactive
        self.size = size
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(LuxuryTheme.textPrimary)

                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(LuxuryTheme.textTertiary)
                }

                Spacer()

                if rating > 0 {
                    HStack(spacing: 3) {
                        Text("\(rating)")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                        Text("/ 5")
                            .font(.system(size: 11, weight: .medium))
                            .opacity(0.7)
                    }
                    .foregroundStyle(starColor)
                } else {
                    Text("Tap to rate")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(LuxuryTheme.textTertiary)
                }
            }

            HStack(spacing: 10) {
                ForEach(1...maxRating, id: \.self) { star in
                    Button {
                        guard interactive else { return }
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        if rating == star {
                            rating = 0
                        } else {
                            rating = star
                        }
                    } label: {
                        Image(systemName: star <= rating ? "star.fill" : "star")
                            .font(.system(size: size))
                            .foregroundStyle(star <= rating ? starColor : Color.white.opacity(0.2))
                            .scaleEffect(star <= rating ? 1.05 : 1.0)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
