import SwiftUI

@MainActor
public final class DataStore: ObservableObject {
    @Published public var items: [WardrobeItem] = []
    @Published public var wishlistItems: [WishlistItem] = []
    @Published public var looks: [CuratedLook] = []
    @Published public var tripPlans: [TripPlan] = []

    private var itemsFileUrl: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("wardrobe_items.json")
    }

    private var backupItemsFileUrl: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("wardrobe_items_backup.json")
    }

    private var wishlistFileUrl: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("wishlist_items.json")
    }

    private var backupWishlistFileUrl: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("wishlist_items_backup.json")
    }

    private var looksFileUrl: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("curated_looks.json")
    }

    private var tripsFileUrl: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("trip_plans.json")
    }

    public init() {
        loadData()
    }

    // MARK: - Portfolio Metrics
    public var totalValuation: Double {
        items.reduce(0) { $0 + $1.price }
    }

    public var formattedTotalValuation: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₹"
        formatter.maximumFractionDigits = 0
        formatter.locale = Locale(identifier: "en_IN")
        return formatter.string(from: NSNumber(value: totalValuation)) ?? "₹\(Int(totalValuation))"
    }

    public func valuation(for category: ItemCategory) -> Double {
        items.filter { $0.category == category }.reduce(0) { $0 + $1.price }
    }

    public func formattedValuation(for category: ItemCategory) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₹"
        formatter.maximumFractionDigits = 0
        formatter.locale = Locale(identifier: "en_IN")
        return formatter.string(from: NSNumber(value: valuation(for: category))) ?? "₹0"
    }

    public func itemCount(for category: ItemCategory) -> Int {
        items.filter { $0.category == category }.count
    }

    // MARK: - Wishlist Valuation
    public var totalWishlistValuation: Double {
        wishlistItems.reduce(0) { $0 + $1.targetPrice }
    }

    public var formattedWishlistValuation: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₹"
        formatter.maximumFractionDigits = 0
        formatter.locale = Locale(identifier: "en_IN")
        return formatter.string(from: NSNumber(value: totalWishlistValuation)) ?? "₹\(Int(totalWishlistValuation))"
    }

    // MARK: - Wardrobe CRUD & Duplicate Handling
    public func isDuplicateItem(_ item: WardrobeItem) -> WardrobeItem? {
        let cleanName = item.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let cleanBrand = item.brand.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !cleanName.isEmpty else { return nil }

        return items.first { existing in
            if existing.id == item.id { return false }
            let exName = existing.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let exBrand = existing.brand.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

            // 1. Exact match on clean name, brand & category
            if exName == cleanName && exBrand == cleanBrand && existing.category == item.category {
                return true
            }

            // 2. Same source URL in notes if imported from web
            if !item.notes.isEmpty && !existing.notes.isEmpty {
                if let url1 = extractFirstUrl(from: item.notes),
                   let url2 = extractFirstUrl(from: existing.notes),
                   url1 == url2 {
                    return true
                }
            }
            return false
        }
    }

    @discardableResult
    public func addItem(_ item: WardrobeItem, ignoreDuplicates: Bool = true) -> Bool {
        if ignoreDuplicates, let duplicate = isDuplicateItem(item) {
            // Merge photos and specs into existing duplicate item
            if let idx = items.firstIndex(where: { $0.id == duplicate.id }) {
                var updated = items[idx]
                for p in item.photos where !updated.photos.contains(p) {
                    updated.photos.append(p)
                }
                if updated.price == 0 && item.price > 0 { updated.price = item.price }
                if updated.size.isEmpty && !item.size.isEmpty { updated.size = item.size }
                if updated.shoeSize.isEmpty && !item.shoeSize.isEmpty { updated.shoeSize = item.shoeSize }
                if updated.fabricMaterial.isEmpty && !item.fabricMaterial.isEmpty { updated.fabricMaterial = item.fabricMaterial }
                items[idx] = updated
                saveItems()
            }
            return false
        }

        items.insert(item, at: 0)
        saveItems()
        return true
    }

    public func updateItem(_ item: WardrobeItem) {
        if let idx = items.firstIndex(where: { $0.id == item.id }) {
            items[idx] = item
            saveItems()
        }
    }

    public func deleteItem(_ item: WardrobeItem) {
        items.removeAll { $0.id == item.id }
        saveItems()
    }

    public func deleteItems(ids: Set<UUID>) {
        items.removeAll { ids.contains($0.id) }
        saveItems()
    }

    @discardableResult
    public func removeDuplicates() -> Int {
        var unique: [WardrobeItem] = []
        var removed = 0

        for item in items {
            let cleanName = item.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            let cleanBrand = item.brand.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

            if let existingIdx = unique.firstIndex(where: { u in
                let uName = u.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                let uBrand = u.brand.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                if uName == cleanName && uBrand == cleanBrand { return true }
                if !cleanBrand.isEmpty && uBrand == cleanBrand && (uName.contains(cleanName) || cleanName.contains(uName)) && u.category == item.category {
                    return true
                }
                return false
            }) {
                for p in item.photos where !unique[existingIdx].photos.contains(p) {
                    unique[existingIdx].photos.append(p)
                }
                removed += 1
            } else {
                unique.append(item)
            }
        }

        if removed > 0 {
            self.items = unique
            saveItems()
        }
        return removed
    }

    public func toggleFavorite(for item: WardrobeItem) {
        if let idx = items.firstIndex(where: { $0.id == item.id }) {
            items[idx].isFavorite.toggle()
            saveItems()
        }
    }

    // MARK: - Wishlist CRUD & Duplicate Handling
    public func isDuplicateWishlistItem(_ item: WishlistItem) -> WishlistItem? {
        let cleanName = item.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let cleanBrand = item.brand.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !cleanName.isEmpty else { return nil }

        return wishlistItems.first { existing in
            if existing.id == item.id { return false }
            let exName = existing.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let exBrand = existing.brand.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if exName == cleanName && exBrand == cleanBrand && existing.category == item.category { return true }
            if !item.storeUrl.isEmpty && item.storeUrl == existing.storeUrl {
                return true
            }
            return false
        }
    }

    @discardableResult
    public func addWishlistItem(_ item: WishlistItem, ignoreDuplicates: Bool = true) -> Bool {
        if ignoreDuplicates, let duplicate = isDuplicateWishlistItem(item) {
            if let idx = wishlistItems.firstIndex(where: { $0.id == duplicate.id }) {
                var updated = wishlistItems[idx]
                for p in item.photos where !updated.photos.contains(p) {
                    updated.photos.append(p)
                }
                if updated.targetPrice == 0 && item.targetPrice > 0 { updated.targetPrice = item.targetPrice }
                wishlistItems[idx] = updated
                saveWishlist()
            }
            return false
        }

        wishlistItems.insert(item, at: 0)
        saveWishlist()
        return true
    }

    public func updateWishlistItem(_ item: WishlistItem) {
        if let idx = wishlistItems.firstIndex(where: { $0.id == item.id }) {
            wishlistItems[idx] = item
            saveWishlist()
        }
    }

    public func deleteWishlistItem(_ item: WishlistItem) {
        wishlistItems.removeAll { $0.id == item.id }
        saveWishlist()
    }

    public func deleteWishlistItems(ids: Set<UUID>) {
        wishlistItems.removeAll { ids.contains($0.id) }
        saveWishlist()
    }

    @discardableResult
    public func removeWishlistDuplicates() -> Int {
        var unique: [WishlistItem] = []
        var removed = 0

        for item in wishlistItems {
            let cleanName = item.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            let cleanBrand = item.brand.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            if let existingIdx = unique.firstIndex(where: { u in
                let uName = u.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                let uBrand = u.brand.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                return (uName == cleanName && uBrand == cleanBrand) ||
                       (!cleanBrand.isEmpty && uBrand == cleanBrand && (uName.contains(cleanName) || cleanName.contains(uName)))
            }) {
                for p in item.photos where !unique[existingIdx].photos.contains(p) {
                    unique[existingIdx].photos.append(p)
                }
                removed += 1
            } else {
                unique.append(item)
            }
        }

        if removed > 0 {
            self.wishlistItems = unique
            saveWishlist()
        }
        return removed
    }

    private func extractFirstUrl(from text: String) -> String? {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        return matches?.first?.url?.absoluteString
    }

    public func moveToVault(wishlistItem: WishlistItem, storageLocation: String = "Main Closet") {
        let wardrobeItem = WardrobeItem(
            name: wishlistItem.name,
            brand: wishlistItem.brand,
            category: wishlistItem.category,
            price: wishlistItem.targetPrice,
            photos: wishlistItem.photos,
            storageLocation: storageLocation,
            notes: wishlistItem.notes.isEmpty ? "Purchased from Wishlist: \(wishlistItem.storeUrl)" : wishlistItem.notes
        )
        addItem(wardrobeItem)
        deleteWishlistItem(wishlistItem)
    }

    public func addLook(_ look: CuratedLook) {
        looks.insert(look, at: 0)
        saveLooks()
    }

    public func togglePackingItem(tripId: UUID, itemId: UUID) {
        if let tIdx = tripPlans.firstIndex(where: { $0.id == tripId }),
           let iIdx = tripPlans[tIdx].items.firstIndex(where: { $0.id == itemId }) {
            tripPlans[tIdx].items[iIdx].isPacked.toggle()
            saveTrips()
        }
    }

    public func addTripPlan(_ plan: TripPlan) {
        tripPlans.insert(plan, at: 0)
        saveTrips()
    }

    public func deleteTripPlan(id: UUID) {
        tripPlans.removeAll { $0.id == id }
        saveTrips()
    }

    public func deleteTripPlan(_ plan: TripPlan) {
        tripPlans.removeAll { $0.id == plan.id }
        saveTrips()
    }

    public func addPackingItem(tripId: UUID, item: PackingItem) {
        if let idx = tripPlans.firstIndex(where: { $0.id == tripId }) {
            tripPlans[idx].items.append(item)
            saveTrips()
        }
    }

    public func deletePackingItem(tripId: UUID, itemId: UUID) {
        if let tIdx = tripPlans.firstIndex(where: { $0.id == tripId }) {
            tripPlans[tIdx].items.removeAll { $0.id == itemId }
            saveTrips()
        }
    }

    public func markAllPacked(tripId: UUID, packed: Bool) {
        if let idx = tripPlans.firstIndex(where: { $0.id == tripId }) {
            for i in 0..<tripPlans[idx].items.count {
                tripPlans[idx].items[i].isPacked = packed
            }
            saveTrips()
        }
    }

    // MARK: - Persistence
    public func saveItems() {
        if let data = try? JSONEncoder().encode(items) {
            try? data.write(to: itemsFileUrl, options: .atomic)
            try? data.write(to: backupItemsFileUrl, options: .atomic)

            // Persist to iOS Keychain (survives app deletion & reinstallation!)
            _ = KeychainHelper.shared.save(data: data, service: "com.amara.AtelierMen", account: "wardrobe_items")
        }
    }

    public func saveWishlist() {
        if let data = try? JSONEncoder().encode(wishlistItems) {
            try? data.write(to: wishlistFileUrl, options: .atomic)
            try? data.write(to: backupWishlistFileUrl, options: .atomic)

            // Persist to iOS Keychain (survives app deletion & reinstallation!)
            _ = KeychainHelper.shared.save(data: data, service: "com.amara.AtelierMen", account: "wishlist_items")
        }
    }

    public func saveLooks() {
        if let data = try? JSONEncoder().encode(looks) {
            try? data.write(to: looksFileUrl, options: .atomic)
        }
    }

    public func saveTrips() {
        if let data = try? JSONEncoder().encode(tripPlans) {
            try? data.write(to: tripsFileUrl, options: .atomic)
        }
    }

    private func loadData() {
        // Items: Priority-ordered fallback (NOT max-count).
        // User's saved data always wins. Bundle is ONLY for fresh installs.
        // 1. Documents primary  →  2. Documents backup  →  3. iOS Keychain  →  4. Bundle default  →  5. Seed
        if let data = try? Data(contentsOf: itemsFileUrl),
           let loaded = try? JSONDecoder().decode([WardrobeItem].self, from: data) {
            // Primary file exists (even if empty — that means user deleted everything intentionally)
            self.items = loaded
        } else if let bData = try? Data(contentsOf: backupItemsFileUrl),
                  let loaded = try? JSONDecoder().decode([WardrobeItem].self, from: bData), !loaded.isEmpty {
            self.items = loaded
            saveItems() // Promote backup to primary
        } else if let kcData = KeychainHelper.shared.read(service: "com.amara.AtelierMen", account: "wardrobe_items"),
                  let loaded = try? JSONDecoder().decode([WardrobeItem].self, from: kcData), !loaded.isEmpty {
            // Keychain survives app reinstalls — use it on fresh install
            self.items = loaded
            saveItems()
        } else if let bundleUrl = Bundle.main.url(forResource: "default_wardrobe", withExtension: "json"),
                  let bData = try? Data(contentsOf: bundleUrl),
                  let loaded = try? JSONDecoder().decode([WardrobeItem].self, from: bData), !loaded.isEmpty {
            // First-ever install with no prior data — seed from bundle
            self.items = loaded
            saveItems()
        } else {
            self.items = SeedData.initialItems
            saveItems()
        }

        // Wishlist: Same priority-ordered fallback
        if let data = try? Data(contentsOf: wishlistFileUrl),
           let loaded = try? JSONDecoder().decode([WishlistItem].self, from: data) {
            self.wishlistItems = loaded
        } else if let bData = try? Data(contentsOf: backupWishlistFileUrl),
                  let loaded = try? JSONDecoder().decode([WishlistItem].self, from: bData), !loaded.isEmpty {
            self.wishlistItems = loaded
            saveWishlist()
        } else if let kcData = KeychainHelper.shared.read(service: "com.amara.AtelierMen", account: "wishlist_items"),
                  let loaded = try? JSONDecoder().decode([WishlistItem].self, from: kcData), !loaded.isEmpty {
            self.wishlistItems = loaded
            saveWishlist()
        } else if let bundleUrl = Bundle.main.url(forResource: "default_wishlist", withExtension: "json"),
                  let bData = try? Data(contentsOf: bundleUrl),
                  let loaded = try? JSONDecoder().decode([WishlistItem].self, from: bData), !loaded.isEmpty {
            self.wishlistItems = loaded
            saveWishlist()
        } else {
            self.wishlistItems = SeedData.initialWishlist
            saveWishlist()
        }

        // Looks
        if let data = try? Data(contentsOf: looksFileUrl),
           let loaded = try? JSONDecoder().decode([CuratedLook].self, from: data), !loaded.isEmpty {
            self.looks = loaded
        } else {
            self.looks = SeedData.initialLooks(from: self.items)
            saveLooks()
        }

        // Trips
        if let data = try? Data(contentsOf: tripsFileUrl),
           let loaded = try? JSONDecoder().decode([TripPlan].self, from: data), !loaded.isEmpty {
            self.tripPlans = loaded
        } else {
            self.tripPlans = SeedData.initialTrips(from: self.items)
            saveTrips()
        }
    }

    // MARK: - Export & Restore Backup
    public func generateBackupFile() -> URL? {
        let backup = AtelierBackup(items: items, wishlistItems: wishlistItems, looks: looks, tripPlans: tripPlans)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(backup) else { return nil }

        let tempUrl = FileManager.default.temporaryDirectory.appendingPathComponent("AtelierMen_Backup_\(Int(Date().timeIntervalSince1970)).json")
        do {
            try data.write(to: tempUrl)
            return tempUrl
        } catch {
            return nil
        }
    }

    public func restoreFromBackup(fileUrl: URL) -> (items: Int, wishlist: Int)? {
        let shouldStopAccessing = fileUrl.startAccessingSecurityScopedResource()
        defer {
            if shouldStopAccessing { fileUrl.stopAccessingSecurityScopedResource() }
        }

        guard let data = try? Data(contentsOf: fileUrl) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        if let backup = try? decoder.decode(AtelierBackup.self, from: data) {
            self.items = backup.items
            self.wishlistItems = backup.wishlistItems
            self.looks = backup.looks
            self.tripPlans = backup.tripPlans
            saveItems()
            saveWishlist()
            saveLooks()
            saveTrips()
            return (backup.items.count, backup.wishlistItems.count)
        }

        if let rawItems = try? decoder.decode([WardrobeItem].self, from: data) {
            self.items = rawItems
            saveItems()
            return (rawItems.count, 0)
        }

        return nil
    }
}

