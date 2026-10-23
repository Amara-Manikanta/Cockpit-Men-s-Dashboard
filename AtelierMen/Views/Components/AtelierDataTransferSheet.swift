import SwiftUI
import UniformTypeIdentifiers

public struct AtelierDataTransferSheet: View {
    @ObservedObject var menStore: DataStore
    @ObservedObject var womenStore: WomenDataStore
    var isWomenSection: Bool = false
    @Environment(\.dismiss) private var dismiss

    @State private var importMode: BackupImportMode = .merge
    @State private var showShareSheet: Bool = false
    @State private var fileToShareUrl: URL? = nil
    @State private var showFileImporter: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var showAlert: Bool = false
    @State private var isProcessing: Bool = false

    private var accentColor: Color {
        isWomenSection ? WomenLuxuryTheme.roseGold : LuxuryTheme.gold
    }

    private var secondaryAccentColor: Color {
        isWomenSection ? WomenLuxuryTheme.champagne : LuxuryTheme.accentAmber
    }

    public init(menStore: DataStore, womenStore: WomenDataStore, isWomenSection: Bool = false) {
        self.menStore = menStore
        self.womenStore = womenStore
        self.isWomenSection = isWomenSection
    }

    public var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    // Header Banner
                    headerCard

                    // Wardrobe Snapshot
                    librarySnapshotCard

                    // Export Section
                    exportSectionCard

                    // Import Section
                    importSectionCard

