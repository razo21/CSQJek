import SwiftUI
import ContentsquareSDK

// MARK: - Market
// `Market` is now just a lightweight, CaseIterable identifier. ALL per-market
// behaviour (currency, labels, strings, content) lives in `MarketProfile` and is
// registered ONCE in `MarketRegistry.all`.
//
// ───────────────────────────────────────────────────────────────────────────
//  TO ADD A NEW MARKET (e.g. Hong Kong):
//    1. Add a case here (e.g. `case hongKong`).
//    2. Add ONE `MarketProfile(...)` entry to `MarketRegistry.all` below.
//    3. (Optional) add that market's data to the per-section dictionaries
//       (TelcoPlan.plansByMarket, Restaurant.byMarket, etc.). Any section you
//       skip falls back to Singapore automatically — nothing else to edit.
//  A new-LANGUAGE market additionally needs a new `AppStrings` conformer
//  (e.g. `ChineseHKStrings`) wired into its profile; user-facing text routes
//  through `marketConfig.strings`, never through `market == .x` checks.
// ───────────────────────────────────────────────────────────────────────────

enum Market: String, CaseIterable, Hashable {
    case singapore
    case tokyo
    case sydney

    // The single lookup. Everything below delegates here, so call sites such as
    // `market.formatPrice(...)`, `market.trackingLabel`, `market.currencyCode`
    // keep working unchanged.
    var profile: MarketProfile { MarketRegistry.profile(for: self) }

    var trackingLabel: String { profile.displayName }
    var currencyCode:  String { profile.currency.code }
    func formatPrice(_ price: Double) -> String { profile.currency.format(price) }
}

// MARK: - Currency
// Currency formatting is data, not a switch. Replicates the previous behaviour
// exactly: SGD/AUD → "S$x.xx" / "A$x.xx" (2dp, no grouping); JPY → "¥x,xxx" (0dp, grouped).

struct Currency {
    let code: String          // ISO 4217 — used for analytics ("SGD"/"JPY"/"AUD")
    let symbol: String        // "S$" / "¥" / "A$"
    let decimalPlaces: Int    // 2 for SGD/AUD, 0 for JPY
    let groupsThousands: Bool // JPY groups; SGD/AUD historically did not

    func format(_ value: Double) -> String {
        if decimalPlaces == 0 {
            let f = NumberFormatter()
            f.numberStyle           = .decimal
            f.groupingSeparator     = ","
            f.groupingSize          = groupsThousands ? 3 : 0
            f.usesGroupingSeparator = groupsThousands
            f.maximumFractionDigits = 0
            return symbol + (f.string(from: NSNumber(value: Int(value))) ?? "\(Int(value))")
        }
        return symbol + String(format: "%.\(decimalPlaces)f", value)
    }
}

// MARK: - MarketProfile
// One value carrying everything a market needs. Adding a market = adding one of these.

struct MarketProfile {
    let id:            Market
    let displayName:   String      // "Singapore" / "Tokyo" / "Sydney"  (also the analytics tracking label)
    let cityLabel:     String      // shown in the market picker card
    let languageLabel: String      // "English" / "日本語"
    let flagCode:      String      // "SG" / "JP" / "AU" — picker badge text (emoji flags don't render in Sim)
    let badgeColor:    Color       // picker badge colour
    let currency:      Currency
    let strings:       AppStrings
    let content:       MarketContent
}

// MARK: - MarketRegistry
// THE single place markets are declared. The picker iterates this; MarketConfig
// reads from it. Add a market here and it appears everywhere automatically.

enum MarketRegistry {
    static let all: [MarketProfile] = [
        MarketProfile(
            id: .singapore, displayName: "Singapore", cityLabel: "Singapore",
            languageLabel: "English", flagCode: "SG", badgeColor: Color(hex: "#EF4444"),
            currency: Currency(code: "SGD", symbol: "S$", decimalPlaces: 2, groupsThousands: false),
            strings: EnglishStrings(region: .singapore), content: .singapore
        ),
        MarketProfile(
            id: .tokyo, displayName: "Tokyo", cityLabel: "東京 / Tokyo",
            languageLabel: "日本語", flagCode: "JP", badgeColor: Color(hex: "#BC002D"),
            currency: Currency(code: "JPY", symbol: "¥", decimalPlaces: 0, groupsThousands: true),
            strings: JapaneseStrings(), content: .tokyo
        ),
        MarketProfile(
            id: .sydney, displayName: "Sydney", cityLabel: "Sydney",
            languageLabel: "English", flagCode: "AU", badgeColor: Color(hex: "#00843D"),
            currency: Currency(code: "AUD", symbol: "A$", decimalPlaces: 2, groupsThousands: false),
            strings: EnglishStrings(region: .sydney), content: .sydney
        ),
    ]

    // Fallback to the first registered market (Singapore) if a profile is ever missing.
    static func profile(for market: Market) -> MarketProfile {
        all.first { $0.id == market } ?? all[0]
    }
}

// MARK: - AppStrings Protocol
// Every user-visible string in the Home + Ride modules is declared here.
// Add a new conforming struct for each new market language.

protocol AppStrings {
    // Splash
    var splashTagline:   String { get }
    var splashTapPrompt: String { get }

    // Tab bar
    var tabHome:    String { get }
    var tabRides:   String { get }
    var tabMobile:  String { get }
    var tabFood:    String { get }
    var tabProfile: String { get }

    // Home — header
    var homeLocationLabel:     String { get }
    var homeWeather:           String { get }
    var homeUserDisplayName:   String { get }   // "Jeff" / "沖本"
    var homeUserAvatarInitials:String { get }   // "JL" / "沖"
    func homeGreeting(name: String, hour: Int) -> String

    // Home — search
    var homeSearchPlaceholder: String { get }

    // Home — section headers
    var homeSectionServices:       String { get }
    var homeSectionFavourites:     String { get }
    var homeFavouritesSubtitle:    String { get }
    var homeSectionDeals:          String { get }
    var homeSectionQuickActions:   String { get }
    var homeSectionRecentActivity: String { get }
    var homeSectionSafety:         String { get }
    var homeSectionSeeAll:         String { get }

    // Home — rewards card
    var homeRewardsName:      String { get }
    var homeRewardsProgress:  String { get }
    var homeRewardsTierGold:  String { get }
    var homeRewardsPtsLabel:  String { get }   // "pts" / "pt"

    // Home — quick actions
    var homeQuickBookRide:     String { get }
    var homeQuickBookRideSub:  String { get }
    var homeQuickSchedule:     String { get }
    var homeQuickScheduleSub:  String { get }
    var homeQuickSendMoney:    String { get }
    var homeQuickSendMoneySub: String { get }
    var homeQuickScanPay:      String { get }
    var homeQuickScanPaySub:   String { get }

    // Home — safety
    var homeSafetySOSTitle:     String { get }
    var homeSafetySOSSub:       String { get }
    var homeSafetyShareTitle:   String { get }
    var homeSafetyShareSub:     String { get }

    // Home — misc
    var homePromoClaimOffer:   String { get }
    var homeEatsDeliveryFree:  String { get }
    var homeChangeLabel:       String { get }
    var homeServicesSoonBadge: String { get }

    // Home — service tile display names (routing keys stay English in HomeView)
    func homeServiceDisplayName(_ key: String) -> String

    // Rides — destination screen
    var rideBookTitle:       String { get }
    var rideSavedAndRecent:  String { get }
    var rideSuggestions:     String { get }
    var rideCurrentLocation: String { get }
    var rideChangeLabel:     String { get }

    // Rides — pickup screen
    var rideSetPickupTitle: String { get }
    var rideGoingTo:        String { get }
    var ridePickupPoint:    String { get }
    var rideDragHint:       String { get }
    var rideConfirmPickup:  String { get }

    // Rides — confirm screen
    var rideChooseTitle:  String { get }
    var rideRouteInfo:    String { get }
    var rideTotalLabel:   String { get }
    var rideEstFare:      String { get }
    var rideBookButton:   String { get }
    var rideFindingDriver: String { get }

    // Rides — payment
    var ridePaymentMethodTitle: String { get }
    var rideAddPromo:           String { get }

    // Rides — promo sheet
    var rideEnterPromoTitle:   String { get }
    var ridePromoPlaceholder:  String { get }
    var rideApply:             String { get }

    // Rides — booked sheet
    var rideDriverFound: String { get }
    func rideDriverETA(rideName: String, eta: Int) -> String
    var rideArrivingIn:    String { get }
    var rideEstimatedFare: String { get }
    var rideCancelRide:    String { get }

    // Rides — active banner (Rides tab)
    var rideActiveBannerTitle: String { get }
    var rideActiveBannerSub:   String { get }

    // Rides tab
    var rideTabTitle:    String { get }
    var rideRecentTitle: String { get }
    var ridePromoHeadline: String { get }
    var ridePromoSub:      String { get }
    var ridePromoClaim:    String { get }

    // Ride option card
    func rideOptionMeta(eta: Int, capacity: Int) -> String
    func rideOptionHorseMeta(eta: Int) -> String   // horse capacity label: "25 min · 1 saddle" / "25分 · 1鞍"

    // Ride ETA chip and LIVE badge in driver approach map
    func rideETAChip(eta: Int) -> String            // "4 min away" / "4分後"
    var rideLiveLabel: String { get }               // "LIVE" / "ライブ"

    // Default pickup address for this market
    var rideDefaultPickupAddress: String { get }

    // Profile
    var profileTitle:           String { get }
    var profileRating:          String { get }
    var profileRidesCount:      String { get }
    var profileSaved:           String { get }
    var profileSectionAccount:  String { get }
    var profilePersonalInfo:    String { get }
    var profilePaymentMethods:  String { get }
    var profileSavedAddresses:  String { get }
    var profileSectionRidePrefs:  String { get }
    var profileDefaultRideType:   String { get }
    var profileMusicPrefs:        String { get }
    var profileMyReviews:         String { get }
    var profileSectionSupport:    String { get }
    var profileNotifications:     String { get }
    var profilePrivacySecurity:   String { get }
    var profileHelpSupport:       String { get }
    var profileSignOut:           String { get }

    // Shared statuses
    var statusCompleted: String { get }
    var statusCancelled: String { get }
    var statusDelivered: String { get }

    // Air
    var airHeroTitle:        String { get }
    var airHeroSubtitle:     String { get }
    var airFromLabel:        String { get }
    var airToLabel:          String { get }
    var airSelectDest:       String { get }
    var airPopularFromTitle: String { get }
    var airSearchFlights:    String { get }
    var airOneWayLabel:      String { get }
    var airRoundTripLabel:   String { get }
    var airDepartLabel:      String { get }
    var airReturnLabel:      String { get }
    func airPassengerLabel(_ count: Int) -> String

    // Food
    var foodTitle:               String { get }
    var foodDeliverySubtitle:    String { get }
    var foodLocationLabel:       String { get }
    var foodSearchPlaceholder:   String { get }
    var foodFeaturedSection:     String { get }
    var foodHawkerPicksSection:  String { get }
    var foodFreeDeliverySection: String { get }
    var foodAllRestaurants:      String { get }
    var foodSeeAll:              String { get }

    // Mart
    var martDeliverTo:          String { get }
    var martSearchPlaceholder:  String { get }
    var martCategorySection:    String { get }
    var martButcherSection:     String { get }
    var martFlashDeals:         String { get }
    var martFlashDealsTimer:    String { get }
    var martFeaturedItems:      String { get }
    var martViewCart:           String { get }
    var martViewAllCuts:        String { get }
    var martSeeAll:             String { get }
    var martChips:              [String] { get }
    var martMeatSubcategories:  [String] { get }

    // Telco
    var telcoHeroTitle:       String { get }
    var telcoHeroSubtitle:    String { get }
    var telcoTopUpChip:       String { get }
    var telcoDataAddOnChip:   String { get }
    var telcoRoamChip:        String { get }
    var telcoCurrentPlan:     String { get }
    var telcoRenewsIn:        String { get }
    var telcoRemainingLabel:  String { get }
    var telcoUsedLabel:       String { get }
    var telcoTotalLabel:      String { get }
    var telcoLatestDevices:   String { get }
    var telcoRoamingAddons:   String { get }
    var telcoRunningLow:      String { get }
    var telcoDialRemaining:   String { get }   // centre dial "remaining" / "残り"
    var telcoDialOf:          String { get }   // centre dial "of X GB" prefix
    var telcoSelectPlan:      String { get }
    var telcoPricePerMonth:   String { get }   // "/mo" / "/月"
    var telcoFromPrice:       String { get }   // "From " / "月額"

    // Telco — Top-Up Sheet
    var telcoTopUpTitle:        String { get }
    var telcoTopUpCurrentBal:   String { get }   // "Current Balance"
    var telcoTopUpSelectAmt:    String { get }   // "Select top-up amount"
    var telcoTopUpDone:         String { get }
    var telcoTopUpToppedUp:     String { get }   // "Topped up!"
    func telcoTopUpButton(_ amount: String) -> String  // "Top Up S$X"

    // Telco — Roaming Sheet
    var telcoRoamingTitle:      String { get }
    var telcoRoamingOff:        String { get }   // "Roaming is OFF"
    var telcoRoamingTip:        String { get }   // tap a day pass below...
    var telcoDayPassesTitle:    String { get }   // "Day Passes"
    var telcoAddButton:         String { get }   // "Add"
    var telcoDone:              String { get }

    // Telco — Data Add-On Sheet
    var telcoDataAddOnTitle:    String { get }
    var telcoChooseDataPack:    String { get }   // "Choose a Data Pack"
    var telcoDataAddedButton:   String { get }   // "Added"
    func telcoDataPrice(_ price: String) -> String   // "S$X"
    func telcoConfirmAddOns(_ count: Int) -> String  // "Confirm X add-on(s)"

    // Profile
    var profileUserName:  String { get }
    var profileUserEmail: String { get }

    // Cash
    var cashAccountLabel:     String { get }   // "jeff.lin · SG" / "jeff.lin · JP"
    var cashAvailableBalance: String { get }
    var cashCurrencyPrefix:   String { get }   // "S$" / "¥"
    var cashMoneyIn:          String { get }
    var cashMoneyOut:         String { get }
    var cashScanQR:           String { get }
    var cashSendMoney:        String { get }
    var cashAddFunds:         String { get }
    var cashWithdraw:         String { get }
    var cashRecent:           String { get }
    var cashSeeAll:           String { get }
    var cashTransactions:     String { get }
    var cashThisMonth:        String { get }
    var cashViewAllTx:        String { get }
    var cashNewContact:       String { get }
    var cashTxQRPayment:      String { get }
    var cashTxSent:           String { get }
    var cashTxReceived:       String { get }
    var cashTxTopUp:          String { get }
    var cashTxWithdrawal:     String { get }
    var cashTxInternational:  String { get }

    // Cash — All Transactions sheet
    var cashAllTransactionsTitle: String { get }
    var cashNoTransactions:       String { get }
    var cashSearchTransactions:   String { get }
    func cashTxCount(_ count: Int) -> String
    var cashFilterAll: String { get }
    var cashFilterIn:  String { get }
    var cashFilterOut: String { get }

    // Air — Results
    var airSortCheapest:          String { get }
    var airSortFastest:           String { get }
    var airSortBest:              String { get }
    var airFilterNonStop:         String { get }
    var airFilterUnder10h:        String { get }
    var airFilterRefundable:      String { get }
    var airFilterMorning:         String { get }
    var airFilterEvening:         String { get }
    func airFlightsFound(_ count: Int) -> String
    var airPricesPerPerson:       String { get }   // "Prices per person · SGD" / "一人当たりの価格 · JPY"
    var airNoFlightsMatch:        String { get }
    var airClearFilters:          String { get }
    var airSelectButton:          String { get }
    var airPax:                   String { get }   // "pax" / "名"
    var airRemoveFiltersHint:     String { get }

    // Air — Detail
    var airFlightDetails:         String { get }
    var airLayoverIn:             String { get }   // prefix: "Layover in X"
    var airDirect:                String { get }
    var airChooseYourFare:        String { get }
    var airWhatsIncluded:         String { get }
    var airFareIncluded:          String { get }   // "Included" (fare price add == 0)
    var airBaggageLabel:          String { get }
    var airChangesLabel:          String { get }
    var airRefundLabel:           String { get }
    var airMealsLabel:            String { get }
    var airSeatSelectionLabel:    String { get }
    var airMilesEarnedLabel:      String { get }
    var airOfBaseMiles:           String { get }   // "of base miles" suffix
    var airPriceBreakdown:        String { get }
    var airBaseFare:              String { get }
    var airUpgrade:               String { get }   // "X Upgrade"
    var airTaxesAndFees:          String { get }
    var airServiceFee:            String { get }
    var airBookNow:               String { get }
    func airForPassengers(_ count: Int) -> String  // "for N passengers"
    var airPerPerson:             String { get }   // "per person"
    func airPerPersonTotal(_ currency: String, _ total: Int) -> String  // "per person · S$N total"

