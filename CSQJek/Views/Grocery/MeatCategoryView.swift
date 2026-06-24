import SwiftUI
import ContentsquareSDK

// MARK: - Meat Category View

struct MeatCategoryView: View {
    @EnvironmentObject var cartStore: CartStore
    @EnvironmentObject var marketConfig: MarketConfig
    @Environment(\.dismiss) var dismiss
    @Binding var rootIsPresented: Bool

    @State private var selectedSubcategoryIndex = 0   // index into subcategories
    @State private var selectedProduct: GroceryProduct? = nil
    @State private var sortOption: SortOption = .featured
    @State private var showCart = false

    private let englishSubcategories = ["All", "Chicken", "Beef", "Pork", "Lamb", "Seafood"]
    private var subcategories: [String] { marketConfig.strings.martMeatSubcategories }
    private var selectedSubcategory: String { englishSubcategories[selectedSubcategoryIndex] }

    enum SortOption: String, CaseIterable {
        case featured   = "featured"
        case priceLow   = "priceLow"
        case priceHigh  = "priceHigh"
        case rating     = "rating"
    }

    private func sortLabel(_ option: SortOption) -> String {
        switch option {
        case .featured:  return marketConfig.strings.meatSortFeatured
        case .priceLow:  return marketConfig.strings.meatSortPriceLow
        case .priceHigh: return marketConfig.strings.meatSortPriceHigh
        case .rating:    return marketConfig.strings.meatSortTopRated
        }
    }

    // ── Colour + badge helpers ────────────────────────────────────────────────

    private func subcategoryColor(_ sub: String) -> Color {
        switch sub {
        case "Chicken":  return Color(hex: "#F97316")
        case "Beef":     return Color(hex: "#E04D3A")
        case "Pork":     return Color(hex: "#EC4899")
        case "Lamb":     return Color(hex: "#7C3AED")
        case "Seafood":  return Color(hex: "#0EA5E9")
        default:         return Color.csqMartGreen
        }
    }

    private func qualityBadge(for product: GroceryProduct) -> (label: String, color: Color)? {
        switch product.brand {
        case "OBE Organic":
            return ("Certified Organic", Color(hex: "#2AC09A"))
        case "Lilydale", "Bannockburn":
            return ("Free Range", Color(hex: "#4CAF50"))
        case "Borrowdale":
            return ("Free Range", Color(hex: "#4CAF50"))
        case "Cape Grim":
            return ("Grass-Fed", Color(hex: "#7C3AED"))
        case "Rangers Valley":
            return ("Grain-Fed 100d", Color(hex: "#E04D3A"))
        case "Mort & Co.":
            return ("Grain-Fed 100d", Color(hex: "#E04D3A"))
        case "Huon Aquaculture":
            return ("Sustainably Farmed", Color(hex: "#0EA5E9"))
        case "Queensland Fresh":
            return ("Wild-Caught", Color(hex: "#0EA5E9"))
        default:
            return nil
        }
    }

    // ── Filtered + sorted products ────────────────────────────────────────────

    private var filteredProducts: [GroceryProduct] {
        let base = selectedSubcategory == "All"
            ? GroceryProduct.meatProducts
            : GroceryProduct.meatProducts.filter { $0.category == selectedSubcategory }

        switch sortOption {
        case .featured:   return base
        case .priceLow:   return base.sorted { $0.price < $1.price }
        case .priceHigh:  return base.sorted { $0.price > $1.price }
        case .rating:     return base.sorted { $0.rating > $1.rating }
        }
    }

    // ── Layout ────────────────────────────────────────────────────────────────

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.csqBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    headerView

