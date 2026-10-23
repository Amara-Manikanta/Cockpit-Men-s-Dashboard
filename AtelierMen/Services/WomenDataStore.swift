import SwiftUI

@MainActor
public final class WomenDataStore: ObservableObject {
    @Published public var items: [WomenWardrobeItem] = []
    @Published public var wishlistItems: [WomenWishlistItem] = []
    @Published public var looks: [WomenCuratedLook] = []
    @Published public var trips: [WomenTripPlan] = []

    private var itemsFileUrl: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("women_wardrobe_items.json")
    }

    private var backupItemsFileUrl: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("women_wardrobe_items_backup.json")
    }

    private var wishlistFileUrl: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("women_wishlist_items.json")
    }

    private var backupWishlistFileUrl: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("women_wishlist_items_backup.json")
    }

    private var looksFileUrl: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("women_curated_looks.json")
    }

    private var tripsFileUrl: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("women_trip_plans.json")
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

    public func valuation(for category: WomenCategory) -> Double {
        items.filter { $0.category == category }.reduce(0) { $0 + $1.price }
    }

    public func formattedValuation(for category: WomenCategory) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₹"
        formatter.maximumFractionDigits = 0
        formatter.locale = Locale(identifier: "en_IN")
        return formatter.string(from: NSNumber(value: valuation(for: category))) ?? "₹0"
    }

    public func itemCount(for category: WomenCategory) -> Int {
        items.filter { $0.category == category }.count
    }

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

    // MARK: - Wardrobe CRUD
    @discardableResult
    public func addItem(_ item: WomenWardrobeItem, ignoreDuplicates: Bool = true) -> Bool {
        if ignoreDuplicates, let existingIdx = items.firstIndex(where: {
            $0.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == item.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() &&
            $0.brand.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == item.brand.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }) {
            var updated = items[existingIdx]
            for p in item.photos where !updated.photos.contains(p) {
                updated.photos.append(p)
            }
            items[existingIdx] = updated
            saveItems()
            return false
        }

        items.insert(item, at: 0)
        saveItems()
        return true
    }

    public func updateItem(_ item: WomenWardrobeItem) {
        if let idx = items.firstIndex(where: { $0.id == item.id }) {
            items[idx] = item
            saveItems()
        }
    }

    public func deleteItem(_ item: WomenWardrobeItem) {
        items.removeAll { $0.id == item.id }
        saveItems()
    }

    public func deleteItems(ids: Set<UUID>) {
        items.removeAll { ids.contains($0.id) }
        saveItems()
    }

    public func toggleFavorite(for item: WomenWardrobeItem) {
        if let idx = items.firstIndex(where: { $0.id == item.id }) {
            items[idx].isFavorite.toggle()
            saveItems()
        }
    }

    public func incrementWearCount(for item: WomenWardrobeItem) {
        if let idx = items.firstIndex(where: { $0.id == item.id }) {
            items[idx].timesWorn += 1
            items[idx].lastWornDate = Date()
            saveItems()
        }
    }

    public func decrementWearCount(for item: WomenWardrobeItem) {
        if let idx = items.firstIndex(where: { $0.id == item.id }) {
            if items[idx].timesWorn > 0 {
                items[idx].timesWorn -= 1
                saveItems()
            }
        }
    }

    public func markWoreToday(for item: WomenWardrobeItem, date: Date = Date()) {
        if let idx = items.firstIndex(where: { $0.id == item.id }) {
            items[idx].timesWorn += 1
            items[idx].lastWornDate = date
            items[idx].wearHistory.append(date)
            saveItems()
        }
    }

    public func logOutfitWorn(itemIds: Set<UUID>, date: Date = Date()) {
        for id in itemIds {
            if let idx = items.firstIndex(where: { $0.id == id }) {
                items[idx].timesWorn += 1
                items[idx].lastWornDate = date
                items[idx].wearHistory.append(date)
            }
        }
        saveItems()
    }

    public func updateGarmentCondition(_ condition: GarmentCondition?, for item: WomenWardrobeItem) {
        if let idx = items.firstIndex(where: { $0.id == item.id }) {
            items[idx].garmentCondition = condition
            saveItems()
        }
    }

    public func incrementQuantity(for item: WomenWardrobeItem) {
        if let idx = items.firstIndex(where: { $0.id == item.id }) {
            items[idx].quantity += 1
            saveItems()
        }
    }

    public func decrementQuantity(for item: WomenWardrobeItem) {
        if let idx = items.firstIndex(where: { $0.id == item.id }) {
            if items[idx].quantity > 1 {
                items[idx].quantity -= 1
                saveItems()
            }
        }
    }

    // MARK: - Wishlist CRUD
    @discardableResult
    public func addWishlistItem(_ item: WomenWishlistItem, ignoreDuplicates: Bool = true) -> Bool {
        if ignoreDuplicates, let existingIdx = wishlistItems.firstIndex(where: {
            $0.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == item.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() &&
            $0.brand.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == item.brand.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }) {
            var updated = wishlistItems[existingIdx]
            for p in item.photos where !updated.photos.contains(p) {
                updated.photos.append(p)
            }
            wishlistItems[existingIdx] = updated
            saveWishlist()
            return false
        }

        wishlistItems.insert(item, at: 0)
        saveWishlist()
        return true
    }

    public func updateWishlistItem(_ item: WomenWishlistItem) {
        if let idx = wishlistItems.firstIndex(where: { $0.id == item.id }) {
            wishlistItems[idx] = item
            saveWishlist()
        }
    }

    public func deleteWishlistItem(_ item: WomenWishlistItem) {
        wishlistItems.removeAll { $0.id == item.id }
        saveWishlist()
    }

    public func deleteWishlistItems(ids: Set<UUID>) {
        wishlistItems.removeAll { ids.contains($0.id) }
        saveWishlist()
    }

    public func moveToBoutique(wishlistItem: WomenWishlistItem, storageLocation: String = "Boutique Vanity Box") {
        let wardrobeItem = WomenWardrobeItem(
            title: wishlistItem.title,
            category: wishlistItem.category,
            subcategory: wishlistItem.subcategory,
            brand: wishlistItem.brand,
            price: wishlistItem.targetPrice,
            originalPrice: wishlistItem.originalPrice,
            photos: wishlistItem.photos,
            metal: wishlistItem.category.isJewelryOrWatch ? .gold18KRose : .pureSilk,
            purity: "Acquired Wishlist Goal",
            sizeOrDimensions: "Boutique Sizing",
            isSet: false,
            setIncludes: "",
            storageLocation: storageLocation.isEmpty ? "Boutique Vanity Box" : storageLocation,
            occasion: "Special Occasion",
            notes: wishlistItem.notes,
            storeUrl: wishlistItem.storeUrl,
            timesWorn: 0,
            lastWornDate: nil,
            dateAdded: Date(),
            isFavorite: true
        )
        addItem(wardrobeItem, ignoreDuplicates: false)
        deleteWishlistItem(wishlistItem)
    }

    // MARK: - Persistence
    public func saveItems() {
        if let data = try? JSONEncoder().encode(items) {
            try? data.write(to: itemsFileUrl, options: .atomic)
            try? data.write(to: backupItemsFileUrl, options: .atomic)
            KeychainHelper.shared.save(data: data, service: "com.amara.AtelierMen.women", account: "women_wardrobe_items")
        }
    }

    public func saveWishlist() {
        if let data = try? JSONEncoder().encode(wishlistItems) {
            try? data.write(to: wishlistFileUrl, options: .atomic)
            try? data.write(to: backupWishlistFileUrl, options: .atomic)
            KeychainHelper.shared.save(data: data, service: "com.amara.AtelierMen.women", account: "women_wishlist_items")
        }
    }

    public func saveLooks() {
        if let data = try? JSONEncoder().encode(looks) {
            try? data.write(to: looksFileUrl, options: .atomic)
        }
    }

    public func saveTrips() {
        if let data = try? JSONEncoder().encode(trips) {
            try? data.write(to: tripsFileUrl, options: .atomic)
        }
    }

    private func loadData() {
        // Priority-ordered fallback: Primary -> Backup -> Keychain -> SeedData
        if let data = try? Data(contentsOf: itemsFileUrl),
           let loaded = try? JSONDecoder().decode([WomenWardrobeItem].self, from: data) {
            self.items = loaded
        } else if let bData = try? Data(contentsOf: backupItemsFileUrl),
                  let loaded = try? JSONDecoder().decode([WomenWardrobeItem].self, from: bData), !loaded.isEmpty {
            self.items = loaded
            saveItems()
        } else if let kcData = KeychainHelper.shared.read(service: "com.amara.AtelierMen.women", account: "women_wardrobe_items"),
                  let loaded = try? JSONDecoder().decode([WomenWardrobeItem].self, from: kcData), !loaded.isEmpty {
            self.items = loaded
            saveItems()
        } else {
            self.items = WomenSeedData.initialItems
            saveItems()
        }

        // Wishlist
        if let data = try? Data(contentsOf: wishlistFileUrl),
           let loaded = try? JSONDecoder().decode([WomenWishlistItem].self, from: data) {
            self.wishlistItems = loaded
        } else if let bData = try? Data(contentsOf: backupWishlistFileUrl),
                  let loaded = try? JSONDecoder().decode([WomenWishlistItem].self, from: bData), !loaded.isEmpty {
            self.wishlistItems = loaded
            saveWishlist()
        } else if let kcData = KeychainHelper.shared.read(service: "com.amara.AtelierMen.women", account: "women_wishlist_items"),
                  let loaded = try? JSONDecoder().decode([WomenWishlistItem].self, from: kcData), !loaded.isEmpty {
            self.wishlistItems = loaded
            saveWishlist()
        } else {
            self.wishlistItems = WomenSeedData.initialWishlist
            saveWishlist()
        }

        // Looks
        if let data = try? Data(contentsOf: looksFileUrl),
           let loaded = try? JSONDecoder().decode([WomenCuratedLook].self, from: data), !loaded.isEmpty {
            self.looks = loaded
        } else {
            self.looks = WomenSeedData.initialLooks(from: self.items)
            saveLooks()
        }

        // Trips
        if let data = try? Data(contentsOf: tripsFileUrl),
           let loaded = try? JSONDecoder().decode([WomenTripPlan].self, from: data), !loaded.isEmpty {
            self.trips = loaded
        } else {
            self.trips = WomenSeedData.initialTrips(from: self.items)
            saveTrips()
        }
    }
}