    // Air — Fare options (display names)
    var airFareLite:              String { get }
    var airFareValue:             String { get }
    var airFareFlex:              String { get }
    // Fare baggage
    var airBaggageLite:           String { get }
    var airBaggageValue:          String { get }
    var airBaggageFlex:           String { get }
    // Fare change fee
    var airChangeLite:            String { get }
    var airChangeValue:           String { get }
    var airChangeFlex:            String { get }
    // Fare refund
    var airRefundLite:            String { get }
    var airRefundValue:           String { get }
    var airRefundFlex:            String { get }
    // Fare meal
    var airMealLite:              String { get }
    var airMealValue:             String { get }
    var airMealFlex:              String { get }
    // Fare seat selection
    var airSeatLite:              String { get }
    var airSeatValue:             String { get }
    var airSeatFlex:              String { get }

    // Air — Booking Confirmation
    var airBookingConfirmed:      String { get }
    func airTicketSentTo(_ email: String) -> String
    var airBookingRef:            String { get }
    var airPassengerLabel2:       String { get }   // "Passenger" (boarding pass)
    var airPassengerName:         String { get }   // "Jeff Lin" / "沖本 篤史"
    var airAdultEconomy:          String { get }   // "Adult · Economy"
    var airSeatLabel:             String { get }   // "Seat" (boarding pass)
    var airSeatWindow:            String { get }   // "Window"
    var airBaggageLabel2:         String { get }   // "Baggage" (boarding pass)
    var airCheckedLabel:          String { get }   // "Checked"
    var airETicketButton:         String { get }   // "E-Ticket"
    var airAddToCalButton:        String { get }   // "Add to Cal"
    var airShareButton:           String { get }   // "Share"
    var airBackToAir:             String { get }   // "Back to CSQAir"
    var airPaxLabel:              String { get }   // "pax" in info chip

    // Telco — Plan Detail
    var telcoBackButton:          String { get }   // "Back"
    var telcoDataAllowance:       String { get }   // "Data Allowance"
    var telcoEverythingInPlan:    String { get }   // "Everything in this plan"
    var telcoCompareOtherPlans:   String { get }   // "Compare with other plans"
    var telcoPortInTitle:         String { get }   // "Switch from Starhub..."
    var telcoPortInBody:          String { get }
    var telcoPortInNow:           String { get }   // "Port In Now"
    var telcoFAQTitle:            String { get }   // "Frequently Asked Questions"
    var telcoFAQ1Q:               String { get }
    var telcoFAQ1A:               String { get }
    var telcoFAQ2Q:               String { get }
    var telcoFAQ2A:               String { get }
    var telcoFAQ3Q:               String { get }
    var telcoFAQ3A:               String { get }
    var telcoFAQ4Q:               String { get }
    var telcoFAQ4A:               String { get }
    var telcoPerMonth:            String { get }   // "/month" (CTA bar)
    func telcoSignUpFor(_ name: String) -> String  // "Sign Up for X"
    var telcoViewDetails:         String { get }   // "View Details"

    // Telco — Purchase Funnel (device detail + financing)
    var telcoColorLabel:        String { get }
    var telcoStorageLabel:      String { get }
    var telcoContinue:          String { get }
    var telcoFinancingTitle:    String { get }
    var telcoInstallmentLabel:  String { get }
    var telcoInstallmentSub:    String { get }
    var telcoOutrightLabel:     String { get }
    var telcoOutrightSub:       String { get }
    var telcoAttachPlanTitle:   String { get }
    var telcoContinueCheckout:  String { get }
    var telcoDueToday:          String { get }
    var telcoMonthlyLabel:      String { get }

    // Telco — Plan Signup
    var telcoSignupTitle:       String { get }
    var telcoSimTypeTitle:      String { get }
    var telcoESIMLabel:         String { get }
    var telcoESIMSub:           String { get }
    var telcoPhysicalSIMLabel:  String { get }
    var telcoPhysicalSIMSub:    String { get }
    var telcoNumberTitle:       String { get }
    var telcoNewNumberLabel:    String { get }
    var telcoNewNumberSub:      String { get }
    var telcoKeepNumberLabel:   String { get }
    var telcoKeepNumberSub:     String { get }

    // Telco — Checkout
    var telcoCheckoutTitle:     String { get }
    var telcoOrderSummary:      String { get }
    var telcoFulfillmentTitle:  String { get }
    var telcoFulfillmentESIM:   String { get }
    var telcoFulfillmentDelivery: String { get }
    var telcoFulfillmentPickup: String { get }
    var telcoYourDetailsTitle:  String { get }
    var telcoFieldName:         String { get }
    var telcoFieldID:           String { get }   // market-specific (NRIC / Medicare / マイナンバー)
    var telcoFieldEmail:        String { get }
    var telcoFieldAddress:      String { get }
    var telcoPaymentTitle:      String { get }
    var telcoPayCard:           String { get }
    var telcoPayWallet:         String { get }   // PayNow / PayPay / PayID
    var telcoFieldCardNumber:   String { get }
    var telcoContinueVerify:    String { get }

    // Telco — Credit / ID Check (drop-off step)
    var telcoCreditTitle:       String { get }
    var telcoCreditBody:        String { get }
    var telcoCreditConsent:     String { get }
    var telcoRunCheck:          String { get }
    var telcoChecking:          String { get }
    var telcoCreditApproved:    String { get }
    var telcoCreditApprovedSub: String { get }
    var telcoPlaceOrder:        String { get }

    // Telco — Order Confirmed
    var telcoOrderConfirmedTitle: String { get }
    var telcoOrderConfirmedSub:   String { get }
    var telcoESIMReady:           String { get }
    var telcoScanToActivate:      String { get }
    var telcoOrderNumberLabel:    String { get }
    var telcoBackToMobile:        String { get }
    var telcoCreditDeclined:      String { get }
    var telcoCreditDeclinedSub:   String { get }
    var telcoSwitchOutright:      String { get }

    // Grocery — Cart
    var cartExpressDelivery:      String { get }   // "Express delivery · Ready in 45 minutes"
    var cartEnterPromo:           String { get }   // "Enter promo code"
    var cartApply:                String { get }   // "Apply"
    var cartInvalidPromo:         String { get }
    var cartOrderSummary:         String { get }
    var cartDeliveryFee:          String { get }
    var cartServiceFee:           String { get }
    var cartPromoDiscount:        String { get }
    var cartTotal:                String { get }
    var cartProceedCheckout:      String { get }
    func cartSubtotal(_ count: Int) -> String       // "Subtotal (N items)"
    var cartEach:                 String { get }    // "each" in per-item price
    var cartNavTitle:             String { get }    // "My Cart"
    var cartClearButton:          String { get }
    var cartEmptyTitle:           String { get }
    var cartEmptySubtitle:        String { get }
    var cartStartShopping:        String { get }

    // Grocery — Checkout
    var checkoutTitle:            String { get }
    var checkoutDeliveryAddress:  String { get }
    var checkoutHome:             String { get }
    var checkoutHomeAddress:      String { get }   // market-specific address
    var checkoutChange:           String { get }
    var checkoutLeaveAtDoor:      String { get }
    var checkoutAddInstructions:  String { get }
    var checkoutDeliverySlot:     String { get }
    var checkoutPayment:          String { get }
    var checkoutPlacingOrder:     String { get }
    var checkoutPlaceOrder:       String { get }   // prefix before price

    // Grocery — Order Confirmation
    var orderPlaced:              String { get }
    var orderGroceriesPrepared:   String { get }
    var orderNumber:              String { get }   // "Order #"
    var orderEstimatedArrival:    String { get }
    var orderProgress:            String { get }
    var orderStepConfirmed:       String { get }
    var orderStepPacked:          String { get }
    var orderStepOutForDelivery:  String { get }
    var orderStepDelivered:       String { get }
    var orderInProgress:          String { get }
    var orderCompleted:           String { get }   // step completed text
    var orderDeliveryPartner:     String { get }
    var orderDeliveryInfo:        String { get }   // delivery stats text
    var orderTrackLiveMap:        String { get }
    var orderReorder:             String { get }
    var orderShare:               String { get }
    var riderFindingPartner:      String { get }   // "Finding your delivery partner"
    var riderFindingSubtitle:     String { get }   // "We're matching you with a nearby rider..."
    var riderCancelOrder:         String { get }
    var riderEstimatedArrival:    String { get }   // same as orderEstimatedArrival but for rider view
    var riderLiveBadge:           String { get }   // "Live"
    var riderSafetyTools:         String { get }   // "Safety Tools"

    // Grocery — Product Detail
    var productInStock:           String { get }
    var productOutOfStock:        String { get }
    var productDescriptionTab:    String { get }
    var productNutritionTab:      String { get }
    var productReviewsTab:        String { get }
    var productQuantity:          String { get }
    var productTotal:             String { get }
    var productAddToCart:         String { get }   // "Add to Cart — $X"
    var productAddedToCart:       String { get }   // "Added to Cart!"
    var productNutritionTitle:    String { get }
    var productServingSize:       String { get }   // "Per serving (100g)"
    var productReviewsCount:      String { get }   // "reviews"

    // Grocery — Meat Category
    var meatFreshDaily:           String { get }
    var meatButcherTitle:         String { get }
    var meatSubtitle:             String { get }
    var meatItemsCount:           String { get }   // "N items" — suffix
    var meatEmptyState:           String { get }
    var meatButcherTipTitle:      String { get }
    var meatButcherTipBody:       String { get }
    var meatViewCart:             String { get }
    var meatSortFeatured:         String { get }
    var meatSortPriceLow:         String { get }
    var meatSortPriceHigh:        String { get }
    var meatSortTopRated:         String { get }

    // Food — Restaurant Detail / Order
    var foodAddItemsToStart:      String { get }
    var foodViewCart:             String { get }
    func foodItemsTotal(_ count: Int, _ currency: String, _ amount: String) -> String
    var foodYourOrder:            String { get }
    var foodOrderSummary:         String { get }
    var foodDeliveryAddress:      String { get }
    var foodHomeAddress:          String { get }   // market-specific
    var foodChange:               String { get }
    var foodPayment:              String { get }
    var foodPromoCode:            String { get }
    var foodAddPromoCode:         String { get }
    var foodEnterCode:            String { get }
    var foodApply:                String { get }
    var foodYouMightLike:         String { get }
    var foodSubtotal:             String { get }
    var foodDeliveryFee:          String { get }
    var foodFree:                 String { get }
    var foodPlatformFee:          String { get }
    var foodTotal:                String { get }
    var foodPlacingOrder:         String { get }
    var foodPlaceOrder:           String { get }
    var foodSomethingWentWrong:   String { get }
    // Food — Order Confirmed
    var foodOrderConfirmedTitle:  String { get }
    func foodOrderFromRestaurant(_ name: String) -> String
    var foodEstimatedArrival:     String { get }
    var foodOrderTotal:           String { get }
    var foodLiveTracking:         String { get }
    var foodStepReceived:         String { get }
    var foodStepPreparing:        String { get }
    var foodStepOnTheWay:         String { get }
    var foodStepDelivered:        String { get }
    var foodDeliveryNote:         String { get }
    var foodTrackMyOrder:         String { get }
    var foodBackToFood:           String { get }
    var foodOrderConfirmed:       String { get }   // nav title

    // Cash — Send Money
    var cashSendMoneyTitle:       String { get }
    var cashCancelButton:         String { get }
    var cashTabContacts:          String { get }
    var cashTabTransfer:          String { get }
    var cashTabOverseas:          String { get }
    var cashAvailablePrefix:      String { get }   // "Available: "
    var cashSendVia:              String { get }
    var cashPhoneLabel:           String { get }
    var cashEmailLabel:           String { get }
    var cashBankAcctLabel:        String { get }
    var cashPhoneNumber:          String { get }
    var cashEmailAddress:         String { get }
    var cashBankAccountNo:        String { get }
    var cashPhonePlaceholder:     String { get }
    var cashBankAcctPlaceholder:  String { get }
    var cashAddNote:              String { get }
    var cashSendMoneyButton:      String { get }
    var cashSendInternational:    String { get }
    var cashDestCountry:          String { get }
    var cashRecipientDetails:     String { get }
    var cashTransferDetails:      String { get }
    var cashAmountIn:             String { get }   // "Amount in SGD" / "金額（SGD）"
    var cashTransferPurpose:      String { get }
    var cashYouSend:              String { get }
    var cashTransferFee:          String { get }
    var cashTotalDeducted:        String { get }
    var cashExchangeRate:         String { get }
    var cashRecipientGets:        String { get }
    var cashSelectCountry:        String { get }
    var cashDoneButton:           String { get }
    var cashLastAmount:           String { get }   // "Last: "
    var cashBalanceAfter:         String { get }   // "Balance after: "
    var cashConfirmSend:          String { get }
    var cashInternationalTransfer: String { get }
    var cashSendMoneyConfirmTitle: String { get }  // "Send Money" in confirm sheet
    // Cash — Add/Withdraw
    var cashAddFundsTitle:        String { get }
    var cashWithdrawTitle:        String { get }
    var cashAddFundsHeader:       String { get }
    var cashWithdrawHeader:       String { get }
    var cashInstantFromBank:      String { get }
    var cashTransferToBank:       String { get }
    var cashWalletBalance:        String { get }
    var cashAfterAdding:          String { get }
    var cashAfterWithdrawal:      String { get }
    var cashSelectAmount:         String { get }
    var cashCustomAmount:         String { get }
    var cashFromAccount:          String { get }
    var cashToAccountLabel:       String { get }
    var cashInstantProcessing:    String { get }
    var cashNoFees:               String { get }
    var cashInsufficientBalance:  String { get }
    var cashConfirmTopUp:         String { get }
    var cashConfirmWithdrawal:    String { get }
    var cashConfirmButton:        String { get }
    func cashAddAmount(_ amount: String) -> String
    func cashWithdrawAmount(_ amount: String) -> String
    func cashFromAccount2(_ bank: String) -> String  // "From BankName ••1234"
    func cashToAccount2(_ bank: String) -> String    // "To BankName ••1234"
    // Cash — QR Scanner
    var cashScanToPayTitle:       String { get }
    var cashPointCamera:          String { get }
    var cashQRSupports:           String { get }
    var cashDemoScan:             String { get }
    var cashCameraDenied:         String { get }
    var cashCancelPayment:        String { get }
    var cashBalanceAfterPayment:  String { get }   // "Balance after: "
    func cashPayAmount(_ amount: String) -> String
}

// MARK: - English (Singapore)

struct EnglishStrings: AppStrings {
    // English is shared by the Singapore and Sydney markets. `region` lets the
    // handful of place/currency-specific strings switch to Australian values
    // without duplicating the entire struct. Defaults to Singapore.
    var region: Market = .singapore
    private var isAU: Bool { region == .sydney }

    // Splash
    var splashTagline:   String { "Your city, at your fingertips" }
    var splashTapPrompt: String { "Tap anywhere to begin" }

    // Tabs
    var tabHome:    String { "Home" }
    var tabRides:   String { "Rides" }
    var tabMobile:  String { "Mobile" }
    var tabFood:    String { "Food" }
    var tabProfile: String { "Profile" }

    // Home header
    var homeLocationLabel:      String { isAU ? "Sydney CBD" : "Singapore CBD" }
    var homeWeather:            String { isAU ? "23°C · Sunny · Light breeze" : "33°C · Sunny · High humidity" }
    var homeUserDisplayName:    String { "Jeff" }
    var homeUserAvatarInitials: String { "JL" }
    func homeGreeting(name: String, hour: Int) -> String {
        if isAU {
            // Australian English — casual, culturally aware ("arvo", "G'day").
            switch hour {
            case 5..<12:  return "Morning, \(name)"
            case 12..<14: return "Lunchtime, \(name)!"
            case 14..<18: return "Good arvo, \(name)"
            case 18..<21: return "Evening, \(name)!"
            default:      return "Still up, \(name)?"
            }
        }
        switch hour {
        case 5..<12:  return "Selamat pagi, \(name)"
        case 12..<14: return "Eh, lunch time, \(name)!"
        case 14..<18: return "Good afternoon, \(name)"
        case 18..<21: return "Eh, dinner lah, \(name)!"
        default:      return "Wah, still awake, \(name)?"
        }
    }

