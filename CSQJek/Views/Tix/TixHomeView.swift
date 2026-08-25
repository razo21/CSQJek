import SwiftUI
import ContentsquareSDK

// MARK: - CSQTix (ticketing marketplace) — Phase 1: buyer flow
//
// Browse → Event Detail → tier + quantity → Checkout → Confirmation.
// Screens: "Tix - Home", "Tix - Event Detail", "Tix - Checkout", "Tix - Order Confirmed".
// (Friction — waiting-room queue, service-fee drip pricing, sold-out rage — and the
// resale/seller flow come in later phases.)

private enum TixAccessID {
    static let close            = "tix_btn_close"
    static func categoryChip(_ c: String) -> String { "tix_chip_\(c)" }
    static func eventCard(_ key: String) -> String   { "tix_event_card_\(key)" }
    static func eventRow(_ key: String) -> String    { "tix_event_row_\(key)" }
    static let detailBack       = "tix_detail_btn_back"
    static func tier(_ key: String) -> String        { "tix_detail_tier_\(key)" }
    static let qtyMinus         = "tix_detail_btn_qty_minus"
    static let qtyPlus          = "tix_detail_btn_qty_plus"
    static let getTickets       = "tix_detail_btn_get_tickets"
    static let checkoutBack     = "tix_checkout_btn_back"
    static let placeOrder       = "tix_checkout_btn_place_order"
    static let confirmDone      = "tix_confirm_btn_done"
    static let resellEntry      = "tix_resell_entry_banner"
    static let resellBack       = "tix_resell_btn_back"
    static func seat(_ id: String) -> String { "tix_resell_seat_\(id)" }
    static let resellTryAgain   = "tix_resell_btn_try_again"
}

private let tixViolet = Color(hex: "#6D28D9")
private let tixPink   = Color(hex: "#DB2777")

// MARK: - Tix Home (browse)

