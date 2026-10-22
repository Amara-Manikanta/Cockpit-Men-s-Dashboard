import Foundation

public struct CuratedLook: Identifiable, Codable {
    public var id: UUID
    public var title: String
    public var occasion: String
    public var description: String
    public var clothesItemIds: [UUID]
    public var shoesItemIds: [UUID]
    public var electronicsItemIds: [UUID]
    public var tags: [String]
    public var coverSymbol: String

    public init(
        id: UUID = UUID(),
        title: String,
        occasion: String,
        description: String,
        clothesItemIds: [UUID] = [],
        shoesItemIds: [UUID] = [],
        electronicsItemIds: [UUID] = [],
        tags: [String] = [],
        coverSymbol: String = "suit.fill"
    ) {
        self.id = id
        self.title = title
        self.occasion = occasion
        self.description = description
        self.clothesItemIds = clothesItemIds
        self.shoesItemIds = shoesItemIds
        self.electronicsItemIds = electronicsItemIds
        self.tags = tags
        self.coverSymbol = coverSymbol
    }
}
