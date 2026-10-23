import Foundation
import UIKit

@MainActor
public final class AtelierBackupManager {
    public static let shared = AtelierBackupManager()

    private init() {}

    private var dateStamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmm"
        return formatter.string(from: Date())
    }

    // MARK: - Export Unified Archive (Men & Women)
    public func generateUnifiedBackup(menStore: DataStore, womenStore: WomenDataStore) -> URL? {
        let backup = AtelierUnifiedBackup(
            menItems: menStore.items,
            menWishlist: menStore.wishlistItems,
            menLooks: menStore.looks,
            menTripPlans: menStore.tripPlans,
            womenItems: womenStore.items,
            womenWishlist: womenStore.wishlistItems,
            womenLooks: womenStore.looks,
            womenTrips: womenStore.trips
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        guard let data = try? encoder.encode(backup) else { return nil }

        let tempUrl = FileManager.default.temporaryDirectory.appendingPathComponent("Atelier_Complete_Archive_\(dateStamp).json")
        do {
            try data.write(to: tempUrl, options: .atomic)
            return tempUrl
        } catch {
            return nil
        }
    }

    // MARK: - Export Men's Archive Only
    public func generateMenBackup(menStore: DataStore) -> URL? {
        let backup = AtelierBackup(
            format: "AtelierMenBackup",
            version: 1,
            exportDate: Date(),
            items: menStore.items,
            wishlistItems: menStore.wishlistItems,
            looks: menStore.looks,
            tripPlans: menStore.tripPlans
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        guard let data = try? encoder.encode(backup) else { return nil }

        let tempUrl = FileManager.default.temporaryDirectory.appendingPathComponent("Atelier_Mens_Vault_\(dateStamp).json")
        do {
            try data.write(to: tempUrl, options: .atomic)
            return tempUrl
        } catch {
            return nil
        }
    }

    // MARK: - Export Women's Archive Only
    public func generateWomenBackup(womenStore: WomenDataStore) -> URL? {
        let backup = WomenAtelierBackup(
            format: "AtelierWomenBackup",
            version: 1,
            exportDate: Date(),
            items: womenStore.items,
            wishlistItems: womenStore.wishlistItems,
            looks: womenStore.looks,
            trips: womenStore.trips
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        guard let data = try? encoder.encode(backup) else { return nil }

        let tempUrl = FileManager.default.temporaryDirectory.appendingPathComponent("Atelier_Womens_Boutique_\(dateStamp).json")
        do {
            try data.write(to: tempUrl, options: .atomic)
            return tempUrl
        } catch {
            return nil
        }
    }

    // MARK: - Import & Restore Backup
    public func importBackup(
        from fileUrl: URL,
        menStore: DataStore,
        womenStore: WomenDataStore,
        mode: BackupImportMode
    ) -> Result<ImportSummary, Error> {
        let shouldStopAccessing = fileUrl.startAccessingSecurityScopedResource()
        defer {
            if shouldStopAccessing { fileUrl.stopAccessingSecurityScopedResource() }
        }

        guard let data = try? Data(contentsOf: fileUrl) else {
            return .failure(NSError(domain: "AtelierImport", code: 404, userInfo: [NSLocalizedDescriptionKey: "Unable to read contents of the chosen file."]))
        }

        // Try decoding with multiple strategies (ISO8601 first, fallback to standard Date)
        if let summary = attemptDecode(data: data, menStore: menStore, womenStore: womenStore, mode: mode, dateStrategy: .iso8601) {
            return .success(summary)
        }

        if let summary = attemptDecode(data: data, menStore: menStore, womenStore: womenStore, mode: mode, dateStrategy: .deferredToDate) {
            return .success(summary)
        }

        if let summary = attemptDecode(data: data, menStore: menStore, womenStore: womenStore, mode: mode, dateStrategy: .secondsSince1970) {
            return .success(summary)
        }

        return .failure(NSError(
            domain: "AtelierImport",
            code: 422,
            userInfo: [NSLocalizedDescriptionKey: "The selected file is not a valid Atelier wardrobe backup or compatible JSON format."]
        ))
    }

    private func attemptDecode(
        data: Data,
        menStore: DataStore,
        womenStore: WomenDataStore,
        mode: BackupImportMode,
        dateStrategy: JSONDecoder.DateDecodingStrategy
    ) -> ImportSummary? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = dateStrategy

        // 1. Try decoding Unified Archive (contains both Men and Women collections)
        if let unified = try? decoder.decode(AtelierUnifiedBackup.self, from: data),
           (unified.menItems != nil || unified.womenItems != nil || unified.format == "AtelierUnifiedBackup") {
            var summary = ImportSummary()

            if let mItems = unified.menItems {
                let res = menStore.restoreItems(
                    mItems,
                    wishlist: unified.menWishlist ?? [],
                    looks: unified.menLooks ?? [],
                    trips: unified.menTripPlans ?? [],
                    mode: mode
                )
                summary.menItems = res.items
                summary.menWishlist = res.wishlist
                summary.looksCount += unified.menLooks?.count ?? 0
                summary.tripsCount += unified.menTripPlans?.count ?? 0
            }

            if let wItems = unified.womenItems {
                let res = womenStore.restoreItems(
                    wItems,
                    wishlist: unified.womenWishlist ?? [],
                    looks: unified.womenLooks ?? [],
                    trips: unified.womenTrips ?? [],
                    mode: mode
                )
                summary.womenItems = res.items
                summary.womenWishlist = res.wishlist
                summary.looksCount += unified.womenLooks?.count ?? 0
                summary.tripsCount += unified.womenTrips?.count ?? 0
            }

            return summary
        }

        // 2. Try decoding Women's Standalone Archive
        if let womenBackup = try? decoder.decode(WomenAtelierBackup.self, from: data) {
            let res = womenStore.restoreItems(
                womenBackup.items,
                wishlist: womenBackup.wishlistItems,
                looks: womenBackup.looks,
                trips: womenBackup.trips,
                mode: mode
            )
            return ImportSummary(
                menItems: 0,
                menWishlist: 0,
                womenItems: res.items,
                womenWishlist: res.wishlist,
                looksCount: womenBackup.looks.count,
                tripsCount: womenBackup.trips.count
            )
        }

        // 3. Try decoding Men's Standalone Archive
        if let menBackup = try? decoder.decode(AtelierBackup.self, from: data) {
            let res = menStore.restoreItems(
                menBackup.items,
                wishlist: menBackup.wishlistItems,
                looks: menBackup.looks,
                trips: menBackup.tripPlans,
                mode: mode
            )
            return ImportSummary(
                menItems: res.items,
                menWishlist: res.wishlist,
                womenItems: 0,
                womenWishlist: 0,
                looksCount: menBackup.looks.count,
                tripsCount: menBackup.tripPlans.count
            )
        }

        // 4. Try decoding raw array of Women's Items
        if let womenItems = try? decoder.decode([WomenWardrobeItem].self, from: data), !womenItems.isEmpty {
            let res = womenStore.restoreItems(womenItems, wishlist: [], looks: [], trips: [], mode: mode)
            return ImportSummary(
                menItems: 0,
                menWishlist: 0,
                womenItems: res.items,
                womenWishlist: 0,
                looksCount: 0,
                tripsCount: 0
            )
        }

        // 5. Try decoding raw array of Men's Items
        if let menItems = try? decoder.decode([WardrobeItem].self, from: data), !menItems.isEmpty {
            let res = menStore.restoreItems(menItems, wishlist: [], looks: [], trips: [], mode: mode)
            return ImportSummary(
                menItems: res.items,
                menWishlist: 0,
                womenItems: 0,
                womenWishlist: 0,
                looksCount: 0,
                tripsCount: 0
            )
        }

        return nil
    }
}
