import SwiftUI
import ContentsquareSDK

// MARK: - CSQMobile Coming Soon (Phase 4 Telco Placeholder)
// Presented as a sheet from the CSQMobile tile on the Home screen.
// Mirrors the FoodDeliveryComingSoonView / GroceryComingSoonView pattern.
// Do NOT wire live telco flows until Phase 4 is explicitly started — see CLAUDE.md.

struct TelcoComingSoonView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.csqBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        Spacer().frame(height: 8)

                        // ── Brand illustration ────────────────────────────────
                        ZStack {
                            Circle()
                                .fill(Color.csqTelcoTeal.opacity(0.06))
                                .frame(width: 180, height: 180)
                            Circle()
                                .fill(Color.csqTelcoTeal.opacity(0.10))
                                .frame(width: 136, height: 136)
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(
                                        colors: [Color.csqTelcoTeal, Color(hex: "#0284C7")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 92, height: 92)
                                    .shadow(color: Color.csqTelcoTeal.opacity(0.4), radius: 18, x: 0, y: 6)
                                Image(systemName: "simcard.fill")
                                    .font(.system(size: 38))
                                    .foregroundColor(.white)
                            }
                        }
                        .accessibilityIdentifier("telco_coming_soon_illustration")

                        // ── Copy ──────────────────────────────────────────────
                        VStack(spacing: 10) {
                            Text("CSQMobile")
                                .font(AppFont.display(28))
                                .foregroundColor(.csqTextPrimary)
                                .accessibilityIdentifier("telco_coming_soon_title")

                            Text("Stay connected, your way")
                                .font(AppFont.body(16))
                                .foregroundColor(.csqTextSecondary)
                                .multilineTextAlignment(.center)

                            Text("Coming in Phase 4")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.csqTelcoTeal)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(Color.csqTelcoTeal.opacity(0.10))
                                .clipShape(RoundedRectangle(cornerRadius: AppRadius.full))
                                .padding(.top, 4)
                                .accessibilityIdentifier("telco_coming_soon_badge")
                        }
                        .padding(.horizontal, 40)

                        // ── Section label ─────────────────────────────────────
                        HStack {
                            Text("What's coming")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.csqTextTertiary)
                                .textCase(.uppercase)
                                .tracking(0.8)
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, -10)

                        // ── Feature teaser rows ───────────────────────────────
                        VStack(spacing: 0) {
                            TelcoTeaserRow(
                                icon: "simcard.fill",
                                color: .csqTelcoTeal,
                                label: "eSIM",
                                detail: "Instant digital SIM — no physical card"
                            )
                            Divider().padding(.leading, 56)
                            TelcoTeaserRow(
                                icon: "iphone",
                                color: Color(hex: "#6366F1"),
                                label: "New Devices",
                                detail: "Browse & finance the latest smartphones"
                            )
                            Divider().padding(.leading, 56)
                            TelcoTeaserRow(
                                icon: "doc.text.fill",
                                color: .csqSuccess,
                                label: "Phone Plans",
                                detail: "Postpaid & SIM-only from S$18/mo"
                            )
                            Divider().padding(.leading, 56)
                            TelcoTeaserRow(
                                icon: "plus.circle.fill",
                                color: .csqWarning,
                                label: "Prepaid Top-Up",
                                detail: "Add data or credit in one tap"
                            )
                            Divider().padding(.leading, 56)
                            TelcoTeaserRow(
                                icon: "globe",
                                color: .csqPrimary,
                                label: "Roaming Packs",
                                detail: "Stay connected across 100+ countries"
                            )
                        }
                        .background(Color.csqSurface)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
                        .padding(.horizontal, 24)
                        .accessibilityIdentifier("telco_coming_soon_feature_list")

                        // ── More features strip ───────────────────────────────
                        HStack {
                            Text("Also planned")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.csqTextTertiary)
                                .textCase(.uppercase)
                                .tracking(0.8)
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, -10)

                        VStack(spacing: 0) {
                            TelcoTeaserRow(
                                icon: "chart.bar.fill",
                                color: Color(hex: "#EC4899"),
                                label: "Usage Monitor",
                                detail: "Real-time data, calls & SMS tracking"
                            )
                            Divider().padding(.leading, 56)
                            TelcoTeaserRow(
                                icon: "person.2.fill",
                                color: .csqRideBlue,
                                label: "Family Plan",
                                detail: "Up to 5 lines, shared or individual data"
                            )
                            Divider().padding(.leading, 56)
                            TelcoTeaserRow(
                                icon: "arrow.up.circle.fill",
                                color: .csqExpressPurple,
                                label: "Plan Upgrade",
                                detail: "Switch plans, prorated billing explained"
                            )
                            Divider().padding(.leading, 56)
                            TelcoTeaserRow(
                                icon: "creditcard.fill",
                                color: .csqNavy,
                                label: "Bill Payment",
                                detail: "Pay bills, set autopay, view invoices"
                            )
                        }
                        .background(Color.csqSurface)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
                        .padding(.horizontal, 24)

                        // ── Notify CTA ────────────────────────────────────────
                        Button {} label: {
                            HStack(spacing: 10) {
                                Image(systemName: "bell.badge.fill")
                                    .font(.system(size: 16))
                                Text("Notify me when it launches")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(
                                LinearGradient(
                                    colors: [Color.csqTelcoTeal, Color(hex: "#0284C7")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                            .shadow(color: Color.csqTelcoTeal.opacity(0.35), radius: 10, x: 0, y: 4)
                        }
                        .padding(.horizontal, 24)
                        .accessibilityIdentifier("telco_btn_notify_me")
                        .accessibilityLabel("Notify me when CSQMobile launches")

                        Spacer().frame(height: 16)
                    }
                }
            }
            .navigationTitle("CSQMobile")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                CSQ.trackScreenview("Telco - Coming Soon")
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.csqTextTertiary)
                    }
                    .accessibilityIdentifier("telco_btn_dismiss")
                    .accessibilityLabel("Close CSQMobile preview")
                }
            }
        }
    }
}

// MARK: - Teaser Row
private struct TelcoTeaserRow: View {
    let icon: String
    let color: Color
    let label: String
    let detail: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.10))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 17))
                    .foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.csqTextPrimary)
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundColor(.csqTextSecondary)
                    .lineLimit(1)
            }
            Spacer()
            Image(systemName: "lock.fill")
                .font(.system(size: 11))
                .foregroundColor(.csqTextTertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}
