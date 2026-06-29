import SwiftUI
import ContentsquareSDK

struct FoodHomeView: View {
    @EnvironmentObject var marketConfig: MarketConfig
    @StateObject private var cartStore = FoodCartStore()
    @State private var selectedCategory: FoodCategory = .all
    @State private var searchText = ""
    @State private var activeRestaurant: Restaurant = Restaurant.sampleRestaurants[0]  // overridden in onAppear

    private enum FoodAccessID {
        static let searchBar = "food_search_bar"
        static let cartBar = "food_cart_bar"
        static func chip(_ category: FoodCategory) -> String { "food_chip_\(category.rawValue)" }
        static func featured(_ index: Int) -> String { "food_featured_\(index)" }
        static func seeAll(_ section: String) -> String { "food_see_all_\(section)" }
        static func hawkerCard(_ name: String) -> String { "food_hawker_\(slug(name))" }
        static func freeDeliveryRow(_ name: String) -> String { "food_free_delivery_\(slug(name))" }
        static func restaurantRow(_ name: String) -> String { "food_restaurant_row_\(slug(name))" }
        private static func slug(_ s: String) -> String {
            s.lowercased().replacingOccurrences(of: " ", with: "_")
        }
    }

    var filteredRestaurants: [Restaurant] {
        let allRestaurants = Restaurant.restaurants(for: marketConfig.market)
        let categoryFiltered = selectedCategory == .all
            ? allRestaurants
            : allRestaurants.filter { $0.category == selectedCategory }

        if searchText.isEmpty {
            return categoryFiltered
        } else {
            return categoryFiltered.filter { restaurant in
                restaurant.name.localizedCaseInsensitiveContains(searchText) ||
                restaurant.cuisine.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#F8F3EF").ignoresSafeArea()

                VStack(spacing: 0) {
                    headerView

                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 24) {
                            searchBarSection
                            categoryFilterSection

                            if !filteredRestaurants.filter({ $0.promo != nil }).isEmpty {
                                featuredSection
                            }

                            if !filteredRestaurants.filter({ $0.category == .hawker }).isEmpty {
                                hawkerPicksSection
                            }

                            if !filteredRestaurants.filter({ $0.deliveryFee == "Free" || $0.deliveryFee == "無料" }).isEmpty {
                                freeDeliverySection
                            }

                            if !filteredRestaurants.isEmpty {
                                allRestaurantsSection
                            }

                            Spacer(minLength: cartStore.itemCount > 0 ? 100 : 0)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                    }

                    if cartStore.itemCount > 0 {
                        floatingCartBar
                    }
                }
                .navigationBarHidden(true)

                // Live Agent FAB — bottom-right, above cart bar
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        LiveAgentButton(screen: "Food - Home")
                    }
                }
            }
            .onAppear {
                activeRestaurant = Restaurant.restaurants(for: marketConfig.market)[0]
                CSQ.trackScreenview("Food - Home")
            }
        }
    }

    private var headerView: some View {
        VStack(spacing: 0) {
            // CSQFood poster banner — shown clean (its own branding), gradient fallback.
            Group {
                if UIImage(named: "FoodHeaderBg") != nil {
                    Image("FoodHeaderBg")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    LinearGradient(
                        gradient: Gradient(colors: [Color(hex: "#FF8C42"), Color(hex: "#E05A00")]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .aspectRatio(1920.0 / 819.0, contentMode: .fit)
                }
            }
            .frame(maxWidth: .infinity)
            .clipped()

            // Location selector beneath the banner, on the app background.
            HStack(spacing: 8) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.csqFoodOrange)

                Text(marketConfig.strings.foodLocationLabel)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.csqTextPrimary)

                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.csqTextSecondary)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private var searchBarSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(hex: "#6B7280"))

            TextField(marketConfig.strings.foodSearchPlaceholder, text: $searchText)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color(hex: "#1C1C2E"))
                .tint(Color(hex: "#FF8C42"))

            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#9CA3AF"))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(hex: "#FFFFFF"))
        .cornerRadius(12)
        .accessibilityIdentifier(FoodAccessID.searchBar)
    }

    private var categoryFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(FoodCategory.allCases, id: \.self) { category in
                    VStack(spacing: 6) {
                        Image(systemName: category.icon)
                            .font(.system(size: 16, weight: .semibold))

                        Text(category.displayName(for: marketConfig.market))
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(selectedCategory == category ? Color(hex: "#FF8C42") : Color(hex: "#6B7280"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(selectedCategory == category ? Color(hex: "#FFF5F0") : Color(hex: "#F8F3EF"))
                    .cornerRadius(10)
                    .onTapGesture {
                        selectedCategory = category
                    }
                    .accessibilityIdentifier(FoodAccessID.chip(category))
                }
            }
            .padding(.horizontal, 0)
        }
    }

    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Text(marketConfig.strings.foodFeaturedSection)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(Color(hex: "#1C1C2E"))
                    Image(systemName: "star.fill")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#FF8C42"))
                }

                Spacer()

                NavigationLink(marketConfig.strings.foodSeeAll) {
                    FoodHomeView()
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(hex: "#FF8C42"))
                .accessibilityIdentifier(FoodAccessID.seeAll("featured"))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(
                        filteredRestaurants
                            .filter { $0.promo != nil }
                            .prefix(6),
                        id: \.id
                    ) { restaurant in
                        NavigationLink(destination: RestaurantDetailView(restaurant: restaurant, cartStore: cartStore)) {
                            FeaturedRestaurantCard(restaurant: restaurant)
                        }
                        .simultaneousGesture(TapGesture().onEnded { activeRestaurant = restaurant })
                        .accessibilityIdentifier(FoodAccessID.featured(filteredRestaurants.firstIndex(where: { $0.id == restaurant.id }) ?? 0))
                    }
                }
            }
        }
    }

    private var hawkerPicksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Text(marketConfig.strings.foodHawkerPicksSection)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(Color(hex: "#1C1C2E"))
                    Image(systemName: "rosette")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#FF8C42"))
                }

                Spacer()

                NavigationLink(marketConfig.strings.foodSeeAll) {
                    FoodHomeView()
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(hex: "#FF8C42"))
                .accessibilityIdentifier(FoodAccessID.seeAll("hawker"))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(
                        filteredRestaurants.filter { $0.category == .hawker }.prefix(4),
                        id: \.id
                    ) { restaurant in
                        NavigationLink(destination: RestaurantDetailView(restaurant: restaurant, cartStore: cartStore)) {
                            RestaurantTileCard(restaurant: restaurant)
                        }
                        .simultaneousGesture(TapGesture().onEnded { activeRestaurant = restaurant })
                        .accessibilityIdentifier(FoodAccessID.hawkerCard(restaurant.name))
                    }
                }
            }
        }
    }

    private var freeDeliverySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Text(marketConfig.strings.foodFreeDeliverySection)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(Color(hex: "#1C1C2E"))
                    Image(systemName: "bicycle")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#FF8C42"))
                }

                Spacer()

                NavigationLink(marketConfig.strings.foodSeeAll) {
                    FoodHomeView()
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(hex: "#FF8C42"))
                .accessibilityIdentifier(FoodAccessID.seeAll("free_delivery"))
            }

            VStack(spacing: 8) {
                ForEach(
                    filteredRestaurants.filter { $0.deliveryFee == "Free" || $0.deliveryFee == "無料" }.prefix(3),
                    id: \.id
                ) { restaurant in
                    NavigationLink(destination: RestaurantDetailView(restaurant: restaurant, cartStore: cartStore)) {
                        RestaurantRow(restaurant: restaurant)
                    }
                    .simultaneousGesture(TapGesture().onEnded { activeRestaurant = restaurant })
                    .accessibilityIdentifier(FoodAccessID.freeDeliveryRow(restaurant.name))
                }
            }
        }
    }

    private var allRestaurantsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(marketConfig.strings.foodAllRestaurants)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(Color(hex: "#1C1C2E"))

            VStack(spacing: 8) {
                ForEach(filteredRestaurants, id: \.id) { restaurant in
                    NavigationLink(destination: RestaurantDetailView(restaurant: restaurant, cartStore: cartStore)) {
                        RestaurantRow(restaurant: restaurant)
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                        activeRestaurant = restaurant
                        CSQ.trackEvent("food_restaurant_tapped", properties: [
                            "restaurant_name": restaurant.name,
                            "cuisine": restaurant.cuisine
                        ])
                    })
                    .accessibilityIdentifier(FoodAccessID.restaurantRow(restaurant.name))
                }
            }
        }
    }

    private var floatingCartBar: some View {
        NavigationLink(destination: FoodOrderView(restaurant: activeRestaurant, cartStore: cartStore)) {
            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "cart.fill")
                        .font(.system(size: 13, weight: .semibold))
                    Text(marketConfig.market == .tokyo
                        ? "\(cartStore.itemCount)点 · \(marketConfig.market.formatPrice(cartStore.subtotal))"
                        : "\(cartStore.itemCount) items · \(marketConfig.market.formatPrice(cartStore.subtotal))")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "#FF8C42"), Color(hex: "#E05A00")]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .padding(16)
            .background(Color(hex: "#F8F3EF"))
        }
        .simultaneousGesture(TapGesture().onEnded {
            CSQ.trackEvent("food_view_cart_tapped", properties: [
                "item_count": cartStore.itemCount,
                "subtotal": String(format: "%.2f", cartStore.subtotal),
                "market": marketConfig.market.trackingLabel
            ])
        })
        .accessibilityIdentifier(FoodAccessID.cartBar)
    }
}

