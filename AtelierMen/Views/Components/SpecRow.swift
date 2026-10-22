import SwiftUI

public struct SpecRow: View {
    public let icon: String
    public let label: String
    public let value: String
    public var accentColor: Color = LuxuryTheme.gold

    public init(icon: String, label: String, value: String, accentColor: Color = LuxuryTheme.gold) {
        self.icon = icon
        self.label = label
        self.value = value
        self.accentColor = accentColor
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(accentColor)
                .frame(width: 22)

            Text(label)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(LuxuryTheme.textSecondary)

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(LuxuryTheme.textPrimary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 6)
    }
}