                    VStack(spacing: 20) {
                        // Subcategory chips
                        subcategoryRow

                        // Sort + count row
                        HStack {
                            Text("\(filteredProducts.count) \(marketConfig.strings.meatItemsCount)")
                                .font(AppFont.body(13))
                                .foregroundColor(.csqTextSecondary)
                            Spacer()
                            sortMenu
                        }
                        .padding(.horizontal, 16)

                        // Product grid
                        if filteredProducts.isEmpty {
                            emptyState
                        } else {
                            LazyVGrid(
                                columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2),
                                spacing: 12
                            ) {
                                ForEach(filteredProducts) { product in
                                    Button { selectedProduct = product } label: {
                                        MeatProductCard(
                                            product: product,
                                            qualityBadge: qualityBadge(for: product)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityIdentifier("meat_product_\(product.name.lowercased().replacingOccurrences(of: " ", with: "_"))")
                                }
                            }
                            .padding(.horizontal, 16)
                        }

                        // Butcher's tip banner
                        butcherTipBanner

                        Color.clear.frame(height: cartStore.totalItems > 0 ? 80 : 20)
                    }
                    .padding(.top, 20)
                }
            }

            // Floating cart
            if cartStore.totalItems > 0 {
                floatingCartBar
            }
        }
        .navigationBarHidden(true)
        .sheet(item: $selectedProduct) { product in
            ProductDetailView(product: product)
                .environmentObject(cartStore)
                .environmentObject(marketConfig)
        }
        .onAppear {
            CSQ.trackScreenview("Grocery - Meat")
            CSQ.trackEvent("meat_category_viewed", properties: ["subcategory": englishSubcategories[selectedSubcategoryIndex]])
        }
        .onChange(of: selectedSubcategoryIndex) { _, idx in
            CSQ.trackEvent("meat_subcategory_tapped", properties: ["subcategory": englishSubcategories[idx]])
        }
    }

    // MARK: - Header

    private var headerView: some View {
        ZStack(alignment: .bottom) {
            // Header image with gradient fallback
            Group {
                if UIImage(named: "MeatHeaderBg") != nil {
                    Image("MeatHeaderBg")
                        .resizable()
                        .scaledToFill()
                } else {
                    LinearGradient(
                        colors: [Color(hex: "#7F1D1D"), Color(hex: "#B91C1C")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            }
            .frame(height: 180)
            .clipped()
            .ignoresSafeArea(edges: .top)

            // Dark scrim so text stays legible over any photo
            LinearGradient(
                colors: [Color.black.opacity(0), Color.black.opacity(0.6)],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 180)
            .ignoresSafeArea(edges: .top)

            VStack(alignment: .leading, spacing: 0) {
                // Nav row
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.15))
                            .clipShape(Circle())
                    }
                    .accessibilityIdentifier("meat_btn_back")

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "#FCA5A5"))
                        Text(marketConfig.strings.meatFreshDaily)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(hex: "#FCA5A5"))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.full))
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 14)

                // Title block
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color(hex: "#FCA5A5"))
                        Text(marketConfig.strings.meatButcherTitle)
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    Text(marketConfig.strings.meatSubtitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.75))
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .padding(.bottom, 4)
    }

    // MARK: - Subcategory Row

    private var subcategoryRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(subcategories.enumerated()), id: \.offset) { idx, sub in
                    let isSelected = selectedSubcategoryIndex == idx
                    let color = idx == 0 ? Color.csqMartGreen : subcategoryColor(englishSubcategories[idx])

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedSubcategoryIndex = idx
                        }
                    } label: {
                        HStack(spacing: 5) {
                            if idx != 0 {
                                Circle()
                                    .fill(isSelected ? Color.white.opacity(0.8) : color)
                                    .frame(width: 7, height: 7)
                            }
                            Text(sub)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(isSelected ? color : Color.csqSurface)
                        .foregroundColor(isSelected ? .white : .csqTextSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.full))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.full)
                                .stroke(isSelected ? Color.clear : Color.csqBorder, lineWidth: 1)
                        )
                        .shadow(color: isSelected ? color.opacity(0.3) : .clear, radius: 6, x: 0, y: 3)
                    }
                    .accessibilityIdentifier("meat_filter_\(englishSubcategories[idx].lowercased())")
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Sort Menu

    private var sortMenu: some View {
        Menu {
            ForEach(SortOption.allCases, id: \.self) { option in
                Button {
                    sortOption = option
                } label: {
                    HStack {
                        Text(sortLabel(option))
                        if sortOption == option {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 11, weight: .semibold))
                Text(sortLabel(sortOption))
                    .font(.system(size: 13, weight: .semibold))
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundColor(.csqMartGreen)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color.csqMartGreenPastel)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.full))
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "fork.knife")
                .font(.system(size: 48))
                .foregroundColor(.csqBorder)
            Text(marketConfig.strings.meatEmptyState)
                .font(AppFont.body(15))
                .foregroundColor(.csqTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Butcher Tip Banner

    private var butcherTipBanner: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#F59E0B"))
                Text(marketConfig.strings.meatButcherTipTitle)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.csqTextPrimary)
            }
            Text(marketConfig.strings.meatButcherTipBody)
                .font(AppFont.body(13))
                .foregroundColor(.csqTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(Color(hex: "#FFFBEB"))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg)
                .stroke(Color(hex: "#FDE68A"), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Floating Cart

    private var floatingCartBar: some View {
        VStack(spacing: 0) {
            NavigationLink(destination: CartView(rootIsPresented: $rootIsPresented).environmentObject(marketConfig), isActive: $showCart) { EmptyView() }
        Button { showCart = true } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.25))
                        .frame(width: 32, height: 32)
                    Text("\(cartStore.totalItems)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
                Text(marketConfig.strings.meatViewCart)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Text(marketConfig.market.formatPrice(cartStore.subtotal))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                LinearGradient(colors: [.csqMartGreen, .csqMartGreenDark], startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.full))
            .shadow(color: Color.csqMartGreen.opacity(0.4), radius: 12, x: 0, y: 6)
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}