public struct AtelierBackup: Codable {
    public var version: Int = 1
    public var exportDate: Date = Date()
    public var items: [WardrobeItem]
    public var wishlistItems: [WishlistItem]
    public var looks: [CuratedLook]
    public var tripPlans: [TripPlan]
}

// MARK: - Seed Data
private struct SeedData {
    static let idMacBook = UUID()
    static let idSonyXM5 = UUID()
    static let idOmega = UUID()
    static let idLeica = UUID()

    static let idCanaliSuit = UUID()
    static let idRLShirt = UUID()
    static let idBarbourJacket = UUID()
    static let idSunspelTee = UUID()

    static let idCrockettOxfords = UUID()
    static let idCommonProjects = UUID()
    static let idSantoniLoafers = UUID()
    static let idRedWingBoots = UUID()

    static let idRimowaCabin = UUID()
    static let idBleuBag = UUID()
    static let idBellroyBackpack = UUID()

    static let idCreedAventus = UUID()
    static let idAesopSerum = UUID()
    static let idMuhleRazor = UUID()

    static let idMontblancWallet = UUID()
    static let idJMMGlasses = UUID()
    static let idHermesBelt = UUID()
    static let idTateossianCufflinks = UUID()

    static let idLululemonShirt = UUID()
    static let idNikeShorts = UUID()
    static let idArcteryxJacket = UUID()