    // Home search + sections
    var homeSearchPlaceholder:     String { "Where to?" }
    var homeSectionServices:       String { "Services" }
    var homeSectionFavourites:     String { isAU ? "Local Faves" : "Hawker Favourites" }
    var homeFavouritesSubtitle:    String { isAU ? "Delivered to Sydney CBD" : "Delivered to Singapore CBD" }
    var homeSectionDeals:          String { "Deals for You" }
    var homeSectionQuickActions:   String { "Quick Actions" }
    var homeSectionRecentActivity: String { "Recent Activity" }
    var homeSectionSafety:         String { "Safety" }
    var homeSectionSeeAll:         String { "See all" }

    // Rewards
    var homeRewardsName:     String { "CSQRewards" }
    var homeRewardsProgress: String { "160 pts to your next reward" }
    var homeRewardsTierGold: String { "GOLD" }
    var homeRewardsPtsLabel: String { "pts" }

    // Quick actions
    var homeQuickBookRide:     String { "Book a Ride" }
    var homeQuickBookRideSub:  String { "Driver 2 min away" }
    var homeQuickSchedule:     String { "Schedule Ride" }
    var homeQuickScheduleSub:  String { "Plan ahead" }
    var homeQuickSendMoney:    String { "Send Money" }
    var homeQuickSendMoneySub: String { "CSQPay" }
    var homeQuickScanPay:      String { "Scan & Pay" }
    var homeQuickScanPaySub:   String { "QR payments" }

    // Safety
    var homeSafetySOSTitle:   String { "Emergency SOS" }
    var homeSafetySOSSub:     String { "Call for help instantly" }
    var homeSafetyShareTitle: String { "Share Trip" }
    var homeSafetyShareSub:   String { "Let someone track you" }

    // Misc
    var homePromoClaimOffer:   String { "Claim Offer →" }
    var homeEatsDeliveryFree:  String { "Free delivery" }
    var homeChangeLabel:       String { "Change" }
    var homeServicesSoonBadge: String { "SOON" }

    // Service tile names — English brand names, no localisation needed
    func homeServiceDisplayName(_ key: String) -> String { key }

    // Destination
    var rideBookTitle:       String { "Book a Ride" }
    var rideSavedAndRecent:  String { "Saved & Recent" }
    var rideSuggestions:     String { "Suggestions" }
    var rideCurrentLocation: String { "Current Location" }
    var rideChangeLabel:     String { "Change" }

    // Pickup
    var rideSetPickupTitle: String { "Set Pickup" }
    var rideGoingTo:        String { "Going to" }
    var ridePickupPoint:    String { "Pickup point" }
    var rideDragHint:       String { "Drag the pin to fine-tune your pickup location" }
    var rideConfirmPickup:  String { "Confirm Pickup Location" }

    // Confirm
    var rideChooseTitle:   String { "Choose Ride" }
    var rideRouteInfo:     String { "18.4 km · ~28 min" }
    var rideTotalLabel:    String { "Total" }
    var rideEstFare:       String { "est. fare" }
    var rideBookButton:    String { "Book" }
    var rideFindingDriver: String { "Finding driver..." }

    // Payment
    var ridePaymentMethodTitle: String { "Payment Method" }
    var rideAddPromo:           String { "Add promo code" }

    // Promo sheet
    var rideEnterPromoTitle:  String { "Enter promo code" }
    var ridePromoPlaceholder: String { "e.g. SAVE20" }
    var rideApply:            String { "Apply" }

    // Booked sheet
    var rideDriverFound: String { "Driver Found!" }
    func rideDriverETA(rideName: String, eta: Int) -> String {
        "Your \(rideName) is \(eta) minutes away"
    }
    var rideArrivingIn:    String { "Arriving in" }
    var rideEstimatedFare: String { "Estimated fare" }
    var rideCancelRide:    String { "Cancel Ride" }

    // Active banner
    var rideActiveBannerTitle: String { "Raj S. is on the way" }
    var rideActiveBannerSub:   String { "Silver Toyota Camry · SJD 9821 B · ~4 min" }

    // Rides tab
    var rideTabTitle:      String { "My Rides" }
    var rideRecentTitle:   String { "Recent Rides" }
    var ridePromoHeadline: String { isAU ? "Ride free up to A$10" : "Ride free up to S$10" }
    var ridePromoSub:      String { "Weekend promo — book before Sunday" }
    var ridePromoClaim:    String { "Claim →" }

    // Ride option meta
    func rideOptionMeta(eta: Int, capacity: Int) -> String {
        "\(eta) min · \(capacity) seat\(capacity == 1 ? "" : "s")"
    }
    func rideOptionHorseMeta(eta: Int) -> String { "\(eta) min · 1 saddle" }
    func rideETAChip(eta: Int) -> String { "\(eta) min away" }
    var rideLiveLabel: String { "LIVE" }
    var rideDefaultPickupAddress: String { isAU ? "Town Hall, 483 George St, Sydney NSW 2000" : "Capitol Tower, 168 Robinson Rd, Singapore 068912" }

    // Profile
    var profileTitle:             String { "Profile" }
    var profileRating:            String { "Rating" }
    var profileRidesCount:        String { "Rides" }
    var profileSaved:             String { "Saved" }
    var profileSectionAccount:    String { "Account" }
    var profilePersonalInfo:      String { "Personal Info" }
    var profilePaymentMethods:    String { "Payment Methods" }
    var profileSavedAddresses:    String { "Saved Addresses" }
    var profileSectionRidePrefs:  String { "Ride Preferences" }
    var profileDefaultRideType:   String { "Default Ride Type" }
    var profileMusicPrefs:        String { "Music Preferences" }
    var profileMyReviews:         String { "My Reviews" }
    var profileSectionSupport:    String { "Support" }
    var profileNotifications:     String { "Notifications" }
    var profilePrivacySecurity:   String { "Privacy & Security" }
    var profileHelpSupport:       String { "Help & Support" }
    var profileSignOut:           String { "Sign Out" }

    // Statuses
    var statusCompleted: String { "Completed" }
    var statusCancelled: String { "Cancelled" }
    var statusDelivered: String { "Delivered" }

    // Air
    var airHeroTitle:        String { "Where to next?" }
    var airHeroSubtitle:     String { isAU ? "Best fares from Sydney — instant booking" : "Best fares from Singapore — instant booking" }
    var airFromLabel:        String { "From" }
    var airToLabel:          String { "To" }
    var airSelectDest:       String { "Select destination" }
    var airPopularFromTitle: String { isAU ? "Popular from Sydney" : "Popular from Singapore" }
    var airSearchFlights:    String { "Search Flights" }
    var airOneWayLabel:      String { "One Way" }
    var airRoundTripLabel:   String { "Round Trip" }
    var airDepartLabel:      String { "Depart" }
    var airReturnLabel:      String { "Return" }
    func airPassengerLabel(_ count: Int) -> String {
        count == 1 ? "1 Passenger" : "\(count) Passengers"
    }

    // Food
    var foodTitle:               String { "CSQFood" }
    var foodDeliverySubtitle:    String { isAU ? "Delivering across Sydney" : "Delivering across Singapore" }
    var foodLocationLabel:       String { isAU ? "Surry Hills · Change" : "Toa Payoh · Change" }
    var foodSearchPlaceholder:   String { "Search dishes, restaurants..." }
    var foodFeaturedSection:     String { "Featured Today" }
    var foodHawkerPicksSection:  String { isAU ? "Sydney Picks" : "Hawker Picks" }
    var foodFreeDeliverySection: String { "Free Delivery" }
    var foodAllRestaurants:      String { "All Restaurants" }
    var foodSeeAll:              String { "See all" }

    // Mart
    var martDeliverTo:          String { isAU ? "Deliver to Sydney CBD" : "Deliver to Singapore CBD" }
    var martSearchPlaceholder:  String { "Search groceries, brands, items..." }
    var martCategorySection:    String { "Shop by Category" }
    var martButcherSection:     String { "The Butcher" }
    var martFlashDeals:         String { "Flash Deals" }
    var martFlashDealsTimer:    String { "Ends in 02:47:33" }
    var martFeaturedItems:      String { "Featured Items" }
    var martViewCart:           String { "View Cart" }
    var martViewAllCuts:        String { "View All\nCuts" }
    var martSeeAll:             String { "See all" }
    var martChips:             [String] { ["All", "Offers", "Fresh", "Organic", "Bestsellers"] }
    var martMeatSubcategories: [String] { ["All", "Chicken", "Beef", "Pork", "Lamb", "Seafood"] }

    // Telco
    var telcoHeroTitle:      String { "Stay Connected." }
    var telcoHeroSubtitle:   String { isAU ? "Australia's smartest mobile network" : "Singapore's smartest mobile network" }
    var telcoTopUpChip:      String { "Top Up" }
    var telcoDataAddOnChip:  String { "Data Add-On" }
    var telcoRoamChip:       String { "Roam" }
    var telcoCurrentPlan:    String { isAU ? "ValuePlus — A$28/mo" : "ValuePlus — S$28/mo" }
    var telcoRenewsIn:       String { "Renews in 12 days" }
    var telcoRemainingLabel: String { "Remaining" }
    var telcoUsedLabel:      String { "Used" }
    var telcoTotalLabel:     String { "Total" }
    var telcoLatestDevices:  String { "Latest Devices" }
    var telcoRoamingAddons:  String { "Roaming & Add-Ons" }
    var telcoRunningLow:     String { "Running low" }
    var telcoDialRemaining:  String { "remaining" }
    var telcoDialOf:         String { "of" }
    var telcoSelectPlan:     String { "Select Plan" }
    var telcoPricePerMonth:  String { "/mo" }
    var telcoFromPrice:      String { "From " }

    // Telco — Top-Up Sheet
    var telcoTopUpTitle:        String { "Top Up" }
    var telcoTopUpCurrentBal:   String { "Current Balance" }
    var telcoTopUpSelectAmt:    String { "Select top-up amount" }
    var telcoTopUpDone:         String { "Done" }
    var telcoTopUpToppedUp:     String { "Topped up!" }
    func telcoTopUpButton(_ amount: String) -> String { isAU ? "Top Up A$\(amount)" : "Top Up S$\(amount)" }

    // Telco — Roaming Sheet
    var telcoRoamingTitle:      String { "Roaming" }
    var telcoRoamingOff:        String { "Roaming is OFF" }
    var telcoRoamingTip:        String { "Tap a day pass below to activate instantly" }
    var telcoDayPassesTitle:    String { "Day Passes" }
    var telcoAddButton:         String { "Add" }
    var telcoDone:              String { "Done" }

    // Telco — Data Add-On Sheet
    var telcoDataAddOnTitle:    String { "Data Add-On" }
    var telcoChooseDataPack:    String { "Choose a Data Pack" }
    var telcoDataAddedButton:   String { "Added" }
    func telcoDataPrice(_ price: String) -> String { isAU ? "A$\(price)" : "S$\(price)" }
    func telcoConfirmAddOns(_ count: Int) -> String { "Confirm \(count) add-on\(count > 1 ? "s" : "")" }

    // Profile
    var profileUserName:  String { "Jeff Lin" }
    var profileUserEmail: String { "jeff.lin@contentsquare.com" }

    // Cash
    var cashAccountLabel:     String { isAU ? "jeff.lin · SYD" : "jeff.lin · SG" }
    var cashAvailableBalance: String { "Available Balance" }
    var cashCurrencyPrefix:   String { isAU ? "A$" : "S$" }
    var cashMoneyIn:          String { "Money In" }
    var cashMoneyOut:         String { "Money Out" }
    var cashScanQR:           String { "Scan\nQR" }
    var cashSendMoney:        String { "Send\nMoney" }
    var cashAddFunds:         String { "Add\nFunds" }
    var cashWithdraw:         String { "With-\ndraw" }
    var cashRecent:           String { "Recent" }
    var cashSeeAll:           String { "See all" }
    var cashTransactions:     String { "Transactions" }
    var cashThisMonth:        String { "This Month" }
    var cashViewAllTx:        String { "View All Transactions" }
    var cashNewContact:       String { "New" }
    var cashTxQRPayment:      String { "QR Payment" }
    var cashTxSent:           String { "Transfer Sent" }
    var cashTxReceived:       String { "Transfer Received" }
    var cashTxTopUp:          String { "Wallet Top Up" }
    var cashTxWithdrawal:     String { "Withdrawal" }
    var cashTxInternational:  String { "International Transfer" }

    // Cash — All Transactions sheet
    var cashAllTransactionsTitle: String { "All Transactions" }
    var cashNoTransactions:       String { "No transactions found" }
    var cashSearchTransactions:   String { "Search transactions" }
    func cashTxCount(_ count: Int) -> String { "\(count) transaction\(count == 1 ? "" : "s")" }
    var cashFilterAll: String { "All" }
    var cashFilterIn:  String { "In" }
    var cashFilterOut: String { "Out" }

    // Air — Results
    var airSortCheapest:          String { "Cheapest" }
    var airSortFastest:           String { "Fastest" }
    var airSortBest:              String { "Best" }
    var airFilterNonStop:         String { "Non-stop" }
    var airFilterUnder10h:        String { "Under 10h" }
    var airFilterRefundable:      String { "Refundable" }
    var airFilterMorning:         String { "Morning dep." }
    var airFilterEvening:         String { "Evening dep." }
    func airFlightsFound(_ count: Int) -> String { "\(count) flights found" }
    var airPricesPerPerson:       String { isAU ? "Prices per person · AUD" : "Prices per person · SGD" }
    var airNoFlightsMatch:        String { "No flights match your filters" }
    var airClearFilters:          String { "Clear Filters" }
    var airSelectButton:          String { "Select" }
    var airPax:                   String { "pax" }
    var airRemoveFiltersHint:     String { "Try removing some filters to see more results" }

    // Air — Detail
    var airFlightDetails:         String { "Flight Details" }
    var airLayoverIn:             String { "Layover in" }
    var airDirect:                String { "Direct" }
    var airChooseYourFare:        String { "Choose Your Fare" }
    var airWhatsIncluded:         String { "What's Included" }
    var airFareIncluded:          String { "Included" }
    var airBaggageLabel:          String { "Baggage" }
    var airChangesLabel:          String { "Changes" }
    var airRefundLabel:           String { "Refund" }
    var airMealsLabel:            String { "Meals" }
    var airSeatSelectionLabel:    String { "Seat Selection" }
    var airMilesEarnedLabel:      String { "Miles Earned" }
    var airOfBaseMiles:           String { "of base miles" }
    var airPriceBreakdown:        String { "Price Breakdown" }
    var airBaseFare:              String { "Base Fare" }
    var airUpgrade:               String { "Upgrade" }
    var airTaxesAndFees:          String { "Taxes & Fees" }
    var airServiceFee:            String { "CSQAir Service Fee" }
    var airBookNow:               String { "Book Now" }
    func airForPassengers(_ count: Int) -> String { "for \(count) passengers" }
    var airPerPerson:             String { "per person" }
    func airPerPersonTotal(_ currency: String, _ total: Int) -> String { "per person · \(currency)\(total) total" }

    // Air — Fare options
    var airFareLite:              String { "Lite" }
    var airFareValue:             String { "Value" }
    var airFareFlex:              String { "Flex" }
    var airBaggageLite:           String { "7kg cabin only" }
    var airBaggageValue:          String { "20kg checked + 7kg cabin" }
    var airBaggageFlex:           String { "30kg checked + 7kg cabin" }
    var airChangeLite:            String { "Not allowed" }
    var airChangeValue:           String { isAU ? "A$75 fee" : "S$75 fee" }
    var airChangeFlex:            String { "Free changes" }
    var airRefundLite:            String { "Non-refundable" }
    var airRefundValue:           String { isAU ? "A$120 fee" : "S$120 fee" }
    var airRefundFlex:            String { "Fully refundable" }
    var airMealLite:              String { "Not included" }
    var airMealValue:             String { "1 meal included" }
    var airMealFlex:              String { "2 meals + snack" }
    var airSeatLite:              String { "Paid" }
    var airSeatValue:             String { "Standard free" }
    var airSeatFlex:              String { "Any seat free" }

    // Air — Booking Confirmation
    var airBookingConfirmed:      String { "Booking Confirmed!" }
    func airTicketSentTo(_ email: String) -> String { "Your e-ticket has been sent to \(email)" }
    var airBookingRef:            String { "Booking Ref" }
    var airPassengerLabel2:       String { "Passenger" }
    var airPassengerName:         String { "Jeff Lin" }
    var airAdultEconomy:          String { "Adult · Economy" }
    var airSeatLabel:             String { "Seat" }
    var airSeatWindow:            String { "Window" }
    var airBaggageLabel2:         String { "Baggage" }
    var airCheckedLabel:          String { "Checked" }
    var airETicketButton:         String { "E-Ticket" }
    var airAddToCalButton:        String { "Add to Cal" }
    var airShareButton:           String { "Share" }
    var airBackToAir:             String { "Back to CSQAir" }
    var airPaxLabel:              String { "pax" }