// MARK: - Meat Product Card

struct MeatProductCard: View {
    @EnvironmentObject var cartStore: CartStore
    @EnvironmentObject var marketConfig: MarketConfig
    let product: GroceryProduct
    let qualityBadge: (label: String, color: Color)?

    var quantity: Int { cartStore.quantity(of: product) }

    private var subcategoryImageName: String {
        switch product.category {
        case "Chicken": return "MeatChicken"
        case "Beef":    return "MeatBeef"
        case "Pork":    return "MeatPork"
        case "Lamb":    return "MeatLamb"
        case "Seafood": return "MeatSeafood"
        default:        return ""
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Image / icon area ──────────────────────────────────────────
            ZStack(alignment: .bottomLeading) {
                // Per-product photo, then subcategory photo, then tinted symbol
                GroceryProductImage(product: product, fallbackAsset: subcategoryImageName, symbolSize: 46)
                    .frame(maxWidth: .infinity)
                    .frame(height: 110)
                    .clipped()

                // Discount badge — top right
                VStack {
                    HStack {
                        Spacer()
                        if let pct = product.discountPercent {
                            Text("\(pct)% OFF")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.csqError)
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                                .padding(7)
                        }
                    }
                    Spacer()
                }

                // Quality badge — bottom left
                if let badge = qualityBadge {
                    Text(badge.label)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(badge.color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(badge.color.opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(badge.color.opacity(0.3), lineWidth: 0.5)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                        .padding(7)
                }
            }
            .frame(height: 110)
            .clipped()

            // ── Info ───────────────────────────────────────────────────────
            VStack(alignment: .leading, spacing: 5) {
                Text(product.brand)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(product.imageColor)
                    .lineLimit(1)

                Text(product.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.csqTextPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 3) {
                    StarRating(rating: product.rating, size: 9)
                    Text("(\(product.reviewCount))")
                        .font(.system(size: 9))
                        .foregroundColor(.csqTextTertiary)
                }

                Text(product.unit)
                    .font(.system(size: 10))
                    .foregroundColor(.csqTextTertiary)

                // Price row + add control
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(marketConfig.market.formatPrice(product.price))
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.csqTextPrimary)
                        if let orig = product.originalPrice {
                            Text(marketConfig.market.formatPrice(orig))
                                .font(.system(size: 10))
                                .foregroundColor(.csqTextTertiary)
                                .strikethrough()
                        }
                    }

                    Spacer()

                    if quantity > 0 {
                        HStack(spacing: 6) {
                            Button { cartStore.remove(product) } label: {
                                Image(systemName: "minus")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.csqMartGreen)
                                    .frame(width: 24, height: 24)
                                    .background(Color.csqMartGreenPastel)
                                    .clipShape(Circle())
                            }
                            Text("\(quantity)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.csqTextPrimary)
                                .frame(minWidth: 14)
                            Button { cartStore.add(product) } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 24, height: 24)
                                    .background(Color.csqMartGreen)
                                    .clipShape(Circle())
                            }
                        }
                    } else {
                        Button { cartStore.add(product) } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 28, height: 28)
                                .background(Color.csqMartGreen)
                                .clipShape(Circle())
                                .shadow(color: Color.csqMartGreen.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        .accessibilityIdentifier("meat_add_\(product.name.lowercased().replacingOccurrences(of: " ", with: "_"))")
                    }
                }
            }
            .padding(10)
        }
        .background(Color.csqSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .shadow(color: Color.black.opacity(0.07), radius: 8, x: 0, y: 3)
    }
}
