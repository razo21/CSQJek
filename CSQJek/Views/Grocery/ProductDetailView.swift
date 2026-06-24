import SwiftUI

struct ProductDetailView: View {
    @EnvironmentObject var cartStore: CartStore
    @EnvironmentObject var marketConfig: MarketConfig
    @Environment(\.dismiss) var dismiss
    let product: GroceryProduct
    @State private var quantity = 1
    @State private var isFavorite = false
    @State private var addedToCart = false
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            // Handle
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.csqBorder)
                .frame(width: 40, height: 4)
                .padding(.top, 12)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // Image hero
                    ZStack(alignment: .topTrailing) {
                        GroceryProductImage(product: product, symbolSize: 100)
                            .frame(maxWidth: .infinity)
                            .frame(height: 240)
                            .clipped()
                        .overlay(alignment: .topLeading) {
                            // Close button — exit the product without adding to cart
                            Button { dismiss() } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.csqTextPrimary)
                                    .frame(width: 40, height: 40)
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .shadow(color: Color.black.opacity(0.1), radius: 4)
                            }
                            .padding(14)
                            .accessibilityIdentifier("grocery_product_btn_close")
                        }

                        // Badges
                        VStack(spacing: 6) {
                            if let discount = product.discountPercent {
                                Text("\(discount)% OFF")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.csqError)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            Button {
                                withAnimation(.spring()) { isFavorite.toggle() }
                            } label: {
                                Image(systemName: isFavorite ? "heart.fill" : "heart")
                                    .font(.system(size: 20))
                                    .foregroundColor(isFavorite ? .csqError : .csqTextTertiary)
                                    .frame(width: 40, height: 40)
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .shadow(color: Color.black.opacity(0.1), radius: 4)
                            }
                        }
                        .padding(14)
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        // Title + brand
                        VStack(alignment: .leading, spacing: 6) {
                            Text(product.brand.uppercased())
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.csqMartGreen)
                                .tracking(1)
                            Text(product.name)
                                .font(AppFont.display(22))
                                .foregroundColor(.csqTextPrimary)
                            Text(product.unit)
                                .font(AppFont.body(14))
                                .foregroundColor(.csqTextSecondary)
                        }

                        // Rating + reviews
                        HStack(spacing: 10) {
                            HStack(spacing: 4) {
                                StarRating(rating: product.rating, size: 13)
                                Text(String(format: "%.1f", product.rating))
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.csqTextPrimary)
                                Text("(\(product.reviewCount) \(marketConfig.strings.productReviewsCount))")
                                    .font(.system(size: 13))
                                    .foregroundColor(.csqTextSecondary)
                            }
                            Spacer()
                            // Stock badge
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(product.inStock ? Color.csqSuccess : Color.csqError)
                                    .frame(width: 6, height: 6)
                                Text(product.inStock ? marketConfig.strings.productInStock : marketConfig.strings.productOutOfStock)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(product.inStock ? .csqSuccess : .csqError)
                            }
                        }

                        // Price
                        HStack(alignment: .bottom, spacing: 10) {
                            Text(marketConfig.market.formatPrice(product.price))
                                .font(.system(size: 30, weight: .bold, design: .rounded))
                                .foregroundColor(.csqTextPrimary)
                            if let orig = product.originalPrice {
                                Text(marketConfig.market.formatPrice(orig))
                                    .font(.system(size: 16))
                                    .foregroundColor(.csqTextTertiary)
                                    .strikethrough()
                                    .padding(.bottom, 4)
                            }
                        }

                        Divider()

                        // Tab selector
                        HStack(spacing: 0) {
                            ForEach([marketConfig.strings.productDescriptionTab, marketConfig.strings.productNutritionTab, marketConfig.strings.productReviewsTab].enumerated().map { $0 }, id: \.offset) { index, tab in
                                Button {
                                    withAnimation { selectedTab = index }
                                } label: {
                                    VStack(spacing: 6) {
                                        Text(tab)
                                            .font(.system(size: 13, weight: selectedTab == index ? .semibold : .regular))
                                            .foregroundColor(selectedTab == index ? .csqTextPrimary : .csqTextTertiary)
                                        Rectangle()
                                            .fill(selectedTab == index ? Color.csqMartGreen : Color.clear)
                                            .frame(height: 2)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }

                        // Tab content
                        Group {
                            if selectedTab == 0 {
                                Text(product.description)
                                    .font(AppFont.body(14))
                                    .foregroundColor(.csqTextSecondary)
                                    .lineSpacing(4)
                            } else if selectedTab == 1 {
                                NutritionView()
                            } else {
                                ReviewsView(product: product)
                            }
                        }
                        .animation(.easeInOut(duration: 0.2), value: selectedTab)

                        // Quantity selector
                        HStack {
                            Text(marketConfig.strings.productQuantity)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.csqTextPrimary)
                            Spacer()
                            HStack(spacing: 16) {
                                Button {
                                    if quantity > 1 { quantity -= 1 }
                                } label: {
                                    Image(systemName: "minus")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(quantity > 1 ? .csqMartGreen : .csqTextTertiary)
                                        .frame(width: 36, height: 36)
                                        .background(quantity > 1 ? Color.csqMartGreenPastel : Color.csqBackground)
                                        .clipShape(Circle())
                                }

                                Text("\(quantity)")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(.csqTextPrimary)
                                    .frame(minWidth: 24)

                                Button { quantity += 1 } label: {
                                    Image(systemName: "plus")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 36, height: 36)
                                        .background(Color.csqMartGreen)
                                        .clipShape(Circle())
                                        .shadow(color: Color.csqMartGreen.opacity(0.3), radius: 4, x: 0, y: 2)
                                }
                            }
                        }
                        .padding(14)
                        .background(Color.csqBackground)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))

                        // Total
                        HStack {
                            Text(marketConfig.strings.productTotal)
                                .font(.system(size: 14))
                                .foregroundColor(.csqTextSecondary)
                            Spacer()
                            Text(marketConfig.market.formatPrice(product.price * Double(quantity)))
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.csqTextPrimary)
                        }
                        .padding(.horizontal, 4)
                    }
                    .padding(20)
                }
            }

            // Bottom CTA
            VStack(spacing: 0) {
                Divider()
                Button {
                    for _ in 0..<quantity { cartStore.add(product) }
                    withAnimation { addedToCart = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        addedToCart = false
                        dismiss()
                    }
                } label: {
                    HStack(spacing: 10) {
                        if addedToCart {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                            Text(marketConfig.strings.productAddedToCart)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                        } else {
                            Image(systemName: "cart.badge.plus")
                                .font(.system(size: 16))
                            Text("\(marketConfig.strings.productAddToCart) — \(marketConfig.market.formatPrice(product.price * Double(quantity)))")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        addedToCart
                        ? AnyShapeStyle(Color.csqSuccess)
                        : AnyShapeStyle(LinearGradient(colors: [.csqMartGreen, .csqMartGreenDark], startPoint: .leading, endPoint: .trailing))
                    )
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.full))
                    .shadow(color: (addedToCart ? Color.csqSuccess : Color.csqMartGreen).opacity(0.35), radius: 8, x: 0, y: 4)
                }
                .disabled(!product.inStock)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .padding(.bottom, 4)
            }
            .background(Color.csqSurface)
        }
        .background(Color.csqSurface.ignoresSafeArea())
    }
}