    static var initialItems: [WardrobeItem] {
        [
            // 1. ELECTRONICS
            WardrobeItem(
                id: idOmega,
                name: "Omega Speedmaster Moonwatch Professional",
                brand: "Omega",
                category: .electronics,
                subcategory: "Watches & Wearables",
                price: 680000.0,
                photos: ["https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=800&q=80"],
                isFavorite: true,
                storageLocation: "Master Safe • Watch Winder #1",
                occasion: "Black Tie / Formal",
                notes: "Calibre 3861 Co-Axial Master Chronometer, Sapphire sandwich case back with stainless steel bracelet.",
                modelSpecs: "Calibre 3861 • Co-Axial Chronometer",
                serialNumber: "OME-84920194",
                warrantyInfo: "5-Year International Warranty",
                techCondition: "Collector Grade"
            ),
            WardrobeItem(
                id: idLeica,
                name: "Leica Q3 Full-Frame Compact Camera",
                brand: "Leica",
                category: .electronics,
                subcategory: "Cameras & Optics",
                price: 550000.0,
                photos: ["https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=800&q=80"],
                isFavorite: false,
                storageLocation: "Peli Air Case 1535",
                occasion: "Travel & Creative",
                notes: "60MP BSI CMOS full-frame sensor, fixed Summilux 28mm f/1.7 ASPH lens, tiltable OLED viewfinder.",
                modelSpecs: "60MP Full-Frame • Summilux 28mm f/1.7",
                serialNumber: "LC-3918204",
                warrantyInfo: "Leica Global Care until 2026",
                techCondition: "Mint"
            ),
            WardrobeItem(
                id: idMacBook,
                name: "MacBook Pro 16\" M3 Max",
                brand: "Apple",
                category: .electronics,
                subcategory: "Laptops & Computing",
                price: 349900.0,
                photos: ["https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=800&q=80"],
                isFavorite: true,
                storageLocation: "Studio Workstation",
                occasion: "Executive / Work",
                notes: "16-core CPU, 40-core GPU, 64GB Unified Memory, 1TB SSD in Space Black finish.",
                modelSpecs: "M3 Max • 64GB • 1TB",
                serialNumber: "C02G9012L4X9",
                warrantyInfo: "AppleCare+ until Nov 2027",
                techCondition: "Flawless"
            ),
            WardrobeItem(
                id: idSonyXM5,
                name: "Sony WH-1000XM5 Noise-Cancelling Headphones",
                brand: "Sony",
                category: .electronics,
                subcategory: "Audio & Acoustics",
                price: 29990.0,
                photos: ["https://images.unsplash.com/photo-1546435770-a3e426bf472b?w=800&q=80"],
                isFavorite: true,
                storageLocation: "Travel EDC Sling",
                occasion: "Travel & Commute",
                notes: "Industry leading dual-processor active noise cancelling, 30hr battery in Platinum Silver.",
                modelSpecs: "Dual Proc ANC • 30h Battery • LDAC",
                serialNumber: "SN-50824912",
                warrantyInfo: "2 Year Manufacturer Warranty",
                techCondition: "Pristine"
            ),

            // 2. CLOTHES
            WardrobeItem(
                id: idCanaliSuit,
                name: "Canali Custom Tailored Navy Wool Suit",
                brand: "Canali",
                category: .clothes,
                subcategory: "Suits & Blazers",
                price: 165000.0,
                photos: ["https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=800&q=80"],
                isFavorite: true,
                storageLocation: "Cedar Wardrobe Section A",
                occasion: "Boardroom / Gala",
                notes: "Super 150s high-twist Italian wool, half-canvas construction, notch lapel with horn buttons.",
                size: "40R (Drop 7)",
                fabricMaterial: "Super 150s Pure Italian Wool",
                color: "Midnight Navy"
            ),
            WardrobeItem(
                id: idRLShirt,
                name: "Ralph Lauren Custom Slim Fit Oxford",
                brand: "Polo Ralph Lauren",
                category: .clothes,
                subcategory: "Shirts & Polos",
                price: 14500.0,
                photos: ["https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf?w=800&q=80"],
                isFavorite: true,
                storageLocation: "Closet Drawer 3",
                occasion: "Smart Casual",
                notes: "Garment-dyed woven cotton oxford fabric with signature embroidered pony emblem.",
                size: "Medium (15.5 / 33)",
                fabricMaterial: "100% Giza Oxford Cotton",
                color: "French Sky Blue"
            ),
            WardrobeItem(
                id: idBarbourJacket,
                name: "Barbour Classic Bedale Waxed Jacket",
                brand: "Barbour",
                category: .clothes,
                subcategory: "Jackets & Outerwear",
                price: 38000.0,
                photos: ["https://images.unsplash.com/photo-1551028719-00167b16eac5?w=800&q=80"],
                isFavorite: false,
                storageLocation: "Foyer Coat Closet",
                occasion: "Outdoor & Travel",
                notes: "Mediumweight 6oz Thornproof waxed cotton, corduroy collar, classic Tartan cotton lining.",
                size: "UK 38 / US 38",
                fabricMaterial: "6oz Sylkoil Waxed Cotton",
                color: "Heritage Olive"
            ),
            WardrobeItem(
                id: idSunspelTee,
                name: "Sunspel Classic Sea Island Cotton T-Shirt",
                brand: "Sunspel",
                category: .clothes,
                subcategory: "T-Shirts & Knits",
                price: 8500.0,
                photos: ["https://images.unsplash.com/photo-1521572267360-ee0c2909d518?w=800&q=80"],
                isFavorite: false,
                storageLocation: "Top Drawer",
                occasion: "Everyday Luxury",
                notes: "Finest hand-picked Sea Island cotton grown in the Caribbean, spun in England.",
                size: "Large (42)",
                fabricMaterial: "100% Sea Island Cotton",
                color: "Optic Crisp White"
            ),

            // 3. SPORTS WEAR & ACTIVEWEAR
            WardrobeItem(
                id: idLululemonShirt,
                name: "Lululemon Metal Vent Tech 2.0 Short-Sleeve",
                brand: "Lululemon",
                category: .sportswear,
                subcategory: "Gym & Training Apparel",
                price: 6800.0,
                photos: ["https://images.unsplash.com/photo-1581655353564-df123a1eb820?w=800&q=80"],
                isFavorite: true,
                storageLocation: "Gym Drawer #1",
                occasion: "Strength & HIIT Training",
                notes: "Powered by Silverescent™ technology that inhibits growth of odor-causing bacteria. Seamless ventilation mesh.",
                size: "Large (Athletic Fit)",
                fabricMaterial: "Silverescent™ Nylon/Recycled Polyester",
                color: "Slate Shadow Black"
            ),
            WardrobeItem(
                id: idNikeShorts,
                name: "Nike Pro Dri-FIT ADV Flyvent Running Shorts",
                brand: "Nike",
                category: .sportswear,
                subcategory: "Athletic Shorts & Joggers",
                price: 5200.0,
                photos: ["https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=800&q=80"],
                isFavorite: false,
                storageLocation: "Gym Drawer #1",
                occasion: "Marathon & Speedwork",
                notes: "Engineered with laser-cut Flyvent waistband and moisture-wicking Dri-FIT ADV 4-way stretch fabric.",
                size: "Medium (7\" Inseam)",
                fabricMaterial: "Dri-FIT ADV 4-Way Stretch",
                color: "Stealth Obsidian"
            ),
            WardrobeItem(
                id: idArcteryxJacket,
                name: "Arc'teryx Norvan Windshell Lightweight Jacket",
                brand: "Arc'teryx",
                category: .sportswear,
                subcategory: "Running & Marathon Gear",
                price: 18500.0,
                photos: ["https://images.unsplash.com/photo-1544441893-675973e31985?w=800&q=80"],
                isFavorite: true,
                storageLocation: "Activewear Rack",
                occasion: "Outdoor Running & Trail",
                notes: "Ultra-packable 90g wind protection crafted from Canim™ polyester ripstop with moisture-shedding DWR finish.",
                size: "Medium",
                fabricMaterial: "Canim™ Wind-Resistant Ripstop",
                color: "Basalt Graphite"
            ),

            // 4. SHOES
            WardrobeItem(
                id: idCrockettOxfords,
                name: "Crockett & Jones Connaught Oxford Shoes",
                brand: "Crockett & Jones",
                category: .shoes,
                subcategory: "Formal Oxfords & Derbies",
                price: 58000.0,
                photos: ["https://images.unsplash.com/photo-1614252235316-8c857d38b5f4?w=800&q=80"],
                isFavorite: true,
                storageLocation: "Shoe Wall Tray #1",
                occasion: "Black Tie / Executive",
                notes: "Straight cap toe oxford made from the finest dark brown burnished calf leather on 236 last.",
                shoeSize: "UK 8.5 E / US 9.5",
                leatherSoleType: "Goodyear Welted Oak Bark Leather Sole"
            ),
            WardrobeItem(
                id: idCommonProjects,
                name: "Common Projects Original Achilles Low",
                brand: "Common Projects",
                category: .shoes,
                subcategory: "Sneakers & Streetwear",
                price: 39000.0,
                photos: ["https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?w=800&q=80"],
                isFavorite: true,
                storageLocation: "Display Cube 2",
                occasion: "Weekend / Smart Casual",
                notes: "Iconic minimalist sneaker crafted in Italy with full grain nappa leather and gold foil serial numbers.",
                shoeSize: "EU 43 / UK 9 / US 10",
                leatherSoleType: "Margom Stitched Rubber Cupsole"
            ),
            WardrobeItem(
                id: idSantoniLoafers,
                name: "Santoni Hand-Finished Suede Penny Loafers",
                brand: "Santoni",
                category: .shoes,
                subcategory: "Loafers & Slip-ons",
                price: 62000.0,
                photos: ["https://images.unsplash.com/photo-1533867617858-e7b97e060509?w=800&q=80"],
                isFavorite: false,
                storageLocation: "Shoe Wall Tray #3",
                occasion: "Resort / Summer Evening",
                notes: "Velvety soft unlined Italian suede with handcrafted Goodyear welt and anti-slip rubber inserts.",
                shoeSize: "UK 8.5 / EU 42.5",
                leatherSoleType: "Flexible Blake Rapid Sole"
            ),
            WardrobeItem(
                id: idRedWingBoots,
                name: "Red Wing Iron Ranger 8111 Heritage Boots",
                brand: "Red Wing",
                category: .shoes,
                subcategory: "Boots & Heritage",
                price: 34000.0,
                photos: ["https://images.unsplash.com/photo-1520639888713-7851133b1ed0?w=800&q=80"],
                isFavorite: false,
                storageLocation: "Entryway Bench",
                occasion: "Rugged Casual & Riding",
                notes: "Built with Amber Harness oiled full grain leather, double layer leather toe cap, and nickel eyelets.",
                shoeSize: "US 9.5 D / UK 8.5",
                leatherSoleType: "Vibram 430 Mini-Lug Goodyear Welt"
            ),

            // 4. BAGS & LUGGAGE
            WardrobeItem(
                id: idRimowaCabin,
                name: "Rimowa Classic Cabin Carry-On Suitcase",
                brand: "Rimowa",
                category: .bags,
                subcategory: "Carry-On Luggage & Cases",
                price: 125000.0,
                photos: ["https://images.unsplash.com/photo-1565026057447-bc90a3dceb87?w=800&q=80"],
                isFavorite: true,
                storageLocation: "Luggage Wardrobe Shelf",
                occasion: "Travel & Flights",
                notes: "High-grade anodized aluminum alloy with riveted corners, TSA locks, Multiwheel ball-bearing system.",
                bagCapacity: "36L • IATA Cabin Approved",
                bagMaterialHardware: "Anodized Aluminum Alloy • TSA Combination Locks"
            ),
            WardrobeItem(
                id: idBleuBag,
                name: "Bleu de Chauffe Postman Leather Bag (Eclair)",
                brand: "Bleu de Chauffe",
                category: .bags,
                subcategory: "Briefcases & Work Bags",
                price: 48000.0,
                photos: ["https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=800&q=80"],
                isFavorite: true,
                storageLocation: "Studio Desk Hook",
                occasion: "Office & Meetings",
                notes: "Handcrafted in France from vegetable-tanned full-grain leather. Removable 15-inch laptop sleeve.",
                bagCapacity: "18L • Fits 15\" Laptop",
                bagMaterialHardware: "Vegetable-Tanned Bridle Leather • Solid Brass"
            ),
            WardrobeItem(
                id: idBellroyBackpack,
                name: "Bellroy Transit Work Backpack 28L",
                brand: "Bellroy",
                category: .bags,
                subcategory: "Backpacks & Slings",
                price: 24000.0,
                photos: ["https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=800&q=80"],
                isFavorite: false,
                storageLocation: "EDC Coat Rack",
                occasion: "Commute & Weekend Trips",
                notes: "Weather-resistant recycled woven fabric, separate padded laptop compartment, quick access passport pocket.",
                bagCapacity: "28L • Dual Bottle Pockets",
                bagMaterialHardware: "Durable Water-Resistant Recycled Nylon"
            ),

            // 5. GROOMING & SKIN PRODUCTS
            WardrobeItem(
                id: idCreedAventus,
                name: "Creed Aventus Eau de Parfum (100ml)",
                brand: "House of Creed",
                category: .grooming,
                subcategory: "Fragrances & Colognes",
                price: 34500.0,
                photos: ["https://images.unsplash.com/photo-1592945403244-b3fbafd7f539?w=800&q=80"],
                isFavorite: true,
                storageLocation: "Master Dressing Console",
                occasion: "Signature / Evenings",
                notes: "Batch F000387. Masterpiece fragrance opening with lemon, pink pepper, and apple, drying to birch and oakmoss.",
                volumeSize: "100ml / 3.3 fl. oz",
                scentIngredients: "Bergamot, Smoky Birch, Jasmine, Patchouli, Ambergris"
            ),
            WardrobeItem(
                id: idAesopSerum,
                name: "Aesop Parsley Seed Anti-Oxidant Intense Serum",
                brand: "Aesop",
                category: .grooming,
                subcategory: "Face & Skincare Serums",
                price: 7800.0,
                photos: ["https://images.unsplash.com/photo-1620916566398-39f1143ab7be?w=800&q=80"],
                isFavorite: true,
                storageLocation: "Vanity Shelf #2",
                occasion: "Daily Morning Routine",
                notes: "Potent anti-oxidant serum designed for urban defense, formulated with red algae and green tea extracts.",
                volumeSize: "60ml Pipette Dropper Bottle",
                scentIngredients: "Parsley Seed, Tocopherol, Red Algae Extract"
            ),
            WardrobeItem(
                id: idMuhleRazor,
                name: "Mühle R89 Traditional Safety Razor & Brush Kit",
                brand: "Mühle Germany",
                category: .grooming,
                subcategory: "Shaving & Beard Care",
                price: 14200.0,
                photos: ["https://images.unsplash.com/photo-1508380702597-707c1b00695c?w=800&q=80"],
                isFavorite: false,
                storageLocation: "Master Shaving Stand",
                occasion: "Shave Ritual",
                notes: "Engineered in Stützengrün Germany with precision closed-comb chrome head and silvertip synthetic brush.",
                volumeSize: "Razor + Stand + Brush",
                scentIngredients: "Corrosion-Resistant Chrome • Silvertip Fiber"
            ),

            // 6. MEN'S ACCESSORIES
            WardrobeItem(
                id: idMontblancWallet,
                name: "Montblanc Meisterstück Leather Card Holder",
                brand: "Montblanc",
                category: .accessories,
                subcategory: "Wallets & Cardholders",
                price: 19500.0,
                photos: ["https://images.unsplash.com/photo-1627123424574-724758594e93?w=800&q=80"],
                isFavorite: true,
                storageLocation: "Nightstand Valet Tray",
                occasion: "Everyday Carry",
                notes: "European full-grain cowhide with unique Montblanc deep shine, jacquard lining with Montblanc brand name.",
                accessoryMaterial: "Full-Grain European Calfskin • Palladium Emblem"
            ),
            WardrobeItem(
                id: idJMMGlasses,
                name: "Jacques Marie Mage Dealan Sunglasses",
                brand: "Jacques Marie Mage",
                category: .accessories,
                subcategory: "Sunglasses & Eyewear",
                price: 72000.0,
                photos: ["https://images.unsplash.com/photo-1511499767150-a48a237f0083?w=800&q=80"],
                isFavorite: true,
                storageLocation: "Eyewear Display Case",
                occasion: "Driving & Sunny Days",
                notes: "Limited batch of 500 pieces. 10mm cured cellulose acetate frame, precious metal sterling silver hardware.",
                accessoryMaterial: "10mm Cured Japanese Acetate • Sterling Silver Arrowhead"
            ),
            WardrobeItem(
                id: idHermesBelt,
                name: "Hermès Reversible Leather Belt 32mm",
                brand: "Hermès Paris",
                category: .accessories,
                subcategory: "Belts & Leather Goods",
                price: 68000.0,
                photos: ["https://images.unsplash.com/photo-1624222247344-550fb60583dc?w=800&q=80"],
                isFavorite: false,
                storageLocation: "Closet Belt Rack",
                occasion: "Business & Formal",
                notes: "Reversible Togo calfskin in Noir and Gold Epsom calfskin, with brushed palladium plated H buckle.",
                accessoryMaterial: "Togo & Epsom Double-Sided Calfskin • Brushed Palladium"
            ),
            WardrobeItem(
                id: idTateossianCufflinks,
                name: "Tateossian London Mechanical Gear Cufflinks",
                brand: "Tateossian",
                category: .accessories,
                subcategory: "Cufflinks & Tie Clips",
                price: 26000.0,
                photos: ["https://images.unsplash.com/photo-1590736969955-71cc94801759?w=800&q=80"],
                isFavorite: false,
                storageLocation: "Jewelry Safe Drawer",
                occasion: "Black Tie & Gala",
                notes: "Rhodium-plated base metal featuring fully moving watch gears that rotate when touched.",
                accessoryMaterial: "Rhodium-Plated Brass • Multi-Color Moving Gears"
            )
        ]
    }