// MARK: - Women Seed Data
private struct WomenSeedData {
    static let idLehenga = UUID()
    static let idKanjeevaram = UUID()
    static let idTanishqSet = UUID()
    static let idTiffany = UUID()
    static let idCartier = UUID()
    static let idCaratlane = UUID()
    static let idCoach = UUID()
    static let idMinaudiere = UUID()
    static let idLulu = UUID()
    static let idKurta = UUID()
    static let idZaraDress = UUID()
    static let idMia = UUID()
    static let idGiva = UUID()
    static let idRaga = UUID()

    static var initialItems: [WomenWardrobeItem] {
        [
            WomenWardrobeItem(
                id: idLehenga,
                title: "Sabyasachi Heritage Crimson Velvet Bridal Lehenga",
                category: .sareesEthnic,
                subcategory: "Bridal & Party Lehengas",
                brand: "Sabyasachi",
                price: 395000.0,
                originalPrice: 425000.0,
                photos: ["https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?auto=format&fit=crop&w=600&q=80"],
                metal: .embellishedZari,
                purity: "Handcrafted Zardozi, Tilla & Crystals",
                sizeOrDimensions: "Custom Tailored Bridal",
                isSet: true,
                setIncludes: "Lehenga Skirt + Blouse + Dual Dupatta",
                storageLocation: "Master Wardrobe Bridal Suite",
                occasion: "Wedding / Grand Reception",
                notes: "Iconic crimson velvet bridal lehenga with antique dabka and tilla embroidery. Worn with heritage jewelry.",
                storeUrl: "https://www.sabyasachi.com",
                timesWorn: 2,
                lastWornDate: Date().addingTimeInterval(-86400 * 45),
                isFavorite: true
            ),
            WomenWardrobeItem(
                id: idKanjeevaram,
                title: "Pure Kanjeevaram Silk Saree in Emerald & Gold Zari",
                category: .sareesEthnic,
                subcategory: "Kanjeevaram & Silk Sarees",
                brand: "Nalli Silks",
                price: 68000.0,
                originalPrice: 75000.0,
                photos: ["https://images.unsplash.com/photo-1610030469983-98e550d6193c?auto=format&fit=crop&w=600&q=80"],
                metal: .pureSilk,
                purity: "100% Pure Mulberry Silk & Real Zari",
                sizeOrDimensions: "6.3m Saree with Unstitched Blouse",
                isSet: false,
                storageLocation: "Silk Saree Velvet Box 1",
                occasion: "Festive & Temple Pujas",
                notes: "Lustrous emerald green body with heavy peacock motif contrast pallu in temple gold zari.",
                storeUrl: "https://www.nalli.com",
                timesWorn: 5,
                lastWornDate: Date().addingTimeInterval(-86400 * 20),
                isFavorite: true
            ),
            WomenWardrobeItem(
                id: idTanishqSet,
                title: "Tanishq 22K Traditional Gold Choker & Jhumkas Set",
                category: .fineJewelry,
                subcategory: "Necklaces & Chokers",
                brand: "Tanishq",
                price: 485000.0,
                originalPrice: 485000.0,
                photos: ["https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?auto=format&fit=crop&w=600&q=80"],
                metal: .gold22K,
                purity: "22K BIS Hallmarked Yellow Gold (64g)",
                sizeOrDimensions: "16\" Choker + Matching 2.5\" Jhumkas",
                isSet: true,
                setIncludes: "Choker Necklace + Hanging Jhumkas",
                storageLocation: "Safety Locker - Jewelry Vault 1",
                occasion: "Weddings & Festive",
                notes: "Intricate filigree work with natural uncut ruby accents and pearl drops.",
                storeUrl: "https://www.tanishq.co.in",
                timesWorn: 4,
                lastWornDate: Date().addingTimeInterval(-86400 * 30),
                isFavorite: true
            ),
            WomenWardrobeItem(
                id: idTiffany,
                title: "Tiffany T Wire 18K Rose Gold Diamond Bracelet",
                category: .fineJewelry,
                subcategory: "Bangles & Kadas",
                brand: "Tiffany & Co.",
                price: 320000.0,
                originalPrice: 350000.0,
                photos: ["https://images.unsplash.com/photo-1611591475824-749e7b233959?auto=format&fit=crop&w=600&q=80"],
                metal: .gold18KRose,
                purity: "18K Rose Gold with Brilliant Pavé Diamonds",
                sizeOrDimensions: "Medium (6.25\" wrist)",
                isSet: false,
                storageLocation: "Velvet Vanity Box - Top Slot 1",
                occasion: "Cocktails & Evening Soirée",
                notes: "Timeless T graphic wire silhouette wrapped with brilliant cut pavé diamonds.",
                storeUrl: "https://www.tiffany.com",
                timesWorn: 8,
                lastWornDate: Date().addingTimeInterval(-86400 * 7),
                isFavorite: true
            ),
            WomenWardrobeItem(
                id: idCartier,
                title: "Cartier Panthère Watch in 18K Yellow Gold",
                category: .watches,
                subcategory: "Jewelry Watches",
                brand: "Cartier",
                price: 680000.0,
                originalPrice: 680000.0,
                photos: ["https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?auto=format&fit=crop&w=600&q=80"],
                metal: .gold24K,
                purity: "18K Solid Gold & Blued Steel Hands",
                sizeOrDimensions: "Small Model (22mm x 30mm)",
                isSet: false,
                storageLocation: "Watch Winder Box - Slot 2",
                occasion: "Everyday Luxury & Formal",
                notes: "The quintessence of jewelry watch elegance with iconic supple link bracelet and sapphire cabochon crown.",
                storeUrl: "https://www.cartier.com",
                timesWorn: 14,
                lastWornDate: Date().addingTimeInterval(-86400 * 2),
                isFavorite: true
            ),
            WomenWardrobeItem(
                id: idCaratlane,
                title: "CaratLane 18K White Gold Solitaire Diamond Ring",
                category: .fineJewelry,
                subcategory: "Solitaire & Cocktail Rings",
                brand: "CaratLane",
                price: 145000.0,
                originalPrice: 160000.0,
                photos: ["https://images.unsplash.com/photo-1605100804763-247f67b3557e?auto=format&fit=crop&w=600&q=80"],
                metal: .diamond,
                purity: "0.75ct VVS1-E Color Certified Solitaire",
                sizeOrDimensions: "Size 12 Indian (6 US)",
                isSet: false,
                storageLocation: "Ring Box - Slot 3",
                occasion: "Daily Wear & Special Dinners",
                notes: "Six-prong platinum-tipped setting on 18K white gold band with micro-pavé shoulders.",
                storeUrl: "https://www.caratlane.com",
                timesWorn: 24,
                lastWornDate: Date().addingTimeInterval(-86400 * 1),
                isFavorite: true
            ),
            WomenWardrobeItem(
                id: idCoach,
                title: "Coach Tabby 26 Leather Shoulder Bag in Chalk",
                category: .handbagsClutches,
                subcategory: "Luxury Totes & Satchels",
                brand: "Coach",
                price: 49500.0,
                originalPrice: 55000.0,
                photos: ["https://images.unsplash.com/photo-1584917865442-de89df76afd3?auto=format&fit=crop&w=600&q=80"],
                metal: .fineLeather,
                purity: "Polished Pebble Leather & Suede Lining",
                sizeOrDimensions: "26cm (L) x 15cm (H) x 7.5cm (W)",
                isSet: false,
                storageLocation: "Handbag Shelf - Section B",
                occasion: "Brunch & Everyday",
                notes: "Iconic C-hardware closure, interchangeable short shoulder strap and long crossbody strap.",
                storeUrl: "https://www.coach.com",
                timesWorn: 18,
                lastWornDate: Date().addingTimeInterval(-86400 * 3),
                isFavorite: true
            ),
            WomenWardrobeItem(
                id: idMinaudiere,
                title: "Sabyasachi Royal Bengal Minaudière Bridal Clutch",
                category: .handbagsClutches,
                subcategory: "Bridal Minaudières & Clutches",
                brand: "Sabyasachi",
                price: 88000.0,
                originalPrice: 88000.0,
                photos: ["https://images.unsplash.com/photo-1566150905458-1bf1fc113f0d?auto=format&fit=crop&w=600&q=80"],
                metal: .embellishedZari,
                purity: "Antique Gold Plated Brass & Velvet",
                sizeOrDimensions: "19cm x 11cm Hardcase",
                isSet: false,
                storageLocation: "Vanity Shelf 1",
                occasion: "Weddings & Red Carpet",
                notes: "Sculpted Royal Bengal Tiger clasp in antique gold finish on black micro-velvet.",
                storeUrl: "https://www.sabyasachi.com",
                timesWorn: 3,
                lastWornDate: Date().addingTimeInterval(-86400 * 40),
                isFavorite: true
            ),
            WomenWardrobeItem(
                id: idLulu,
                title: "Lululemon Align Activewear Yoga Training Set",
                category: .activewear,
                subcategory: "Yoga Sets & Leggings",
                brand: "Lululemon",
                price: 18500.0,
                originalPrice: 21000.0,
                photos: ["https://images.unsplash.com/photo-1518611012118-696072aa579a?auto=format&fit=crop&w=600&q=80"],
                metal: .technicalAthletic,
                purity: "Weightless Nulu™ Butter-Soft Fabric",
                sizeOrDimensions: "Size S / 4 US",
                isSet: true,
                setIncludes: "High-Rise 25\" Leggings + Free to Be Bra",
                storageLocation: "Gym Drawer 2",
                occasion: "Pilates, Yoga & Gym",
                notes: "Dusty Mauve colorway. Sweat-wicking with four-way stretch.",
                storeUrl: "https://www.lululemon.com",
                timesWorn: 16,
                lastWornDate: Date().addingTimeInterval(-86400 * 1),
                isFavorite: true
            ),
            WomenWardrobeItem(
                id: idKurta,
                title: "Biba Handcrafted Chanderi Silk Kurta & Palazzo Set",
                category: .kurtisTops,
                subcategory: "Handcrafted Kurtis",
                brand: "Biba",
                price: 12999.0,
                originalPrice: 15999.0,
                photos: ["https://images.unsplash.com/photo-1617627143750-d86bc21e42bb?auto=format&fit=crop&w=600&q=80"],
                metal: .pureSilk,
                purity: "Chanderi Silk with Gota Patti Work",
                sizeOrDimensions: "Size 36 (Medium)",
                isSet: true,
                setIncludes: "A-Line Kurta + Flared Palazzo + Chiffon Dupatta",
                storageLocation: "Ethnic Wardrobe - Row 3",
                occasion: "Festivals & Family Gatherings",
                notes: "Blush pink with delicate gold zari embroidery on yoke and hemline.",
                storeUrl: "https://www.biba.in",
                timesWorn: 7,
                lastWornDate: Date().addingTimeInterval(-86400 * 14),
                isFavorite: false
            ),
            WomenWardrobeItem(
                id: idZaraDress,
                title: "Zara Pleated Satin Evening Midi Dress in Emerald",
                category: .dressesGowns,
                subcategory: "Midi & Wrap Dresses",
                brand: "Zara",
                price: 6990.0,
                originalPrice: 7990.0,
                photos: ["https://images.unsplash.com/photo-1595777457583-95e059d581b8?auto=format&fit=crop&w=600&q=80"],
                metal: .other,
                purity: "Pleated Liquid Satin Finish",
                sizeOrDimensions: "Size M (EUR 38 / US 6)",
                isSet: false,
                storageLocation: "Cocktail Dress Wardrobe",
                occasion: "Dinner Dates & Parties",
                notes: "V-neckline with draped gathering and flowing pleated skirt.",
                storeUrl: "https://www.zara.com",
                timesWorn: 6,
                lastWornDate: Date().addingTimeInterval(-86400 * 10),
                isFavorite: false
            ),
            WomenWardrobeItem(
                id: idMia,
                title: "Mia by Tanishq 14K Yellow Gold Diamond Drop Earrings",
                category: .fineJewelry,
                subcategory: "Diamond Earrings & Studs",
                brand: "Mia by Tanishq",
                price: 44500.0,
                originalPrice: 48000.0,
                photos: ["https://images.unsplash.com/photo-1630019852942-f89202989a59?auto=format&fit=crop&w=600&q=80"],
                metal: .gold18KRose,
                purity: "14K Gold with Natural Diamonds (0.28ct)",
                sizeOrDimensions: "3.2cm Drop Length",
                isSet: false,
                storageLocation: "Earrings Stand 2",
                occasion: "Office Wear & Evenings",
                notes: "Contemporary geometric linear drops with post and butterfly backs.",
                storeUrl: "https://www.miabytanishq.com",
                timesWorn: 15,
                lastWornDate: Date().addingTimeInterval(-86400 * 5),
                isFavorite: false
            ),
            WomenWardrobeItem(
                id: idGiva,
                title: "Giva 925 Sterling Silver Sparkle Tennis Bracelet",
                category: .fineJewelry,
                subcategory: "Bangles & Kadas",
                brand: "Giva",
                price: 6499.0,
                originalPrice: 8999.0,
                photos: ["https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?auto=format&fit=crop&w=600&q=80"],
                metal: .silver925,
                purity: "925 Pure Silver with Rhodium Anti-Tarnish Finish",
                sizeOrDimensions: "7.0\" Length with Lobster Clasp",
                isSet: false,
                storageLocation: "Silver Box 1",
                occasion: "Casual & Smart Chic",
                notes: "AAA+ Swiss Zircons set in continuous channel row.",
                storeUrl: "https://www.giva.co",
                timesWorn: 12,
                lastWornDate: Date().addingTimeInterval(-86400 * 8),
                isFavorite: false
            ),
            WomenWardrobeItem(
                id: idRaga,
                title: "Titan Raga Viva Rose Gold Mother-of-Pearl Watch",
                category: .watches,
                subcategory: "Jewelry Watches",
                brand: "Titan Raga",
                price: 14995.0,
                originalPrice: 16995.0,
                photos: ["https://images.unsplash.com/photo-1508685096489-7aacd43bd3b1?auto=format&fit=crop&w=600&q=80"],
                metal: .gold18KRose,
                purity: "Rose Gold Ion Plated with Swarovski Crystals",
                sizeOrDimensions: "28mm Dial with Jewelry Clasp",
                isSet: false,
                storageLocation: "Watch Box 2",
                occasion: "Ethnic Gatherings & Office",
                notes: "Iridescent mother-of-pearl dial with faceted crystal bezel.",
                storeUrl: "https://www.titan.co.in",
                timesWorn: 22,
                lastWornDate: Date().addingTimeInterval(-86400 * 4),
                isFavorite: false
            )
        ]
    }