// MARK: - Nutrition Panel
struct NutritionView: View {
    @EnvironmentObject var marketConfig: MarketConfig
    let facts: [(String, String)] = [
        ("Calories", "85 kcal"),
        ("Total Fat", "0.4g"),
        ("Carbohydrates", "20g"),
        ("Dietary Fiber", "2.3g"),
        ("Sugars", "14g"),
        ("Protein", "1.1g"),
        ("Sodium", "1mg"),
        ("Vitamin C", "97% DV")
    ]

    var body: some View {
        VStack(spacing: 0) {
            Text(marketConfig.strings.productNutritionTitle)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.csqTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 8)
            Text(marketConfig.strings.productServingSize)
                .font(.system(size: 11))
                .foregroundColor(.csqTextTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 10)
            ForEach(facts, id: \.0) { fact in
                HStack {
                    Text(fact.0)
                        .font(.system(size: 13))
                        .foregroundColor(.csqTextSecondary)
                    Spacer()
                    Text(fact.1)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.csqTextPrimary)
                }
                .padding(.vertical, 7)
                if fact.0 != facts.last?.0 {
                    Divider()
                }
            }
        }
        .padding(12)
        .background(Color.csqBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }
}

// MARK: - Reviews Panel
struct ReviewsView: View {
    @EnvironmentObject var marketConfig: MarketConfig
    let product: GroceryProduct

    let reviews: [(name: String, initials: String, rating: Double, comment: String, time: String)] = [
        ("Sarah K.", "SK", 5.0, "Absolutely delicious! Will definitely buy again. The quality is outstanding.", "2 days ago"),
        ("Mike T.", "MT", 4.0, "Great product, arrived fresh and well-packaged. Slight delay on delivery.", "1 week ago"),
        ("Anna R.", "AR", 5.0, "My go-to every week. Consistent quality and great value for money.", "2 weeks ago")
    ]

    var body: some View {
        VStack(spacing: 12) {
            // Summary
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text(String(format: "%.1f", product.rating))
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.csqTextPrimary)
                    StarRating(rating: product.rating, size: 14)
                    Text("\(product.reviewCount) \(marketConfig.strings.productReviewsCount)")
                        .font(.system(size: 11))
                        .foregroundColor(.csqTextTertiary)
                }
                VStack(spacing: 4) {
                    ForEach([5,4,3,2,1], id: \.self) { stars in
                        HStack(spacing: 6) {
                            Text("\(stars)")
                                .font(.system(size: 11))
                                .foregroundColor(.csqTextTertiary)
                            GeometryReader { geo in
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.csqBorder)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(Color.csqWarning)
                                            .frame(width: geo.size.width * (stars == 5 ? 0.7 : stars == 4 ? 0.2 : 0.05), alignment: .leading),
                                        alignment: .leading
                                    )
                            }
                            .frame(height: 6)
                        }
                    }
                }
            }
            .padding(12)
            .background(Color.csqBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))

            ForEach(reviews, id: \.name) { review in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(Color.csqMartGreen.opacity(0.15))
                                .frame(width: 34, height: 34)
                            Text(review.initials)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.csqMartGreen)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(review.name)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.csqTextPrimary)
                            StarRating(rating: review.rating, size: 10)
                        }
                        Spacer()
                        Text(review.time)
                            .font(.system(size: 11))
                            .foregroundColor(.csqTextTertiary)
                    }
                    Text(review.comment)
                        .font(.system(size: 13))
                        .foregroundColor(.csqTextSecondary)
                        .lineSpacing(3)
                }
                .padding(12)
                .background(Color.csqBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            }
        }
    }
}