    static var initialWishlist: [WishlistItem] {
        [
            WishlistItem(
                name: "Nike Men Downshifter 14 White/Black-Platinum Tint Running Shoes",
                brand: "Nike",
                category: .shoes,
                targetPrice: 4895.0,
                photos: ["https://m.media-amazon.com/images/I/51JjqvF1yrL._AC_SL1500_.jpg"],
                storeUrl: "https://www.amazon.in/Nike-Downshifter-Black-Platinum-Tint-Anthracite-Running/dp/B0FFTD9NS8",
                priority: .high,
                notes: "Comfortable daily running trainers in size 9 UK. Target acquisition for marathon training."
            ),
            WishlistItem(
                name: "Tracksmith Turnover Half Tights & Van Cortlandt Singlet",
                brand: "Tracksmith",
                category: .sportswear,
                targetPrice: 12500.0,
                photos: ["https://images.unsplash.com/photo-1552674605-db6ffd4facb5?w=800&q=80"],
                storeUrl: "https://www.tracksmith.com",
                priority: .high,
                notes: "Premium Italian 2:09 mesh fabric with lightweight moisture management and gel pockets for endurance training."
            ),
            WishlistItem(
                name: "Rimowa Original Check-In M Titanium Suitcase",
                brand: "Rimowa",
                category: .bags,
                targetPrice: 145000.0,
                photos: ["https://images.unsplash.com/photo-1565026057447-bc90a3dceb87?w=800&q=80"],
                storeUrl: "https://www.rimowa.com",
                priority: .high,
                notes: "68L check-in suitcase in brushed titanium for international flights."
            ),
            WishlistItem(
                name: "Tom Ford Tuscan Leather Eau de Parfum 50ml",
                brand: "Tom Ford",
                category: .grooming,
                targetPrice: 28000.0,
                photos: ["https://images.unsplash.com/photo-1523293182086-7651a899d37f?w=800&q=80"],
                storeUrl: "https://www.tomfordbeauty.com",
                priority: .medium,
                notes: "Raw yet refined, sensual leather with night-blooming jasmine and black suede."
            ),
            WishlistItem(
                name: "Leica M11 Rangefinder Digital Camera",
                brand: "Leica",
                category: .electronics,
                targetPrice: 720000.0,
                photos: ["https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=800&q=80"],
                storeUrl: "https://leica-camera.com",
                priority: .low,
                notes: "Triple Resolution 60MP BSI sensor, black finish with aluminum top plate."
            )
        ]
    }

