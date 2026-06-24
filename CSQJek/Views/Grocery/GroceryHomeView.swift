import SwiftUI

struct GroceryHomeView: View {
    @EnvironmentObject var cartStore: CartStore
    @EnvironmentObject var marketConfig: MarketConfig
    @Binding var isPresented: Bool
    @State private var searchText = ""
    @State private var selectedCategory: String? = nil
    @State private var selectedProduct: GroceryProduct? = nil
    @State private var showCart = false
    @State private var showMeatCategory = false
    @State private var selectedChipIndex = 0
    @State private var selectedMeatSubcategoryIndex = 0

    // English keys used for filtering — order must match martMeatSubcategories array
    private let meatCategoryKeys = ["", "Chicken", "Beef", "Pork", "Lamb", "Seafood"]

    private var meatSubcategories: [String] { marketConfig.strings.martMeatSubcategories }
    private var chips: [String] { marketConfig.strings.martChips }

    private var filteredMeatPreview: [GroceryProduct] {
        let key = selectedMeatSubcategoryIndex < meatCategoryKeys.count
            ? meatCategoryKeys[selectedMeatSubcategoryIndex] : ""
        let base = key.isEmpty
            ? GroceryProduct.meatProducts
            : GroceryProduct.meatProducts.filter { $0.category == key }
        return Array(base.prefix(6))
    }

    let categories = GroceryCategory.all
    let featured = GroceryProduct.featured
    let flashDeals = GroceryProduct.flashDeals

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Header
                        groceryHeader

