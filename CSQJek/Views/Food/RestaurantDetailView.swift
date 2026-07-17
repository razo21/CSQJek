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
        static let buildBanner = "restaurant_build_your_own_banner"
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
                            if restaurant.buildable {
                                buildYourOwnBanner
                            }

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
        // The info sits ON the photo over a dark scrim. The image is a clipped
        // background sized to the header, and the content uses minHeight so the
        // text can never overflow onto the page background (the earlier bug:
        // white text spilling below a fixed-height photo onto the cream page).
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

            Spacer(minLength: 30)

            VStack(alignment: .leading, spacing: 8) {
                Text(restaurant.name)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.35), radius: 3, x: 0, y: 1)

                HStack(spacing: 8) {
                    Text(restaurant.cuisine)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.35))
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
                            .foregroundColor(.white.opacity(0.85))
                    }

                    Spacer()
                }
                .shadow(color: .black.opacity(0.35), radius: 3, x: 0, y: 1)

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
                    .background(Color.black.opacity(0.3))
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
                    .background(Color.black.opacity(0.3))
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
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(4)

                    Spacer()
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 240, alignment: .topLeading)
        .background(
            ZStack {
                if !restaurant.imageName.isEmpty, let uiImg = UIImage(named: restaurant.imageName) {
                    Image(uiImage: uiImg)
                        .resizable()
                        .scaledToFill()
                } else {
                    LinearGradient(
                        gradient: Gradient(colors: [restaurant.headerColor, Color.black.opacity(0.85)]),
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                }
                LinearGradient(
                    colors: [Color.black.opacity(0.15), Color.black.opacity(0.7)],
                    startPoint: .top, endPoint: .bottom
                )
            }
        )
        .clipped()
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

    // Hero entry point to the customizer — only shown for buildable venues (CSQ Burrito).
    private var buildYourOwnBanner: some View {
        let strings = BurritoBuilder.strings(for: marketConfig.market)
        return NavigationLink(
            destination: BurritoBuilderView(restaurant: restaurant, cartStore: cartStore)
                .environmentObject(marketConfig)
        ) {
            HStack(spacing: 14) {
                Image(systemName: "fork.knife")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 46, height: 46)
                    .background(Circle().fill(Color.white.opacity(0.18)))

                VStack(alignment: .leading, spacing: 3) {
                    Text(strings.bannerTitle)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Text(strings.bannerSubtitle)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.white.opacity(0.9))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(14)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "#1FA463"), Color(hex: "#0E7A46")]),
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .cornerRadius(14)
        }
        .accessibilityIdentifier(RestaurantAccessID.buildBanner)
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
                    .accessibilityIdentifier("restaurant_item_qty_minus_\(item.id)")

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
                    .accessibilityIdentifier("restaurant_item_qty_plus_\(item.id)")
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
                .accessibilityIdentifier("restaurant_add_\(item.id)")
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

// MARK: - Build Your Own Burrito (CSQ Burrito parody demo)
//
// Single-screen customizer. Every option tap fires that step's `burrito_<x>_selected`
// event; "Add to Cart" fires `burrito_build_completed` and drops a configured MenuItem
// (fresh UUID → its own cart line) into the shared FoodCartStore, so the standard
// CSQFood checkout + tracking flow handles the rest. Screen: "Burrito - Builder".
struct BurritoBuilderView: View {
    let restaurant: Restaurant
    @ObservedObject var cartStore: FoodCartStore
    @EnvironmentObject var marketConfig: MarketConfig
    @Environment(\.presentationMode) var presentationMode

    // step.key → set of chosen option idKeys. Single-mode steps hold 0 or 1.
    @State private var selections: [String: Set<String>] = [:]
    // Deterministic frustration signal for the deliberately-broken guac topping.
    @State private var guacRage = RageTapDetector()

    private enum BurritoAccessID {
        static let closeButton = "burrito_builder_close"
        static let addToCartButton = "burrito_builder_add_to_cart"
        static func option(_ stepKey: String, _ optionKey: String) -> String {
            "burrito_option_\(stepKey)_\(optionKey)"
        }
    }

    // MARK: Derived state