    static var initialWishlist: [WomenWishlistItem] {
        [
            WomenWishlistItem(
                title: "Van Cleef & Arpels Vintage Alhambra Mother-of-Pearl Bracelet",
                category: .fineJewelry,
                subcategory: "Bangles & Kadas",
                brand: "Van Cleef & Arpels",
                targetPrice: 420000.0,
                originalPrice: 450000.0,
                photos: ["https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?auto=format&fit=crop&w=600&q=80"],
                priority: "HIGH",
                storeUrl: "https://www.vancleefarpels.com",
                notes: "5-motif iconic clover bracelet in 18K yellow gold and white mother-of-pearl."
            ),
            WomenWishlistItem(
                title: "Chanel Classic Flap Medium Handbag in Lambskin",
                category: .handbagsClutches,
                subcategory: "Luxury Totes & Satchels",
                brand: "Chanel",
                targetPrice: 780000.0,
                originalPrice: 820000.0,
                photos: ["https://images.unsplash.com/photo-1584917865442-de89df76afd3?auto=format&fit=crop&w=600&q=80"],
                priority: "HIGH",
                storeUrl: "https://www.chanel.com",
                notes: "Quilted black lambskin with signature CC turnlock and gold chain strap."
            ),
            WomenWishlistItem(
                title: "Jimmy Choo Romy 85 Platinum Ice Glitter Pumps",
                category: .dressesGowns,
                subcategory: "Evening & Cocktail Gowns",
                brand: "Jimmy Choo",
                targetPrice: 72000.0,
                originalPrice: 79000.0,
                photos: ["https://images.unsplash.com/photo-1543163521-1bf539c55dd2?auto=format&fit=crop&w=600&q=80"],
                priority: "MEDIUM",
                storeUrl: "https://www.jimmychoo.com",
                notes: "85mm stiletto heel coated with dusty glitter fabric. Perfect pairing with lehengas."
            ),
            WomenWishlistItem(
                title: "Dyson Airwrap Multi-Styler Complete in Strawberry Bronze",
                category: .watches,
                subcategory: "Smart Luxury Wearables",
                brand: "Dyson",
                targetPrice: 49900.0,
                originalPrice: 52900.0,
                photos: ["https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?auto=format&fit=crop&w=600&q=80"],
                priority: "HIGH",
                storeUrl: "https://www.dyson.in",
                notes: "Coanda airflow styling for voluminous curls, blowout drying and smoothing flyaways."
            )
        ]
    }

