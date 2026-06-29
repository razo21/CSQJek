import SwiftUI
import ContentsquareSDK

struct RestaurantDetailView: View {
    let restaurant: Restaurant
    @ObservedObject var cartStore: FoodCartStore
    @EnvironmentObject var marketConfig: MarketConfig

    @State private var selectedSectionIndex: Int = 0
    @State private var navigateToOrder: Bool = false
    @Environment(\.presentationMode) var presentationMode

    private enum RestaurantAccessID {
        static let backButton = "restaurant_back_button"
        static let viewCartButton = "restaurant_view_cart_button"
        static func categoryTab(_ index: Int) -> String { "restaurant_category_tab_\(index)" }
        static func itemRow(_ itemId: UUID) -> String { "restaurant_item_\(itemId)" }
        static func addButton(_ itemId: UUID) -> String { "restaurant_add_\(itemId)" }
    }

    var body: some View {
        ZStack {
            Color(hex: "#F8F3EF").ignoresSafeArea()

            VStack(spacing: 0) {
                headerView

                VStack(spacing: 0) {
                    categoryTabBar

                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 20) {
                            ForEach(0..<restaurant.menu.count, id: \.self) { index in
                                if index == selectedSectionIndex || restaurant.menu.count == 1 {
                                    menuSectionView(restaurant.menu[index])
                                }
                            }

                            Spacer(minLength: 20)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                    }
                }
                .background(Color(hex: "#F8F3EF"))

                bottomCartBar
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            CSQ.trackScreenview("Food - Restaurant Menu")
        }
    }

    private var headerView: some View {
        ZStack(alignment: .topLeading) {
            // Photo or gradient fallback
            if !restaurant.imageName.isEmpty, let uiImg = UIImage(named: restaurant.imageName) {
                Image(uiImage: uiImg)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .clipped()
            } else {
                LinearGradient(
                    gradient: Gradient(colors: [restaurant.headerColor, Color.black.opacity(0.85)]),
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .frame(height: 220)
            }
            // Always overlay a scrim so text stays readable over any photo
            LinearGradient(
                colors: [Color.black.opacity(0.25), Color.black.opacity(0.65)],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 220)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(hex: "#1C1C2E"))
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Color.white))
                            .shadow(color: .black.opacity(0.18), radius: 4, x: 0, y: 2)
                    }
                    .accessibilityIdentifier(RestaurantAccessID.backButton)

                    Spacer()
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(restaurant.name)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)

                    HStack(spacing: 8) {
                        Text(restaurant.cuisine)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(4)
                    }

                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "#F59E0B"))

                            Text(String(format: "%.1f", restaurant.rating))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)

                            Text("(\(restaurant.reviewCount) \(marketConfig.strings.productReviewsCount))")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(.white.opacity(0.8))
                        }

                        Spacer()
                    }

                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                                .foregroundColor(.white)

                            Text(restaurant.deliveryTime)
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(4)

                        HStack(spacing: 4) {
                            Image(systemName: "truck.box")
                                .font(.system(size: 10))
                                .foregroundColor(.white)

                            Text(restaurant.deliveryFee)
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(4)

                        HStack(spacing: 4) {
                            Image(systemName: "tag")
                                .font(.system(size: 10))
                                .foregroundColor(.white)

                            Text(restaurant.minOrder)
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(4)

                        Spacer()
                    }
                }

                Spacer()
            }
            .padding(16)
        }
    }

    private var categoryTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(0..<restaurant.menu.count, id: \.self) { index in
                    VStack(spacing: 0) {
                        Button(action: { withAnimation { selectedSectionIndex = index } }) {
                            Text(restaurant.menu[index].name)
                                .font(.system(size: 13, weight: selectedSectionIndex == index ? .semibold : .regular))
                                .foregroundColor(
                                    selectedSectionIndex == index
                                        ? Color(hex: "#FF8C42")
                                        : Color(hex: "#6B7280")
                                )
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                        }
                        .accessibilityIdentifier(RestaurantAccessID.categoryTab(index))

                        if selectedSectionIndex == index {
                            Rectangle()
                                .fill(Color(hex: "#FF8C42"))
                                .frame(height: 2)
                        }
                    }
                }
            }
            .background(Color(hex: "#FFFFFF"))
            .overlay(
                Rectangle()
                    .stroke(Color(hex: "#E8E0DA"), lineWidth: 1)
                    .frame(height: 1),
                alignment: .bottom
            )
        }
    }

    private func menuSectionView(_ section: MenuSection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(section.name)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(Color(hex: "#1C1C2E"))

            VStack(spacing: 12) {
                ForEach(section.items, id: \.id) { item in
                    MenuItemRow(
                        item: item,
                        restaurant: restaurant,
                        cartStore: cartStore,
                        accessibilityID: RestaurantAccessID.itemRow(item.id)
                    )
                }
            }
        }
    }

    private var bottomCartBar: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color(hex: "#E8E0DA"))

            if cartStore.itemCount == 0 {
                Text(marketConfig.strings.foodAddItemsToStart)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color(hex: "#6B7280"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(hex: "#FFFFFF"))
            } else {
                NavigationLink(
                    destination: FoodOrderView(restaurant: restaurant, cartStore: cartStore)
                        .environmentObject(marketConfig),
                    isActive: $navigateToOrder
                ) {
                    HStack(spacing: 8) {
                        Text(marketConfig.strings.foodViewCart)
                            .font(.system(size: 14, weight: .semibold))

                        Spacer()

                        Text(marketConfig.strings.foodItemsTotal(cartStore.itemCount, "", marketConfig.market.formatPrice(cartStore.subtotal)))
                            .font(.system(size: 13, weight: .regular))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "#FF8C42"), Color(hex: "#E05A00")]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(10)
                    .padding(12)
                    .background(Color(hex: "#FFFFFF"))
                }
                .accessibilityIdentifier(RestaurantAccessID.viewCartButton)
            }
        }
        .background(Color(hex: "#FFFFFF"))
    }
}