    private var market: Market { marketConfig.market }
    private var steps: [BurritoStep] { BurritoBuilder.steps(for: market) }
    private var strings: BurritoStrings { BurritoBuilder.strings(for: market) }

    private var totalPrice: Double {
        var total = BurritoBuilder.basePrice(for: market)
        for step in steps {
            let chosen = selections[step.key] ?? []
            for option in step.options where chosen.contains(option.idKey) {
                total += option.priceDelta
            }
        }
        return total
    }

    private var requiredSatisfied: Bool {
        BurritoBuilder.requiredKeys(for: market).allSatisfy { !(selections[$0] ?? []).isEmpty }
    }

    private func isSelected(_ stepKey: String, _ optionKey: String) -> Bool {
        (selections[stepKey] ?? []).contains(optionKey)
    }

    var body: some View {
        ZStack {
            Color(hex: "#F8F3EF").ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 20) {
                        ForEach(steps) { step in
                            stepSection(step)
                        }
                        Spacer(minLength: 20)
                    }
                    .padding(16)
                }

                addToCartBar
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            CSQ.trackScreenview("Burrito - Builder")
            CSQ.trackEvent("burrito_build_started", properties: [
                "restaurant": restaurant.name,
                "market": marketConfig.market.trackingLabel
            ])
        }
    }

    // MARK: Header

    private var header: some View {
        // Content sits inside the safe area; only the gradient background bleeds
        // up behind the status bar, so the title never collides with the notch.
        HStack(spacing: 12) {
            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "#0E7A46"))
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.white))
            }
            .accessibilityIdentifier(BurritoAccessID.closeButton)
            .accessibilityLabel("Close burrito builder")

            VStack(alignment: .leading, spacing: 2) {
                Text(strings.builderTitle)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                Text(restaurant.name)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white.opacity(0.9))
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 14)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#1FA463"), Color(hex: "#0E7A46")]),
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea(edges: .top)
        )
    }

    // MARK: Step section

    private func stepSection(_ step: BurritoStep) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(step.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: "#1C1C2E"))

                if step.required {
                    Text(strings.requiredBadge)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color(hex: "#0E7A46"))
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color(hex: "#DCFCE7"))
                        .cornerRadius(3)
                }

                Spacer()

                Text(step.subtitle)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(Color(hex: "#6B7280"))
            }

            VStack(spacing: 8) {
                ForEach(step.options) { option in
                    optionRow(step, option)
                }
            }
        }
    }

    private func optionRow(_ step: BurritoStep, _ option: BurritoOption) -> some View {
        let selected = isSelected(step.key, option.idKey)
        return Button(action: { toggle(step, option) }) {
            HStack(spacing: 12) {
                Image(systemName: indicatorSymbol(step.mode, selected: selected))
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(selected ? Color(hex: "#1FA463") : Color(hex: "#C4C4C4"))

                Text(option.name)
                    .font(.system(size: 14, weight: selected ? .semibold : .regular))
                    .foregroundColor(Color(hex: "#1C1C2E"))

                if let tag = option.tag {
                    Text(tag)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color(hex: "#0E7A46"))
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color(hex: "#DCFCE7"))
                        .cornerRadius(3)
                }

                Spacer()

                if option.priceDelta > 0 {
                    Text("+\(marketConfig.market.formatPrice(option.priceDelta))")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "#6B7280"))
                }
            }
            .padding(12)
            .background(Color.white)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(selected ? Color(hex: "#1FA463") : Color(hex: "#E8E0DA"),
                            lineWidth: selected ? 1.5 : 1)
            )
        }
        .accessibilityIdentifier(BurritoAccessID.option(step.key, option.idKey))
        .accessibilityLabel(option.name)
    }

    private func indicatorSymbol(_ mode: BurritoSelectionMode, selected: Bool) -> String {
        switch mode {
        case .single: return selected ? "largecircle.fill.circle" : "circle"
        case .multi:  return selected ? "checkmark.square.fill" : "square"
        }
    }

    // MARK: Selection logic

    private func toggle(_ step: BurritoStep, _ option: BurritoOption) {
        // ⚠️ Deliberately-broken control (demo): the guacamole topping never
        // registers — no checkbox, no selection captured, no price change — so a
        // user hammers it. Every tap is still autocaptured (server-side rage), and
        // once the burst crosses the threshold we fire a deterministic rage event.
        if step.key == "toppings" && option.idKey == "guac" {
            if let count = guacRage.registerTap() {
                FrustrationSignal.burritoOptionRage(
                    option: option.idKey,
                    step: step.key,
                    tapCount: count,
                    market: market
                )
            }
            return   // no toggle, no burrito_topping_selected event
        }

        var chosen = selections[step.key] ?? []

        switch step.mode {
        case .single:
            // Radio: re-tapping the same option keeps it; tapping another replaces.
            if chosen.contains(option.idKey) { return }
            chosen = [option.idKey]
        case .multi:
            if chosen.contains(option.idKey) {
                chosen.remove(option.idKey)     // deselect — no event
                selections[step.key] = chosen
                return
            }
            chosen.insert(option.idKey)
        }

        selections[step.key] = chosen

        CSQ.trackEvent(step.selectEvent, properties: [
            "option": option.idKey,
            "step": step.key,
            "price_delta": option.priceDelta,
            "market": marketConfig.market.trackingLabel
        ])
    }

    // MARK: Add to cart

    private var addToCartBar: some View {
        VStack(spacing: 0) {
            Divider().background(Color(hex: "#E8E0DA"))

            Button(action: addBuildToCart) {
                HStack(spacing: 8) {
                    Text(requiredSatisfied ? strings.addToCart : strings.addToCartLocked)
                        .font(.system(size: 15, weight: .semibold))
                    Spacer()
                    Text(marketConfig.market.formatPrice(totalPrice))
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.vertical, 14)
                .padding(.horizontal, 18)
                .background(
                    requiredSatisfied
                        ? Color(hex: "#1FA463")
                        : Color(hex: "#9CA3AF")
                )
                .cornerRadius(12)
                .padding(12)
            }
            .disabled(!requiredSatisfied)
            .accessibilityIdentifier(BurritoAccessID.addToCartButton)
            .accessibilityLabel("Add your burrito to cart")
        }
        .background(Color.white)
    }

    private func addBuildToCart() {
        guard requiredSatisfied else { return }

        let proteinName = selectedName(step: "protein") ?? ""
        let summary = buildSummary()
        let displayName = proteinName.isEmpty
            ? strings.cartNamePrefix
            : "\(strings.cartNamePrefix) · \(proteinName)"
        let item = MenuItem(
            name: displayName,
            description: summary,
            price: totalPrice,
            isPopular: false,
            tag: nil,
            idKey: "byo_burrito"
        )
        cartStore.add(item)

        CSQ.trackEvent("burrito_build_completed", properties: [
            "base":          selectedKey(step: "base") ?? "",
            "protein":       selectedKey(step: "protein") ?? "",
            "salsa":         selectedKey(step: "salsa") ?? "",
            "topping_count": (selections["toppings"] ?? []).count,
            "extra_count":   (selections["extras"] ?? []).count,
            "total":         totalPrice,
            "market":        marketConfig.market.trackingLabel
        ])

        presentationMode.wrappedValue.dismiss()
    }

    // First chosen option's stable key for a single-select step.
    private func selectedKey(step: String) -> String? {
        (selections[step] ?? []).first
    }

    // First chosen option's display name for a single-select step.
    private func selectedName(step: String) -> String? {
        guard let key = selectedKey(step: step),
              let stepDef = steps.first(where: { $0.key == step }),
              let option = stepDef.options.first(where: { $0.idKey == key })
        else { return nil }
        return option.name
    }

    // Human-readable summary for the cart line description.
    private func buildSummary() -> String {
        var parts: [String] = []
        for step in steps {
            let chosen = selections[step.key] ?? []
            let names = step.options
                .filter { chosen.contains($0.idKey) }
                .map { $0.name }
            if !names.isEmpty {
                parts.append(names.joined(separator: ", "))
            }
        }
        return parts.joined(separator: " · ")
    }
}