struct TixHomeView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var marketConfig: MarketConfig
    @State private var selectedCategory: TixCategory? = nil   // nil = All

    private func t(_ en: String, _ jp: String) -> String { marketConfig.market == .tokyo ? jp : en }

    private var events: [TixEvent] { TixEvent.events(for: marketConfig.market) }
    private var filteredEvents: [TixEvent] {
        guard let cat = selectedCategory else { return events }
        return events.filter { $0.category == cat }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color.csqBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        categoryChips
                        resellBanner
                        if selectedCategory == nil { featuredSection }
                        sellingFastSection
                        allEventsSection
                        Spacer(minLength: 20)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
            }
            .safeAreaInset(edge: .top) { header }
            .navigationBarHidden(true)
            .onAppear { CSQ.trackScreenview("Tix - Home") }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button { isPresented = false } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 34, height: 34)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
            }
            .accessibilityIdentifier(TixAccessID.close)
            .accessibilityLabel(t("Close", "閉じる"))

            VStack(alignment: .leading, spacing: 1) {
                Text("CSQTix")
                    .font(.system(size: 19, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                Text(t("Live events near \(marketConfig.market.trackingLabel)", "\(marketConfig.market.trackingLabel)周辺のイベント"))
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.9))
            }
            Spacer()
            Image(systemName: "ticket.fill")
                .font(.system(size: 20))
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 14)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(colors: [tixViolet, tixPink], startPoint: .leading, endPoint: .trailing)
                .ignoresSafeArea(edges: .top)
        )
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(nil, label: t("All", "すべて"), icon: "square.grid.2x2.fill")
                ForEach(TixCategory.allCases) { cat in
                    chip(cat, label: cat.displayName(for: marketConfig.market), icon: cat.icon)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func chip(_ cat: TixCategory?, label: String, icon: String) -> some View {
        let selected = selectedCategory == cat
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) { selectedCategory = cat }
            CSQ.trackEvent("tix_category_selected", properties: [
                "category": cat?.rawValue ?? "all",
                "market":   marketConfig.market.trackingLabel
            ])
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 12, weight: .semibold))
                Text(label).font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(selected ? .white : .csqTextPrimary)
            .padding(.horizontal, 14).padding(.vertical, 9)
            .background(selected ? tixViolet : Color.csqSurface)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.csqBorder, lineWidth: selected ? 0 : 1))
        }
        .accessibilityIdentifier(TixAccessID.categoryChip(cat?.rawValue ?? "all"))
    }

    // Entry to the resale flow — its seat-selection step is a deliberate friction demo.
    private var resellBanner: some View {
        NavigationLink {
            TixResellSeatView(isPresented: $isPresented)
                .environmentObject(marketConfig)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "arrow.left.arrow.right.circle.fill")
                    .font(.system(size: 24)).foregroundColor(.white)
                VStack(alignment: .leading, spacing: 2) {
                    Text(t("Sell your tickets", "チケットを売る"))
                        .font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                    Text(t("List a seat on the CSQTix resale marketplace", "CSQTixリセールに座席を出品"))
                        .font(.system(size: 11)).foregroundColor(.white.opacity(0.9))
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
            }
            .padding(14)
            .background(LinearGradient(colors: [Color(hex: "#0F766E"), Color(hex: "#0E7490")],
                                       startPoint: .leading, endPoint: .trailing))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 16)
        }
        .accessibilityIdentifier(TixAccessID.resellEntry)
    }

    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle(t("Featured", "注目"))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(events.prefix(4)) { event in
                        NavigationLink {
                            TixEventDetailView(event: event, isPresented: $isPresented)
                                .environmentObject(marketConfig)
                        } label: {
                            TixFeaturedCard(event: event, market: marketConfig.market)
                        }
                        .simultaneousGesture(TapGesture().onEnded { fireEventTapped(event) })
                        .accessibilityIdentifier(TixAccessID.eventCard(event.idKey))
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private var sellingFastSection: some View {
        let hot = filteredEvents.filter { !$0.tags.isEmpty }
        return Group {
            if !hot.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    sectionTitle(t("Selling Fast", "売切間近"), icon: "flame.fill")
                    VStack(spacing: 10) {
                        ForEach(hot) { event in eventRow(event) }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }

    private var allEventsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle(selectedCategory?.displayName(for: marketConfig.market) ?? t("All Events", "すべてのイベント"))
            VStack(spacing: 10) {
                ForEach(filteredEvents) { event in eventRow(event) }
            }
            .padding(.horizontal, 16)
        }
    }

    private func eventRow(_ event: TixEvent) -> some View {
        NavigationLink {
            TixEventDetailView(event: event, isPresented: $isPresented)
                .environmentObject(marketConfig)
        } label: {
            TixEventRow(event: event, market: marketConfig.market)
        }
        .simultaneousGesture(TapGesture().onEnded { fireEventTapped(event) })
        .accessibilityIdentifier(TixAccessID.eventRow(event.idKey))
    }

    private func sectionTitle(_ text: String, icon: String? = nil) -> some View {
        HStack(spacing: 6) {
            Text(text).font(.system(size: 17, weight: .bold)).foregroundColor(.csqTextPrimary)
            if let icon { Image(systemName: icon).font(.system(size: 13)).foregroundColor(tixPink) }
        }
        .padding(.horizontal, 16)
    }

    private func fireEventTapped(_ event: TixEvent) {
        CSQ.trackEvent("tix_event_tapped", properties: [
            "event":    event.idKey,
            "category": event.category.rawValue,
            "market":   marketConfig.market.trackingLabel
        ])
    }
}

// MARK: - Cards

