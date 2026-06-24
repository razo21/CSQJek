import SwiftUI
import ContentsquareSDK

// MARK: - Food Delivery Coming Soon
// Phase 3 placeholder. Mirrors GroceryComingSoonView pattern.
// Do not wire live flows until Phase 3 is explicitly started — see CLAUDE.md.

struct FoodDeliveryComingSoonView: View {
    var body: some View {
        NavigationView {
            ZStack {
                Color.csqBackground.ignoresSafeArea()

                VStack(spacing: 28) {
                    Spacer()

                    // Illustration
                    ZStack {
                        Circle()
                            .fill(Color.csqFoodOrange.opacity(0.08))
                            .frame(width: 160, height: 160)
                        Circle()
                            .fill(Color.csqFoodOrange.opacity(0.12))
                            .frame(width: 120, height: 120)
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [Color.csqFoodOrange, Color(hex: "#E8732C")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 84, height: 84)
                                .shadow(color: Color.csqFoodOrange.opacity(0.4), radius: 16, x: 0, y: 6)
                            Image(systemName: "takeoutbag.and.cup.and.straw.fill")
                                .font(.system(size: 34))
                                .foregroundColor(.white)
                        }
                    }

                    // Copy
                    VStack(spacing: 10) {
                        Text("CSQEats")
                            .font(AppFont.display(28))
                            .foregroundColor(.csqTextPrimary)

                        Text("Restaurant favourites at your door")
                            .font(AppFont.body(16))
                            .foregroundColor(.csqTextSecondary)
                            .multilineTextAlignment(.center)

                        Text("Coming soon")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.csqFoodOrange)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(Color.csqFoodOrange.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.full))
                            .padding(.top, 4)
                    }
                    .padding(.horizontal, 40)

                    // Teaser features
                    VStack(spacing: 0) {
                        FoodTeaserRow(icon: "building.2.fill",          color: .csqFoodOrange,  label: "Top restaurants near you")
                        Divider().padding(.leading, 52)
                        FoodTeaserRow(icon: "clock.badge.checkmark",    color: .csqRideBlue,    label: "30-min guaranteed delivery")
                        Divider().padding(.leading, 52)
                        FoodTeaserRow(icon: "location.fill",            color: .csqPrimary,     label: "Live order tracking")
                    }
                    .background(Color.csqSurface)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                    .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
                    .padding(.horizontal, 24)

                    Spacer()
                }
            }
            .navigationTitle("Food")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                CSQ.trackScreenview("Food - Coming Soon")
            }
        }
    }
}

private struct FoodTeaserRow: View {
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