    // Telco — Plan Detail
    var telcoBackButton:          String { "Back" }
    var telcoDataAllowance:       String { "Data Allowance" }
    var telcoEverythingInPlan:    String { "Everything in this plan" }
    var telcoCompareOtherPlans:   String { "Compare with other plans" }
    var telcoPortInTitle:         String { "Switch from Starhub, M1 or SingTel?" }
    var telcoPortInBody:          String { isAU ? "Port your number in 3 business days. Get A$30 credit when you port in with a 24-month contract." : "Port your number in 3 business days, IMDA-compliant. Get S$30 credit when you port in with a 24-month contract." }
    var telcoPortInNow:           String { "Port In Now" }
    var telcoFAQTitle:            String { "Frequently Asked Questions" }
    var telcoFAQ1Q:               String { "Can I keep my existing number?" }
    var telcoFAQ1A:               String { isAU ? "Yes, number portability is available. Transfer takes 3 business days." : "Yes, number portability is available. Transfer takes 3 business days and is IMDA-compliant." }
    var telcoFAQ2Q:               String { "What happens after the contract?" }
    var telcoFAQ2A:               String { "Your plan auto-renews month-to-month at the same rate. Cancel anytime with 30 days notice." }
    var telcoFAQ3Q:               String { "Is 5G available on this plan?" }
    var telcoFAQ3A:               String { isAU ? "5G is included on ValuePlus, Infinite, and Black plans. Coverage across the Sydney CBD, suburbs, and major transport hubs." : "5G is included on ValuePlus, Infinite, and Black plans. Coverage across all MRT stations, CBD, and major shopping malls." }
    var telcoFAQ4Q:               String { "How do I activate my eSIM?" }
    var telcoFAQ4A:               String { "Download the CSQMobile app, go to eSIM Setup, and scan the QR code from your confirmation email. Activate instantly." }
    var telcoPerMonth:            String { "/month" }
    func telcoSignUpFor(_ name: String) -> String { "Sign Up for \(name)" }
    var telcoViewDetails:         String { "View Details" }

    // Telco — Purchase Funnel (device detail + financing)
    var telcoColorLabel:       String { "Colour" }
    var telcoStorageLabel:     String { "Storage" }
    var telcoContinue:         String { "Continue" }
    var telcoFinancingTitle:   String { "Choose how to pay" }
    var telcoInstallmentLabel: String { isAU ? "24-month instalment" : "24-month installment" }
    var telcoInstallmentSub:   String { "No upfront cost · spread over 24 months" }
    var telcoOutrightLabel:    String { "Pay outright" }
    var telcoOutrightSub:      String { "One-time payment, own it today" }
    var telcoAttachPlanTitle:  String { "Add a mobile plan (optional)" }
    var telcoContinueCheckout: String { "Continue to checkout" }
    var telcoDueToday:         String { "Due today" }
    var telcoMonthlyLabel:     String { "Monthly" }

    // Telco — Plan Signup
    var telcoSignupTitle:      String { "Set up your plan" }
    var telcoSimTypeTitle:     String { "Choose your SIM" }
    var telcoESIMLabel:        String { "eSIM" }
    var telcoESIMSub:          String { "Activate instantly — no physical SIM" }
    var telcoPhysicalSIMLabel: String { "Physical SIM" }
    var telcoPhysicalSIMSub:   String { isAU ? "Posted to your address" : "Delivered to your address" }
    var telcoNumberTitle:      String { "Your number" }
    var telcoNewNumberLabel:   String { "New number" }
    var telcoNewNumberSub:     String { "Get a fresh CSQMobile number" }
    var telcoKeepNumberLabel:  String { "Keep my number" }
    var telcoKeepNumberSub:    String { "Port in from your current telco" }

    // Telco — Checkout
    var telcoCheckoutTitle:    String { "Checkout" }
    var telcoOrderSummary:     String { "Order summary" }
    var telcoFulfillmentTitle: String { "Delivery method" }
    var telcoFulfillmentESIM:  String { "eSIM — instant activation" }
    var telcoFulfillmentDelivery: String { isAU ? "Home delivery (1–3 business days)" : "Home delivery (1–2 days)" }
    var telcoFulfillmentPickup: String { isAU ? "Pick up in store" : "Collect at a CSQMobile store" }
    var telcoYourDetailsTitle: String { "Your details" }
    var telcoFieldName:        String { "Full name" }
    var telcoFieldID:          String { isAU ? "Medicare or licence no." : "NRIC / FIN" }
    var telcoFieldEmail:       String { "Email address" }
    var telcoFieldAddress:     String { "Delivery address" }
    var telcoPaymentTitle:     String { "Payment method" }
    var telcoPayCard:          String { "Credit / debit card" }
    var telcoPayWallet:        String { isAU ? "PayID" : "PayNow" }
    var telcoFieldCardNumber:  String { "Card number" }
    var telcoContinueVerify:   String { "Continue to verification" }

    // Telco — Credit / ID Check
    var telcoCreditTitle:      String { "Credit & ID check" }
    var telcoCreditBody:       String { isAU
        ? "We run a quick credit and identity check before activating a contract line. It usually takes a few seconds."
        : "CSQMobile runs a quick credit and identity check before activating a contract line. This usually takes a few seconds." }
    var telcoCreditConsent:    String { "I consent to a credit and identity check" }
    var telcoRunCheck:         String { "Run credit check" }
    var telcoChecking:         String { "Checking…" }
    var telcoCreditApproved:   String { "Approved" }
    var telcoCreditApprovedSub:String { "You're all set — complete your order below." }
    var telcoPlaceOrder:       String { "Place order" }

    // Telco — Order Confirmed
    var telcoOrderConfirmedTitle: String { "Order confirmed!" }
    var telcoOrderConfirmedSub:   String { "We've emailed your confirmation and receipt." }
    var telcoESIMReady:           String { "Your eSIM is ready to activate" }
    var telcoScanToActivate:      String { "Scan the QR code to activate your line" }
    var telcoOrderNumberLabel:    String { "Order number" }
    var telcoBackToMobile:        String { "Back to CSQMobile" }
    var telcoCreditDeclined:      String { isAU ? "Instalment financing declined" : "Installment financing declined" }
    var telcoCreditDeclinedSub:   String { isAU
        ? "We can't offer monthly financing for this device right now. You can still buy it outright today."
        : "We're unable to offer monthly financing for this device right now. You can still buy it outright today." }
    var telcoSwitchOutright:      String { "Switch to outright purchase" }

    // Grocery — Cart
    var cartExpressDelivery:      String { "Express delivery · Ready in **45 minutes**" }
    var cartEnterPromo:           String { "Enter promo code" }
    var cartApply:                String { "Apply" }
    var cartInvalidPromo:         String { "Invalid promo code. Please check and try again." }
    var cartOrderSummary:         String { "Order Summary" }
    var cartDeliveryFee:          String { "Delivery fee" }
    var cartServiceFee:           String { "Service fee" }
    var cartPromoDiscount:        String { "Promo discount" }
    var cartTotal:                String { "Total" }
    var cartProceedCheckout:      String { "Proceed to Checkout" }
    func cartSubtotal(_ count: Int) -> String { "Subtotal (\(count) items)" }
    var cartEach:                 String { "each" }
    var cartNavTitle:             String { "My Cart" }
    var cartClearButton:          String { "Clear" }
    var cartEmptyTitle:           String { "Your cart is empty" }
    var cartEmptySubtitle:        String { "Add items from CSQMart to get started" }
    var cartStartShopping:        String { "Start Shopping" }

    // Grocery — Checkout
    var checkoutTitle:            String { "Checkout" }
    var checkoutDeliveryAddress:  String { "Delivery Address" }
    var checkoutHome:             String { "Home" }
    var checkoutHomeAddress:      String { isAU ? "14 Harbour St, Sydney NSW 2000" : "14 Harbour St, Singapore 049315" }
    var checkoutChange:           String { "Change" }
    var checkoutLeaveAtDoor:      String { "Leave at door if no answer" }
    var checkoutAddInstructions:  String { "Add delivery instructions..." }
    var checkoutDeliverySlot:     String { "Delivery Slot" }
    var checkoutPayment:          String { "Payment" }
    var checkoutPlacingOrder:     String { "Placing Order..." }
    var checkoutPlaceOrder:       String { "Place Order · " }

    // Grocery — Order Confirmation
    var orderPlaced:              String { "Order Placed!" }
    var orderGroceriesPrepared:   String { "Your groceries are being prepared" }
    var orderNumber:              String { "Order #" }
    var orderEstimatedArrival:    String { "Estimated Arrival" }
    var orderProgress:            String { "Order Progress" }
    var orderStepConfirmed:       String { "Order Confirmed" }
    var orderStepPacked:          String { "Being Packed" }
    var orderStepOutForDelivery:  String { "Out for Delivery" }
    var orderStepDelivered:       String { "Delivered" }
    var orderInProgress:          String { "In progress..." }
    var orderCompleted:           String { "Completed" }
    var orderDeliveryPartner:     String { "Your Delivery Partner" }
    var orderDeliveryInfo:        String { "On a bicycle · 2.1 km away" }
    var orderTrackLiveMap:        String { "Track Live on Map" }
    var orderReorder:             String { "Reorder" }
    var orderShare:               String { "Share" }
    var riderFindingPartner:      String { "Finding your delivery partner" }
    var riderFindingSubtitle:     String { "We're matching you with a nearby rider.\nThis usually takes a few seconds." }
    var riderCancelOrder:         String { "Cancel Order" }
    var riderEstimatedArrival:    String { "Estimated Arrival" }
    var riderLiveBadge:           String { "Live" }
    var riderSafetyTools:         String { "Safety Tools" }

    // Grocery — Product Detail
    var productInStock:           String { "In Stock" }
    var productOutOfStock:        String { "Out of Stock" }
    var productDescriptionTab:    String { "Description" }
    var productNutritionTab:      String { "Nutrition" }
    var productReviewsTab:        String { "Reviews" }
    var productQuantity:          String { "Quantity" }
    var productTotal:             String { "Total" }
    var productAddToCart:         String { "Add to Cart" }
    var productAddedToCart:       String { "Added to Cart!" }
    var productNutritionTitle:    String { "Nutrition Facts" }
    var productServingSize:       String { "Per serving (100g)" }
    var productReviewsCount:      String { "reviews" }

    // Grocery — Meat Category
    var meatFreshDaily:           String { "Fresh daily" }
    var meatButcherTitle:         String { "The Butcher" }
    var meatSubtitle:             String { "Premium cuts • Fresh daily • Delivered to your door" }
    var meatItemsCount:           String { "items" }
    var meatEmptyState:           String { "No items in this category" }
    var meatButcherTipTitle:      String { "Butcher's Tip" }
    var meatButcherTipBody:       String { "All our beef and lamb are MSA graded for guaranteed tenderness. Look for the marble score on premium cuts — a score of 3+ means restaurant-quality eating every time." }
    var meatViewCart:             String { "View Cart" }
    var meatSortFeatured:         String { "Featured" }
    var meatSortPriceLow:         String { "Price: Low–High" }
    var meatSortPriceHigh:        String { "Price: High–Low" }
    var meatSortTopRated:         String { "Top Rated" }

    // Food — Restaurant Detail / Order
    var foodAddItemsToStart:      String { "Add items to start your order" }
    var foodViewCart:             String { "View Cart" }
    func foodItemsTotal(_ count: Int, _ currency: String, _ amount: String) -> String {
        "\(count) items — \(currency)\(amount)"
    }
    var foodYourOrder:            String { "Your Order" }
    var foodOrderSummary:         String { "Order Summary" }
    var foodDeliveryAddress:      String { "Delivery Address" }
    var foodHomeAddress:          String { isAU ? "12 Crown St, Surry Hills, Sydney NSW 2010" : "480 Lor 6 Toa Payoh, Singapore 310480" }
    var foodChange:               String { "Change" }
    var foodPayment:              String { "Payment" }
    var foodPromoCode:            String { "Promo Code" }
    var foodAddPromoCode:         String { "Add promo code" }
    var foodEnterCode:            String { "Enter code" }
    var foodApply:                String { "Apply" }
    var foodYouMightLike:         String { "You might also like" }
    var foodSubtotal:             String { "Subtotal" }
    var foodDeliveryFee:          String { "Delivery fee" }
    var foodFree:                 String { "Free" }
    var foodPlatformFee:          String { "Platform fee" }
    var foodTotal:                String { "Total" }
    var foodPlacingOrder:         String { "Placing order..." }
    var foodPlaceOrder:           String { "Place Order" }
    var foodSomethingWentWrong:   String { "Something went wrong. Please try again." }
    var foodOrderConfirmedTitle:  String { "Order Confirmed" }
    func foodOrderFromRestaurant(_ name: String) -> String { "Your order from \(name) is being prepared" }
    var foodEstimatedArrival:     String { "Estimated Arrival" }
    var foodOrderTotal:           String { "Order Total" }
    var foodLiveTracking:         String { "Live Tracking" }
    var foodStepReceived:         String { "Order Received" }
    var foodStepPreparing:        String { "Preparing" }
    var foodStepOnTheWay:         String { "On the Way" }
    var foodStepDelivered:        String { "Delivered" }
    var foodDeliveryNote:         String { "Leave at door or ring the bell — add delivery notes in the CSQFood app." }
    var foodTrackMyOrder:         String { "Track My Order" }
    var foodBackToFood:           String { "Back to CSQFood" }
    var foodOrderConfirmed:       String { "Order Confirmed!" }

    // Cash — Send Money
    var cashSendMoneyTitle:       String { "Send Money" }
    var cashCancelButton:         String { "Cancel" }
    var cashTabContacts:          String { "Contacts" }
    var cashTabTransfer:          String { "Transfer" }
    var cashTabOverseas:          String { "Overseas" }
    var cashAvailablePrefix:      String { "Available: " }
    var cashSendVia:              String { "Send Via" }
    var cashPhoneLabel:           String { "Phone" }
    var cashEmailLabel:           String { "Email" }
    var cashBankAcctLabel:        String { "Bank Acct" }
    var cashPhoneNumber:          String { "Phone Number" }
    var cashEmailAddress:         String { "Email Address" }
    var cashBankAccountNo:        String { "Bank Account No." }
    var cashPhonePlaceholder:     String { isAU ? "+61 4XX XXX XXX" : "+65 XXXX XXXX" }
    var cashBankAcctPlaceholder:  String { "Account number" }
    var cashAddNote:              String { "Add a note (optional)" }
    var cashSendMoneyButton:      String { "Send Money" }
    var cashSendInternational:    String { "Send Internationally" }
    var cashDestCountry:          String { "Destination Country" }
    var cashRecipientDetails:     String { "Recipient Details" }
    var cashTransferDetails:      String { "Transfer Details" }
    var cashAmountIn:             String { isAU ? "Amount in AUD" : "Amount in SGD" }
    var cashTransferPurpose:      String { "Purpose" }
    var cashYouSend:              String { "You Send" }
    var cashTransferFee:          String { "Transfer Fee" }
    var cashTotalDeducted:        String { "Total Deducted" }
    var cashExchangeRate:         String { "Exchange Rate" }
    var cashRecipientGets:        String { "Recipient Gets" }
    var cashSelectCountry:        String { "Select Country" }
    var cashDoneButton:           String { "Done" }
    var cashLastAmount:           String { "Last: " }
    var cashBalanceAfter:         String { "Balance after: " }
    var cashConfirmSend:          String { "Confirm Send" }
    var cashInternationalTransfer: String { "International Transfer" }
    var cashSendMoneyConfirmTitle: String { "Send Money" }
    // Cash — Add/Withdraw
    var cashAddFundsTitle:        String { "Add Funds" }
    var cashWithdrawTitle:        String { "Withdraw" }
    var cashAddFundsHeader:       String { "Add Funds to Wallet" }
    var cashWithdrawHeader:       String { "Withdraw from Wallet" }
    var cashInstantFromBank:      String { "Instant transfer from your bank" }
    var cashTransferToBank:       String { "Transfer to your linked bank account" }
    var cashWalletBalance:        String { "Wallet Balance" }
    var cashAfterAdding:          String { "After Adding" }
    var cashAfterWithdrawal:      String { "After Withdrawal" }
    var cashSelectAmount:         String { "Select Amount" }
    var cashCustomAmount:         String { "Custom amount" }
    var cashFromAccount:          String { "From Account" }
    var cashToAccountLabel:       String { "To Account" }
    var cashInstantProcessing:    String { "Instant processing · Available immediately" }
    var cashNoFees:               String { "No fees" }
    var cashInsufficientBalance:  String { "Insufficient wallet balance" }
    var cashConfirmTopUp:         String { "Confirm Top Up" }
    var cashConfirmWithdrawal:    String { "Confirm Withdrawal" }
    var cashConfirmButton:        String { "Confirm" }
    func cashAddAmount(_ amount: String) -> String { isAU ? "Add A$\(amount)" : "Add S$\(amount)" }
    func cashWithdrawAmount(_ amount: String) -> String { isAU ? "Withdraw A$\(amount)" : "Withdraw S$\(amount)" }
    func cashFromAccount2(_ bank: String) -> String { "From \(bank)" }
    func cashToAccount2(_ bank: String) -> String { "To \(bank)" }
    // Cash — QR Scanner
    var cashScanToPayTitle:       String { "Scan to Pay" }
    var cashPointCamera:          String { "Point your camera at a QR code" }
    var cashQRSupports:           String { isAU ? "Supports PayID, BPAY, and CSQCash QR codes" : "Supports PayNow, SGQR, and CSQCash QR codes" }
    var cashDemoScan:             String { "Demo: Simulate QR Scan" }
    var cashCameraDenied:         String { "Camera access denied. Enable in Settings or use Demo Scan." }
    var cashCancelPayment:        String { "Cancel" }
    var cashBalanceAfterPayment:  String { "Balance after: " }
    func cashPayAmount(_ amount: String) -> String { isAU ? "Pay A$\(amount)" : "Pay S$\(amount)" }
}