struct FeaturedRestaurantCard: View {
    let restaurant: Restaurant

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                if !restaurant.imageName.isEmpty, let uiImg = UIImage(named: restaurant.imageName) {
                    Image(uiImage: uiImg)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 280, height: 130)
                        .clipped()
                } else {
                    LinearGradient(
                        gradient: Gradient(colors: [restaurant.headerColor, restaurant.headerColor.opacity(0.7)]),
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                }
                // Dark scrim so text is always readable
                LinearGradient(colors: [.clear, .black.opacity(0.6)], startPoint: .top, endPoint: .bottom)

                VStack(alignment: .leading, spacing: 4) {
                    Text(restaurant.name)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    Text(restaurant.cuisine)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.85))
                    if let promo = restaurant.promo {
                        Text(promo)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Color.black.opacity(0.35))
                            .cornerRadius(4)
                    }
                }
                .padding(10)
            }
            .frame(height: 130)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "#F59E0B"))

                    Text(String(format: "%.1f", restaurant.rating))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(hex: "#1C1C2E"))

                    Text("(\(restaurant.reviewCount))")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(Color(hex: "#6B7280"))
                }

                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "#6B7280"))

                    Text(restaurant.deliveryTime)
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(Color(hex: "#6B7280"))
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(hex: "#FFFFFF"))
        }
        .frame(width: 280, height: 130)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "#E8E0DA"), lineWidth: 1)
        )
    }
}

