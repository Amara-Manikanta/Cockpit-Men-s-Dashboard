import Foundation

public struct PackingItem: Identifiable, Codable {
    public var id: UUID
    public var title: String
    public var category: ItemCategory?
    public var linkedWardrobeItemId: UUID?
    public var isPacked: Bool

    public init(
        id: UUID = UUID(),
        title: String,
        category: ItemCategory? = nil,
        linkedWardrobeItemId: UUID? = nil,
        isPacked: Bool = false
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.linkedWardrobeItemId = linkedWardrobeItemId
        self.isPacked = isPacked
    }
}

public struct TripPlan: Identifiable, Codable {
    public var id: UUID
    public var destination: String
    public var purpose: String
    public var durationDays: Int
    public var items: [PackingItem]

    public init(
        id: UUID = UUID(),
        destination: String,
        purpose: String,
        durationDays: Int = 3,
        items: [PackingItem] = []
    ) {
        self.id = id
        self.destination = destination
        self.purpose = purpose
        self.durationDays = durationDays
        self.items = items
    }

    public var packedCount: Int {
        items.filter { $0.isPacked }.count
    }

    public var totalCount: Int {
        items.count
    }

    public var progress: Double {
        totalCount == 0 ? 0.0 : Double(packedCount) / Double(totalCount)
    }
}