// MARK: - Japanese (Tokyo)

struct JapaneseStrings: AppStrings {
    // Splash
    var splashTagline:   String { "あなたの街を、指先に。" }
    var splashTapPrompt: String { "タップして開始" }

    // Tabs
    var tabHome:    String { "ホーム" }
    var tabRides:   String { "乗車" }
    var tabMobile:  String { "モバイル" }
    var tabFood:    String { "フード" }
    var tabProfile: String { "プロフィール" }

    // Home header
    var homeLocationLabel:      String { "東京・渋谷" }
    var homeWeather:            String { "24°C · 晴れ · 湿度低め" }
    var homeUserDisplayName:    String { "沖本" }       // Okimoto — surname used with さん
    var homeUserAvatarInitials: String { "沖" }         // First kanji of surname
    func homeGreeting(name: String, hour: Int) -> String {
        switch hour {
        case 5..<12:  return "おはようございます、\(name)さん"
        case 12..<14: return "お昼ですよ、\(name)さん！"
        case 14..<18: return "こんにちは、\(name)さん"
        case 18..<21: return "夕食の時間ですよ、\(name)さん！"
        default:      return "まだ起きてますか、\(name)さん？"
        }
    }

    // Home search + sections
    var homeSearchPlaceholder:     String { "どこへ？" }
    var homeSectionServices:       String { "サービス" }
    var homeSectionFavourites:     String { "おすすめグルメ" }
    var homeFavouritesSubtitle:    String { "渋谷区にお届け" }
    var homeSectionDeals:          String { "お得情報" }
    var homeSectionQuickActions:   String { "クイックアクション" }
    var homeSectionRecentActivity: String { "最近の履歴" }
    var homeSectionSafety:         String { "安全" }
    var homeSectionSeeAll:         String { "すべて見る" }

    // Rewards
    var homeRewardsName:     String { "CSQリワーズ" }
    var homeRewardsProgress: String { "次の特典まで160ポイント" }
    var homeRewardsTierGold: String { "GOLD" }
    var homeRewardsPtsLabel: String { "pt" }

    // Quick actions
    var homeQuickBookRide:     String { "乗車を予約" }
    var homeQuickBookRideSub:  String { "2分後に到着" }
    var homeQuickSchedule:     String { "予約乗車" }
    var homeQuickScheduleSub:  String { "事前に計画" }
    var homeQuickSendMoney:    String { "送金" }
    var homeQuickSendMoneySub: String { "CSQペイ" }
    var homeQuickScanPay:      String { "スキャン支払い" }
    var homeQuickScanPaySub:   String { "QRコード決済" }

    // Safety
    var homeSafetySOSTitle:   String { "緊急SOS" }
    var homeSafetySOSSub:     String { "すぐにサポートに連絡" }
    var homeSafetyShareTitle: String { "乗車共有" }
    var homeSafetyShareSub:   String { "現在地を友人に共有" }

    // Misc
    var homePromoClaimOffer:   String { "特典を受け取る →" }
    var homeEatsDeliveryFree:  String { "配送無料" }
    var homeChangeLabel:       String { "変更" }
    var homeServicesSoonBadge: String { "近日" }

    // Service tile names — localised for Japanese market
    func homeServiceDisplayName(_ key: String) -> String {
        switch key {
        case "CSQRide":        return "CSQライド"
        case "CSQMart":        return "CSQマート"
        case "CSQFood":        return "CSQフード"
        case "CSQDragonDance": return "CSQ龍舞"
        case "CSQOutfits":     return "CSQファッション"
        case "CSQAir":         return "CSQエア"
        case "CSQCash":        return "CSQキャッシュ"
        case "CSQMobile":      return "CSQモバイル"
        default:               return key
        }
    }

    // Destination
    var rideBookTitle:       String { "乗車を予約" }
    var rideSavedAndRecent:  String { "保存済み・最近" }
    var rideSuggestions:     String { "候補" }
    var rideCurrentLocation: String { "現在地" }
    var rideChangeLabel:     String { "変更" }

    // Pickup
    var rideSetPickupTitle: String { "乗車地点を設定" }
    var rideGoingTo:        String { "目的地" }
    var ridePickupPoint:    String { "乗車地点" }
    var rideDragHint:       String { "ピンをドラッグして乗車地点を調整" }
    var rideConfirmPickup:  String { "乗車地点を確定" }

    // Confirm
    var rideChooseTitle:   String { "乗車タイプを選択" }
    var rideRouteInfo:     String { "12.3 km · 約35分" }
    var rideTotalLabel:    String { "合計" }
    var rideEstFare:       String { "予想運賃" }
    var rideBookButton:    String { "予約" }
    var rideFindingDriver: String { "ドライバーを探しています..." }

    // Payment
    var ridePaymentMethodTitle: String { "お支払い方法" }
    var rideAddPromo:           String { "プロモコードを追加" }

    // Promo sheet
    var rideEnterPromoTitle:  String { "プロモコードを入力" }
    var ridePromoPlaceholder: String { "例: SAVE20" }
    var rideApply:            String { "適用" }

    // Booked sheet
    var rideDriverFound: String { "ドライバーが見つかりました！" }
    func rideDriverETA(rideName: String, eta: Int) -> String {
        "\(rideName)が\(eta)分後に到着します"
    }
    var rideArrivingIn:    String { "到着まで" }
    var rideEstimatedFare: String { "予想運賃" }
    var rideCancelRide:    String { "乗車をキャンセル" }

    // Active banner
    var rideActiveBannerTitle: String { "田中 浩二 さんが向かっています" }
    var rideActiveBannerSub:   String { "ホワイト Toyota Prius · 練馬 301 あ 12-34 · 約4分" }

    // Rides tab
    var rideTabTitle:      String { "乗車履歴" }
    var rideRecentTitle:   String { "最近の乗車" }
    var ridePromoHeadline: String { "最大1,000円オフ" }
    var ridePromoSub:      String { "週末プロモ — 日曜日までに予約" }
    var ridePromoClaim:    String { "今すぐ →" }

    // Ride option meta
    func rideOptionMeta(eta: Int, capacity: Int) -> String {
        "\(eta)分 · \(capacity)席"
    }
    func rideOptionHorseMeta(eta: Int) -> String { "\(eta)分 · 1鞍" }
    func rideETAChip(eta: Int) -> String { "\(eta)分後" }
    var rideLiveLabel: String { "ライブ" }
    var rideDefaultPickupAddress: String { "渋谷区神南1丁目19-14" }

    // Profile
    var profileTitle:             String { "プロフィール" }
    var profileRating:            String { "評価" }
    var profileRidesCount:        String { "乗車" }
    var profileSaved:             String { "節約" }
    var profileSectionAccount:    String { "アカウント" }
    var profilePersonalInfo:      String { "個人情報" }
    var profilePaymentMethods:    String { "お支払い方法" }
    var profileSavedAddresses:    String { "保存済み住所" }
    var profileSectionRidePrefs:  String { "乗車設定" }
    var profileDefaultRideType:   String { "デフォルト乗車タイプ" }
    var profileMusicPrefs:        String { "音楽設定" }
    var profileMyReviews:         String { "レビュー" }
    var profileSectionSupport:    String { "サポート" }
    var profileNotifications:     String { "通知" }
    var profilePrivacySecurity:   String { "プライバシーとセキュリティ" }
    var profileHelpSupport:       String { "ヘルプとサポート" }
    var profileSignOut:           String { "サインアウト" }

    // Statuses
    var statusCompleted: String { "完了" }
    var statusCancelled: String { "キャンセル" }
    var statusDelivered: String { "配達済み" }

    // Air
    var airHeroTitle:        String { "次はどこへ？" }
    var airHeroSubtitle:     String { "東京発の最安値フライト — 即時予約" }
    var airFromLabel:        String { "出発地" }
    var airToLabel:          String { "目的地" }
    var airSelectDest:       String { "目的地を選択" }
    var airPopularFromTitle: String { "東京から人気の路線" }
    var airSearchFlights:    String { "フライトを検索" }
    var airOneWayLabel:      String { "片道" }
    var airRoundTripLabel:   String { "往復" }
    var airDepartLabel:      String { "出発" }
    var airReturnLabel:      String { "帰り" }
    func airPassengerLabel(_ count: Int) -> String { "\(count)名" }

    // Food
    var foodTitle:               String { "CSQフード" }
    var foodDeliverySubtitle:    String { "東京全域にお届け" }
    var foodLocationLabel:       String { "渋谷区 · 変更" }
    var foodSearchPlaceholder:   String { "料理・レストランを検索..." }
    var foodFeaturedSection:     String { "注目のお店" }
    var foodHawkerPicksSection:  String { "おすすめグルメ" }
    var foodFreeDeliverySection: String { "配送無料" }
    var foodAllRestaurants:      String { "すべてのレストラン" }
    var foodSeeAll:              String { "すべて見る" }

    // Mart
    var martDeliverTo:          String { "東京・渋谷区にお届け" }
    var martSearchPlaceholder:  String { "商品・ブランドを検索..." }
    var martCategorySection:    String { "カテゴリー" }
    var martButcherSection:     String { "精肉コーナー" }
    var martFlashDeals:         String { "タイムセール" }
    var martFlashDealsTimer:    String { "終了まで 02:47:33" }
    var martFeaturedItems:      String { "注目商品" }
    var martViewCart:           String { "カートを見る" }
    var martViewAllCuts:        String { "全て見る" }
    var martSeeAll:             String { "すべて見る" }
    var martChips:             [String] { ["すべて", "特売", "新鮮", "オーガニック", "ベストセラー"] }
    var martMeatSubcategories: [String] { ["すべて", "鶏肉", "牛肉", "豚肉", "羊肉", "魚介類"] }

    // Telco
    var telcoHeroTitle:      String { "つながり続けよう。" }
    var telcoHeroSubtitle:   String { "日本最先端のモバイルネットワーク" }
    var telcoTopUpChip:      String { "チャージ" }
    var telcoDataAddOnChip:  String { "データ追加" }
    var telcoRoamChip:       String { "ローミング" }
    var telcoCurrentPlan:    String { "バリュープラス — ¥2,800/月" }
    var telcoRenewsIn:       String { "12日後に更新" }
    var telcoRemainingLabel: String { "残り" }
    var telcoUsedLabel:      String { "使用済み" }
    var telcoTotalLabel:     String { "合計" }
    var telcoLatestDevices:  String { "最新デバイス" }
    var telcoRoamingAddons:  String { "ローミングと追加オプション" }
    var telcoRunningLow:     String { "残りわずか" }
    var telcoDialRemaining:  String { "残り" }
    var telcoDialOf:         String { "合計" }
    var telcoSelectPlan:     String { "プランを選択" }
    var telcoPricePerMonth:  String { "/月" }
    var telcoFromPrice:      String { "月額" }

    // Telco — Top-Up Sheet
    var telcoTopUpTitle:        String { "チャージ" }
    var telcoTopUpCurrentBal:   String { "現在の残高" }
    var telcoTopUpSelectAmt:    String { "チャージ金額を選択" }
    var telcoTopUpDone:         String { "完了" }
    var telcoTopUpToppedUp:     String { "チャージ完了！" }
    func telcoTopUpButton(_ amount: String) -> String { "¥\(amount)チャージ" }

    // Telco — Roaming Sheet
    var telcoRoamingTitle:      String { "ローミング" }
    var telcoRoamingOff:        String { "ローミング：OFF" }
    var telcoRoamingTip:        String { "以下のデイパスをタップしてすぐに有効化" }
    var telcoDayPassesTitle:    String { "デイパス" }
    var telcoAddButton:         String { "追加" }
    var telcoDone:              String { "完了" }

    // Telco — Data Add-On Sheet
    var telcoDataAddOnTitle:    String { "データ追加" }
    var telcoChooseDataPack:    String { "データパックを選択" }
    var telcoDataAddedButton:   String { "追加済み" }
    func telcoDataPrice(_ price: String) -> String { "¥\(price)" }
    func telcoConfirmAddOns(_ count: Int) -> String { "\(count)件の追加オプションを確認" }

    // Profile
    var profileUserName:  String { "沖本 篤史" }
    var profileUserEmail: String { "jeff.lin@contentsquare.com" }

    // Cash
    var cashAccountLabel:     String { "jeff.lin · JP" }
    var cashAvailableBalance: String { "残高" }
    var cashCurrencyPrefix:   String { "¥" }
    var cashMoneyIn:          String { "入金" }
    var cashMoneyOut:         String { "出金" }
    var cashScanQR:           String { "QR\nスキャン" }
    var cashSendMoney:        String { "送金" }
    var cashAddFunds:         String { "チャージ" }
    var cashWithdraw:         String { "引き出し" }
    var cashRecent:           String { "最近" }
    var cashSeeAll:           String { "すべて見る" }
    var cashTransactions:     String { "取引" }
    var cashThisMonth:        String { "今月" }
    var cashViewAllTx:        String { "全取引を見る" }
    var cashNewContact:       String { "新規" }
    var cashTxQRPayment:      String { "QR決済" }
    var cashTxSent:           String { "送金" }
    var cashTxReceived:       String { "受取" }
    var cashTxTopUp:          String { "チャージ" }
    var cashTxWithdrawal:     String { "引き出し" }
    var cashTxInternational:  String { "海外送金" }

    // Cash — All Transactions sheet
    var cashAllTransactionsTitle: String { "全取引" }
    var cashNoTransactions:       String { "取引が見つかりません" }
    var cashSearchTransactions:   String { "取引を検索" }
    func cashTxCount(_ count: Int) -> String { "\(count)件の取引" }
    var cashFilterAll: String { "すべて" }
    var cashFilterIn:  String { "入金" }
    var cashFilterOut: String { "出金" }

    // Air — Results
    var airSortCheapest:          String { "最安値" }
    var airSortFastest:           String { "最速" }
    var airSortBest:              String { "おすすめ" }
    var airFilterNonStop:         String { "直行便" }
    var airFilterUnder10h:        String { "10時間以内" }
    var airFilterRefundable:      String { "払い戻し可" }
    var airFilterMorning:         String { "午前発" }
    var airFilterEvening:         String { "夜間発" }
    func airFlightsFound(_ count: Int) -> String { "\(count)便見つかりました" }
    var airPricesPerPerson:       String { "一人当たりの価格 · JPY" }
    var airNoFlightsMatch:        String { "条件に合うフライトがありません" }
    var airClearFilters:          String { "フィルターをクリア" }
    var airSelectButton:          String { "選択" }
    var airPax:                   String { "名" }
    var airRemoveFiltersHint:     String { "フィルターを外してさらに結果を表示" }

