import SwiftUI

public struct WebImportSheet: View {
    @Environment(\.dismiss) private var dismiss
    public let onImportComplete: (ImportedProductData) -> Void

    @State private var urlString: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var importedData: ImportedProductData? = nil

    public init(onImportComplete: @escaping (ImportedProductData) -> Void) {
        self.onImportComplete = onImportComplete
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Card
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(LuxuryTheme.gold.opacity(0.18))
                                .frame(width: 56, height: 56)
                            Image(systemName: "globe")
                                .font(.system(size: 26))
                                .foregroundStyle(LuxuryTheme.gold)
                        }

                        Text("Import from Web or Store")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(LuxuryTheme.textPrimary)

                        Text("Paste a product link from Myntra, Apple, Nike, Amazon, Zara or any direct image URL. We'll automatically download high-resolution photos and auto-fill product details!")
                            .font(.system(size: 13))
                            .foregroundStyle(LuxuryTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 10)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .luxuryCardStyle(cornerRadius: 16)

                    // URL Input Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Product Link or Image URL")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(LuxuryTheme.textSecondary)

                        HStack {
                            TextField("https://www.myntra.com/... or apple.com", text: $urlString)
                                .font(.system(size: 14))
                                .foregroundStyle(LuxuryTheme.textPrimary)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)

                            if !urlString.isEmpty {
                                Button(action: { urlString = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(LuxuryTheme.textTertiary)
                                }
                            }

                            Button(action: {
                                if let clip = UIPasteboard.general.string {
                                    urlString = clip
                                }
                            }) {
                                Text("Paste")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(LuxuryTheme.gold)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(LuxuryTheme.secondaryBackground)
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(14)
                        .background(LuxuryTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(LuxuryTheme.cardBorder, lineWidth: 1)
                        )

                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .font(.system(size: 12))
                                .foregroundStyle(Color.red)
                                .padding(.top, 4)
                        } else {
                            HStack(spacing: 6) {
                                Text("Quick sample:")
                                    .font(.system(size: 11))
                                    .foregroundStyle(LuxuryTheme.textTertiary)
                                Button(action: {
                                    urlString = "https://www.amazon.in/dp/B0FFTD9NS8"
                                }) {
                                    Text("Nike Downshifter 14")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(LuxuryTheme.gold)
                                }
                            }
                            .padding(.top, 2)
                        }
                    }
                    .padding(.horizontal)

                    // Import Button
                    Button(action: performImport) {
                        HStack(spacing: 8) {
                            if isLoading {
                                ProgressView()
                                    .tint(.black)
                                Text("Fetching & Downloading...")
                            } else {
                                Image(systemName: "sparkles")
                                Text("Import & Auto-Fill")
                            }
                        }
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(urlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? LuxuryTheme.gold.opacity(0.4) : LuxuryTheme.gold)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(isLoading || urlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .padding(.horizontal)

                    // Preview Card if already imported
                    if let data = importedData {
                        previewCard(data: data)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(LuxuryTheme.background.ignoresSafeArea())
            .navigationTitle("Web Importer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(LuxuryTheme.textSecondary)
                }
            }
        }
    }

    private func previewCard(data: ImportedProductData) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Extracted Preview")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(LuxuryTheme.gold)

                Spacer()

                Text("\(data.photoFilenames.count) Photos Downloaded")
                    .font(.system(size: 11, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(LuxuryTheme.gold.opacity(0.18))
                    .foregroundStyle(LuxuryTheme.gold)
                    .clipShape(Capsule())
            }

            // Photos Row
            if !data.photoFilenames.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(data.photoFilenames, id: \.self) { photo in
                            ItemImageView(photoNameOrUrl: photo, category: data.category)
                                .frame(width: 80, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                if !data.brand.isEmpty {
                    Text(data.brand.uppercased())
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(data.category.accentColor)
                }

                Text(data.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(LuxuryTheme.textPrimary)

                if data.price > 0 {
                    Text("₹\(Int(data.price))")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(LuxuryTheme.gold)
                }

                HStack {
                    Text(data.category.rawValue)
                    if !data.subcategory.isEmpty {
                        Text("• " + data.subcategory)
                    }
                }
                .font(.system(size: 12))
                .foregroundStyle(LuxuryTheme.textSecondary)
            }

            Button(action: {
                onImportComplete(data)
                dismiss()
            }) {
                Text("Use This Product in Form ✨")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(LuxuryTheme.gold)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .luxuryCardStyle(cornerRadius: 16)
    }

    private func performImport() {
        errorMessage = nil
        isLoading = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        Task {
            do {
                let data = try await WebProductImporter.shared.importFromUrl(urlString)
                await MainActor.run {
                    self.isLoading = false
                    self.importedData = data
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "Failed to import: \(error.localizedDescription)"
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                }
            }
        }
    }
}
