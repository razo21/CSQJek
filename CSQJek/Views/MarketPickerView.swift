import SwiftUI
import ContentsquareSDK

// MARK: - MarketPickerView
// Shown before the splash screen on every launch.
// User picks their regional experience (Singapore or Tokyo).
// Fires a CS event on selection so demo sessions are tagged by market.

struct MarketPickerView: View {
    @ObservedObject var marketConfig: MarketConfig
    let onSelect: () -> Void

    @State private var logoScale:   CGFloat = 0.8
    @State private var logoOpacity: Double  = 0.0
    @State private var cardsOffset: CGFloat = 40
    @State private var cardsOpacity: Double = 0.0

    var body: some View {
        ZStack {
            // Same coral gradient as SplashView — visual continuity
            LinearGradient(
                colors: [Color.csqPrimary, Color.csqPrimaryDark],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo + headline
                VStack(spacing: 16) {
                    CSQJekLogoView(style: .white, iconSize: 56, showWordmark: false)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)

                    VStack(spacing: 6) {
                        Text("CSQJek")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .tracking(-0.5)

                        Text("Choose your city")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.75))
                    }
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                }

                Spacer()

                // Market cards — driven by the registry, so a new market appears
                // automatically with no edit here.
                VStack(spacing: 14) {
                    ForEach(MarketRegistry.all, id: \.id) { profile in
                        MarketCard(
                            countryCode: profile.flagCode,
                            badgeColor:  profile.badgeColor,
                            cityName:    profile.cityLabel,
                            language:    profile.languageLabel,
                            currency:    profile.currency.code,
                            isSelected:  marketConfig.market == profile.id,
                            action: {
                                marketConfig.market = profile.id
                                didSelect(profile.id)
                            }
                        )
                    }
                }
                .padding(.horizontal, 24)
                .offset(y: cardsOffset)
                .opacity(cardsOpacity)

                // Fine print
                Text("More cities coming soon")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.45))
                    .padding(.top, 24)
                    .padding(.bottom, 48)
                    .offset(y: cardsOffset)
                    .opacity(cardsOpacity)
            }
        }
        .onAppear {
            CSQ.trackScreenview("Market Picker")

            withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.1)) {
                logoScale   = 1.0
                logoOpacity = 1.0
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.35)) {
                cardsOffset  = 0
                cardsOpacity = 1.0
            }
        }
    }

    private func didSelect(_ market: Market) {
        CSQ.trackEvent("market_selected", properties: [
            "market":   market.trackingLabel,
            "currency": market.currencyCode
        ])
        CSQ.addUserProperties(["market": market.trackingLabel])
        withAnimation(.easeOut(duration: 0.3)) {
            onSelect()
        }
    }
}

// MARK: - Market Card

private struct MarketCard: View {
    let countryCode: String   // "SG" / "JP" — emoji flags don't render in Simulator
    let badgeColor:  Color    // national accent colour for the badge ring
    let cityName:    String
    let language:    String
    let currency:    String
    let isSelected:  Bool
    let action:      () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Country badge — coloured circle + bold ISO code, reliable on all targets
                ZStack {
                    Circle()
                        .fill(badgeColor)
                        .frame(width: 56, height: 56)
                    Circle()
                        .stroke(Color.white.opacity(0.25), lineWidth: 1.5)
                        .frame(width: 56, height: 56)
                    Text(countryCode)
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(1)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(cityName)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    HStack(spacing: 8) {
                        Text(language)
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.75))
                        Text("·")
                            .foregroundColor(.white.opacity(0.4))
                        Text(currency)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.75))
                    }
                }

                Spacer()

                // Selection ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(isSelected ? 1.0 : 0.35), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    if isSelected {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 13, height: 13)
                    }
                }
                .animation(.spring(response: 0.25), value: isSelected)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(isSelected ? 0.22 : 0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(isSelected ? 0.6 : 0.2), lineWidth: isSelected ? 2 : 1)
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}