    // Air — Detail
    var airFlightDetails:         String { "フライト詳細" }
    var airLayoverIn:             String { "乗り継ぎ：" }
    var airDirect:                String { "直行" }
    var airChooseYourFare:        String { "運賃を選択" }
    var airWhatsIncluded:         String { "含まれるサービス" }
    var airFareIncluded:          String { "込み" }
    var airBaggageLabel:          String { "手荷物" }
    var airChangesLabel:          String { "変更" }
    var airRefundLabel:           String { "払い戻し" }
    var airMealsLabel:            String { "食事" }
    var airSeatSelectionLabel:    String { "座席指定" }
    var airMilesEarnedLabel:      String { "マイル積算" }
    var airOfBaseMiles:           String { "の基本マイル" }
    var airPriceBreakdown:        String { "料金内訳" }
    var airBaseFare:              String { "基本運賃" }
    var airUpgrade:               String { "アップグレード" }
    var airTaxesAndFees:          String { "税金・手数料" }
    var airServiceFee:            String { "CSQエア手数料" }
    var airBookNow:               String { "今すぐ予約" }
    func airForPassengers(_ count: Int) -> String { "\(count)名分" }
    var airPerPerson:             String { "1名あたり" }
    func airPerPersonTotal(_ currency: String, _ total: Int) -> String { "1名あたり · 合計\(currency)\(total)" }

    // Air — Fare options
    var airFareLite:              String { "ライト" }
    var airFareValue:             String { "バリュー" }
    var airFareFlex:              String { "フレックス" }
    var airBaggageLite:           String { "機内持ち込み7kgのみ" }
    var airBaggageValue:          String { "預け荷物20kg + 機内持ち込み7kg" }
    var airBaggageFlex:           String { "預け荷物30kg + 機内持ち込み7kg" }
    var airChangeLite:            String { "変更不可" }
    var airChangeValue:           String { "¥7,500の手数料" }
    var airChangeFlex:            String { "変更無料" }
    var airRefundLite:            String { "払い戻し不可" }
    var airRefundValue:           String { "¥12,000の手数料" }
    var airRefundFlex:            String { "全額払い戻し可" }
    var airMealLite:              String { "食事なし" }
    var airMealValue:             String { "機内食1回" }
    var airMealFlex:              String { "機内食2回＋軽食" }
    var airSeatLite:              String { "有料" }
    var airSeatValue:             String { "標準座席無料" }
    var airSeatFlex:              String { "全座席無料" }

    // Air — Booking Confirmation
    var airBookingConfirmed:      String { "予約が確定しました！" }
    func airTicketSentTo(_ email: String) -> String { "eチケットを \(email) に送信しました" }
    var airBookingRef:            String { "予約番号" }
    var airPassengerLabel2:       String { "乗客" }
    var airPassengerName:         String { "沖本 篤史" }
    var airAdultEconomy:          String { "大人 · エコノミー" }
    var airSeatLabel:             String { "座席" }
    var airSeatWindow:            String { "窓側" }
    var airBaggageLabel2:         String { "手荷物" }
    var airCheckedLabel:          String { "預け荷物" }
    var airETicketButton:         String { "eチケット" }
    var airAddToCalButton:        String { "カレンダー" }
    var airShareButton:           String { "共有" }
    var airBackToAir:             String { "CSQエアに戻る" }
    var airPaxLabel:              String { "名" }

    // Telco — Plan Detail
    var telcoBackButton:          String { "戻る" }
    var telcoDataAllowance:       String { "データ容量" }
    var telcoEverythingInPlan:    String { "このプランの内容" }
    var telcoCompareOtherPlans:   String { "他のプランと比較" }
    var telcoPortInTitle:         String { "他社からの乗り換えをお考えですか？" }
    var telcoPortInBody:          String { "3営業日で番号ポータビリティに対応。24ヶ月契約でのMNP転入で¥3,000クレジットをプレゼント。" }
    var telcoPortInNow:           String { "今すぐ乗り換え" }
    var telcoFAQTitle:            String { "よくある質問" }
    var telcoFAQ1Q:               String { "今の電話番号を引き継げますか？" }
    var telcoFAQ1A:               String { "はい、番号ポータビリティに対応しています。転入には3営業日かかります。" }
    var telcoFAQ2Q:               String { "契約期間終了後はどうなりますか？" }
    var telcoFAQ2A:               String { "同じ料金で月ごとの自動更新となります。30日前の通知でいつでもキャンセル可能です。" }
    var telcoFAQ3Q:               String { "このプランで5Gは使えますか？" }
    var telcoFAQ3A:               String { "5GはバリュープラスInfinite、Blackプランに含まれます。主要駅、都市部、大型商業施設でカバーされています。" }
    var telcoFAQ4Q:               String { "eSIMのアクティベーション方法は？" }
    var telcoFAQ4A:               String { "CSQモバイルアプリをダウンロードし、eSIMセットアップからメールのQRコードをスキャンしてください。すぐに有効化されます。" }
    var telcoPerMonth:            String { "/月" }
    func telcoSignUpFor(_ name: String) -> String { "\(name)に申し込む" }
    var telcoViewDetails:         String { "詳細を見る" }

    // Telco — Purchase Funnel (device detail + financing)
    var telcoColorLabel:       String { "カラー" }
    var telcoStorageLabel:     String { "ストレージ" }
    var telcoContinue:         String { "次へ" }
    var telcoFinancingTitle:   String { "お支払い方法を選択" }
    var telcoInstallmentLabel: String { "24回分割払い" }
    var telcoInstallmentSub:   String { "頭金なし・24回に分けてお支払い" }
    var telcoOutrightLabel:    String { "一括払い" }
    var telcoOutrightSub:      String { "一回のお支払いで本日から利用可能" }
    var telcoAttachPlanTitle:  String { "モバイルプランを追加(任意)" }
    var telcoContinueCheckout: String { "購入手続きへ" }
    var telcoDueToday:         String { "本日のお支払い" }
    var telcoMonthlyLabel:     String { "月額" }

    // Telco — Plan Signup
    var telcoSignupTitle:      String { "プランの設定" }
    var telcoSimTypeTitle:     String { "SIMタイプを選択" }
    var telcoESIMLabel:        String { "eSIM" }
    var telcoESIMSub:          String { "物理SIM不要・即時開通" }
    var telcoPhysicalSIMLabel: String { "物理SIM" }
    var telcoPhysicalSIMSub:   String { "ご自宅へ配送" }
    var telcoNumberTitle:      String { "電話番号" }
    var telcoNewNumberLabel:   String { "新規番号" }
    var telcoNewNumberSub:     String { "新しいCSQMobile番号を取得" }
    var telcoKeepNumberLabel:  String { "番号そのまま" }
    var telcoKeepNumberSub:    String { "現在の通信会社から乗り換え(MNP)" }

    // Telco — Checkout
    var telcoCheckoutTitle:    String { "購入手続き" }
    var telcoOrderSummary:     String { "ご注文内容" }
    var telcoFulfillmentTitle: String { "受け取り方法" }
    var telcoFulfillmentESIM:  String { "eSIM(即時開通)" }
    var telcoFulfillmentDelivery: String { "自宅配送(1〜2営業日)" }
    var telcoFulfillmentPickup: String { "店舗で受け取り" }
    var telcoYourDetailsTitle: String { "お客様情報" }
    var telcoFieldName:        String { "氏名" }
    var telcoFieldID:          String { "マイナンバー / 在留カード番号" }
    var telcoFieldEmail:       String { "メールアドレス" }
    var telcoFieldAddress:     String { "お届け先住所" }
    var telcoPaymentTitle:     String { "お支払い方法" }
    var telcoPayCard:          String { "クレジット / デビットカード" }
    var telcoPayWallet:        String { "PayPay" }
    var telcoFieldCardNumber:  String { "カード番号" }
    var telcoContinueVerify:   String { "本人確認へ進む" }

    // Telco — Credit / ID Check
    var telcoCreditTitle:      String { "与信・本人確認" }
    var telcoCreditBody:       String { "契約回線の開通前に、簡単な与信および本人確認を行います。通常数秒で完了します。" }
    var telcoCreditConsent:    String { "与信および本人確認に同意します" }
    var telcoRunCheck:         String { "審査を実行" }
    var telcoChecking:         String { "確認中…" }
    var telcoCreditApproved:   String { "承認されました" }
    var telcoCreditApprovedSub:String { "準備完了です。下記からご注文を確定してください。" }
    var telcoPlaceOrder:       String { "注文を確定" }

    // Telco — Order Confirmed
    var telcoOrderConfirmedTitle: String { "ご注文ありがとうございます！" }
    var telcoOrderConfirmedSub:   String { "確認メールと領収書をお送りしました。" }
    var telcoESIMReady:           String { "eSIMの準備ができました" }
    var telcoScanToActivate:      String { "QRコードをスキャンして開通してください" }
    var telcoOrderNumberLabel:    String { "注文番号" }
    var telcoBackToMobile:        String { "CSQMobileに戻る" }
    var telcoCreditDeclined:      String { "分割払いの審査が承認されませんでした" }
    var telcoCreditDeclinedSub:   String { "この端末の分割払いは現在ご利用いただけません。一括払いでのご購入は可能です。" }
    var telcoSwitchOutright:      String { "一括払いに変更" }

    // Grocery — Cart
    var cartExpressDelivery:      String { "速達配送 · **45分**で到着予定" }
    var cartEnterPromo:           String { "プロモコードを入力" }
    var cartApply:                String { "適用" }
    var cartInvalidPromo:         String { "無効なプロモコードです。ご確認の上、再度入力してください。" }
    var cartOrderSummary:         String { "注文内容" }
    var cartDeliveryFee:          String { "配送料" }
    var cartServiceFee:           String { "サービス料" }
    var cartPromoDiscount:        String { "割引" }
    var cartTotal:                String { "合計" }
    var cartProceedCheckout:      String { "レジへ進む" }
    func cartSubtotal(_ count: Int) -> String { "商品 \(count)点" }
    var cartEach:                 String { "各" }
    var cartNavTitle:             String { "カート" }
    var cartClearButton:          String { "クリア" }
    var cartEmptyTitle:           String { "カートは空です" }
    var cartEmptySubtitle:        String { "CSQマートから商品を追加してください" }
    var cartStartShopping:        String { "ショッピングを始める" }

    // Grocery — Checkout
    var checkoutTitle:            String { "チェックアウト" }
    var checkoutDeliveryAddress:  String { "配送先住所" }
    var checkoutHome:             String { "自宅" }
    var checkoutHomeAddress:      String { "東京都渋谷区神南1丁目19-14" }
    var checkoutChange:           String { "変更" }
    var checkoutLeaveAtDoor:      String { "不在の場合はドア前に置いてください" }
    var checkoutAddInstructions:  String { "配送指示を追加..." }
    var checkoutDeliverySlot:     String { "配送時間" }
    var checkoutPayment:          String { "お支払い" }
    var checkoutPlacingOrder:     String { "注文中..." }
    var checkoutPlaceOrder:       String { "注文する · " }

    // Grocery — Order Confirmation
    var orderPlaced:              String { "注文完了！" }
    var orderGroceriesPrepared:   String { "食料品の準備をしています" }
    var orderNumber:              String { "注文番号" }
    var orderEstimatedArrival:    String { "到着予定" }
    var orderProgress:            String { "注文状況" }
    var orderStepConfirmed:       String { "注文確認済み" }
    var orderStepPacked:          String { "梱包中" }
    var orderStepOutForDelivery:  String { "配達中" }
    var orderStepDelivered:       String { "配達完了" }
    var orderInProgress:          String { "進行中..." }
    var orderCompleted:           String { "完了" }
    var orderDeliveryPartner:     String { "配達担当者" }
    var orderDeliveryInfo:        String { "自転車 · 2.1km先" }
    var orderTrackLiveMap:        String { "地図でリアルタイム追跡" }
    var orderReorder:             String { "再注文" }
    var orderShare:               String { "共有" }
    var riderFindingPartner:      String { "配達パートナーを探しています" }
    var riderFindingSubtitle:     String { "近くのライダーをマッチングしています。\n通常は数秒で完了します。" }
    var riderCancelOrder:         String { "注文をキャンセル" }
    var riderEstimatedArrival:    String { "到着予定時間" }
    var riderLiveBadge:           String { "ライブ" }
    var riderSafetyTools:         String { "安全ツール" }

    // Grocery — Product Detail
    var productInStock:           String { "在庫あり" }
    var productOutOfStock:        String { "在庫なし" }
    var productDescriptionTab:    String { "説明" }
    var productNutritionTab:      String { "栄養成分" }
    var productReviewsTab:        String { "レビュー" }
    var productQuantity:          String { "数量" }
    var productTotal:             String { "合計" }
    var productAddToCart:         String { "カートに追加" }
    var productAddedToCart:       String { "カートに追加しました！" }
    var productNutritionTitle:    String { "栄養成分表示" }
    var productServingSize:       String { "1食分あたり（100g）" }
    var productReviewsCount:      String { "件のレビュー" }

    // Grocery — Meat Category
    var meatFreshDaily:           String { "毎日新鮮" }
    var meatButcherTitle:         String { "精肉コーナー" }
    var meatSubtitle:             String { "厳選カット • 毎日新鮮 • ご自宅にお届け" }
    var meatItemsCount:           String { "点" }
    var meatEmptyState:           String { "このカテゴリに商品はありません" }
    var meatButcherTipTitle:      String { "精肉のヒント" }
    var meatButcherTipBody:       String { "牛肉と羊肉はすべてMSAグレード認定済みで、柔らかさが保証されています。プレミアムカットのマーブルスコアをご確認ください。スコア3以上でレストラン品質のお肉が楽しめます。" }
    var meatViewCart:             String { "カートを見る" }
    var meatSortFeatured:         String { "おすすめ" }
    var meatSortPriceLow:         String { "価格：安い順" }
    var meatSortPriceHigh:        String { "価格：高い順" }
    var meatSortTopRated:         String { "評価が高い順" }

    // Food — Restaurant Detail / Order
    var foodAddItemsToStart:      String { "注文するには商品を追加してください" }
    var foodViewCart:             String { "カートを見る" }
    func foodItemsTotal(_ count: Int, _ currency: String, _ amount: String) -> String {
        "\(count)点 — \(currency)\(amount)"
    }
    var foodYourOrder:            String { "ご注文内容" }
    var foodOrderSummary:         String { "注文概要" }
    var foodDeliveryAddress:      String { "配達住所" }
    var foodHomeAddress:          String { "東京都渋谷区神南1丁目19-14" }
    var foodChange:               String { "変更" }
    var foodPayment:              String { "お支払い" }
    var foodPromoCode:            String { "プロモコード" }
    var foodAddPromoCode:         String { "プロモコードを追加" }
    var foodEnterCode:            String { "コードを入力" }
    var foodApply:                String { "適用" }
    var foodYouMightLike:         String { "こちらもおすすめ" }
    var foodSubtotal:             String { "小計" }
    var foodDeliveryFee:          String { "配送料" }
    var foodFree:                 String { "無料" }
    var foodPlatformFee:          String { "プラットフォーム手数料" }
    var foodTotal:                String { "合計" }
    var foodPlacingOrder:         String { "注文中..." }
    var foodPlaceOrder:           String { "注文する" }
    var foodSomethingWentWrong:   String { "エラーが発生しました。もう一度お試しください。" }
    var foodOrderConfirmedTitle:  String { "注文確定" }
    func foodOrderFromRestaurant(_ name: String) -> String { "\(name)のご注文を準備中です" }
    var foodEstimatedArrival:     String { "到着予定" }
    var foodOrderTotal:           String { "注文合計" }
    var foodLiveTracking:         String { "リアルタイム追跡" }
    var foodStepReceived:         String { "注文受付" }
    var foodStepPreparing:        String { "準備中" }
    var foodStepOnTheWay:         String { "配達中" }
    var foodStepDelivered:        String { "配達完了" }
    var foodDeliveryNote:         String { "不在時はドア前に置くか、ベルを押してください。" }
    var foodTrackMyOrder:         String { "注文を追跡" }
    var foodBackToFood:           String { "CSQフードに戻る" }
    var foodOrderConfirmed:       String { "注文が確定しました！" }

