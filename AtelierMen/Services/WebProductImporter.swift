import Foundation
import UIKit

public struct ImportedProductData {
    public var name: String = ""
    public var brand: String = ""
    public var price: Double = 0.0
    public var category: ItemCategory = .clothes
    public var subcategory: String = ""
    public var fabricMaterial: String = ""
    public var size: String = ""
    public var modelSpecs: String = ""
    public var shoeSize: String = ""
    public var bagCapacity: String = ""
    public var volumeSize: String = ""
    public var accessoryMaterial: String = ""
    public var occasion: String = "Everyday"
    public var notes: String = ""
    public var photoFilenames: [String] = []
    public var sourceUrl: String = ""
}

public final class WebProductImporter {
    public static let shared = WebProductImporter()

    // Realistic Mobile Safari user agent matching iOS environment to avoid bot blocking
    private let userAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1"

    public func importFromUrl(_ rawUrl: String) async throws -> ImportedProductData {
        let trimmed = rawUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed) else {
            throw NSError(domain: "WebProductImporter", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL string"])
        }

        // Direct image URL check
        let lowerPath = url.path.lowercased()
        if lowerPath.hasSuffix(".jpg") || lowerPath.hasSuffix(".jpeg") || lowerPath.hasSuffix(".png") || lowerPath.hasSuffix(".webp") {
            var data = ImportedProductData()
            data.sourceUrl = trimmed
            if let savedName = await downloadAndSaveImage(from: url) {
                data.photoFilenames = [savedName]
            } else {
                data.photoFilenames = [trimmed]
            }
            data.name = "Imported Image Item"
            return data
        }

        let host = url.host?.lowercased() ?? ""
        let isAmazonHost = host.contains("amazon.") || host.contains("amzn.") || host == "amzn.in" || host == "amzn.to"

        let targetUrl: URL
        let urlSlug: String?
        if isAmazonHost {
            let canonical = canonicalizeAmazonUrl(trimmed)
            targetUrl = canonical.url
            urlSlug = canonical.slug
        } else {
            targetUrl = url
            urlSlug = nil
        }

        var request = URLRequest(url: targetUrl)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8", forHTTPHeaderField: "Accept")
        request.setValue("en-IN,en-GB;q=0.9,en-US;q=0.8,en;q=0.7", forHTTPHeaderField: "Accept-Language")
        request.setValue("none", forHTTPHeaderField: "Sec-Fetch-Site")
        request.setValue("navigate", forHTTPHeaderField: "Sec-Fetch-Mode")
        request.setValue("document", forHTTPHeaderField: "Sec-Fetch-Dest")
        request.timeoutInterval = 20.0

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let html = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) else {
            throw NSError(domain: "WebProductImporter", code: 402, userInfo: [NSLocalizedDescriptionKey: "Unable to decode webpage HTML"])
        }

