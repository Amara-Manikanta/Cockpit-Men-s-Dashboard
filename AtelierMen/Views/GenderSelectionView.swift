import SwiftUI

public struct GenderSelectionView: View {
    @Binding var selectedGender: String

    public init(selectedGender: Binding<String>) {
        self._selectedGender = selectedGender
    }

    public var body: some View {
        ZStack {
            // Ambient Dark Luxury Gradient Background
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.06, blue: 0.08),
                    Color(red: 0.09, green: 0.06, blue: 0.09),
                    Color(red: 0.03, green: 0.03, blue: 0.04)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Spacer(minLength: 20)

                    // Header Emblem & Title
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Text("🎩")
                                .font(.system(size: 20))
                            Image(systemName: "sparkles")
                                .font(.system(size: 16))
                                .foregroundStyle(LuxuryTheme.accentAmber)
                            Text("👗")
                                .font(.system(size: 20))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(white: 0.12))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))

                        Text("ATELIER & ADORN")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .tracking(2.5)
                            .foregroundStyle(Color.white)

                        Text("Select your wardrobe experience to personalize your dashboard:")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.white.opacity(0.65))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    // Selection Cards
                    VStack(spacing: 18) {
                        // Card 1: MALE
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                selectedGender = "male"
                            }
                        }) {
                            maleOptionCard
                        }
                        .buttonStyle(PlainButtonStyle())

                        // Card 2: FEMALE
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                selectedGender = "female"
                            }
                        }) {
                            femaleOptionCard
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 20)

                    // Footer Switcher Hint
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 11))
                        Text("You can switch between Men's and Women's wardrobes anytime from the header.")
                            .font(.system(size: 11))
                    }
                    .foregroundStyle(Color.white.opacity(0.45))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                    Spacer(minLength: 30)
                }
            }
        }
    }

    // MARK: - Male Card
    private var maleOptionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                ZStack {
                    Circle()
                        .fill(LuxuryTheme.accentAmber.opacity(0.2))
                        .frame(width: 48, height: 48)
                    Text("🎩")
                        .font(.system(size: 24))
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("MALE")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundStyle(Color.white)
                        Text("• GENTLEMAN")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .tracking(1.2)
                            .foregroundStyle(LuxuryTheme.accentAmber)
                    }
                    Text("Men's Atelier & Vault")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.white.opacity(0.7))
                }

                Spacer()

                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(LuxuryTheme.accentAmber)
            }

            Divider()
                .background(Color.white.opacity(0.12))

            VStack(alignment: .leading, spacing: 6) {
                featureBullet(icon: "tshirt.fill", text: "Bespoke Tailoring, Suits, Denim & Footwear", color: LuxuryTheme.accentAmber)
                featureBullet(icon: "applewatch", text: "Horology, Luxury Watches & Tech EDC", color: LuxuryTheme.cyberBlue)
                featureBullet(icon: "briefcase.fill", text: "Leather Bags, Grooming & Travel Packing", color: LuxuryTheme.titanium)
            }

            HStack {
                Spacer()
                Text("Launch Men's Vault →")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(LuxuryTheme.accentAmber)
                    .clipShape(Capsule())
            }
            .padding(.top, 4)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(red: 0.08, green: 0.10, blue: 0.13))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(LuxuryTheme.accentAmber.opacity(0.4), lineWidth: 1.5)
                )
                .shadow(color: LuxuryTheme.accentAmber.opacity(0.2), radius: 14, y: 6)
        )
    }

    // MARK: - Female Card
    private var femaleOptionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                ZStack {
                    Circle()
                        .fill(WomenLuxuryTheme.roseGold.opacity(0.2))
                        .frame(width: 48, height: 48)
                    Text("👗")
                        .font(.system(size: 24))
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("FEMALE")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundStyle(Color.white)
                        Text("• COUTURE")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .tracking(1.2)
                            .foregroundStyle(WomenLuxuryTheme.roseGold)
                    }
                    Text("Women's Luxury Boutique")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.white.opacity(0.7))
                }

                Spacer()

                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(WomenLuxuryTheme.roseGold)
            }

            Divider()
                .background(Color.white.opacity(0.12))

            VStack(alignment: .leading, spacing: 6) {
                featureBullet(icon: "sparkles", text: "Silk Sarees, Lehengas, Dresses & Kurtis", color: WomenLuxuryTheme.roseGold)
                featureBullet(icon: "suit.diamond.fill", text: "22K Gold, Solitaire Diamonds & Jewelry Box", color: WomenLuxuryTheme.champagne)
                featureBullet(icon: "handbag.fill", text: "Luxury Handbags, Clutches & AI Stylist Studio", color: WomenLuxuryTheme.blushCoral)
            }

            HStack {
                Spacer()
                Text("Launch Women's Boutique →")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(WomenLuxuryTheme.roseGold)
                    .clipShape(Capsule())
            }
            .padding(.top, 4)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(red: 0.11, green: 0.07, blue: 0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(WomenLuxuryTheme.roseGold.opacity(0.4), lineWidth: 1.5)
                )
                .shadow(color: WomenLuxuryTheme.roseGold.opacity(0.2), radius: 14, y: 6)
        )
    }

    private func featureBullet(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(color)
                .frame(width: 16)
            Text(text)
                .font(.system(size: 12))
                .foregroundStyle(Color.white.opacity(0.85))
        }
    }
}