    static func initialLooks(from items: [WomenWardrobeItem]) -> [WomenCuratedLook] {
        let weddingItemIds = items.filter { $0.id == idLehenga || $0.id == idTanishqSet || $0.id == idMinaudiere }.map { $0.id }
        let cocktailItemIds = items.filter { $0.id == idZaraDress || $0.id == idTiffany || $0.id == idCoach || $0.id == idCaratlane }.map { $0.id }

        return [
            WomenCuratedLook(
                name: "Royal Heritage Bridal Majesty",
                occasion: "Grand Wedding",
                anchorItemId: idLehenga,
                itemIds: weddingItemIds,
                harmonyScore: 98,
                stylistAdvice: "The rich crimson velvet of the Sabyasachi lehenga pairs seamlessly with the 22K temple filigree choker. Carry the Royal Bengal minaudière for a regal heritage finish."
            ),
            WomenCuratedLook(
                name: "Emerald Soirée & Diamonds",
                occasion: "Cocktail Evening",
                anchorItemId: idZaraDress,
                itemIds: cocktailItemIds,
                harmonyScore: 96,
                stylistAdvice: "Liquid emerald satin midi dress highlighted by the 18K rose gold Tiffany T wire bracelet and solitaire diamond ring. Keep the look modern with the Coach Tabby bag."
            )
        ]
    }

    static func initialTrips(from items: [WomenWardrobeItem]) -> [WomenTripPlan] {
        let udaipurIds = Set(items.prefix(6).map { $0.id })
        return [
            WomenTripPlan(
                destination: "Udaipur Royal Palace Wedding",
                travelDate: "Dec 12 - Dec 16",
                packedItemIds: udaipurIds,
                returnedItemIds: [],
                notes: "Keep Tanishq choker in hotel room electronic safe. Return to Velvet Vanity Box 1 upon return."
            )
        ]
    }
}