struct TixFeaturedCard: View {
    let event: TixEvent
    let market: Market

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                banner(height: 130)
                VStack(alignment: .leading, spacing: 3) {
                    if let tag = event.tags.first { tixTag(tag) }
                    Text(event.name)
                        .font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                        .lineLimit(2)
                }
                .padding(10)
            }
            .frame(width: 260, height: 130)
            .clipped()

            VStack(alignment: .leading, spacing: 4) {
                Label(event.dateLabel, systemImage: "calendar")
                    .font(.system(size: 11)).foregroundColor(.csqTextSecondary).lineLimit(1)
                Label(event.venue, systemImage: "mappin.and.ellipse")
                    .font(.system(size: 11)).foregroundColor(.csqTextSecondary).lineLimit(1)
                Text("\(fromLabel(market)) \(market.formatPrice(event.priceFrom))")
                    .font(.system(size: 13, weight: .bold)).foregroundColor(event.accent)
            }
            .padding(10)
            .frame(width: 260, alignment: .leading)
            .background(Color.csqSurface)
        }
        .frame(width: 260)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.csqBorder, lineWidth: 1))
    }

    private func banner(height: CGFloat) -> some View {
        ZStack {
            if !event.imageName.isEmpty, let ui = UIImage(named: event.imageName) {
                Image(uiImage: ui).resizable().scaledToFill()
            } else {
                LinearGradient(colors: [event.accent, event.accent.opacity(0.6)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                Image(systemName: event.category.icon)
                    .font(.system(size: 40)).foregroundColor(.white.opacity(0.25))
            }
            LinearGradient(colors: [.clear, .black.opacity(0.55)], startPoint: .center, endPoint: .bottom)
        }
        .frame(width: 260, height: height)
    }

    private func fromLabel(_ m: Market) -> String { m == .tokyo ? "〜" : "From" }
}

struct TixEventRow: View {
    let event: TixEvent
    let market: Market

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                if !event.imageName.isEmpty, let ui = UIImage(named: event.imageName) {
                    Image(uiImage: ui).resizable().scaledToFill()
                } else {
                    LinearGradient(colors: [event.accent, event.accent.opacity(0.6)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                    Image(systemName: event.category.icon).font(.system(size: 24)).foregroundColor(.white.opacity(0.85))
                }
            }
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 3) {
                Text(event.name).font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.csqTextPrimary).lineLimit(2)
                Text("\(event.dateLabel) · \(event.venue)")
                    .font(.system(size: 11)).foregroundColor(.csqTextSecondary).lineLimit(1)
                Text("\(market == .tokyo ? "〜" : "From") \(market.formatPrice(event.priceFrom))")
                    .font(.system(size: 12, weight: .bold)).foregroundColor(event.accent)
            }
            Spacer()
            if let tag = event.tags.first { tixTag(tag) }
            Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundColor(.csqTextTertiary)
        }
        .padding(10)
        .background(Color.csqSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.csqBorder, lineWidth: 1))
    }
}

private func tixTag(_ tag: String) -> some View {
    Text(tag)
        .font(.system(size: 10, weight: .bold))
        .foregroundColor(.white)
        .padding(.horizontal, 7).padding(.vertical, 3)
        .background(Color(hex: "#DC2626"))
        .clipShape(Capsule())
}

// MARK: - Event Detail

struct TixEventDetailView: View {
    let event: TixEvent
    @Binding var isPresented: Bool
    @EnvironmentObject var marketConfig: MarketConfig
    @Environment(\.dismiss) var dismiss

    @State private var selectedTierID: UUID?
    @State private var quantity = 1

    private func t(_ en: String, _ jp: String) -> String { marketConfig.market == .tokyo ? jp : en }

