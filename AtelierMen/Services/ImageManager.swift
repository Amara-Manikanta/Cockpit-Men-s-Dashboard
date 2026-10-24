import SwiftUI

public final class ImageManager {
    public static let shared = ImageManager()

    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    public func saveImageData(_ data: Data, filename: String? = nil) -> String? {
        let name = filename ?? "item_\(UUID().uuidString).jpg"
        let fileURL = documentsDirectory.appendingPathComponent(name)
        do {
            try data.write(to: fileURL)
            return name
        } catch {
            print("Failed to save image: \(error)")
            return nil
        }
    }

    public func localImageUrl(for filename: String) -> URL? {
        let fileURL = documentsDirectory.appendingPathComponent(filename)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            return fileURL
        }

        // Check main bundle or BundledImages subfolder
        let baseName = (filename as NSString).deletingPathExtension
        let ext = (filename as NSString).pathExtension
        if let bundleUrl = Bundle.main.url(forResource: baseName, withExtension: ext) {
            return bundleUrl
        }
        if let bundleUrl = Bundle.main.url(forResource: baseName, withExtension: ext, subdirectory: "BundledImages") {
            return bundleUrl
        }
        return nil
    }

    public func deleteImage(filename: String) {
        let fileURL = documentsDirectory.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: fileURL)
    }

    public func loadUIImage(for filenameOrUrl: String) -> UIImage? {
        if let localUrl = localImageUrl(for: filenameOrUrl),
           let data = try? Data(contentsOf: localUrl) {
            return UIImage(data: data)
        }
        return nil
    }
}

public struct ItemImageView: View {
    public let photoNameOrUrl: String
    public let category: ItemCategory
    public var contentMode: ContentMode = .fill

    public init(photoNameOrUrl: String, category: ItemCategory, contentMode: ContentMode = .fill) {
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
                        colors: [Color(white: 0.18), Color(white: 0.12)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: photoNameOrUrl)
                        .font(.system(size: 44, weight: .light))
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
                colors: [Color(white: 0.20), Color(white: 0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            VStack(spacing: 8) {
                Image(systemName: category.iconName)
                    .font(.system(size: 38, weight: .light))
                    .foregroundStyle(category.accentColor.opacity(0.85))
                Text(category.rawValue.uppercased())
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .tracking(1.5)
                    .foregroundStyle(.white.opacity(0.45))
            }
        }
    }
}