                    // Privacy Note
                    privacyFooter

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Data Backup & Transfer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(accentColor)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = fileToShareUrl {
                    ShareActivityView(activityItems: [url])
                }
            }
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleImportSelection(result: result)
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }

    // MARK: - Header Banner
    private var headerCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                .font(.system(size: 44, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [accentColor, secondaryAccentColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("Wardrobe Portability & Vault")
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(Color.white)

            Text("Export your entire collection, luxury wishlist, and outfit logs into open, secure JSON format, or restore from files anytime.")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(white: 0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(accentColor.opacity(0.2), lineWidth: 1)
                )
        )
    }

    // MARK: - Snapshot
    private var librarySnapshotCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("CURRENT INVENTORY")
                .font(.system(size: 11, weight: .heavy))
                .tracking(1.4)
                .foregroundStyle(Color.white.opacity(0.5))

            HStack(spacing: 12) {
                // Men's Snapshot
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "tshirt.fill")
                            .foregroundStyle(LuxuryTheme.gold)
                        Text("Men's Vault")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color.white)
                    }

                    Text("\(menStore.items.count) pieces")
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundStyle(LuxuryTheme.gold)

                    Text("\(menStore.wishlistItems.count) wishlist • \(menStore.looks.count) looks")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.white.opacity(0.6))
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(white: 0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(LuxuryTheme.gold.opacity(0.25), lineWidth: 1)
                        )
                )

                // Women's Snapshot
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(WomenLuxuryTheme.roseGold)
                        Text("Women's Boutique")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color.white)
                    }

                    Text("\(womenStore.items.count) pieces")
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundStyle(WomenLuxuryTheme.roseGold)

                    Text("\(womenStore.wishlistItems.count) wishlist • \(womenStore.looks.count) looks")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.white.opacity(0.6))
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(white: 0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(WomenLuxuryTheme.roseGold.opacity(0.25), lineWidth: 1)
                        )
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(white: 0.06))
        )
    }

    // MARK: - Export Section
    private var exportSectionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("EXPORT ARCHIVE")
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(1.4)
                    .foregroundStyle(Color.white.opacity(0.5))
                Spacer()
                Text("JSON Format")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(accentColor)
            }

            // Export Complete Archive Button
            Button(action: {
                exportCompleteArchive()
            }) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(accentColor.opacity(0.2))
                            .frame(width: 44, height: 44)
                        Image(systemName: "sparkles.square.filled.on.square")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(accentColor)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text("Export Complete Archive")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(Color.white)
                            Text("RECOMMENDED")
                                .font(.system(size: 9, weight: .heavy))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(accentColor)
                                .foregroundStyle(Color.black)
                                .clipShape(Capsule())
                        }
                        Text("Both Men's & Women's pieces, wishlists, & outfits")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.white.opacity(0.6))
                    }

                    Spacer()

                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(accentColor)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(white: 0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(accentColor.opacity(0.35), lineWidth: 1)
                        )
                )
            }

            // Individual Exports
            HStack(spacing: 12) {
                // Men's Only
                Button(action: {
                    exportMenOnly()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "tshirt")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Export Men's")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundStyle(Color.white)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(Color(white: 0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
                }

                // Women's Only
                Button(action: {
                    exportWomenOnly()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Export Women's")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundStyle(Color.white)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(Color(white: 0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(white: 0.06))
        )
    }

    // MARK: - Import Section
    private var importSectionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("RESTORE & IMPORT DATA")
                .font(.system(size: 11, weight: .heavy))
                .tracking(1.4)
                .foregroundStyle(Color.white.opacity(0.5))

            // Strategy Picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Import Strategy:")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.8))

                Picker("Import Mode", selection: $importMode) {
                    ForEach(BackupImportMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }

            Text(importMode == .merge
                 ? "• Merge preserves existing items and only adds new/missing pieces."
                 : "• Replace will cleanly overwrite your current collection with the backup file.")
                .font(.system(size: 11))
                .foregroundStyle(importMode == .merge ? Color.green.opacity(0.9) : Color.orange.opacity(0.9))
                .lineLimit(2)

            // Select Backup File Button
            Button(action: {
                showFileImporter = true
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "square.and.arrow.down.on.square.fill")
                        .font(.system(size: 16, weight: .bold))
                    Text("Select Backup File (.json)")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundStyle(Color.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [accentColor, secondaryAccentColor],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: accentColor.opacity(0.35), radius: 10, y: 4)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(white: 0.06))
        )
    }

    // MARK: - Privacy Footer
    private var privacyFooter: some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 14))
                .foregroundStyle(accentColor)
            Text("100% On-Device & Private. All wardrobe photos and details remain entirely on your device and private iCloud Drive.")
                .font(.system(size: 11))
                .foregroundStyle(Color.white.opacity(0.5))
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Actions
    private func exportCompleteArchive() {
        if let url = AtelierBackupManager.shared.generateUnifiedBackup(menStore: menStore, womenStore: womenStore) {
            fileToShareUrl = url
            showShareSheet = true
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else {
            alertTitle = "Export Error"
            alertMessage = "Failed to compile complete archive JSON."
            showAlert = true
        }
    }

    private func exportMenOnly() {
        if let url = AtelierBackupManager.shared.generateMenBackup(menStore: menStore) {
            fileToShareUrl = url
            showShareSheet = true
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else {
            alertTitle = "Export Error"
            alertMessage = "Failed to compile Men's Vault JSON."
            showAlert = true
        }
    }

    private func exportWomenOnly() {
        if let url = AtelierBackupManager.shared.generateWomenBackup(womenStore: womenStore) {
            fileToShareUrl = url
            showShareSheet = true
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else {
            alertTitle = "Export Error"
            alertMessage = "Failed to compile Women's Boutique JSON."
            showAlert = true
        }
    }

    private func handleImportSelection(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let fileUrl = urls.first else { return }
            let importResult = AtelierBackupManager.shared.importBackup(
                from: fileUrl,
                menStore: menStore,
                womenStore: womenStore,
                mode: importMode
            )
            switch importResult {
            case .success(let summary):
                alertTitle = "Import Successful! 🎉"
                alertMessage = "Successfully imported:\n\(summary.detailedMessage)"
                showAlert = true
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            case .failure(let err):
                alertTitle = "Import Failed"
                alertMessage = err.localizedDescription
                showAlert = true
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
        case .failure(let err):
            alertTitle = "Cancelled"
            alertMessage = err.localizedDescription
            showAlert = true
        }
    }
}
