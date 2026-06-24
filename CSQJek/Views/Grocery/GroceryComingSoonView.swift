import SwiftUI
import ContentsquareSDK

// MARK: - Grocery Coming Soon
// Phase 2 placeholder. Do not replace until Phase 2 is explicitly started.
// See CLAUDE.md — "Phase 2 (Grocery)" section.

struct GroceryComingSoonView: View {
    var body: some View {
        NavigationView {
            ZStack {
                Color.csqBackground.ignoresSafeArea()

                VStack(spacing: 28) {
                    Spacer()

                    // Illustration
                    ZStack {
                        Circle()
                            .fill(Color.csqMartGreen.opacity(0.08))
                            .frame(width: 160, height: 160)
                        Circle()
                            .fill(Color.csqMartGreen.opacity(0.12))
                            .frame(width: 120, height: 120)
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [Color.csqMartGreen, Color(hex: "#1A9E82")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 84, height: 84)
                                .shadow(color: Color.csqMartGreen.opacity(0.4), radius: 16, x: 0, y: 6)
                            Image(systemName: "cart.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.white)
                        }
                    }

                    // Copy
                    VStack(spacing: 10) {
                        Text("CSQMart")
                            .font(AppFont.display(28))
                            .foregroundColor(.csqTextPrimary)

                        Text("Groceries delivered in 45 minutes")
                            .font(AppFont.body(16))
                            .foregroundColor(.csqTextSecondary)
                            .multilineTextAlignment(.center)

                        Text("Coming soon")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.csqMartGreen)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(Color.csqMartGreen.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.full))
                            .padding(.top, 4)
                    }
                    .padding(.horizontal, 40)

                    // Teaser features
                    VStack(spacing: 0) {
                        TeaserRow(icon: "leaf.fill",    color: .csqMartGreen, label: "Fresh produce & organics")
                        Divider().padding(.leading, 52)
                        TeaserRow(icon: "clock.fill",   color: .csqRideBlue,     label: "Express 30-min delivery")
                        Divider().padding(.leading, 52)
                        TeaserRow(icon: "tag.fill",     color: .csqMartGreen,      label: "Exclusive CSQJek deals")
                    }
                    .background(Color.csqSurface)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                    .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
                    .padding(.horizontal, 24)

                    Spacer()
                }
            }
            .navigationTitle("Grocery")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                CSQ.trackScreenview("Grocery - Coming Soon")
            }
        }
    }
}

private struct TeaserRow: View {
    let icon: String
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.1))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
            }
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.csqTextPrimary)
            Spacer()
            Image(systemName: "lock.fill")
                .font(.system(size: 11))
                .foregroundColor(.csqTextTertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}