    private var selectedTier: TixTier? {
        event.tiers.first { $0.id == selectedTierID } ?? event.tiers.first { !$0.soldOut }
    }
    private var subtotal: Double { (selectedTier?.price ?? 0) * Double(quantity) }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.csqBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    hero
                    infoBlock.padding(.horizontal, 16)
                    tierSelector.padding(.horizontal, 16)
                    quantityBlock.padding(.horizontal, 16)
                    Spacer(minLength: 110)
                }
            }
            .ignoresSafeArea(edges: .top)

            getTicketsBar
        }
        .navigationBarHidden(true)
        .overlay(alignment: .topLeading) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold)).foregroundColor(Color(hex: "#1C1C2E"))
                    .frame(width: 36, height: 36).background(Circle().fill(Color.white))
                    .shadow(color: .black.opacity(0.18), radius: 4, x: 0, y: 2)
            }
            .accessibilityIdentifier(TixAccessID.detailBack)
            .padding(.leading, 16).padding(.top, 8)
        }
        .onAppear {
            if selectedTierID == nil { selectedTierID = event.tiers.first { !$0.soldOut }?.id }
            CSQ.trackScreenview("Tix - Event Detail")
            CSQ.trackEvent("tix_event_viewed", properties: [
                "event":      event.idKey,
                "performer":  event.performer,
                "category":   event.category.rawValue,
                "price_from": event.priceFrom,
                "market":     marketConfig.market.trackingLabel
            ])
        }
    }

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                if !event.imageName.isEmpty, let ui = UIImage(named: event.imageName) {
                    Image(uiImage: ui).resizable().scaledToFill()
                } else {
                    LinearGradient(colors: [event.accent, event.accent.opacity(0.55)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                    Image(systemName: event.category.icon).font(.system(size: 70)).foregroundColor(.white.opacity(0.22))
                }
            }
            .frame(height: 260).frame(maxWidth: .infinity).clipped()
            .overlay(LinearGradient(colors: [.clear, .black.opacity(0.7)], startPoint: .center, endPoint: .bottom))

            VStack(alignment: .leading, spacing: 6) {
                if let tag = event.tags.first { tixTag(tag) }
                Text(event.name).font(.system(size: 22, weight: .bold)).foregroundColor(.white)
                Text(event.performer).font(.system(size: 13, weight: .medium)).foregroundColor(.white.opacity(0.9))
            }
            .padding(16)
        }
        .frame(height: 260)
    }

    private var infoBlock: some View {
        VStack(spacing: 10) {
            infoRow("calendar", t("Date", "日付"), event.dateLabel)
            Divider()
            infoRow("mappin.and.ellipse", t("Venue", "会場"), "\(event.venue), \(event.city)")
        }
        .padding(16).background(Color.csqSurface).clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.csqBorder, lineWidth: 1))
    }

    private func infoRow(_ icon: String, _ label: String, _ value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 14)).foregroundColor(event.accent).frame(width: 24)
            Text(label).font(.system(size: 13)).foregroundColor(.csqTextSecondary)
            Spacer()
            Text(value).font(.system(size: 13, weight: .medium)).foregroundColor(.csqTextPrimary)
                .multilineTextAlignment(.trailing)
        }
    }

    private var tierSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(t("Choose your tickets", "チケットを選択"))
                .font(.system(size: 15, weight: .bold)).foregroundColor(.csqTextPrimary)
            ForEach(event.tiers) { tier in tierRow(tier) }
        }
    }

    private func tierRow(_ tier: TixTier) -> some View {
        let selected = selectedTier?.id == tier.id
        return Button {
            guard !tier.soldOut else { return }
            selectedTierID = tier.id
            CSQ.trackEvent("tix_tier_selected", properties: [
                "event":  event.idKey,
                "tier":   tier.idKey,
                "price":  tier.price,
                "market": marketConfig.market.trackingLabel
            ])
        } label: {
            HStack(spacing: 12) {
                Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 18)).foregroundColor(selected ? event.accent : Color(hex: "#C4C4C4"))
                VStack(alignment: .leading, spacing: 2) {
                    Text(tier.name).font(.system(size: 14, weight: .semibold))
                        .foregroundColor(tier.soldOut ? .csqTextTertiary : .csqTextPrimary)
                    Text(tier.soldOut ? t("Sold out", "完売") : tier.perks)
                        .font(.system(size: 11)).foregroundColor(tier.soldOut ? .csqError : .csqTextSecondary)
                }
                Spacer()
                Text(marketConfig.market.formatPrice(tier.price))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(tier.soldOut ? .csqTextTertiary : .csqTextPrimary)
            }
            .padding(12)
            .background(Color.csqSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12)
                .stroke(selected ? event.accent : Color.csqBorder, lineWidth: selected ? 1.5 : 1))
            .opacity(tier.soldOut ? 0.6 : 1)
        }
        .disabled(tier.soldOut)
        .accessibilityIdentifier(TixAccessID.tier(tier.idKey))
        .accessibilityLabel(tier.name)
    }

    private var quantityBlock: some View {
        HStack {
            Text(t("Quantity", "枚数")).font(.system(size: 15, weight: .bold)).foregroundColor(.csqTextPrimary)
            Spacer()
            HStack(spacing: 16) {
                Button { if quantity > 1 { quantity -= 1 } } label: {
                    Image(systemName: "minus").font(.system(size: 14, weight: .bold)).foregroundColor(event.accent)
                        .frame(width: 30, height: 30).background(Color.csqBackground).clipShape(Circle())
                }
                .accessibilityIdentifier(TixAccessID.qtyMinus)
                Text("\(quantity)").font(.system(size: 17, weight: .bold)).foregroundColor(.csqTextPrimary).frame(minWidth: 24)
                Button { if quantity < 8 { quantity += 1 } } label: {
                    Image(systemName: "plus").font(.system(size: 14, weight: .bold)).foregroundColor(event.accent)
                        .frame(width: 30, height: 30).background(Color.csqBackground).clipShape(Circle())
                }
                .accessibilityIdentifier(TixAccessID.qtyPlus)
            }
        }
        .padding(16).background(Color.csqSurface).clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.csqBorder, lineWidth: 1))
    }

    private var getTicketsBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(marketConfig.market.formatPrice(subtotal))
                        .font(.system(size: 22, weight: .bold, design: .rounded)).foregroundColor(event.accent)
                    Text("\(quantity) × \(selectedTier?.name ?? "")")
                        .font(.system(size: 11)).foregroundColor(.csqTextSecondary).lineLimit(1)
                }
                Spacer()
                NavigationLink {
                    TixCheckoutView(event: event, tier: selectedTier ?? event.tiers[0],
                                    quantity: quantity, isPresented: $isPresented)
                        .environmentObject(marketConfig)
                } label: {
                    Text(t("Get Tickets", "チケットを購入"))
                        .font(.system(size: 16, weight: .bold, design: .rounded)).foregroundColor(.white)
                        .padding(.horizontal, 30).padding(.vertical, 14)
                        .background(LinearGradient(colors: [tixViolet, tixPink], startPoint: .leading, endPoint: .trailing))
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.full))
                        .shadow(color: tixViolet.opacity(0.35), radius: 8, x: 0, y: 4)
                }
                .accessibilityIdentifier(TixAccessID.getTickets)
            }
            .padding(.horizontal, 20).padding(.vertical, 14).background(Color.csqSurface)
        }
    }
}