        let finalHost = (response.url ?? targetUrl).host?.lowercased() ?? host
        if isAmazonHost || finalHost.contains("amazon.") || finalHost.contains("amzn.") {
            return await parseAmazon(html: html, sourceUrl: trimmed, baseUrl: targetUrl, fallbackSlug: urlSlug)
        } else if finalHost.contains("myntra.com") {
            return await parseMyntra(html: html, sourceUrl: trimmed)
        } else {
            return await parseGenericWebPage(html: html, sourceUrl: trimmed, baseUrl: targetUrl)
        }
    }

    // MARK: - Amazon Canonicalization
    private func canonicalizeAmazonUrl(_ rawUrl: String) -> (url: URL, asin: String?, slug: String?) {
        guard let originalUrl = URL(string: rawUrl) else {
            return (URL(string: rawUrl) ?? URL(string: "https://www.amazon.in")!, nil, nil)
        }

        let urlStr = originalUrl.absoluteString
        var asin: String? = nil
        var slug: String? = nil

        // Match /dp/ASIN or /gp/product/ASIN or /d/ASIN
        if let match = extractRegex(pattern: "/(?:dp|gp/product|d)/([A-Z0-9]{10})", from: urlStr) {
            asin = match
        }

        // Match slug before /dp/
        if let matchSlug = extractRegex(pattern: "https?://[^/]+/([^/]+)/(?:dp|gp/product|d)/", from: urlStr),
           !matchSlug.isEmpty, matchSlug != "gp", matchSlug != "dp" {
            slug = matchSlug.replacingOccurrences(of: "-", with: " ")
        }

        if let asin = asin {
            let host = originalUrl.host ?? "www.amazon.in"
            if let clean = URL(string: "https://\(host)/dp/\(asin)") {
                return (clean, asin, slug)
            }
        }

        return (originalUrl, asin, slug)
    }

    // MARK: - Amazon Parsing
    private func parseAmazon(html: String, sourceUrl: String, baseUrl: URL, fallbackSlug: String? = nil) async -> ImportedProductData {
        var result = ImportedProductData()
        result.sourceUrl = sourceUrl
        result.notes = "Imported from Amazon: \(sourceUrl)"

        let isCaptcha = html.contains("validateCaptcha") || html.contains("Robot Check")

        // 1. Title Extraction & Cleaning
        var rawTitle = ""
        if let h1Match = extractRegex(pattern: "<span[^>]+id=[\"']productTitle[\"'][^>]*>(.*?)</span>", from: html),
           !h1Match.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            rawTitle = h1Match
        } else if let metaTitle = extractRegex(pattern: "<meta[^>]+name=[\"']title[\"'][^>]+content=[\"']([^\"']+)[\"']", from: html),
                  !metaTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            rawTitle = metaTitle
        } else if let spanBold = extractRegex(pattern: "<span class=[\"']a-text-bold[\"']>([^<]+)</span>", from: html),
                  !spanBold.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            rawTitle = spanBold
        } else if let tTag = extractTitleTag(from: html),
                  !tTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  !tTag.hasPrefix("Amazon.in") {
            rawTitle = tTag
        }

        // Fallback to URL slug if blocked by captcha or title is generic
        if rawTitle.isEmpty || isCaptcha || rawTitle.trimmingCharacters(in: .whitespacesAndNewlines) == "Amazon.in" {
            if let slug = fallbackSlug, !slug.isEmpty {
                rawTitle = slug
            }
        }

        result.name = cleanProductTitle(rawTitle)
        if result.name.isEmpty {
            result.name = "Amazon Product"
        }

        // 2. Brand Extraction
        if let byline = extractRegex(pattern: "id=[\"']bylineInfo[\"'][^>]*>(.*?)</a>", from: html) {
            var b = byline.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            b = b.replacingOccurrences(of: "Brand: ", with: "")
            b = b.replacingOccurrences(of: "Visit the ", with: "")
            b = b.replacingOccurrences(of: " Store", with: "")
            result.brand = b.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            // Infer brand from title first word (e.g. Nike, Rimowa, Apple)
            let words = result.name.split(separator: " ")
            if let first = words.first, first.count > 1 {
                result.brand = String(first)
            }
        }

        // 3. Price Extraction
        if let wholePrice = extractRegex(pattern: "<span class=[\"']a-price-whole[\"']>([^<]+)</span>", from: html) {
            let digits = wholePrice.filter("0123456789.".contains)
            if let p = Double(digits) {
                result.price = p
            }
        } else if let offscreenPrice = extractRegex(pattern: "<span class=[\"']a-offscreen[\"']>([^<]+)</span>", from: html) {
            let digits = offscreenPrice.filter("0123456789.".contains)
            if let p = Double(digits) {
                result.price = p
            }
        }

        // 4. Image Extraction (Desktop & Mobile Amazon)
        var candidateImages: [String] = []

        func normalizeAmazonUrl(_ urlStr: String) -> String {
            if let match = urlStr.range(of: "^(https://m\\.media-amazon\\.com/images/I/[A-Za-z0-9+%_-]+)", options: .regularExpression) {
                return String(urlStr[match]) + ".jpg"
            }
            return urlStr
        }

        let ignoredSubstrings = ["icon", "logo", "badge", "play", "pixel", "transparent", "banner", "spinner", "button"]

        let patterns = [
            "\"hiRes\"\\s*:\\s*\"(https://m\\.media-amazon\\.com/images/I/[^\"\\\\?]+)",
            "\"large\"\\s*:\\s*\"(https://m\\.media-amazon\\.com/images/I/[^\"\\\\?]+)",
            "data-a-hires=[\"'](https://m\\.media-amazon\\.com/images/I/[^\"'\\?]+)[\"']",
            "data-old-hires=[\"'](https://m\\.media-amazon\\.com/images/I/[^\"'\\?]+)[\"']",
            "\"mainUrl\"\\s*:\\s*\"(https://m\\.media-amazon\\.com/images/I/[^\"\\\\?]+)"
        ]

        for pat in patterns {
            if let regex = try? NSRegularExpression(pattern: pat, options: [.caseInsensitive, .dotMatchesLineSeparators]) {
                let nsString = html as NSString
                let matches = regex.matches(in: html, range: NSRange(location: 0, length: nsString.length))
                for match in matches {
                    if let r = Range(match.range(at: 1), in: html) {
                        let rawImg = String(html[r])
                        let cleanImg = normalizeAmazonUrl(rawImg)
                        let lower = cleanImg.lowercased()
                        if !candidateImages.contains(cleanImg) && !ignoredSubstrings.contains(where: { lower.contains($0) }) {
                            candidateImages.append(cleanImg)
                        }
                    }
                }
            }
        }

        // Regex capture for all media-amazon product master images
        if let regex = try? NSRegularExpression(pattern: "https://m\\.media-amazon\\.com/images/I/([A-Za-z0-9+%_-]{10,})(?:\\.[a-zA-Z0-9_\\-\\.]+)?\\.(?:jpg|png)", options: [.caseInsensitive]) {
            let nsString = html as NSString
            let matches = regex.matches(in: html, range: NSRange(location: 0, length: nsString.length))
            for match in matches {
                if let r = Range(match.range(at: 1), in: html) {
                    let id = String(html[r])
                    let lower = id.lowercased()
                    if !ignoredSubstrings.contains(where: { lower.contains($0) }) {
                        let fullUrl = "https://m.media-amazon.com/images/I/\(id).jpg"
                        if !candidateImages.contains(fullUrl) {
                            candidateImages.append(fullUrl)
                        }
                    }
                }
            }
        }

        // Fallback: landingImage
        if candidateImages.isEmpty {
            let fallbackPattern = "id=[\"']landingImage[\"'][^>]+src=[\"']([^\"']+)[\"']"
            if let landingSrc = extractRegex(pattern: fallbackPattern, from: html), !landingSrc.isEmpty {
                candidateImages.append(normalizeAmazonUrl(landingSrc))
            }
        }

        // Deduplicate maintaining order
        var uniqueCandidates: [String] = []
        for img in candidateImages {
            if !uniqueCandidates.contains(img) {
                uniqueCandidates.append(img)
            }
        }

        result.photoFilenames = await downloadAllImages(imageUrls: Array(uniqueCandidates.prefix(6)))
        assignCategoryAndSubcategory(for: (result.name + " " + result.brand).lowercased(), result: &result)
        return result
    }

    // MARK: - Myntra Parsing
    private func parseMyntra(html: String, sourceUrl: String) async -> ImportedProductData {
        var result = ImportedProductData()
        result.sourceUrl = sourceUrl
        result.notes = "Imported from Myntra: \(sourceUrl)"

        guard let myxRange = html.range(of: "window.__myx\\s*=\\s*\\{", options: .regularExpression) else {
            return await parseGenericWebPage(html: html, sourceUrl: sourceUrl, baseUrl: URL(string: sourceUrl)!)
        }

        let substring = html[myxRange.upperBound...]
        if let closingIndex = findMatchingBrace(in: substring) {
            let jsonString = "{" + String(substring[..<closingIndex])
            if let jsonData = jsonString.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
               let pdpData = json["pdpData"] as? [String: Any] {

                let rawName = (pdpData["name"] as? String) ?? ""
                result.name = cleanProductTitle(rawName)

                if let brandDict = pdpData["brand"] as? [String: Any] {
                    result.brand = (brandDict["name"] as? String) ?? ""
                }

                if let priceDict = pdpData["price"] as? [String: Any] {
                    let discounted = priceDict["discounted"] as? Double ?? Double(priceDict["discounted"] as? Int ?? 0)
                    let mrp = priceDict["mrp"] as? Double ?? Double(priceDict["mrp"] as? Int ?? 0)
                    result.price = discounted > 0 ? discounted : mrp
                }

                var imageUrls: [String] = []
                if let media = pdpData["media"] as? [String: Any],
                   let albums = media["albums"] as? [[String: Any]] {
                    for album in albums {
                        if let images = album["images"] as? [[String: Any]] {
                            for img in images {
                                if let src = img["src"] as? String {
                                    let fullUrl = src
                                        .replacingOccurrences(of: "($height)", with: "1440")
                                        .replacingOccurrences(of: "($qualityPercentage)", with: "85")
                                        .replacingOccurrences(of: "($width)", with: "1080")
                                        .replacingOccurrences(of: "http://", with: "https://")
                                    imageUrls.append(fullUrl)
                                }
                            }
                        }
                    }
                }

                result.photoFilenames = await downloadAllImages(imageUrls: Array(imageUrls.prefix(6)))

                if let articleAttributes = pdpData["articleAttributes"] as? [String: Any] {
                    let topFabric = articleAttributes["Top Fabric"] as? String ?? articleAttributes["Fabric"] as? String ?? ""
                    let pattern = articleAttributes["Pattern"] as? String ?? ""
                    var parts: [String] = []
                    if !topFabric.isEmpty { parts.append(topFabric) }
                    if !pattern.isEmpty { parts.append(pattern) }
                    result.fabricMaterial = parts.joined(separator: " • ")

                    if let occasion = articleAttributes["Occasion"] as? String {
                        result.occasion = occasion
                    }
                }

                if let sizes = pdpData["sizes"] as? [[String: Any]] {
                    let available = sizes.compactMap { $0["label"] as? String }
                    if !available.isEmpty {
                        result.size = "Sizes: " + available.joined(separator: ", ")
                    }
                }

                let analyticsStr = (pdpData["analytics"] as? [String: Any])?.description ?? ""
                let fullText = (result.name + " " + analyticsStr).lowercased()
                assignCategoryAndSubcategory(for: fullText, result: &result)
                return result
            }
        }

        return await parseGenericWebPage(html: html, sourceUrl: sourceUrl, baseUrl: URL(string: sourceUrl)!)
    }

    // MARK: - Generic Web Page / OpenGraph
    private func parseGenericWebPage(html: String, sourceUrl: String, baseUrl: URL) async -> ImportedProductData {
        var result = ImportedProductData()
        result.sourceUrl = sourceUrl
        result.notes = "Imported from web: \(sourceUrl)"

        if let rawTitle = extractMeta(property: "og:title", from: html) ?? extractTitleTag(from: html) {
            result.name = cleanProductTitle(rawTitle)
        }

        if let desc = extractMeta(property: "og:description", from: html) {
            result.notes += "\n" + cleanHtmlEntities(desc)
        }

        if let brand = extractMeta(property: "og:site_name", from: html) {
            result.brand = cleanHtmlEntities(brand)
        }

        var candidateImages: [String] = []
        if let ogImage = extractMeta(property: "og:image", from: html) {
            if let resolved = URL(string: ogImage, relativeTo: baseUrl)?.absoluteString {
                candidateImages.append(resolved)
            }
        }

        if let priceStr = extractMeta(property: "product:price:amount", from: html),
           let p = Double(priceStr.filter("0123456789.".contains)) {
            result.price = p
        }

        result.photoFilenames = await downloadAllImages(imageUrls: candidateImages)
        assignCategoryAndSubcategory(for: result.name.lowercased(), result: &result)
        return result
    }

    // MARK: - Title Cleaning
    public func cleanProductTitle(_ raw: String) -> String {
        var t = cleanHtmlEntities(raw)
        // Remove prefixes like "Buy ", "Shop ", "Purchase ", "Order "
        t = t.replacingOccurrences(of: "^(Buy|Shop|Purchase|Order)\\s+", with: "", options: [.regularExpression, .caseInsensitive])
        // Remove trailing store and category suffixes
        t = t.replacingOccurrences(of: "\\s+(at|on)\\s+Amazon\\.[a-z.]+.*", with: "", options: [.regularExpression, .caseInsensitive])
        t = t.replacingOccurrences(of: "\\s*[:|-]\\s*Amazon\\.[a-z.]+.*", with: "", options: [.regularExpression, .caseInsensitive])
        t = t.replacingOccurrences(of: "\\s*[:|-]\\s*Buy\\s+Online.*", with: "", options: [.regularExpression, .caseInsensitive])
        t = t.replacingOccurrences(of: "\\s*\\|\\s*Myntra.*", with: "", options: [.regularExpression, .caseInsensitive])
        t = t.replacingOccurrences(of: "\\s+Online\\s+at\\s+Best\\s+Prices.*", with: "", options: [.regularExpression, .caseInsensitive])
        t = t.replacingOccurrences(of: "\\s+at\\s+best\\s+price.*", with: "", options: [.regularExpression, .caseInsensitive])
        t = t.replacingOccurrences(of: "\\s*:\\s*(Shoes|Clothing|Electronics|Handbags|Luggage|Beauty|Sports).*", with: "", options: [.regularExpression, .caseInsensitive])
        // Remove trailing shoe sizes e.g. " 9 UK"
        t = t.replacingOccurrences(of: "\\s+\\d+(?:\\.\\d+)?\\s*(?:UK|US|EU|IN)\\b.*", with: "", options: [.regularExpression, .caseInsensitive])
        return t.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Category Inference (Across all 6 categories!)
    private func assignCategoryAndSubcategory(for text: String, result: inout ImportedProductData) {
        let shoeKeywords = ["shoe", "sneaker", "boot", "loafer", "oxford", "derby", "footwear", "sandal", "trainer", "slides", "downshifter"]
        let bagKeywords = ["bag", "backpack", "briefcase", "duffel", "duffle", "luggage", "suitcase", "sling", "tote", "messenger", "dopp kit", "carry-on", "pouch"]
        let groomingKeywords = [
            "cologne", "perfume", "fragrance", "serum", "moisturizer", "skincare", "cream",
            "shave", "razor", "pomade", "beard", "eau de parfum", "grooming", "lotion", "cleanser",
            "tongue", "cleaner", "scraper", "oral", "dental", "toothbrush", "toothpaste", "floss",
            "hygiene", "trimmer", "clipper", "comb", "tweezer", "nail", "soap", "body wash",
            "deodorant", "shampoo", "conditioner", "bath"
        ]
        let accessoryKeywords = ["wallet", "cardholder", "belt", "sunglass", "glasses", "eyewear", "cufflink", "tie clip", "watch winder", "pocket square", "scarf", "hat", "cap"]
        let techKeywords = ["laptop", "phone", "macbook", "headphone", "audio", "earbuds", "watch", "camera", "tablet", "gadget", "charger", "display", "ipad", "airpods"]
        let sportswearKeywords = ["sportswear", "activewear", "gym", "workout", "training", "dri-fit", "aeroready", "tracksuit", "jogger", "compression", "jersey", "rashguard", "athletic", "legging", "running shorts", "running tee", "sports tee", "gym tee", "gym shorts"]
        let clothesKeywords = ["shirt", "t-shirt", "tshirt", "tee", "polo", "suit", "blazer", "jacket", "coat", "trouser", "pant", "chino", "denim", "jean", "knit", "sweater", "cardigan", "hoodie", "overcoat", "kurta", "sherwani", "waistcoat"]

        if shoeKeywords.contains(where: { text.contains($0) }) {
            result.category = .shoes
            if text.contains("sneaker") || text.contains("trainer") || text.contains("running") || text.contains("downshifter") {
                result.subcategory = "Sneakers & Streetwear"
            } else if text.contains("boot") {
                result.subcategory = "Boots & Heritage"
            } else if text.contains("loafer") {
                result.subcategory = "Loafers & Slip-ons"
            } else {
                result.subcategory = "Formal Oxfords & Derbies"
            }
            if let sizeMatch = extractRegex(pattern: "(\\d+(?:\\.\\d+)?\\s*(?:UK|US|EU))", from: result.name) {
                result.shoeSize = sizeMatch
            } else if result.shoeSize.isEmpty {
                result.shoeSize = result.size.isEmpty ? "UK 9 / US 10" : result.size
            }
        } else if bagKeywords.contains(where: { text.contains($0) }) {
            result.category = .bags
            if text.contains("briefcase") || text.contains("work") {
                result.subcategory = "Briefcases & Work Bags"
            } else if text.contains("backpack") {
                result.subcategory = "Backpacks & Slings"
            } else if text.contains("luggage") || text.contains("suitcase") || text.contains("carry-on") {
                result.subcategory = "Carry-On Luggage & Cases"
            } else if text.contains("duffel") || text.contains("duffle") || text.contains("weekender") {
                result.subcategory = "Weekender Duffels"
            } else {
                result.subcategory = "Totes & Messengers"
            }
            result.bagCapacity = "Standard Capacity"
        } else if groomingKeywords.contains(where: { text.contains($0) }) {
            result.category = .grooming
            if text.contains("cologne") || text.contains("perfume") || text.contains("fragrance") || text.contains("parfum") {
                result.subcategory = "Fragrances & Colognes"
            } else if text.contains("serum") || text.contains("skincare") || text.contains("cream") || text.contains("moisturizer") {
                result.subcategory = "Face & Skincare Serums"
            } else if text.contains("shave") || text.contains("razor") || text.contains("beard") {
                result.subcategory = "Shaving & Beard Care"
            } else if text.contains("tongue") || text.contains("scraper") || text.contains("dental") || text.contains("oral") || text.contains("toothbrush") || text.contains("brush") || text.contains("floss") || text.contains("trimmer") || text.contains("clipper") || text.contains("comb") || text.contains("cleaner") || text.contains("nail") || text.contains("tweezer") {
                result.subcategory = "Grooming Tools & Trimmers"
            } else if text.contains("soap") || text.contains("shower") || text.contains("bath") || text.contains("deodorant") || text.contains("body wash") || text.contains("shampoo") {
                result.subcategory = "Body & Shower Essentials"
            } else {
                result.subcategory = "Hair Styling & Pomades"
            }
            result.volumeSize = "Standard Size"
        } else if accessoryKeywords.contains(where: { text.contains($0) }) {
            result.category = .accessories
            if text.contains("wallet") || text.contains("cardholder") {
                result.subcategory = "Wallets & Cardholders"
            } else if text.contains("belt") {
                result.subcategory = "Belts & Leather Goods"
            } else if text.contains("sunglass") || text.contains("glasses") || text.contains("eyewear") {
                result.subcategory = "Sunglasses & Eyewear"
            } else if text.contains("cufflink") {
                result.subcategory = "Cufflinks & Tie Clips"
            } else {
                result.subcategory = "Hats & Caps"
            }
            result.accessoryMaterial = "Premium Material"
        } else if techKeywords.contains(where: { text.contains($0) }) {
            result.category = .electronics
            if text.contains("headphone") || text.contains("audio") || text.contains("earbuds") {
                result.subcategory = "Audio & Acoustics"
            } else if text.contains("watch") {
                result.subcategory = "Watches & Wearables"
            } else if text.contains("camera") {
                result.subcategory = "Cameras & Optics"
            } else {
                result.subcategory = "Laptops & Computing"
            }
            result.modelSpecs = result.fabricMaterial.isEmpty ? "Flagship Edition" : result.fabricMaterial
        } else if sportswearKeywords.contains(where: { text.contains($0) }) {
            result.category = .sportswear
            if text.contains("running") || text.contains("marathon") {
                result.subcategory = "Running & Marathon Gear"
            } else if text.contains("gym") || text.contains("workout") || text.contains("training") {
                result.subcategory = "Gym & Training Apparel"
            } else if text.contains("hoodie") || text.contains("tracksuit") {
                result.subcategory = "Performance Hoodies & Tracksuits"
            } else if text.contains("short") || text.contains("jogger") {
                result.subcategory = "Athletic Shorts & Joggers"
            } else if text.contains("compression") || text.contains("base layer") {
                result.subcategory = "Compression & Base Layers"
            } else if text.contains("jersey") || text.contains("kit") {
                result.subcategory = "Sports Jerseys & Kits"
            } else {
                result.subcategory = "Outdoor & Trail Activewear"
            }
        } else if clothesKeywords.contains(where: { text.contains($0) }) {
            result.category = .clothes
            if text.contains("suit") || text.contains("blazer") {
                result.subcategory = "Suits & Blazers"
            } else if text.contains("shirt") || text.contains("polo") {
                result.subcategory = "Shirts & Polos"
            } else if text.contains("jacket") || text.contains("coat") || text.contains("overcoat") {
                result.subcategory = "Jackets & Outerwear"
            } else if text.contains("trouser") || text.contains("pant") || text.contains("chino") {
                result.subcategory = "Trousers & Chinos"
            } else if text.contains("jean") || text.contains("denim") {
                result.subcategory = "Denim & Jeans"
            } else {
                result.subcategory = "T-Shirts & Knits"
            }
        } else {
            // Unrecognized fallback: Do not falsely assign to T-Shirts & Knits!
            if text.contains("cleaner") || text.contains("tool") || text.contains("hygiene") || text.contains("care") {
                result.category = .grooming
                result.subcategory = "Grooming Tools & Trimmers"
            } else {
                result.category = .accessories
                result.subcategory = "EDC & Accessories"
            }
        }
    }

    // MARK: - Image Downloader
    private func downloadAllImages(imageUrls: [String]) async -> [String] {
        var filenames: [String] = []
        for urlStr in imageUrls {
            if let url = URL(string: urlStr) {
                if let saved = await downloadAndSaveImage(from: url) {
                    filenames.append(saved)
                } else {
                    // CRITICAL FALLBACK: If local saving fails or times out,
                    // keep the live HTTPS CDN URL! ItemImageView & AsyncImage will render it seamlessly.
                    filenames.append(urlStr)
                }
            }
        }
        return filenames
    }

    private func downloadAndSaveImage(from url: URL) async -> String? {
        var req = URLRequest(url: url)
        req.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        req.timeoutInterval = 10.0

        guard let (data, response) = try? await URLSession.shared.data(for: req),
              let http = response as? HTTPURLResponse, http.statusCode == 200,
              data.count > 1000,
              UIImage(data: data) != nil else {
            return nil
        }

        let filename = "store_\(UUID().uuidString.prefix(12)).jpg"
        return ImageManager.shared.saveImageData(data, filename: filename)
    }

    // MARK: - Helpers
    private func findMatchingBrace(in text: Substring) -> String.Index? {
        var depth = 1
        var index = text.startIndex
        while index < text.endIndex {
            let char = text[index]
            if char == "{" {
                depth += 1
            } else if char == "}" {
                depth -= 1
                if depth == 0 {
                    return index
                }
            }
            index = text.index(after: index)
        }
        return nil
    }

    private func extractMeta(property: String, from html: String) -> String? {
        let pattern = "<meta[^>]+(?:property|name)=[\"']\(property)[\"'][^>]+content=[\"']([^\"']+)[\"']"
        return extractRegex(pattern: pattern, from: html)
    }

    private func extractTitleTag(from html: String) -> String? {
        let pattern = "<title[^>]*>([^<]+)</title>"
        return extractRegex(pattern: pattern, from: html)
    }

    private func extractRegex(pattern: String, from text: String) -> String? {
        if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           match.numberOfRanges > 1,
           let range = Range(match.range(at: 1), in: text) {
            return String(text[range])
        }
        return nil
    }

    private func cleanHtmlEntities(_ text: String) -> String {
        text.replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