struct RestaurantTileCard: View {
    let restaurant: Restaurant

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                if !restaurant.imageName.isEmpty, let uiImg = UIImage(named: restaurant.imageName) {
                    Image(uiImage: uiImg)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 140, height: 80)
                        .clipped()
                } else {
                    LinearGradient(
                        gradient: Gradient(colors: [restaurant.headerColor, restaurant.headerColor.opacity(0.6)]),
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                }
            }
            .frame(height: 80)

            VStack(alignment: .leading, spacing: 6) {
                Text(restaurant.name)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(hex: "#1C1C2E"))
                    .lineLimit(1)

                Text(restaurant.cuisine)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(Color(hex: "#6B7280"))
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 9))
                        .foregroundColor(Color(hex: "#F59E0B"))

                    Text(String(format: "%.1f", restaurant.rating))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color(hex: "#1C1C2E"))

                    Spacer()

                    Text(restaurant.deliveryTime)
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(Color(hex: "#6B7280"))
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(hex: "#FFFFFF"))
        }
        .frame(width: 140, height: 160)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(hex: "#E8E0DA"), lineWidth: 1)
        )
    }
}

struct RestaurantRow: View {
    let restaurant: Restaurant

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if !restaurant.imageName.isEmpty, let uiImg = UIImage(named: restaurant.imageName) {
                    Image(uiImage: uiImg)
                        .resizable()
                        .scaledToFill()
                } else {
                    Rectangle().fill(restaurant.headerColor)
                }
            }
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(restaurant.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: "#1C1C2E"))

                Text(restaurant.cuisine)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(Color(hex: "#6B7280"))
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "#F59E0B"))

                    Text(String(format: "%.1f", restaurant.rating))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(hex: "#1C1C2E"))
                }

                Text(restaurant.deliveryTime)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(Color(hex: "#6B7280"))
            }

            if let promo = restaurant.promo {
                VStack(spacing: 2) {
                    Text(promo)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: "#FF8C42"))
                        .cornerRadius(3)
                }
                .frame(width: 45)
            }
        }
        .padding(10)
        .background(Color(hex: "#FFFFFF"))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(hex: "#E8E0DA"), lineWidth: 1)
        )
    }
}

#Preview {
    FoodHomeView()
        .environmentObject(MarketConfig())
}