// MARK: - Checkout

struct TixCheckoutView: View {
    let event: TixEvent
    let tier: TixTier
    let quantity: Int
    @Binding var isPresented: Bool
    @EnvironmentObject var marketConfig: MarketConfig
    @Environment(\.dismiss) var dismiss

    @State private var showConfirm = false

    private func t(_ en: String, _ jp: String) -> String { marketConfig.market == .tokyo ? jp : en }
    private var total: Double { tier.price * Double(quantity) }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.csqBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    summaryCard
                    deliveryCard
                    paymentCard
                    Spacer(minLength: 110)
                }
                .padding(.horizontal, 16).padding(.top, 8)
            }

            payBar
        }
        .safeAreaInset(edge: .top) { header }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showConfirm) {
            TixConfirmedView(event: event, tier: tier, quantity: quantity, total: total, isPresented: $isPresented)
                .environmentObject(marketConfig)
        }
        .onAppear {
            CSQ.trackScreenview("Tix - Checkout")
            CSQ.trackEvent("tix_checkout_started", properties: [
                "event":    event.idKey,
                "tier":     tier.idKey,
                "quantity": quantity,
                "subtotal": total,
                "market":   marketConfig.market.trackingLabel
            ])
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left").font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                    .frame(width: 36, height: 36).background(Color.white.opacity(0.2)).clipShape(Circle())
            }
            .accessibilityIdentifier(TixAccessID.checkoutBack)
            Text(t("Checkout", "お会計")).font(.system(size: 17, weight: .bold)).foregroundColor(.white)
            Spacer()
        }
        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 14).frame(maxWidth: .infinity)
        .background(LinearGradient(colors: [tixViolet, tixPink], startPoint: .leading, endPoint: .trailing)
            .ignoresSafeArea(edges: .top))
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(t("Order summary", "注文内容")).font(.system(size: 14, weight: .bold)).foregroundColor(.csqTextPrimary)
            HStack(spacing: 12) {
                ZStack {
                    LinearGradient(colors: [event.accent, event.accent.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    Image(systemName: event.category.icon).font(.system(size: 18)).foregroundColor(.white.opacity(0.35))
                }
                .frame(width: 52, height: 52).clipShape(RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 2) {
                    Text(event.name).font(.system(size: 13, weight: .semibold)).foregroundColor(.csqTextPrimary).lineLimit(2)
                    Text("\(event.dateLabel)").font(.system(size: 11)).foregroundColor(.csqTextSecondary)
                }
                Spacer()
            }
            Divider()
            row(t("Ticket", "チケット"), tier.name)
            row(t("Quantity", "枚数"), "\(quantity)")
            row("\(marketConfig.market.formatPrice(tier.price)) × \(quantity)", marketConfig.market.formatPrice(total))
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.csqSurface).clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.csqBorder, lineWidth: 1))
    }

    private var deliveryCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "iphone").font(.system(size: 16)).foregroundColor(tixViolet).frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(t("Mobile Tickets", "モバイルチケット")).font(.system(size: 14, weight: .semibold)).foregroundColor(.csqTextPrimary)
                Text(t("Delivered to this device", "この端末に配信")).font(.system(size: 11)).foregroundColor(.csqTextSecondary)
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill").foregroundColor(.csqSuccess)
        }
        .padding(16).background(Color.csqSurface).clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.csqBorder, lineWidth: 1))
    }

    private var paymentCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "creditcard.fill").font(.system(size: 16)).foregroundColor(tixViolet).frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(t("Pay with", "お支払い")).font(.system(size: 12)).foregroundColor(.csqTextSecondary)
                Text("Visa •••• 4242").font(.system(size: 14, weight: .semibold)).foregroundColor(.csqTextPrimary)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundColor(.csqTextTertiary)
        }
        .padding(16).background(Color.csqSurface).clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.csqBorder, lineWidth: 1))
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.system(size: 13)).foregroundColor(.csqTextSecondary)
            Spacer()
            Text(value).font(.system(size: 13, weight: .medium)).foregroundColor(.csqTextPrimary)
        }
    }

    private var payBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(marketConfig.market.formatPrice(total)).font(.system(size: 22, weight: .bold, design: .rounded)).foregroundColor(tixViolet)
                    Text(t("Total", "合計")).font(.system(size: 11)).foregroundColor(.csqTextSecondary)
                }
                Spacer()
                Button {
                    CSQ.trackEvent("tix_order_completed", properties: [
                        "event":    event.idKey,
                        "tier":     tier.idKey,
                        "quantity": quantity,
                        "total":    total,
                        "market":   marketConfig.market.trackingLabel
                    ])
                    showConfirm = true
                } label: {
                    Text(t("Place Order", "注文を確定")).font(.system(size: 16, weight: .bold, design: .rounded)).foregroundColor(.white)
                        .padding(.horizontal, 30).padding(.vertical, 14)
                        .background(LinearGradient(colors: [tixViolet, tixPink], startPoint: .leading, endPoint: .trailing))
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.full))
                        .shadow(color: tixViolet.opacity(0.35), radius: 8, x: 0, y: 4)
                }
                .accessibilityIdentifier(TixAccessID.placeOrder)
            }
            .padding(.horizontal, 20).padding(.vertical, 14).background(Color.csqSurface)
        }
    }
}