struct MenuItemRow: View {
    let item: MenuItem
    let restaurant: Restaurant
    @ObservedObject var cartStore: FoodCartStore
    @EnvironmentObject var marketConfig: MarketConfig
    let accessibilityID: String

    @State private var isAnimating = false

    var quantity: Int {
        cartStore.quantity(for: item)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Dish photo — shown only when its asset exists, so rows stay text-only
            // until dish images are added.
            if let ui = UIImage(named: item.imageAssetName) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(item.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: "#1C1C2E"))

                    if let tag = item.tag {
                        tagBadge(tag)
                    }
                }

                if !item.description.isEmpty {
                    Text(item.description)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Color(hex: "#6B7280"))
                        .lineLimit(2)
                }

                Text(marketConfig.market.formatPrice(item.price))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "#FF8C42"))
            }

            Spacer()

            if quantity > 0 {
                HStack(spacing: 8) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if quantity > 1 {
                                cartStore.remove(item)
                                cartStore.add(item)
                            } else {
                                cartStore.remove(item)
                            }
                        }
                    }) {
                        Image(systemName: "minus")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(hex: "#FF8C42"))
                            .frame(width: 24, height: 24)
                    }

                    Text("\(quantity)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "#1C1C2E"))
                        .frame(minWidth: 20)

                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            cartStore.add(item)
                        }
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(hex: "#FF8C42"))
                            .frame(width: 24, height: 24)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(hex: "#FFF5F0"))
                .cornerRadius(6)
            } else {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        cartStore.add(item)
                        isAnimating = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            isAnimating = false
                        }
                    }
                    CSQ.trackEvent("food_item_added", properties: [
                        "item_name": item.name,
                        "price": item.price,
                        "restaurant": restaurant.name,
                        "market": marketConfig.market.trackingLabel
                    ])
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color(hex: "#FF8C42")))
                }
                .scaleEffect(isAnimating ? 1.2 : 1.0)
            }
        }
        .padding(12)
        .background(Color(hex: "#FFFFFF"))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(hex: "#E8E0DA"), lineWidth: 1)
        )
        .accessibilityIdentifier(accessibilityID)
    }

    private func tagBadge(_ tag: String) -> some View {
        let (bgColor, textColor) = tagColors(tag)

        return Text(tag)
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(textColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(bgColor)
            .cornerRadius(3)
    }

    private func tagColors(_ tag: String) -> (background: Color, text: Color) {
        switch tag {
        // English (Singapore) tags
        case "Bestseller":
            return (Color(hex: "#FEF3C7"), Color(hex: "#92400E"))
        case "Popular":
            return (Color(hex: "#DBEAFE"), Color(hex: "#1E40AF"))
        case "Spicy":
            return (Color(hex: "#FEE2E2"), Color(hex: "#991B1B"))
        case "New":
            return (Color(hex: "#DCFCE7"), Color(hex: "#166534"))
        case "Veg":
            return (Color(hex: "#DCFCE7"), Color(hex: "#166534"))
        case "Halal":
            return (Color(hex: "#CFFAFE"), Color(hex: "#164E63"))
        // Japanese (Tokyo) tags
        case "ベストセラー", "定番", "シグネチャー":
            return (Color(hex: "#FEF3C7"), Color(hex: "#92400E"))
        case "人気", "おすすめ":
            return (Color(hex: "#DBEAFE"), Color(hex: "#1E40AF"))
        case "辛口":
            return (Color(hex: "#FEE2E2"), Color(hex: "#991B1B"))
        case "和風":
            return (Color(hex: "#DCFCE7"), Color(hex: "#166534"))
        case "プレミアム":
            return (Color(hex: "#CFFAFE"), Color(hex: "#164E63"))
        default:
            return (Color(hex: "#F3F4F6"), Color(hex: "#6B7280"))
        }
    }
}

#Preview {
    NavigationView {
        RestaurantDetailView(
            restaurant: Restaurant.sampleRestaurants[0],
            cartStore: FoodCartStore()
        )
    }
}