    static func initialLooks(from items: [WardrobeItem]) -> [CuratedLook] {
        [
            CuratedLook(
                title: "The Boardroom Executive",
                occasion: "Executive Summit & Presentations",
                description: "Impeccably tailored navy wool paired with dark brown Goodyear welted oxfords, powered by the M3 Max MacBook, timed with the Omega Moonwatch, carrying the Bleu de Chauffe briefcase.",
                clothesItemIds: [idCanaliSuit, idRLShirt],
                shoesItemIds: [idCrockettOxfords],
                electronicsItemIds: [idMacBook, idOmega],
                tags: ["Power Dressing", "Formal", "High Stakes"],
                coverSymbol: "briefcase.fill"
            ),
            CuratedLook(
                title: "Urban Studio & Creative Director",
                occasion: "Client Walkthroughs & Gallery Openings",
                description: "Subtle minimalist luxury: crisp cotton oxford, handcrafted Italian sneakers, paired with the Leica Q3 60MP camera and JMM sunglasses.",
                clothesItemIds: [idRLShirt],
                shoesItemIds: [idCommonProjects],
                electronicsItemIds: [idLeica, idSonyXM5],
                tags: ["Smart Minimalist", "Creative", "Studio"],
                coverSymbol: "camera.macro"
            ),
            CuratedLook(
                title: "First-Class Transcontinental",
                occasion: "International Flights & City Layovers",
                description: "Weather-resistant waxed outerwear, softest Sea Island cotton tee, slip-on suede loafers for security checkpoints, and the Rimowa Classic Cabin suitcase.",
                clothesItemIds: [idBarbourJacket, idSunspelTee],
                shoesItemIds: [idSantoniLoafers],
                electronicsItemIds: [idSonyXM5, idMacBook],
                tags: ["Travel EDC", "Long Haul", "Effortless"],
                coverSymbol: "airplane"
            )
        ]
    }

