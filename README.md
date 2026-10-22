# Atelier Men — Luxury Menswear & EDC Portfolio for iOS

A native, high-performance iOS application built with SwiftUI for modern gentlemen to curate, value, organize, and plan their wardrobe, timepiece collection, footwear, and travel gear.

Designed with an Obsidian & Cognac Gold aesthetic inspired by haute horlogerie and bespoke tailoring ateliers.

---

## Key Features

- **7 Tailored Luxury Categories**:
  - **Clothes**: Bespoke suits, Italian blazers, Oxford shirts, knitwear, and outerwear.
  - **Shoes**: Goodyear-welted oxfords, loafers, Chelsea boots, and designer sneakers.
  - **Sports Wear**: Gym & training apparel, running kits, performance hoodies, and trail gear.
  - **Electronics & Horology**: Luxury mechanical timepieces, Leica cameras, flagship computing, and acoustics.
  - **Bags & Luggage**: Aluminum carry-ons, full-grain briefcases, weekender duffels, and sling bags.
  - **Grooming & Fragrances**: Haute parfumerie, shaving sets, and skincare serums.
  - **Accessories**: Wallets, leather belts, Japanese titanium eyewear, and cufflinks.

- **Automated Web & Store Importer**:
  - Import product specifications and high-resolution master images directly from Amazon, Myntra, or any web product link.
  - Automatic ASIN canonicalization and anti-bot bypass for reliable scraping.
  - Real-time photo fallback preserving high-res CDN images without data loss.

- **Intelligent Duplicate Prevention & Cleaner**:
  - Automatic duplicate detection on import: prevents duplicate entries and merges newly discovered photos and specs into the existing piece.
  - One-tap "Remove Duplicates" scanner to consolidate and clean redundant pieces across the vault and wishlist.

- **Multi-Select & Bulk Deletion**:
  - Dedicated selection mode with gold circular checkmark indicators and highlighted borders.
  - "Select All" / "Deselect All" capabilities.
  - Floating batch deletion bar with confirmation safety alerts.

- **Wishlist & Target Acquisitions**:
  - Track target prices and high-priority upgrades.
  - One-tap transfer from Wishlist to Vault upon acquisition.

- **Trip Packing Director**:
  - Independent directory of travel plans with packing completion meters.
  - Category-by-category checklists with full packing item management.

- **Personal AI Stylist**:
  - Occasion-based outfit recommendations (Black Tie, Business Executive, Casual Sartorial, Active Training).

---

## Tech Stack & Architecture

- **Language & Framework**: Swift 5.10 / SwiftUI
- **Minimum iOS Target**: iOS 17.0+
- **Architecture**: MVVM with reactive `@Published` state store
- **Design System**: Custom dark luxury palette (`Obsidian`, `Gold`, `Cognac`, `Crimson Volt`)
- **Storage**: Local JSON disk persistence with image asset sandboxing

---

## Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/Amara-Manikanta/Cockpit-Men-s-Dashboard.git
   cd Cockpit-Men-s-Dashboard
   ```

2. Open the project in Xcode:
   ```bash
   open AtelierMen.xcodeproj
   ```

3. Select your physical iPhone or Simulator target and press **Cmd + R** to run.