// MARK: - Confirmation (QR ticket)

struct TixConfirmedView: View {
    let event: TixEvent
    let tier: TixTier
    let quantity: Int
    let total: Double
    @Binding var isPresented: Bool
    @EnvironmentObject var marketConfig: MarketConfig

    private func t(_ en: String, _ jp: String) -> String { marketConfig.market == .tokyo ? jp : en }

    var body: some View {
        ZStack {
            Color.csqBackground.ignoresSafeArea()
            VStack(spacing: 20) {
                Spacer()
                ZStack {
                    Circle().fill(Color.csqSuccess.opacity(0.15)).frame(width: 96, height: 96)
                    Image(systemName: "checkmark").font(.system(size: 42, weight: .bold)).foregroundColor(.csqSuccess)
                }
                VStack(spacing: 6) {
                    Text(t("You're going!", "チケット確保！")).font(.system(size: 22, weight: .bold)).foregroundColor(.csqTextPrimary)
                    Text(t("\(quantity) ticket(s) confirmed", "\(quantity)枚のチケットを確保しました")).font(.system(size: 14)).foregroundColor(.csqTextSecondary)
                }

                // Mobile ticket card
                VStack(spacing: 12) {
                    Text(event.name).font(.system(size: 15, weight: .bold)).foregroundColor(.csqTextPrimary)
                        .multilineTextAlignment(.center)
                    Text("\(event.dateLabel) · \(event.venue)").font(.system(size: 12)).foregroundColor(.csqTextSecondary)
                    Image(systemName: "qrcode").resizable().scaledToFit().frame(width: 150, height: 150).foregroundColor(.csqTextPrimary)
                    Text("\(tier.name) · ×\(quantity)").font(.system(size: 13, weight: .semibold)).foregroundColor(event.accent)
                    Text(marketConfig.market.formatPrice(total)).font(.system(size: 13)).foregroundColor(.csqTextSecondary)
                }
                .padding(20).background(Color.csqSurface).clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.csqBorder, lineWidth: 1))
                .padding(.horizontal, 32)

                Spacer()
                Button { isPresented = false } label: {
                    Text(t("Done", "完了")).font(.system(size: 16, weight: .bold, design: .rounded)).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(LinearGradient(colors: [tixViolet, tixPink], startPoint: .leading, endPoint: .trailing))
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.full))
                }
                .accessibilityIdentifier(TixAccessID.confirmDone)
                .padding(.horizontal, 24).padding(.bottom, 20)
            }
        }
        .onAppear { CSQ.trackScreenview("Tix - Order Confirmed") }
    }
}