    static func initialTrips(from items: [WardrobeItem]) -> [TripPlan] {
        [
            TripPlan(
                destination: "Mumbai Business Summit",
                purpose: "Keynote presentation & executive meetings",
                durationDays: 3,
                items: [
                    PackingItem(title: "Canali Navy Suit", category: .clothes, linkedWardrobeItemId: idCanaliSuit, isPacked: true),
                    PackingItem(title: "Ralph Lauren Oxford Shirt", category: .clothes, linkedWardrobeItemId: idRLShirt, isPacked: true),
                    PackingItem(title: "Crockett & Jones Oxfords", category: .shoes, linkedWardrobeItemId: idCrockettOxfords, isPacked: false),
                    PackingItem(title: "MacBook Pro 16\" M3 Max", category: .electronics, linkedWardrobeItemId: idMacBook, isPacked: true),
                    PackingItem(title: "Rimowa Classic Cabin Suitcase", category: .bags, linkedWardrobeItemId: idRimowaCabin, isPacked: true),
                    PackingItem(title: "Creed Aventus Cologne (100ml)", category: .grooming, linkedWardrobeItemId: idCreedAventus, isPacked: false),
                    PackingItem(title: "Montblanc Card Holder", category: .accessories, linkedWardrobeItemId: idMontblancWallet, isPacked: true),
                    PackingItem(title: "140W USB-C GaN Fast Charger & Cables", category: .electronics, isPacked: false)
                ]
            )
        ]
    }
}