    // Cash — Send Money
    var cashSendMoneyTitle:       String { "送金" }
    var cashCancelButton:         String { "キャンセル" }
    var cashTabContacts:          String { "連絡先" }
    var cashTabTransfer:          String { "振込" }
    var cashTabOverseas:          String { "海外送金" }
    var cashAvailablePrefix:      String { "残高：" }
    var cashSendVia:              String { "送金方法" }
    var cashPhoneLabel:           String { "電話番号" }
    var cashEmailLabel:           String { "メール" }
    var cashBankAcctLabel:        String { "銀行口座" }
    var cashPhoneNumber:          String { "電話番号" }
    var cashEmailAddress:         String { "メールアドレス" }
    var cashBankAccountNo:        String { "口座番号" }
    var cashPhonePlaceholder:     String { "+81 XX-XXXX-XXXX" }
    var cashBankAcctPlaceholder:  String { "口座番号" }
    var cashAddNote:              String { "メモを追加（任意）" }
    var cashSendMoneyButton:      String { "送金する" }
    var cashSendInternational:    String { "海外送金する" }
    var cashDestCountry:          String { "送金先の国" }
    var cashRecipientDetails:     String { "受取人情報" }
    var cashTransferDetails:      String { "送金詳細" }
    var cashAmountIn:             String { "金額（SGD）" }
    var cashTransferPurpose:      String { "目的" }
    var cashYouSend:              String { "送金額" }
    var cashTransferFee:          String { "送金手数料" }
    var cashTotalDeducted:        String { "合計引落額" }
    var cashExchangeRate:         String { "為替レート" }
    var cashRecipientGets:        String { "受取金額" }
    var cashSelectCountry:        String { "国を選択" }
    var cashDoneButton:           String { "完了" }
    var cashLastAmount:           String { "前回：" }
    var cashBalanceAfter:         String { "残高（送金後）：" }
    var cashConfirmSend:          String { "送金を確認" }
    var cashInternationalTransfer: String { "海外送金" }
    var cashSendMoneyConfirmTitle: String { "送金" }
    // Cash — Add/Withdraw
    var cashAddFundsTitle:        String { "チャージ" }
    var cashWithdrawTitle:        String { "引き出し" }
    var cashAddFundsHeader:       String { "ウォレットにチャージ" }
    var cashWithdrawHeader:       String { "ウォレットから引き出し" }
    var cashInstantFromBank:      String { "銀行から即時振込" }
    var cashTransferToBank:       String { "連携銀行口座に振込" }
    var cashWalletBalance:        String { "ウォレット残高" }
    var cashAfterAdding:          String { "チャージ後" }
    var cashAfterWithdrawal:      String { "引き出し後" }
    var cashSelectAmount:         String { "金額を選択" }
    var cashCustomAmount:         String { "金額を入力" }
    var cashFromAccount:          String { "引き落とし口座" }
    var cashToAccountLabel:       String { "振込先口座" }
    var cashInstantProcessing:    String { "即時処理 · すぐに利用可能" }
    var cashNoFees:               String { "手数料無料" }
    var cashInsufficientBalance:  String { "残高不足" }
    var cashConfirmTopUp:         String { "チャージを確認" }
    var cashConfirmWithdrawal:    String { "引き出しを確認" }
    var cashConfirmButton:        String { "確認" }
    func cashAddAmount(_ amount: String) -> String { "¥\(amount)チャージ" }
    func cashWithdrawAmount(_ amount: String) -> String { "¥\(amount)引き出し" }
    func cashFromAccount2(_ bank: String) -> String { "\(bank)から" }
    func cashToAccount2(_ bank: String) -> String { "\(bank)へ" }
    // Cash — QR Scanner
    var cashScanToPayTitle:       String { "スキャンして支払う" }
    var cashPointCamera:          String { "QRコードにカメラを向けてください" }
    var cashQRSupports:           String { "PayPay、JPQR、CSQキャッシュのQRコードに対応" }
    var cashDemoScan:             String { "デモ：QRスキャンを試す" }
    var cashCameraDenied:         String { "カメラのアクセスが拒否されました。設定から許可するかデモスキャンをご利用ください。" }
    var cashCancelPayment:        String { "キャンセル" }
    var cashBalanceAfterPayment:  String { "支払い後残高：" }
    func cashPayAmount(_ amount: String) -> String { "¥\(amount)支払う" }
}

// MARK: - Market Content
// All market-specific data. Views pull from this instead of hardcoded static arrays.

struct MarketContent {
    let locations:          [Location]
    let rideOptions:        [RideOption]
    let driver:             Driver
    let rideHistory:        [RideHistoryItem]
    let nearbyRestaurants:  [NearbyRestaurant]
    let deals:              [HomeDeal]
    let promos:             [HomePromo]
    let recentActivity:     [HomeActivity]
    let paymentMethods:     [RidePaymentMethod]

    // MARK: Singapore
    static let singapore = MarketContent(
        locations: [
            Location(name: "Home",                address: "Toa Payoh HDB Hub, 480 Lor 6 Toa Payoh, 310480",    iconName: "house.fill"),
            Location(name: "Capitol Tower",        address: "168 Robinson Rd, Singapore 068912",                  iconName: "building.2.fill"),
            Location(name: "Changi Airport T3",    address: "Airport Blvd, Singapore 819830",                     iconName: "airplane"),
            Location(name: "Woodlands Ave",        address: "30 Woodlands Ave 2, Singapore 738343",               iconName: "mappin.fill"),
            Location(name: "Resorts World Sentosa",address: "8 Sentosa Gateway, Singapore 098269",                iconName: "star.fill"),
            Location(name: "Marina Bay Sands",     address: "10 Bayfront Ave, Singapore 018956",                  iconName: "building.columns.fill"),
            Location(name: "Peranakan Place",      address: "180 Orchard Rd, Singapore 238851",                   iconName: "house.and.flag.fill"),
            Location(name: "Haji Lane",            address: "Haji Lane, Kampong Glam, Singapore 189225",          iconName: "fork.knife"),
        ],
        rideOptions: [
            RideOption(name: "CSQRide",    subtitle: "Affordable everyday rides",               iconName: "car.fill",                  price: 8.50,   eta: 4,  capacity: 4, color: .csqPrimary,          badge: nil,       badgeColor: .csqRideBlue,          isHorse: false),
            RideOption(name: "CSQXpress",  subtitle: "Fast pickup, no detours",                 iconName: "bolt.car.fill",             price: 11.00,  eta: 2,  capacity: 4, color: .csqRideBlue,         badge: "FAST",    badgeColor: .csqRideBlue,          isHorse: false),
            RideOption(name: "CSQBlack",   subtitle: "Premium comfort rides",                   iconName: "car.fill",                  price: 18.75,  eta: 7,  capacity: 4, color: Color(hex: "#1C1C2E"),badge: nil,       badgeColor: .csqRideBlue,          isHorse: false),
            RideOption(name: "CSQ Tank",   subtitle: "Military-grade ground transport",           iconName: "shield.fill",               price: 249.99, eta: 45, capacity: 1, color: Color(hex: "#5C6B2E"),
                       disclaimer: "* Commander must clear own route · 3.2m clearance required · Tolls extra", badge: "ARMORED", badgeColor: Color(hex: "#5C6B2E"), isHorse: false, priceColor: .csqWarning),
            RideOption(name: "CSQ Horse",  subtitle: "Eco-friendly. Hay-powered. Zero emissions.", iconName: "figure.equestrian.sports", price: 4.20,   eta: 25, capacity: 1, color: Color(hex: "#8B5E3C"),
                       disclaimer: "* Hay included · ETA subject to horse's mood · No refunds if horse",        badge: "ECO",     badgeColor: .csqSuccess,           isHorse: true,  priceColor: .csqSuccess),
        ],
        driver: Driver(name: "Raj S.", rating: 4.9, trips: 2847, plateNumber: "SJD 9821 B", carModel: "Toyota Camry", carColor: "Silver", avatarInitials: "RS"),
        rideHistory: [
            RideHistoryItem(rideType: "CSQRide",   destination: "Capitol Tower, Robinson Rd", date: "Today, 8:42 AM",   fare: "S$9.20",  status: "Completed", iconName: "car.fill",      statusColor: .csqSuccess),
            RideHistoryItem(rideType: "CSQBlack",  destination: "Changi Airport T3",          date: "Apr 3, 6:15 AM",   fare: "S$22.50", status: "Completed", iconName: "car.fill",      statusColor: .csqSuccess),
            RideHistoryItem(rideType: "CSQXpress", destination: "Marina Bay Sands",           date: "Mar 29, 2:30 PM",  fare: "S$14.00", status: "Completed", iconName: "bolt.car.fill", statusColor: .csqSuccess),
            RideHistoryItem(rideType: "CSQRide",   destination: "Orchard MRT",                date: "Mar 27, 9:00 AM",  fare: "S$7.80",  status: "Cancelled", iconName: "car.fill",      statusColor: .csqError),
            RideHistoryItem(rideType: "CSQRide",   destination: "Home — Toa Payoh",           date: "Mar 25, 11:45 PM", fare: "S$11.30", status: "Completed", iconName: "car.fill",      statusColor: .csqSuccess),
        ],
        nearbyRestaurants: [
            NearbyRestaurant(name: "Lau Pa Sat",          imageName: "FoodLauPaSat",    cuisine: "Hawker · Mixed",        rating: "4.8", deliveryTime: "15–25 min", deliveryFee: "Free",   tag: "Popular",  color: .csqFoodOrange),
            NearbyRestaurant(name: "Birds of Paradise",   imageName: "FoodBirds",       cuisine: "Gelato · Desserts",     rating: "4.9", deliveryTime: "20–30 min", deliveryFee: "S$1.99", tag: "Trending", color: Color(hex: "#F472B6")),
            NearbyRestaurant(name: "The Coconut Club",    imageName: "FoodCoconutClub", cuisine: "Nasi Lemak · Local",    rating: "4.8", deliveryTime: "15–20 min", deliveryFee: "Free",   tag: "Nearby",   color: .csqGroceryGreen),
            NearbyRestaurant(name: "Jumbo Seafood",       imageName: "FoodJumbo",       cuisine: "Seafood · Chilli Crab", rating: "4.6", deliveryTime: "25–35 min", deliveryFee: "S$1.99", tag: "Must Try", color: .csqRideBlue),
            NearbyRestaurant(name: "Ya Kun Kaya Toast",   imageName: "",                cuisine: "Breakfast · Local",     rating: "4.5", deliveryTime: "10–15 min", deliveryFee: "Free",   tag: "Quick",    color: .csqWarning),
            NearbyRestaurant(name: "Odette",              imageName: "FoodOdette",      cuisine: "French · Fine Dining",  rating: "4.7", deliveryTime: "30–40 min", deliveryFee: "S$2.99", tag: "Premium",  color: Color(hex: "#6366F1")),
        ],
        deals: [
            HomeDeal(title: "S$5 off your next CSQRide",    merchant: "Weekday CBD special",              badge: "S$5 OFF",  expiry: "Today only",    color: .csElectricBlue,      icon: "car.fill"),
            HomeDeal(title: "Free delivery — Hawker Night", merchant: "CSQFood — orders after 6pm",       badge: "FREE DEL", expiry: "Tonight",       color: .csCoral,             icon: "fork.knife"),
            HomeDeal(title: "15% off data top-up",          merchant: "CSQMobile prepaid SIM",            badge: "15% OFF",  expiry: "5 days left",   color: .csqTelcoTeal,        icon: "simcard.fill"),
            HomeDeal(title: "Kopi + Kaya Toast deal",       merchant: "Ya Kun · Toa Payoh & CBD outlets", badge: "S$4.50",   expiry: "Weekend only",  color: Color(hex: "#92400E"),icon: "cup.and.saucer.fill"),
            HomeDeal(title: "National Day bonus points",    merchant: "CSQRewards — 3x pts this Aug",     badge: "3x PTS",   expiry: "Aug 9 only",    color: Color(hex: "#CD3246"),icon: "rosette"),
        ],
        promos: [
            HomePromo(headline: "Ride anywhere in Singapore — up to S$10 off", sub: "Weekend promo for CBD commuters",           color: .csElectricBlue,  icon: "car.fill",          imageName: "PromoRide",     logoName: ""),
            HomePromo(headline: "Hawker Heroes: free delivery all week",        sub: "Ya Kun, Coconut Club & more",              color: .csCoral,         icon: "fork.knife",        imageName: "PromoHawker",   logoName: ""),
            HomePromo(headline: "CSQBlack — lah, ride in style from S$18.75",  sub: "Leather seats, top-rated drivers",         color: .csDeepNavy,      icon: "star.fill",         imageName: "PromoBlack",    logoName: ""),
            HomePromo(headline: "Double points every Tuesday, can?",            sub: "CSQRewards Gold — 2x pts on all services", color: .csElectricBlue,  icon: "gift.fill",         imageName: "",              logoName: ""),
            HomePromo(headline: "Refer kawan, both save S$15",                  sub: "Share your referral code — limited time",  color: Color(hex: "#004C3D"), icon: "person.badge.plus", imageName: "PromoReferral", logoName: ""),
            HomePromo(headline: "CSQMobile — stay connected from S$18/mo",     sub: "5G network across Singapore",              color: .csqTelcoTeal,    icon: "simcard.fill",      imageName: "PromoMobile",   logoName: ""),
        ],
        recentActivity: [
            HomeActivity(icon: "car.fill",      iconColor: .csqRideBlue,          title: "Capitol Tower, Robinson Rd", subtitle: "CSQRide · Today, 8:42 AM · S$9.20",     status: "Completed"),
            HomeActivity(icon: "car.fill",      iconColor: Color(hex: "#1C1C2E"), title: "Changi Airport T3",          subtitle: "CSQBlack · Apr 3, 6:15 AM · S$38.50",   status: "Completed"),
            HomeActivity(icon: "bolt.car.fill", iconColor: .csqRideBlue,          title: "Sentosa Island",             subtitle: "CSQXpress · Mar 29, 2:30 PM · S$14.00", status: "Completed"),
            HomeActivity(icon: "cart.fill",     iconColor: .csqGroceryGreen,      title: "CSQMart — Grocery order",   subtitle: "S$47.80 · Mar 27 · 8 items",            status: "Delivered"),
        ],
        paymentMethods: [.payNow, .visa, .mastercard, .amex]
    )