                        VStack(spacing: 20) {
                            // Category chips
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(Array(chips.enumerated()), id: \.offset) { idx, chip in
                                        CSQChip(label: chip, isSelected: selectedChipIndex == idx, tint: .csqMartGreen) {
                                            selectedChipIndex = idx
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }

                            // Categories grid
                            categorySection

                            // Flash deals
                            flashDealsSection

                            // Meat section
                            meatSection

                            // Featured products
                            featuredSection

                            // Bottom padding for cart button
                            Color.clear.frame(height: cartStore.totalItems > 0 ? 80 : 20)
                        }
                        .padding(.top, 16)
                    }
                }
                .background(Color.csqBackground.ignoresSafeArea())

                // Floating cart button
                if cartStore.totalItems > 0 {
                    NavigationLink(destination: CartView(rootIsPresented: $isPresented), isActive: $showCart) {
                        EmptyView()
                    }
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
                            Text(marketConfig.strings.martViewCart)
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
            .navigationBarHidden(true)
            .background(
                NavigationLink(
                    destination: MeatCategoryView(rootIsPresented: $isPresented)
                        .environmentObject(cartStore)
                        .environmentObject(marketConfig),
                    isActive: $showMeatCategory
                ) { EmptyView() }
            )
            .sheet(item: $selectedProduct) { product in
                ProductDetailView(product: product)
                    .environmentObject(cartStore)
                    .environmentObject(marketConfig)
            }
        }
    }

    // MARK: - Header
    var groceryHeader: some View {
        VStack(spacing: 0) {
            // 1. Slim top bar — controls on the app background, always legible (never on the art).
            HStack {
                // Close button
                Button { isPresented = false } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.csqTextPrimary)
                        .frame(width: 36, height: 36)
                        .background(Color.csqSurface)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.csqBorder, lineWidth: 1))
                }

                Spacer()

                // Bell
                ZStack(alignment: .topTrailing) {
                    Button {} label: {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.csqMartForest)
                            .frame(width: 36, height: 36)
                            .background(Color.csqSurface)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.csqBorder, lineWidth: 1))
                    }
                    Circle()
                        .fill(Color.csqMartAmber)
                        .frame(width: 8, height: 8)
                        .offset(x: 1, y: -1)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            // 2. Poster hero — clean, untouched, shown in full as a rounded banner.
            Group {
                if UIImage(named: "MartHeaderBg") != nil {
                    Image("MartHeaderBg")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    LinearGradient(
                        colors: [Color.csqMartGreen, Color.csqMartGreen.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .aspectRatio(3.0 / 2.0, contentMode: .fit)
                }
            }
            .frame(maxWidth: .infinity)
            .background(Color.csqMartGreen)   // brand green shows through the transparent PNG background
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 16)

            // 3. Location selector + search — beneath the poster, dark-on-light.
            VStack(spacing: 12) {
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.csqMartGreen)
                    Text(marketConfig.strings.martDeliverTo)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.csqTextPrimary)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.csqTextSecondary)
                    Spacer()
                }

                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.csqTextTertiary)
                    TextField(marketConfig.strings.martSearchPlaceholder, text: $searchText)
                        .font(.system(size: 14))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 13)
                .background(Color.csqSurface)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.csqBorder, lineWidth: 1))
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
        }
    }

    // MARK: - Categories
    var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(marketConfig.strings.martCategorySection)
                    .font(AppFont.display(17))
                    .foregroundColor(.csqMartForest)
                Spacer()
                Button(marketConfig.strings.martSeeAll) {}
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.csqMartGreen)
            }
            .padding(.horizontal, 16)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                ForEach(categories) { category in
                    Button {
                        if category.name == "Meat" {
                            showMeatCategory = true
                        } else {
                            selectedCategory = category.name
                        }
                    } label: {
                        VStack(spacing: 8) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(category.color.opacity(0.12))
                                    .frame(width: 52, height: 52)
                                Image(systemName: category.iconName)
                                    .font(.system(size: 20))
                                    .foregroundColor(category.color)
                            }
                            Text(category.name)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.csqTextSecondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("grocery_category_\(category.name.lowercased())")
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Meat Section

    var meatSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#E04D3A"))
                    Text(marketConfig.strings.martButcherSection)
                        .font(AppFont.display(17))
                        .foregroundColor(.csqMartForest)
                }
                Spacer()
                Button {
                    showMeatCategory = true
                } label: {
                    Text(marketConfig.strings.martSeeAll)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.csqMartGreen)
                }
                .accessibilityIdentifier("meat_see_all_button")
            }
            .padding(.horizontal, 16)

            // Subcategory chips — index-based to support localised display names
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(meatSubcategories.enumerated()), id: \.offset) { idx, sub in
                        let isSelected = selectedMeatSubcategoryIndex == idx
                        let dotColor: Color = {
                            switch idx {
                            case 1: return Color(hex: "#F97316")  // Chicken
                            case 2: return Color(hex: "#E04D3A")  // Beef
                            case 3: return Color(hex: "#EC4899")  // Pork
                            case 4: return Color(hex: "#7C3AED")  // Lamb
                            case 5: return Color(hex: "#0EA5E9")  // Seafood
                            default: return Color.csqMartGreen
                            }
                        }()

                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedMeatSubcategoryIndex = idx
                            }
                        } label: {
                            HStack(spacing: 5) {
                                if idx > 0 {
                                    Circle()
                                        .fill(isSelected ? Color.white.opacity(0.8) : dotColor)
                                        .frame(width: 6, height: 6)
                                }
                                Text(sub)
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(isSelected ? dotColor : Color.csqSurface)
                            .foregroundColor(isSelected ? .white : .csqTextSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.full))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.full)
                                    .stroke(isSelected ? Color.clear : Color.csqBorder, lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(.horizontal, 16)
            }

            // Horizontal product scroll
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(filteredMeatPreview) { product in
                        Button { selectedProduct = product } label: {
                            MeatPreviewCard(product: product)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("meat_preview_\(product.name.lowercased().replacingOccurrences(of: " ", with: "_"))")
                    }

                    // "See all" card at end
                    Button { showMeatCategory = true } label: {
                        VStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: "#E04D3A").opacity(0.1))
                                    .frame(width: 52, height: 52)
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(Color(hex: "#E04D3A"))
                            }
                            Text(marketConfig.strings.martViewAllCuts)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.csqTextSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(width: 80, height: 160)
                        .background(Color.csqSurface)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Flash Deals
    var flashDealsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.csqMartAmber)
                    Text(marketConfig.strings.martFlashDeals)
                        .font(AppFont.display(17))
                        .foregroundColor(.csqMartForest)
                }
                Spacer()
                Text(marketConfig.strings.martFlashDealsTimer)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.csqMartAmber)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.csqMartAmber.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(flashDeals) { product in
                        Button { selectedProduct = product } label: {
                            CompactProductCard(product: product)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Featured
    var featuredSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(marketConfig.strings.martFeaturedItems)
                    .font(AppFont.display(17))
                    .foregroundColor(.csqMartForest)
                Spacer()
                Button(marketConfig.strings.martSeeAll) {}
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.csqMartGreen)
            }
            .padding(.horizontal, 16)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                ForEach(featured) { product in
                    Button { selectedProduct = product } label: {
                        FeaturedProductCard(product: product)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Compact Product Card (for flash deals)
struct CompactProductCard: View {
    @EnvironmentObject var cartStore: CartStore
    @EnvironmentObject var marketConfig: MarketConfig
    let product: GroceryProduct

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image area
            ZStack(alignment: .topLeading) {
                GroceryProductImage(product: product, symbolSize: 40)
                    .frame(width: 140, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                if let discount = product.discountPercent {
                    Text("\(discount)% OFF")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.csqError)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .padding(6)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(product.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.csqTextPrimary)
                    .lineLimit(1)
                Text(product.unit)
                    .font(.system(size: 10))
                    .foregroundColor(.csqTextTertiary)
                HStack {
                    Text(marketConfig.market.formatPrice(product.price))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.csqTextPrimary)
                    if let orig = product.originalPrice {
                        Text(marketConfig.market.formatPrice(orig))
                            .font(.system(size: 10))
                            .foregroundColor(.csqTextTertiary)
                            .strikethrough()
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .frame(width: 140)
        .background(Color.csqSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: Color.black.opacity(0.07), radius: 8, x: 0, y: 3)
    }
}

// MARK: - Featured Product Card
struct FeaturedProductCard: View {
    @EnvironmentObject var cartStore: CartStore
    @EnvironmentObject var marketConfig: MarketConfig
    let product: GroceryProduct
    @State private var addedFeedback = false

    var quantity: Int { cartStore.quantity(of: product) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image
            ZStack(alignment: .topLeading) {
                GroceryProductImage(product: product, symbolSize: 48)
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .clipped()

                if let discount = product.discountPercent {
                    Text("\(discount)% OFF")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.csqError)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .padding(8)
                }
            }
            .frame(height: 120)
            .clipped()

            VStack(alignment: .leading, spacing: 6) {
                Text(product.brand)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.csqMartGreen)
                Text(product.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.csqTextPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 4) {
                    StarRating(rating: product.rating, size: 10)
                    Text("(\(product.reviewCount))")
                        .font(.system(size: 10))
                        .foregroundColor(.csqTextTertiary)
                }
                Text(product.unit)
                    .font(.system(size: 10))
                    .foregroundColor(.csqTextTertiary)

                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(marketConfig.market.formatPrice(product.price))
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.csqTextPrimary)
                        if let orig = product.originalPrice {
                            Text(marketConfig.market.formatPrice(orig))
                                .font(.system(size: 11))
                                .foregroundColor(.csqTextTertiary)
                                .strikethrough()
                        }
                    }
                    Spacer()
                    // Quantity control
                    if quantity > 0 {
                        HStack(spacing: 8) {
                            Button { cartStore.remove(product) } label: {
                                Image(systemName: "minus")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.csqMartGreen)
                                    .frame(width: 26, height: 26)
                                    .background(Color.csqMartGreenPastel)
                                    .clipShape(Circle())
                            }
                            Text("\(quantity)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.csqTextPrimary)
                                .frame(minWidth: 16)
                            Button { cartStore.add(product) } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 26, height: 26)
                                    .background(Color.csqMartGreen)
                                    .clipShape(Circle())
                            }
                        }
                    } else {
                        Button { cartStore.add(product) } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 30, height: 30)
                                .background(Color.csqMartGreen)
                                .clipShape(Circle())
                                .shadow(color: Color.csqMartGreen.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
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

// MARK: - Meat Preview Card (compact horizontal scroll card)

struct MeatPreviewCard: View {
    @EnvironmentObject var cartStore: CartStore
    @EnvironmentObject var marketConfig: MarketConfig
    let product: GroceryProduct

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

            // Photo or tinted fallback
            ZStack(alignment: .topTrailing) {
                GroceryProductImage(product: product, fallbackAsset: subcategoryImageName, symbolSize: 38)
                    .frame(width: 130, height: 90)
                    .clipped()

                if let pct = product.discountPercent {
                    Text("\(pct)% OFF")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.csqError)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                        .padding(6)
                }
            }
            .frame(width: 130, height: 90)
            .clipped()

            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.csqTextPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Text(product.unit)
                    .font(.system(size: 10))
                    .foregroundColor(.csqTextTertiary)
                HStack {
                    Text(marketConfig.market.formatPrice(product.price))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.csqTextPrimary)
                    Spacer()
                    if quantity > 0 {
                        Text("\(quantity)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 22, height: 22)
                            .background(Color.csqMartGreen)
                            .clipShape(Circle())
                    } else {
                        Button { cartStore.add(product) } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 26, height: 26)
                                .background(Color.csqMartGreen)
                                .clipShape(Circle())
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
        .frame(width: 130)
        .background(Color.csqSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: Color.black.opacity(0.07), radius: 8, x: 0, y: 3)
    }
}