// MARK: - Resale Seat Selection (⚠️ deliberate friction: 8s spinner → native 504 timeout)
//
// The seat-selection step of the resale flow is intentionally broken for the demo:
// tapping any seat shows a blocking "Verifying with the venue…" spinner that hangs
// for a full 8 seconds and then FAILS. The failure fires a real POST that returns
// 504 Gateway Timeout, so Contentsquare captures it as a NATIVE API error on the
// Session Replay timeline + Error Analysis (native iOS has no JavaScript errors —
// this is the equivalent). "Try Again" repeats the 8-second pain; repeated attempts
// also emit a rage signal. Screen: "Tix - Resell Seat Select".
struct TixResellSeatView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var marketConfig: MarketConfig
    @Environment(\.dismiss) var dismiss

    @State private var selectedSeat: String? = nil
    @State private var reserving = false
    @State private var failed = false
    @State private var attempts = 0
    @State private var seatRage = RageTapDetector()

    private func t(_ en: String, _ jp: String) -> String { marketConfig.market == .tokyo ? jp : en }
    private let teal = Color(hex: "#0F766E")

    private let rows = ["A", "B", "C", "D", "E", "F"]
    private let seatsPerRow = 10
    // Fixed "already taken" seats — deterministic so the map looks real and stable.
    private let taken: Set<String> = ["A3", "A4", "B7", "C2", "C3", "D9", "E5", "F1", "F2", "F8"]

    var body: some View {
        ZStack {
            Color.csqBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        instructions
                        stageBar
                        seatMap
                        legend
                        if failed, let seat = selectedSeat { errorCard(seat) }
                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
            }

            if reserving { reservingOverlay }
        }
        .navigationBarHidden(true)
        .onAppear { CSQ.trackScreenview("Tix - Resell Seat Select") }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left").font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                    .frame(width: 36, height: 36).background(Color.white.opacity(0.2)).clipShape(Circle())
            }
            .accessibilityIdentifier(TixAccessID.resellBack)
            VStack(alignment: .leading, spacing: 1) {
                Text(t("List a Ticket for Resale", "リセール出品")).font(.system(size: 17, weight: .bold)).foregroundColor(.white)
                Text(t("Select your seat", "座席を選択")).font(.system(size: 11)).foregroundColor(.white.opacity(0.9))
            }
            Spacer()
        }
        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 14).frame(maxWidth: .infinity)
        .background(LinearGradient(colors: [teal, Color(hex: "#0E7490")], startPoint: .leading, endPoint: .trailing)
            .ignoresSafeArea(edges: .top))
    }

    private var instructions: some View {
        Text(t("Tap the seat you want to list. We'll verify it with the venue before publishing.",
               "出品する座席をタップしてください。公開前に会場と照合します。"))
            .font(.system(size: 13)).foregroundColor(.csqTextSecondary)
    }

    private var stageBar: some View {
        Text(t("S T A G E", "ス テ ー ジ"))
            .font(.system(size: 12, weight: .bold)).foregroundColor(.csqTextSecondary)
            .frame(maxWidth: .infinity).padding(.vertical, 8)
            .background(Color.csqBorder.opacity(0.5)).clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var seatMap: some View {
        VStack(spacing: 8) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 6) {
                    Text(row).font(.system(size: 11, weight: .semibold)).foregroundColor(.csqTextTertiary).frame(width: 14)
                    ForEach(1...seatsPerRow, id: \.self) { num in
                        seatCell("\(row)\(num)")
                    }
                }
            }
        }
    }

    private func seatCell(_ id: String) -> some View {
        let isTaken = taken.contains(id)
        let isSelected = selectedSeat == id
        return Button {
            guard !isTaken, !reserving else { return }
            attemptReserve(id)
        } label: {
            RoundedRectangle(cornerRadius: 5)
                .fill(isTaken ? Color.csqBorder
                      : isSelected ? teal
                      : teal.opacity(0.12))
                .frame(height: 26)
                .overlay(
                    Image(systemName: isTaken ? "xmark" : "chair.fill")
                        .font(.system(size: 9))
                        .foregroundColor(isTaken ? .csqTextTertiary : isSelected ? .white : teal)
                )
        }
        .disabled(isTaken || reserving)
        .accessibilityIdentifier(TixAccessID.seat(id))
        .accessibilityLabel("Seat \(id)\(isTaken ? " taken" : "")")
    }

    private var legend: some View {
        HStack(spacing: 16) {
            legendItem(teal.opacity(0.12), t("Available", "空席"))
            legendItem(teal, t("Selected", "選択中"))
            legendItem(Color.csqBorder, t("Taken", "販売済"))
            Spacer()
        }
        .font(.system(size: 11)).foregroundColor(.csqTextSecondary)
    }

    private func legendItem(_ color: Color, _ label: String) -> some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 3).fill(color).frame(width: 14, height: 14)
            Text(label)
        }
    }

    private func errorCard(_ seat: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.octagon.fill").font(.system(size: 18)).foregroundColor(.csqError)
                VStack(alignment: .leading, spacing: 2) {
                    Text(t("Verification timed out", "照合がタイムアウトしました"))
                        .font(.system(size: 14, weight: .bold)).foregroundColor(.csqError)
                    Text(t("The venue didn't respond for seat \(seat). (Error CSQ-504)",
                           "座席\(seat)について会場から応答がありませんでした。（エラー CSQ-504）"))
                        .font(.system(size: 12)).foregroundColor(.csqTextSecondary)
                }
            }
            Button { attemptReserve(seat) } label: {
                Text(t("Try Again", "再試行"))
                    .font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                    .background(teal).clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .accessibilityIdentifier(TixAccessID.resellTryAgain)
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.csqError.opacity(0.08)).clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.csqError.opacity(0.3), lineWidth: 1))
    }

    private var reservingOverlay: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView().progressViewStyle(.circular).tint(.white).scaleEffect(1.6)
                Text(t("Verifying seat \(selectedSeat ?? "") with the venue…",
                       "座席\(selectedSeat ?? "")を会場と照合中…"))
                    .font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                Text(t("Please don't close the app", "アプリを閉じないでください"))
                    .font(.system(size: 11)).foregroundColor(.white.opacity(0.7))
            }
            .padding(28).background(Color.black.opacity(0.35)).clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .transition(.opacity)
    }

    // ⚠️ The deliberate 8-second hang + native 504 timeout.
    private func attemptReserve(_ seat: String) {
        selectedSeat = seat
        failed = false
        attempts += 1
        withAnimation { reserving = true }

        CSQ.trackEvent("tix_resale_seat_selected", properties: [
            "seat":    seat,
            "attempt": attempts,
            "market":  marketConfig.market.trackingLabel
        ])
        if let count = seatRage.registerTap() {
            CSQ.trackEvent("tix_resale_seat_rage", properties: [
                "tap_count": count,
                "seat":      seat,
                "market":    marketConfig.market.trackingLabel
            ])
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
            // Real failing request → native 504 error captured by CS (Error Analysis + replay).
            DemoErrorSimulator.requestFailure(
                status: 504, method: "POST", path: "/v1/resale/seat/hold",
                screen: "Tix - Resell Seat Select",
                market: marketConfig.market.trackingLabel
            )
            withAnimation { reserving = false }
            failed = true
        }
    }
}