    // MARK: Tokyo
    static let tokyo = MarketContent(
        locations: [
            Location(name: "自宅",                 address: "東京都渋谷区神南1丁目19-14",              iconName: "house.fill"),
            Location(name: "新宿駅",                address: "東京都新宿区新宿3丁目38-1",              iconName: "tram.fill"),
            Location(name: "羽田空港 第2ターミナル",   address: "東京都大田区羽田空港2丁目6-5",           iconName: "airplane"),
            Location(name: "東京タワー",              address: "東京都港区芝公園4丁目2-8",              iconName: "building.2.fill"),
            Location(name: "渋谷スクランブル交差点",   address: "東京都渋谷区道玄坂2丁目1",              iconName: "mappin.fill"),
            Location(name: "東京ディズニーランド",     address: "千葉県浦安市舞浜1-1",                   iconName: "star.fill"),
            Location(name: "秋葉原",                 address: "東京都千代田区外神田1丁目",              iconName: "bolt.fill"),
            Location(name: "六本木ヒルズ",            address: "東京都港区六本木6丁目10-1",             iconName: "building.columns.fill"),
        ],
        rideOptions: [
            RideOption(name: "CSQライド",      subtitle: "日常のお手頃乗車",                    iconName: "car.fill",                  price: 850,   eta: 4,  capacity: 4, color: .csqPrimary,          badge: nil,   badgeColor: .csqRideBlue,          isHorse: false),
            RideOption(name: "CSQエクスプレス", subtitle: "速達、迂回なし",                     iconName: "bolt.car.fill",             price: 1100,  eta: 2,  capacity: 4, color: .csqRideBlue,         badge: "速達", badgeColor: .csqRideBlue,          isHorse: false),
            RideOption(name: "CSQブラック",    subtitle: "プレミアムコンフォート",               iconName: "car.fill",                  price: 1875,  eta: 7,  capacity: 4, color: Color(hex: "#1C1C2E"),badge: nil,   badgeColor: .csqRideBlue,          isHorse: false),
            RideOption(name: "CSQ 戦車",       subtitle: "軍用グレードの地上輸送",               iconName: "shield.fill",               price: 24999, eta: 45, capacity: 1, color: Color(hex: "#5C6B2E"),
                       disclaimer: "* 指揮官は自ら経路を確保 · 高さ3.2m必要 · 通行料別途",      badge: "装甲", badgeColor: Color(hex: "#5C6B2E"), isHorse: false, priceColor: .csqWarning),
            RideOption(name: "CSQ 馬車",       subtitle: "エコフレンドリー。馬力駆動。ゼロ排出。", iconName: "figure.equestrian.sports", price: 420,   eta: 25, capacity: 1, color: Color(hex: "#8B5E3C"),
                       disclaimer: "* 干し草込み · 馬の機嫌による · 返金不可（馬の場合）",       badge: "エコ", badgeColor: .csqSuccess,           isHorse: true,  priceColor: .csqSuccess),
        ],
        driver: Driver(name: "田中 浩二", rating: 4.9, trips: 3241, plateNumber: "練馬 301 あ 12-34", carModel: "Toyota Prius", carColor: "ホワイト", avatarInitials: "田"),
        rideHistory: [
            RideHistoryItem(rideType: "CSQライド",      destination: "渋谷センタービル",         date: "今日 8:42",      fare: "¥920",   status: "完了",      iconName: "car.fill",      statusColor: .csqSuccess),
            RideHistoryItem(rideType: "CSQブラック",    destination: "羽田空港 第2ターミナル",    date: "4月3日 6:15",    fare: "¥3,850", status: "完了",      iconName: "car.fill",      statusColor: .csqSuccess),
            RideHistoryItem(rideType: "CSQエクスプレス", destination: "お台場",                   date: "3月29日 14:30",  fare: "¥1,400", status: "完了",      iconName: "bolt.car.fill", statusColor: .csqSuccess),
            RideHistoryItem(rideType: "CSQライド",      destination: "新宿駅",                   date: "3月27日 9:00",   fare: "¥780",   status: "キャンセル", iconName: "car.fill",      statusColor: .csqError),
            RideHistoryItem(rideType: "CSQライド",      destination: "自宅 — 渋谷",              date: "3月25日 23:45",  fare: "¥1,130", status: "完了",      iconName: "car.fill",      statusColor: .csqSuccess),
        ],
        nearbyRestaurants: [
            NearbyRestaurant(name: "一風堂",        imageName: "", cuisine: "ラーメン · 博多豚骨", rating: "4.8", deliveryTime: "15〜25分", deliveryFee: "無料",  tag: "人気",     color: .csqFoodOrange),
            NearbyRestaurant(name: "すきやばし次郎", imageName: "", cuisine: "寿司 · 高級",       rating: "4.9", deliveryTime: "30〜40分", deliveryFee: "¥299", tag: "話題",     color: Color(hex: "#F472B6")),
            NearbyRestaurant(name: "天ぷら近藤",    imageName: "", cuisine: "天ぷら · 和食",      rating: "4.8", deliveryTime: "20〜30分", deliveryFee: "無料",  tag: "近く",     color: .csqGroceryGreen),
            NearbyRestaurant(name: "焼肉叙々苑",   imageName: "", cuisine: "焼肉 · 和牛",        rating: "4.7", deliveryTime: "25〜35分", deliveryFee: "¥199", tag: "必食",     color: .csqRideBlue),
            NearbyRestaurant(name: "吉野家",        imageName: "", cuisine: "牛丼 · ファスト",    rating: "4.3", deliveryTime: "10〜15分", deliveryFee: "無料",  tag: "速い",     color: .csqWarning),
            NearbyRestaurant(name: "銀座久兵衛",   imageName: "", cuisine: "寿司 · 銀座",        rating: "4.8", deliveryTime: "30〜45分", deliveryFee: "¥399", tag: "プレミアム", color: Color(hex: "#6366F1")),
        ],
        deals: [
            HomeDeal(title: "次のCSQライドで500円オフ", merchant: "平日都心特別割引",              badge: "500円OFF", expiry: "本日限り",   color: .csElectricBlue,      icon: "car.fill"),
            HomeDeal(title: "夜のラーメン配達無料",     merchant: "CSQフード — 18時以降のご注文",   badge: "配送無料",  expiry: "今夜",      color: .csCoral,             icon: "fork.knife"),
            HomeDeal(title: "データチャージ15%オフ",    merchant: "CSQモバイル プリペイドSIM",      badge: "15% OFF",  expiry: "残り5日",   color: .csqTelcoTeal,        icon: "simcard.fill"),
            HomeDeal(title: "コーヒーセット特別価格",   merchant: "スターバックス · 全国店舗",       badge: "¥850",     expiry: "週末限定",  color: Color(hex: "#92400E"),icon: "cup.and.saucer.fill"),
            HomeDeal(title: "山の日ボーナスポイント",   merchant: "CSQリワーズ — 3x pts",          badge: "3x PTS",   expiry: "8月11日のみ", color: Color(hex: "#CD3246"),icon: "rosette"),
        ],
        promos: [
            HomePromo(headline: "東京どこでも乗車 — 最大1,000円オフ",      sub: "平日の都心通勤に",                        color: .csElectricBlue,       icon: "car.fill",          imageName: "PromoRide",     logoName: ""),
            HomePromo(headline: "ラーメン英雄: 今週は送料無料",              sub: "一風堂、博多一幡など",                    color: .csCoral,              icon: "fork.knife",        imageName: "PromoHawker",   logoName: ""),
            HomePromo(headline: "CSQブラック — 1,875円から快適乗車",        sub: "本革シート、高評価ドライバー",             color: .csDeepNavy,           icon: "star.fill",         imageName: "PromoBlack",    logoName: ""),
            HomePromo(headline: "毎週火曜日はダブルポイント",                sub: "CSQリワーズゴールド — 全サービス2x pt",   color: .csElectricBlue,       icon: "gift.fill",         imageName: "",              logoName: ""),
            HomePromo(headline: "友達紹介で1,500円オフ",                    sub: "紹介コードをシェア — 期間限定",           color: Color(hex: "#004C3D"), icon: "person.badge.plus", imageName: "PromoReferral", logoName: ""),
            HomePromo(headline: "CSQモバイル — 月額1,800円から",            sub: "5Gネットワーク — 東京全域対応",           color: .csqTelcoTeal,         icon: "simcard.fill",      imageName: "PromoMobile",   logoName: ""),
        ],
        recentActivity: [
            HomeActivity(icon: "car.fill",      iconColor: .csqRideBlue,          title: "渋谷センタービル",      subtitle: "CSQライド · 今日 8:42 · ¥920",          status: "完了"),
            HomeActivity(icon: "car.fill",      iconColor: Color(hex: "#1C1C2E"), title: "羽田空港 第2ターミナル", subtitle: "CSQブラック · 4月3日 6:15 · ¥3,850",    status: "完了"),
            HomeActivity(icon: "bolt.car.fill", iconColor: .csqRideBlue,          title: "お台場",               subtitle: "CSQエクスプレス · 3月29日 14:30 · ¥1,400", status: "完了"),
            HomeActivity(icon: "cart.fill",     iconColor: .csqGroceryGreen,      title: "CSQマート — 食料品注文", subtitle: "¥4,780 · 3月27日 · 8点",               status: "配達済み"),
        ],
        paymentMethods: [.payPay, .suica, .visa, .mastercard, .amex]
    )

    // MARK: Sydney
    static let sydney = MarketContent(
        locations: [
            Location(name: "Home",                 address: "12 Crown St, Surry Hills, Sydney NSW 2010",    iconName: "house.fill"),
            Location(name: "Town Hall",             address: "483 George St, Sydney NSW 2000",               iconName: "building.2.fill"),
            Location(name: "Sydney Airport T1",     address: "Departure Plaza, Mascot NSW 2020",             iconName: "airplane"),
            Location(name: "Bondi Beach",           address: "Campbell Parade, Bondi Beach NSW 2026",        iconName: "mappin.fill"),
            Location(name: "Sydney Opera House",    address: "Bennelong Point, Sydney NSW 2000",             iconName: "star.fill"),
            Location(name: "Darling Harbour",       address: "Darling Dr, Sydney NSW 2000",                  iconName: "building.columns.fill"),
            Location(name: "The Rocks",             address: "Playfair St, The Rocks NSW 2000",              iconName: "house.and.flag.fill"),
            Location(name: "Surry Hills",           address: "Crown St, Surry Hills NSW 2010",               iconName: "fork.knife"),
        ],
        rideOptions: [
            RideOption(name: "CSQRide",    subtitle: "Affordable everyday rides",                 iconName: "car.fill",                  price: 8.50,   eta: 4,  capacity: 4, color: .csqPrimary,          badge: nil,       badgeColor: .csqRideBlue,          isHorse: false),
            RideOption(name: "CSQXpress",  subtitle: "Fast pickup, no detours",                   iconName: "bolt.car.fill",             price: 11.00,  eta: 2,  capacity: 4, color: .csqRideBlue,         badge: "FAST",    badgeColor: .csqRideBlue,          isHorse: false),
            RideOption(name: "CSQBlack",   subtitle: "Premium comfort rides",                     iconName: "car.fill",                  price: 18.75,  eta: 7,  capacity: 4, color: Color(hex: "#1C1C2E"),badge: nil,       badgeColor: .csqRideBlue,          isHorse: false),
            RideOption(name: "CSQ Tank",   subtitle: "Military-grade ground transport",           iconName: "shield.fill",               price: 249.99, eta: 45, capacity: 1, color: Color(hex: "#5C6B2E"),
                       disclaimer: "* Commander must clear own route · 3.2m clearance required · Tolls extra", badge: "ARMORED", badgeColor: Color(hex: "#5C6B2E"), isHorse: false, priceColor: .csqWarning),
            RideOption(name: "CSQ Horse",  subtitle: "Eco-friendly. Hay-powered. Zero emissions.", iconName: "figure.equestrian.sports", price: 4.20,   eta: 25, capacity: 1, color: Color(hex: "#8B5E3C"),
                       disclaimer: "* Hay included · ETA subject to horse's mood · No refunds if horse",        badge: "ECO",     badgeColor: .csqSuccess,           isHorse: true,  priceColor: .csqSuccess),
        ],
        driver: Driver(name: "Jack T.", rating: 4.9, trips: 2731, plateNumber: "BXR 42K", carModel: "Toyota Camry", carColor: "Silver", avatarInitials: "JT"),
        rideHistory: [
            RideHistoryItem(rideType: "CSQRide",   destination: "Town Hall, George St",   date: "Today, 8:42 AM",   fare: "A$9.20",  status: "Completed", iconName: "car.fill",      statusColor: .csqSuccess),
            RideHistoryItem(rideType: "CSQBlack",  destination: "Sydney Airport T1",      date: "Apr 3, 6:15 AM",   fare: "A$22.50", status: "Completed", iconName: "car.fill",      statusColor: .csqSuccess),
            RideHistoryItem(rideType: "CSQXpress", destination: "Darling Harbour",        date: "Mar 29, 2:30 PM",  fare: "A$14.00", status: "Completed", iconName: "bolt.car.fill", statusColor: .csqSuccess),
            RideHistoryItem(rideType: "CSQRide",   destination: "Bondi Junction",         date: "Mar 27, 9:00 AM",  fare: "A$7.80",  status: "Cancelled", iconName: "car.fill",      statusColor: .csqError),
            RideHistoryItem(rideType: "CSQRide",   destination: "Home — Surry Hills",     date: "Mar 25, 11:45 PM", fare: "A$11.30", status: "Completed", iconName: "car.fill",      statusColor: .csqSuccess),
        ],
        nearbyRestaurants: [
            NearbyRestaurant(name: "Bills Surry Hills",       imageName: "", cuisine: "Brunch · Cafe",                 rating: "4.8", deliveryTime: "15–25 min", deliveryFee: "Free",   tag: "Popular",  color: .csqFoodOrange),
            NearbyRestaurant(name: "Gelato Messina",          imageName: "", cuisine: "Gelato · Desserts",             rating: "4.9", deliveryTime: "20–30 min", deliveryFee: "A$1.99", tag: "Trending", color: Color(hex: "#F472B6")),
            NearbyRestaurant(name: "Chat Thai",               imageName: "", cuisine: "Thai · Local",                  rating: "4.7", deliveryTime: "15–20 min", deliveryFee: "Free",   tag: "Nearby",   color: .csqGroceryGreen),
            NearbyRestaurant(name: "The Rocks Cafe",          imageName: "", cuisine: "Seafood · Modern Australian",   rating: "4.6", deliveryTime: "25–35 min", deliveryFee: "A$1.99", tag: "Must Try", color: .csqRideBlue),
            NearbyRestaurant(name: "Harry's Cafe de Wheels",  imageName: "", cuisine: "Pies · Quick Bites",            rating: "4.5", deliveryTime: "10–15 min", deliveryFee: "Free",   tag: "Quick",    color: .csqWarning),
            NearbyRestaurant(name: "Quay",                    imageName: "", cuisine: "Fine Dining · Modern Australian", rating: "4.7", deliveryTime: "30–40 min", deliveryFee: "A$2.99", tag: "Premium",  color: Color(hex: "#6366F1")),
        ],
        deals: [
            HomeDeal(title: "A$5 off your next CSQRide",     merchant: "Weekday CBD special",              badge: "A$5 OFF",  expiry: "Today only",    color: .csElectricBlue,      icon: "car.fill"),
            HomeDeal(title: "Free delivery — Dinner Rush",   merchant: "CSQFood — orders after 6pm",       badge: "FREE DEL", expiry: "Tonight",       color: .csCoral,             icon: "fork.knife"),
            HomeDeal(title: "15% off data top-up",           merchant: "CSQMobile prepaid SIM",            badge: "15% OFF",  expiry: "5 days left",   color: .csqTelcoTeal,        icon: "simcard.fill"),
            HomeDeal(title: "Flat white + brekkie pastry",   merchant: "Bills · Surry Hills & CBD outlets", badge: "A$4.50",  expiry: "Weekend only",  color: Color(hex: "#92400E"),icon: "cup.and.saucer.fill"),
            HomeDeal(title: "Australia Day bonus points",    merchant: "CSQRewards — 3x pts this Jan",     badge: "3x PTS",   expiry: "Jan 26 only",   color: Color(hex: "#CD3246"),icon: "rosette"),
        ],
        promos: [
            HomePromo(headline: "Zip around Sydney — up to A$10 off", sub: "Weekend deal for the CBD commute",          color: .csElectricBlue,  icon: "car.fill",          imageName: "PromoRide",     logoName: ""),
            HomePromo(headline: "Local legends: free delivery all week",     sub: "Bills, Chat Thai & heaps more",                  color: .csCoral,         icon: "fork.knife",        imageName: "PromoHawker",   logoName: ""),
            HomePromo(headline: "CSQBlack — ride in style from A$18.75",    sub: "Leather seats, top-rated drivers",         color: .csDeepNavy,      icon: "star.fill",         imageName: "PromoBlack",    logoName: ""),
            HomePromo(headline: "Double points every Tuesday",              sub: "CSQRewards Gold — 2x pts on all services", color: .csElectricBlue,  icon: "gift.fill",         imageName: "",              logoName: ""),
            HomePromo(headline: "Refer a mate, both save A$15",             sub: "Share your referral code — limited time",  color: Color(hex: "#004C3D"), icon: "person.badge.plus", imageName: "PromoReferral", logoName: ""),
            HomePromo(headline: "CSQMobile — stay connected from A$18/mo",  sub: "5G network across Australia",              color: .csqTelcoTeal,    icon: "simcard.fill",      imageName: "PromoMobile",   logoName: ""),
        ],
        recentActivity: [
            HomeActivity(icon: "car.fill",      iconColor: .csqRideBlue,          title: "Town Hall, George St", subtitle: "CSQRide · Today, 8:42 AM · A$9.20",     status: "Completed"),
            HomeActivity(icon: "car.fill",      iconColor: Color(hex: "#1C1C2E"), title: "Sydney Airport T1",    subtitle: "CSQBlack · Apr 3, 6:15 AM · A$38.50",   status: "Completed"),
            HomeActivity(icon: "bolt.car.fill", iconColor: .csqRideBlue,          title: "Bondi Beach",          subtitle: "CSQXpress · Mar 29, 2:30 PM · A$14.00", status: "Completed"),
            HomeActivity(icon: "cart.fill",     iconColor: .csqGroceryGreen,      title: "CSQMart — Grocery order", subtitle: "A$47.80 · Mar 27 · 8 items",         status: "Delivered"),
        ],
        paymentMethods: [.visa, .mastercard, .amex]
    )
}

// MARK: - Value Types for MarketContent arrays

struct NearbyRestaurant {
    let name:         String
    let imageName:    String
    let cuisine:      String
    let rating:       String
    let deliveryTime: String
    let deliveryFee:  String
    let tag:          String
    let color:        Color
}

struct HomeDeal {
    let title:    String
    let merchant: String
    let badge:    String
    let expiry:   String
    let color:    Color
    let icon:     String
}

struct HomePromo {
    let headline:  String
    let sub:       String
    let color:     Color
    let icon:      String
    let imageName: String
    let logoName:  String
}

struct HomeActivity {
    let icon:      String
    let iconColor: Color
    let title:     String
    let subtitle:  String
    let status:    String
    var isError:   Bool = false   // true for cancelled/failed states; drives status pill colour
}

// MARK: - MarketConfig (Observable)
// Inject at the app root via .environmentObject(marketConfig).
// All views access strings and content through this object.

class MarketConfig: ObservableObject {
    @Published var market: Market = .singapore

    // All per-market data now comes from the single registry profile.
    var profile:  MarketProfile { market.profile }
    var strings:  AppStrings    { profile.strings }
    var content:  MarketContent { profile.content }
    var currency: Currency      { profile.currency }
}
