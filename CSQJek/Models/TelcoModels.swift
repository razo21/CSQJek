import SwiftUI

// MARK: - Plan Type

enum PlanType: String, CaseIterable {
    case postpaid
    case prepaid
    case simOnly = "sim_only"

    // English fallback display name (stable; used where no market context exists).
    var displayName: String {
        switch self {
        case .postpaid:
            return "Postpaid"
        case .prepaid:
            return "Prepaid"
        case .simOnly:
            return "SIM-Only"
        }
    }

    // Market-aware, localized display name for the plan-type tabs.
    // Tokyo is Japanese; every other market (incl. future cases) falls back to
    // the English `displayName`.
    func displayName(for market: Market) -> String {
        switch market {
        case .tokyo:
            switch self {
            case .postpaid: return "ポストペイド"
            case .prepaid:  return "プリペイド"
            case .simOnly:  return "SIMオンリー"
            }
        default:
            return displayName
        }
    }

    var icon: String {
        switch self {
        case .postpaid:
            return "creditcard.fill"
        case .prepaid:
            return "wallet.pass"
        case .simOnly:
            return "sim.fill"
        }
    }
}

// MARK: - Telco Plan

struct TelcoPlan: Identifiable {
    let id: UUID
    let name: String          // Stable English key — used for accessibilityIdentifier + analytics. Do NOT localize.
    let displayName: String   // Localized, user-visible plan name.
    let type: PlanType
    let monthlyPrice: Double
    let dataAllowance: String
    let localCalls: String
    let sms: String
    let contractTerm: String
    let features: [String]
    let badge: String?
    let color: Color
    let isPopular: Bool

    // Market-aware accessor. Returns the localized plan catalogue for the given
    // market, falling back to the Singapore catalogue for any unhandled market.
    static let plansByMarket: [Market: [TelcoPlan]] = [
        .singapore: singaporePlans,
        .tokyo:     tokyoPlans,
        .sydney:    sydneyPlans
    ]

    static func plans(for market: Market) -> [TelcoPlan] {
        plansByMarket[market] ?? singaporePlans
    }

    // MARK: Singapore (English)

    static let singaporePlans: [TelcoPlan] = [
        // Postpaid
        TelcoPlan(
            id: UUID(),
            name: "Essential",
            displayName: "Essential",
            type: .postpaid,
            monthlyPrice: 18,
            dataAllowance: "5 GB",
            localCalls: "100 min free, S$0.05/min after",
            sms: "100 SMS",
            contractTerm: "24-month",
            features: [
                "5G Ready",
                "Caller ID included",
                "IDD to Malaysia at 3 sen/min",
                "Free incoming calls",
                "Data rollover up to 1 GB"
            ],
            badge: nil,
            color: Color(hex: "#0EA5E9"),
            isPopular: false
        ),
        TelcoPlan(
            id: UUID(),
            name: "ValuePlus",
            displayName: "ValuePlus",
            type: .postpaid,
            monthlyPrice: 28,
            dataAllowance: "20 GB",
            localCalls: "Unlimited local calls",
            sms: "Unlimited SMS",
            contractTerm: "24-month",
            features: [
                "5G Ready",
                "Unlimited local calls & SMS",
                "IDD to MY & ID free 100 min/mo",
                "Data rollover up to 5 GB",
                "Free caller ID & voicemail",
                "1 complimentary roaming day pass/yr"
            ],
            badge: "Most Popular",
            color: Color(hex: "#7C3AED"),
            isPopular: true
        ),
        TelcoPlan(
            id: UUID(),
            name: "Infinite",
            displayName: "Infinite",
            type: .postpaid,
            monthlyPrice: 45,
            dataAllowance: "80 GB",
            localCalls: "Unlimited",
            sms: "Unlimited",
            contractTerm: "24-month",
            features: [
                "5G Priority access",
                "80 GB local + 10 GB roaming data",
                "Unlimited local calls & SMS",
                "IDD to MY/ID/CN/HK free unlimited",
                "Free caller ID & voicemail",
                "4 complimentary roaming day passes/yr",
                "Netflix mobile plan included"
            ],
            badge: "Best Value",
            color: Color(hex: "#059669"),
            isPopular: false
        ),
        TelcoPlan(
            id: UUID(),
            name: "Black",
            displayName: "Black",
            type: .postpaid,
            monthlyPrice: 68,
            dataAllowance: "Unlimited",
            localCalls: "Unlimited",
            sms: "Unlimited",
            contractTerm: "24-month",
            features: [
                "Unlimited 5G data with priority lane",
                "Unlimited local & IDD calls to 30 destinations",
                "12 roaming day passes/yr included",
                "Complimentary airport lounge access x2",
                "Dedicated Black customer hotline",
                "Apple Watch connectivity plan S$5/mo add-on",
                "Free international data SIM for travel"
            ],
            badge: "Premium",
            color: Color(hex: "#1C1C2E"),
            isPopular: false
        ),

        // Prepaid
        TelcoPlan(
            id: UUID(),
            name: "Tourist SIM",
            displayName: "Tourist SIM",
            type: .prepaid,
            monthlyPrice: 15,
            dataAllowance: "5 GB",
            localCalls: "Local calls S$0.03/min",
            sms: "100 SMS",
            contractTerm: "7-day validity",
            features: [
                "Valid for 7 days",
                "5 GB local data",
                "SIM delivered within 2 hrs or pick up at Changi",
                "IDD calls available at standard rates",
                "Supports eSIM — scan QR to activate",
                "Top up to extend validity"
            ],
            badge: "Traveller Pick",
            color: Color(hex: "#0EA5E9"),
            isPopular: false
        ),
        TelcoPlan(
            id: UUID(),
            name: "Value Card 10",
            displayName: "Value Card 10",
            type: .prepaid,
            monthlyPrice: 10,
            dataAllowance: "3 GB",
            localCalls: "Local calls S$0.03/min",
            sms: "50 SMS",
            contractTerm: "28-day validity",
            features: [
                "28-day validity",
                "3 GB local data",
                "Auto-renew available",
                "IDD rates from S$0.02/min to Malaysia",
                "Free incoming calls",
                "Top up via PayNow or AXS"
            ],
            badge: nil,
            color: Color(hex: "#6B7280"),
            isPopular: false
        ),
        TelcoPlan(
            id: UUID(),
            name: "Value Card 25",
            displayName: "Value Card 25",
            type: .prepaid,
            monthlyPrice: 25,
            dataAllowance: "15 GB",
            localCalls: "Unlimited local calls",
            sms: "Unlimited SMS",
            contractTerm: "28-day validity",
            features: [
                "28-day validity",
                "15 GB local data (throttled after)",
                "Unlimited local calls & SMS",
                "IDD to Malaysia free 30 min/month",
                "Data rollover 1 GB if unused",
                "Top up via PayNow, AXS, or CSQJek app"
            ],
            badge: "Best Prepaid",
            color: Color(hex: "#0EA5E9"),
            isPopular: true
        ),

        // SIM-Only
        TelcoPlan(
            id: UUID(),
            name: "SIM-Only 5",
            displayName: "SIM-Only 5",
            type: .simOnly,
            monthlyPrice: 10,
            dataAllowance: "5 GB",
            localCalls: "100 min free",
            sms: "100 SMS",
            contractTerm: "No contract",
            features: [
                "Month-to-month",
                "5 GB data",
                "Bring your own number",
                "IMDA registered",
                "e-SIM or physical SIM"
            ],
            badge: nil,
            color: Color(hex: "#6B7280"),
            isPopular: false
        ),
        TelcoPlan(
            id: UUID(),
            name: "SIM-Only 15",
            displayName: "SIM-Only 15",
            type: .simOnly,
            monthlyPrice: 15,
            dataAllowance: "15 GB",
            localCalls: "Unlimited",
            sms: "Unlimited",
            contractTerm: "No contract",
            features: [
                "Month-to-month",
                "15 GB data",
                "Unlimited local calls & SMS",
                "Bring your existing number",
                "Cancel anytime — no penalty",
                "eSIM support"
            ],
            badge: "Popular",
            color: Color(hex: "#0EA5E9"),
            isPopular: true
        ),
        TelcoPlan(
            id: UUID(),
            name: "SIM-Only 30",
            displayName: "SIM-Only 30",
            type: .simOnly,
            monthlyPrice: 22,
            dataAllowance: "30 GB",
            localCalls: "Unlimited",
            sms: "Unlimited",
            contractTerm: "No contract",
            features: [
                "Month-to-month",
                "30 GB data + 3 GB roaming",
                "Unlimited local calls & SMS",
                "IDD to Malaysia included",
                "eSIM + physical SIM dual support",
                "Priority 5G access"
            ],
            badge: "Best Value",
            color: Color(hex: "#059669"),
            isPopular: false
        )
    ]

    // MARK: Tokyo (Japanese, Japan-localized)

    static let tokyoPlans: [TelcoPlan] = [
        // Postpaid（ポストペイド）
        TelcoPlan(
            id: UUID(),
            name: "Essential",
            displayName: "エッセンシャル",
            type: .postpaid,
            monthlyPrice: 18,
            dataAllowance: "5 GB",
            localCalls: "国内通話100分無料、以降30秒¥20",
            sms: "SMS 100通",
            contractTerm: "24ヶ月契約",
            features: [
                "5G対応",
                "発信者番号表示込み",
                "国際通話 韓国へ¥30/分",
                "着信無料",
                "データ繰り越し最大1 GB"
            ],
            badge: nil,
            color: Color(hex: "#0EA5E9"),
            isPopular: false
        ),
        TelcoPlan(
            id: UUID(),
            name: "ValuePlus",
            displayName: "バリュープラス",
            type: .postpaid,
            monthlyPrice: 28,
            dataAllowance: "20 GB",
            localCalls: "国内通話かけ放題",
            sms: "SMS送り放題",
            contractTerm: "24ヶ月契約",
            features: [
                "5G対応",
                "国内通話・SMSかけ放題",
                "国際通話 韓国・中国へ毎月100分無料",
                "データ繰り越し最大5 GB",
                "発信者番号表示・留守番電話無料",
                "海外ローミング1日パス 年1回無料"
            ],
            badge: "人気No.1",
            color: Color(hex: "#7C3AED"),
            isPopular: true
        ),
        TelcoPlan(
            id: UUID(),
            name: "Infinite",
            displayName: "インフィニット",
            type: .postpaid,
            monthlyPrice: 45,
            dataAllowance: "80 GB",
            localCalls: "無制限",
            sms: "無制限",
            contractTerm: "24ヶ月契約",
            features: [
                "5G優先接続",
                "国内80 GB + ローミング10 GB",
                "国内通話・SMSかけ放題",
                "国際通話 韓国/中国/香港/米国 無制限",
                "発信者番号表示・留守番電話無料",
                "海外ローミング1日パス 年4回無料",
                "Netflixモバイルプラン込み"
            ],
            badge: "おすすめ",
            color: Color(hex: "#059669"),
            isPopular: false
        ),
        TelcoPlan(
            id: UUID(),
            name: "Black",
            displayName: "ブラック",
            type: .postpaid,
            monthlyPrice: 68,
            dataAllowance: "無制限",
            localCalls: "無制限",
            sms: "無制限",
            contractTerm: "24ヶ月契約",
            features: [
                "5Gデータ無制限・優先レーン",
                "国内通話・30カ国への国際通話かけ放題",
                "海外ローミング1日パス 年12回込み",
                "空港ラウンジ利用 年2回無料",
                "Black専用カスタマーホットライン",
                "Apple Watch通信プラン 月額¥500で追加可",
                "海外用データSIM無料"
            ],
            badge: "プレミアム",
            color: Color(hex: "#1C1C2E"),
            isPopular: false
        ),

        // Prepaid（プリペイド）
        TelcoPlan(
            id: UUID(),
            name: "Tourist SIM",
            displayName: "ツーリストSIM",
            type: .prepaid,
            monthlyPrice: 15,
            dataAllowance: "5 GB",
            localCalls: "国内通話¥30/分",
            sms: "SMS 100通",
            contractTerm: "7日間有効",
            features: [
                "7日間有効",
                "国内データ5 GB",
                "2時間以内に配送、または成田・羽田で受け取り",
                "国際通話は標準レートで利用可",
                "eSIM対応 — QRコードで即有効化",
                "チャージで有効期間を延長"
            ],
            badge: "旅行者向け",
            color: Color(hex: "#0EA5E9"),
            isPopular: false
        ),
        TelcoPlan(
            id: UUID(),
            name: "Value Card 10",
            displayName: "バリューカード10",
            type: .prepaid,
            monthlyPrice: 10,
            dataAllowance: "3 GB",
            localCalls: "国内通話¥30/分",
            sms: "SMS 50通",
            contractTerm: "28日間有効",
            features: [
                "28日間有効",
                "国内データ3 GB",
                "自動更新対応",
                "国際通話 韓国へ¥20/分から",
                "着信無料",
                "PayPay・コンビニでチャージ"
            ],
            badge: nil,
            color: Color(hex: "#6B7280"),
            isPopular: false
        ),
        TelcoPlan(
            id: UUID(),
            name: "Value Card 25",
            displayName: "バリューカード25",
            type: .prepaid,
            monthlyPrice: 25,
            dataAllowance: "15 GB",
            localCalls: "国内通話かけ放題",
            sms: "SMS送り放題",
            contractTerm: "28日間有効",
            features: [
                "28日間有効",
                "国内データ15 GB（超過後は速度制限）",
                "国内通話・SMSかけ放題",
                "国際通話 韓国へ毎月30分無料",
                "未使用分1 GBを翌月へ繰り越し",
                "PayPay・コンビニ・CSQJekアプリでチャージ"
            ],
            badge: "プリペイド人気",
            color: Color(hex: "#0EA5E9"),
            isPopular: true
        ),

        // SIM-Only（SIMオンリー）
        TelcoPlan(
            id: UUID(),
            name: "SIM-Only 5",
            displayName: "SIMオンリー5",
            type: .simOnly,
            monthlyPrice: 10,
            dataAllowance: "5 GB",
            localCalls: "無料通話100分",
            sms: "SMS 100通",
            contractTerm: "契約なし",
            features: [
                "月ごとの契約",
                "データ5 GB",
                "今の番号をそのまま利用（MNP）",
                "本人確認登録済み",
                "eSIMまたは物理SIM"
            ],
            badge: nil,
            color: Color(hex: "#6B7280"),
            isPopular: false
        ),
        TelcoPlan(
            id: UUID(),
            name: "SIM-Only 15",
            displayName: "SIMオンリー15",
            type: .simOnly,
            monthlyPrice: 15,
            dataAllowance: "15 GB",
            localCalls: "無制限",
            sms: "無制限",
            contractTerm: "契約なし",
            features: [
                "月ごとの契約",
                "データ15 GB",
                "国内通話・SMSかけ放題",
                "今の番号をそのまま利用（MNP）",
                "違約金なしでいつでも解約可",
                "eSIM対応"
            ],
            badge: "人気",
            color: Color(hex: "#0EA5E9"),
            isPopular: true
        ),
        TelcoPlan(
            id: UUID(),
            name: "SIM-Only 30",
            displayName: "SIMオンリー30",
            type: .simOnly,
            monthlyPrice: 22,
            dataAllowance: "30 GB",
            localCalls: "無制限",
            sms: "無制限",
            contractTerm: "契約なし",
            features: [
                "月ごとの契約",
                "データ30 GB + ローミング3 GB",
                "国内通話・SMSかけ放題",
                "国際通話 韓国込み",
                "eSIM・物理SIM両対応",
                "5G優先接続"
            ],
            badge: "おすすめ",
            color: Color(hex: "#059669"),
            isPopular: false
        )
    ]

    // MARK: Sydney (English, Australia-localized)

    static let sydneyPlans: [TelcoPlan] = [
        // Postpaid
        TelcoPlan(
            id: UUID(),
            name: "Essential",
            displayName: "Essential",
            type: .postpaid,
            monthlyPrice: 18,
            dataAllowance: "5 GB",
            localCalls: "100 min free, A$0.05/min after",
            sms: "100 SMS",
            contractTerm: "24-month",
            features: [
                "5G across Australia",
                "Caller ID included",
                "International calls to NZ at 5c/min",
                "Free incoming calls",
                "Data rollover up to 1 GB"
            ],
            badge: nil,
            color: Color(hex: "#0EA5E9"),
            isPopular: false
        ),
        TelcoPlan(
            id: UUID(),
            name: "ValuePlus",
            displayName: "ValuePlus",
            type: .postpaid,
            monthlyPrice: 28,
            dataAllowance: "20 GB",
            localCalls: "Unlimited national calls",
            sms: "Unlimited SMS",
            contractTerm: "24-month",
            features: [
                "5G across Australia",
                "Unlimited national calls & SMS",
                "Intl calls to NZ & UK free 100 min/mo",
                "Data rollover up to 5 GB",
                "Free caller ID & voicemail",
                "1 complimentary roaming day pass/yr"
            ],
            badge: "Most Popular",
            color: Color(hex: "#7C3AED"),
            isPopular: true
        ),
        TelcoPlan(
            id: UUID(),
            name: "Infinite",
            displayName: "Infinite",
            type: .postpaid,
            monthlyPrice: 45,
            dataAllowance: "80 GB",
            localCalls: "Unlimited",
            sms: "Unlimited",
            contractTerm: "24-month",
            features: [
                "5G Priority access",
                "80 GB national + 10 GB roaming data",
                "Unlimited national calls & SMS",
                "Intl calls to NZ/UK/US free unlimited",
                "Free caller ID & voicemail",
                "4 complimentary roaming day passes/yr",
                "Netflix mobile plan included"
            ],
            badge: "Best Value",
            color: Color(hex: "#059669"),
            isPopular: false
        ),
        TelcoPlan(
            id: UUID(),
            name: "Black",
            displayName: "Black",
            type: .postpaid,
            monthlyPrice: 68,
            dataAllowance: "Unlimited",
            localCalls: "Unlimited",
            sms: "Unlimited",
            contractTerm: "24-month",
            features: [
                "Unlimited 5G data with priority lane",
                "Unlimited national & intl calls to 30 destinations",
                "12 roaming day passes/yr included",
                "Complimentary airport lounge access x2",
                "Dedicated Black customer hotline",
                "Apple Watch connectivity plan A$5/mo add-on",
                "Free international data SIM for travel"
            ],
            badge: "Premium",
            color: Color(hex: "#1C1C2E"),
            isPopular: false
        ),

        // Prepaid
        TelcoPlan(
            id: UUID(),
            name: "Tourist SIM",
            displayName: "Tourist SIM",
            type: .prepaid,
            monthlyPrice: 15,
            dataAllowance: "5 GB",
            localCalls: "National calls A$0.03/min",
            sms: "100 SMS",
            contractTerm: "7-day validity",
            features: [
                "Valid for 7 days",
                "5 GB national data",
                "SIM delivered within 2 hrs or pick up at Sydney Airport",
                "International calls available at standard rates",
                "Supports eSIM — scan QR to activate",
                "Top up to extend validity"
            ],
            badge: "Traveller Pick",
            color: Color(hex: "#0EA5E9"),
            isPopular: false
        ),
        TelcoPlan(
            id: UUID(),
            name: "Value Card 10",
            displayName: "Value Card 10",
            type: .prepaid,
            monthlyPrice: 10,
            dataAllowance: "3 GB",
            localCalls: "National calls A$0.03/min",
            sms: "50 SMS",
            contractTerm: "28-day validity",
            features: [
                "28-day validity",
                "3 GB national data",
                "Auto-renew available",
                "Intl rates from A$0.02/min to NZ",
                "Free incoming calls",
                "Top up via PayID or BPAY"
            ],
            badge: nil,
            color: Color(hex: "#6B7280"),
            isPopular: false
        ),
        TelcoPlan(
            id: UUID(),
            name: "Value Card 25",
            displayName: "Value Card 25",
            type: .prepaid,
            monthlyPrice: 25,
            dataAllowance: "15 GB",
            localCalls: "Unlimited national calls",
            sms: "Unlimited SMS",
            contractTerm: "28-day validity",
            features: [
                "28-day validity",
                "15 GB national data (throttled after)",
                "Unlimited national calls & SMS",
                "Intl calls to NZ free 30 min/month",
                "Data rollover 1 GB if unused",
                "Top up via PayID, BPAY, or CSQJek app"
            ],
            badge: "Best Prepaid",
            color: Color(hex: "#0EA5E9"),
            isPopular: true
        ),

        // SIM-Only
        TelcoPlan(
            id: UUID(),
            name: "SIM-Only 5",
            displayName: "SIM-Only 5",
            type: .simOnly,
            monthlyPrice: 10,
            dataAllowance: "5 GB",
            localCalls: "100 min free",
            sms: "100 SMS",
            contractTerm: "No contract",
            features: [
                "Month-to-month",
                "5 GB data",
                "Keep your number (MNP)",
                "ID verified",
                "eSIM or physical SIM"
            ],
            badge: nil,
            color: Color(hex: "#6B7280"),
            isPopular: false
        ),
        TelcoPlan(
            id: UUID(),
            name: "SIM-Only 15",
            displayName: "SIM-Only 15",
            type: .simOnly,
            monthlyPrice: 15,
            dataAllowance: "15 GB",
            localCalls: "Unlimited",
            sms: "Unlimited",
            contractTerm: "No contract",
            features: [
                "Month-to-month",
                "15 GB data",
                "Unlimited national calls & SMS",
                "Keep your existing number (MNP)",
                "Cancel anytime — no penalty",
                "eSIM support"
            ],
            badge: "Popular",
            color: Color(hex: "#0EA5E9"),
            isPopular: true
        ),
        TelcoPlan(
            id: UUID(),
            name: "SIM-Only 30",
            displayName: "SIM-Only 30",
            type: .simOnly,
            monthlyPrice: 22,
            dataAllowance: "30 GB",
            localCalls: "Unlimited",
            sms: "Unlimited",
            contractTerm: "No contract",
            features: [
                "Month-to-month",
                "30 GB data + 3 GB roaming",
                "Unlimited national calls & SMS",
                "Intl calls to NZ included",
                "eSIM + physical SIM dual support",
                "Priority 5G access"
            ],
            badge: "Best Value",
            color: Color(hex: "#059669"),
            isPopular: false
        )
    ]
}

// MARK: - Telco Device

struct TelcoDevice: Identifiable {
    let id: UUID
    let brand: String
    let model: String
    let storage: String
    let outrightPrice: Double
    let monthlyPrice: Double
    let contractPlan: String
    let colorOptions: [String]
    let badge: String?
    let imageName: String        // Asset catalog name — falls back to SF symbol if nil
    let fallbackIcon: String     // SF symbol for when image hasn't landed yet

    // Market-aware accessor. Brand/model names stay in Latin (real product names);
    // contract labels, badges, and colour names are localized.
    static let devicesByMarket: [Market: [TelcoDevice]] = [
        .singapore: singaporeDevices,
        .tokyo:     tokyoDevices,
        .sydney:    sydneyDevices
    ]

    static func devices(for market: Market) -> [TelcoDevice] {
        devicesByMarket[market] ?? singaporeDevices
    }

    static let singaporeDevices: [TelcoDevice] = [
        TelcoDevice(
            id: UUID(),
            brand: "Apple",
            model: "iPhone 16 Pro",
            storage: "256 GB",
            outrightPrice: 1649,
            monthlyPrice: 79,
            contractPlan: "with ValuePlus",
            colorOptions: ["Black Titanium", "White Titanium", "Natural Titanium", "Desert Titanium"],
            badge: "New",
            imageName: "PhoneAppleiPhone16Pro",
            fallbackIcon: "iphone"
        ),
        TelcoDevice(
            id: UUID(),
            brand: "Samsung",
            model: "Galaxy S26",
            storage: "256 GB",
            outrightPrice: 1699,
            monthlyPrice: 75,
            contractPlan: "with ValuePlus",
            colorOptions: ["Titanium Black", "Titanium Silver", "Titanium Blue", "Titanium Gold"],
            badge: "Trending",
            imageName: "PhoneSamsungGalaxyS26",
            fallbackIcon: "iphone"
        ),
        TelcoDevice(
            id: UUID(),
            brand: "Google",
            model: "Pixel 9 Pro",
            storage: "128 GB",
            outrightPrice: 999,
            monthlyPrice: 45,
            contractPlan: "with Essential",
            colorOptions: ["Obsidian", "Porcelain", "Hazel", "Rose Quartz"],
            badge: nil,
            imageName: "PhoneGooglePixel9Pro",
            fallbackIcon: "iphone"
        ),
        TelcoDevice(
            id: UUID(),
            brand: "Samsung",
            model: "Galaxy Z Fold 6",
            storage: "256 GB",
            outrightPrice: 2388,
            monthlyPrice: 99,
            contractPlan: "with Infinite",
            colorOptions: ["Crafted Black", "Pink", "Navy"],
            badge: "Foldable",
            imageName: "PhoneSamsungGalaxyZFold6",
            fallbackIcon: "iphone.gen2"
        )
    ]

    static let tokyoDevices: [TelcoDevice] = [
        TelcoDevice(
            id: UUID(),
            brand: "Apple",
            model: "iPhone 16 Pro",
            storage: "256 GB",
            outrightPrice: 1649,
            monthlyPrice: 79,
            contractPlan: "バリュープラス対応",
            colorOptions: ["ブラックチタニウム", "ホワイトチタニウム", "ナチュラルチタニウム", "デザートチタニウム"],
            badge: "新着",
            imageName: "PhoneAppleiPhone16Pro",
            fallbackIcon: "iphone"
        ),
        TelcoDevice(
            id: UUID(),
            brand: "Samsung",
            model: "Galaxy S26",
            storage: "256 GB",
            outrightPrice: 1699,
            monthlyPrice: 75,
            contractPlan: "バリュープラス対応",
            colorOptions: ["チタニウムブラック", "チタニウムシルバー", "チタニウムブルー", "チタニウムゴールド"],
            badge: "話題",
            imageName: "PhoneSamsungGalaxyS26",
            fallbackIcon: "iphone"
        ),
        TelcoDevice(
            id: UUID(),
            brand: "Google",
            model: "Pixel 9 Pro",
            storage: "128 GB",
            outrightPrice: 999,
            monthlyPrice: 45,
            contractPlan: "エッセンシャル対応",
            colorOptions: ["オブシディアン", "ポーセリン", "ヘーゼル", "ローズクォーツ"],
            badge: nil,
            imageName: "PhoneGooglePixel9Pro",
            fallbackIcon: "iphone"
        ),
        TelcoDevice(
            id: UUID(),
            brand: "Samsung",
            model: "Galaxy Z Fold 6",
            storage: "256 GB",
            outrightPrice: 2388,
            monthlyPrice: 99,
            contractPlan: "インフィニット対応",
            colorOptions: ["クラフテッドブラック", "ピンク", "ネイビー"],
            badge: "折りたたみ",
            imageName: "PhoneSamsungGalaxyZFold6",
            fallbackIcon: "iphone.gen2"
        )
    ]

    static let sydneyDevices: [TelcoDevice] = [
        TelcoDevice(
            id: UUID(),
            brand: "Apple",
            model: "iPhone 16 Pro",
            storage: "256 GB",
            outrightPrice: 1649,
            monthlyPrice: 79,
            contractPlan: "with ValuePlus",
            colorOptions: ["Black Titanium", "White Titanium", "Natural Titanium", "Desert Titanium"],
            badge: "New",
            imageName: "PhoneAppleiPhone16Pro",
            fallbackIcon: "iphone"
        ),
        TelcoDevice(
            id: UUID(),
            brand: "Samsung",
            model: "Galaxy S26",
            storage: "256 GB",
            outrightPrice: 1699,
            monthlyPrice: 75,
            contractPlan: "with ValuePlus",
            colorOptions: ["Titanium Black", "Titanium Silver", "Titanium Blue", "Titanium Gold"],
            badge: "Trending",
            imageName: "PhoneSamsungGalaxyS26",
            fallbackIcon: "iphone"
        ),
        TelcoDevice(
            id: UUID(),
            brand: "Google",
            model: "Pixel 9 Pro",
            storage: "128 GB",
            outrightPrice: 999,
            monthlyPrice: 45,
            contractPlan: "with Essential",
            colorOptions: ["Obsidian", "Porcelain", "Hazel", "Rose Quartz"],
            badge: nil,
            imageName: "PhoneGooglePixel9Pro",
            fallbackIcon: "iphone"
        ),
        TelcoDevice(
            id: UUID(),
            brand: "Samsung",
            model: "Galaxy Z Fold 6",
            storage: "256 GB",
            outrightPrice: 2388,
            monthlyPrice: 99,
            contractPlan: "with Infinite",
            colorOptions: ["Crafted Black", "Pink", "Navy"],
            badge: "Foldable",
            imageName: "PhoneSamsungGalaxyZFold6",
            fallbackIcon: "iphone.gen2"
        )
    ]
}

// MARK: - Telco Add-On

struct TelcoAddOn: Identifiable {
    let id: UUID
    let name: String
    let description: String
    let price: Double
    let period: String
    let icon: String
    let color: Color

    // Market-aware accessor. Tokyo prices are expressed in yen directly
    // (the add-on price is formatted as-is, without the ×100 scaling used elsewhere).
    static let addOnsByMarket: [Market: [TelcoAddOn]] = [
        .singapore: singaporeAddOns,
        .tokyo:     tokyoAddOns,
        .sydney:    sydneyAddOns
    ]

    static func addOns(for market: Market) -> [TelcoAddOn] {
        addOnsByMarket[market] ?? singaporeAddOns
    }

    static let singaporeAddOns: [TelcoAddOn] = [
        TelcoAddOn(
            id: UUID(),
            name: "Roam ASEAN Day Pass",
            description: "Unlimited data in SG+9 ASEAN countries including MY, TH, ID, PH, VN, KH, MM, BN, LA",
            price: 8,
            period: "per day",
            icon: "airplane.circle.fill",
            color: Color(hex: "#0EA5E9")
        ),
        TelcoAddOn(
            id: UUID(),
            name: "JB Roam Pack",
            description: "7 days unlimited data roaming to Johor Bahru — perfect for weekend jaunts up north",
            price: 5,
            period: "7 days",
            icon: "map.fill",
            color: Color(hex: "#059669")
        ),
        TelcoAddOn(
            id: UUID(),
            name: "港澳台 Bundle",
            description: "5 GB roaming data valid across Hong Kong, Macau & Taiwan for 30 days",
            price: 15,
            period: "30 days",
            icon: "globe.asia.australia.fill",
            color: Color(hex: "#DC2626")
        ),
        TelcoAddOn(
            id: UUID(),
            name: "IDD MY Booster",
            description: "Unlimited IDD calls to all Malaysian mobile & fixed lines",
            price: 5,
            period: "per month",
            icon: "phone.fill",
            color: Color(hex: "#7C3AED")
        ),
        TelcoAddOn(
            id: UUID(),
            name: "Data Booster 10 GB",
            description: "Instant 10 GB data top-up — no expiry, rolls over to next cycle",
            price: 12,
            period: "one-time",
            icon: "arrow.up.circle.fill",
            color: Color(hex: "#F59E0B")
        ),
        TelcoAddOn(
            id: UUID(),
            name: "Family Share Plan",
            description: "Add up to 4 supplementary lines at S$15/line. Shared or individual data allocation.",
            price: 15,
            period: "per line/month",
            icon: "person.2.fill",
            color: Color(hex: "#6B21A8")
        )
    ]

    static let tokyoAddOns: [TelcoAddOn] = [
        TelcoAddOn(
            id: UUID(),
            name: "アジアローミング 1日パス",
            description: "韓国・台湾・タイなどアジア10カ国以上でデータ無制限",
            price: 800,
            period: "1日あたり",
            icon: "airplane.circle.fill",
            color: Color(hex: "#0EA5E9")
        ),
        TelcoAddOn(
            id: UUID(),
            name: "近隣アジア周遊パック",
            description: "7日間 韓国・台湾でデータ無制限 — 週末旅行に最適",
            price: 500,
            period: "7日間",
            icon: "map.fill",
            color: Color(hex: "#059669")
        ),
        TelcoAddOn(
            id: UUID(),
            name: "香港・マカオ・台湾パック",
            description: "香港・マカオ・台湾で使えるローミングデータ5 GB（30日間）",
            price: 1500,
            period: "30日間",
            icon: "globe.asia.australia.fill",
            color: Color(hex: "#DC2626")
        ),
        TelcoAddOn(
            id: UUID(),
            name: "国際通話定額ブースター",
            description: "韓国・中国・米国の携帯・固定電話へかけ放題",
            price: 500,
            period: "月額",
            icon: "phone.fill",
            color: Color(hex: "#7C3AED")
        ),
        TelcoAddOn(
            id: UUID(),
            name: "データブースター 10 GB",
            description: "即時10 GBチャージ — 有効期限なし、翌月へ繰り越し",
            price: 1200,
            period: "1回限り",
            icon: "arrow.up.circle.fill",
            color: Color(hex: "#F59E0B")
        ),
        TelcoAddOn(
            id: UUID(),
            name: "家族シェアプラン",
            description: "追加回線を最大4回線、1回線¥1,500で追加。データは共有または個別割当。",
            price: 1500,
            period: "1回線/月",
            icon: "person.2.fill",
            color: Color(hex: "#6B21A8")
        )
    ]

    static let sydneyAddOns: [TelcoAddOn] = [
        TelcoAddOn(
            id: UUID(),
            name: "Trans-Tasman Day Pass",
            description: "Unlimited data in New Zealand — perfect for a quick hop across the Tasman",
            price: 8,
            period: "per day",
            icon: "airplane.circle.fill",
            color: Color(hex: "#0EA5E9")
        ),
        TelcoAddOn(
            id: UUID(),
            name: "Asia Roaming Pass",
            description: "7 days unlimited data across Indonesia, Thailand, Japan & 10 more Asian destinations",
            price: 5,
            period: "7 days",
            icon: "map.fill",
            color: Color(hex: "#059669")
        ),
        TelcoAddOn(
            id: UUID(),
            name: "UK & Europe Pass",
            description: "5 GB roaming data valid across the UK & 42 European countries for 30 days",
            price: 15,
            period: "30 days",
            icon: "globe.europe.africa.fill",
            color: Color(hex: "#DC2626")
        ),
        TelcoAddOn(
            id: UUID(),
            name: "International Calls Booster",
            description: "Unlimited international calls to NZ, UK & US mobile & fixed lines",
            price: 5,
            period: "per month",
            icon: "phone.fill",
            color: Color(hex: "#7C3AED")
        ),
        TelcoAddOn(
            id: UUID(),
            name: "Data Booster 10 GB",
            description: "Instant 10 GB data top-up — no expiry, rolls over to next cycle",
            price: 12,
            period: "one-time",
            icon: "arrow.up.circle.fill",
            color: Color(hex: "#F59E0B")
        ),
        TelcoAddOn(
            id: UUID(),
            name: "Family Share Plan",
            description: "Add up to 4 supplementary lines at A$15/line. Shared or individual data allocation.",
            price: 15,
            period: "per line/month",
            icon: "person.2.fill",
            color: Color(hex: "#6B21A8")
        )
    ]
}

// MARK: - Purchase Funnel (Phase 4) ------------------------------------------
// Value types + store powering the device-purchase and plan-signup funnels.
// All prices are stored in Singapore-scale numbers (matching plans/devices);
// views scale ×100 for Tokyo (yen) the same way the rest of CSQMobile does.

enum TelcoFinanceMode: String, CaseIterable, Identifiable {
    case installment24
    case outright
    var id: String { rawValue }
    var analytics: String { self == .outright ? "outright" : "installment_24mo" }
}

enum TelcoFulfillment: String, CaseIterable, Identifiable {
    case esim
    case delivery
    case pickup
    var id: String { rawValue }
    var analytics: String { rawValue }
    var icon: String {
        switch self {
        case .esim:     return "qrcode"
        case .delivery: return "shippingbox.fill"
        case .pickup:   return "bag.fill"
        }
    }
}

enum TelcoSIMType: String, CaseIterable, Identifiable {
    case esim
    case physical
    var id: String { rawValue }
    var analytics: String { rawValue }
    var icon: String { self == .esim ? "qrcode" : "simcard.fill" }
}

enum TelcoNumberChoice: String, CaseIterable, Identifiable {
    case newNumber
    case portIn
    var id: String { rawValue }
    var analytics: String { self == .newNumber ? "new_number" : "port_in" }
}

struct TelcoStorageOption: Identifiable, Equatable {
    let id = UUID()
    let label: String        // "256 GB" / "1 TB"
    let priceDelta: Double    // added to the device base outright price (SG-scale)

    static func == (lhs: TelcoStorageOption, rhs: TelcoStorageOption) -> Bool { lhs.id == rhs.id }
}

enum TelcoPurchaseKind: String {
    case device
    case plan
}

extension TelcoDevice {
    /// Standard storage ladder anchored on the device's base storage.
    /// Storage labels (GB/TB) are universal across all three markets.
    var storageTiers: [TelcoStorageOption] {
        let base = Int(storage.replacingOccurrences(of: " GB", with: "")
                              .replacingOccurrences(of: " TB", with: "")
                              .trimmingCharacters(in: .whitespaces)) ?? 256
        func gb(_ v: Int) -> String { v >= 1024 ? "\(v / 1024) TB" : "\(v) GB" }
        return [
            TelcoStorageOption(label: gb(base),     priceDelta: 0),
            TelcoStorageOption(label: gb(base * 2), priceDelta: 150),
            TelcoStorageOption(label: gb(base * 4), priceDelta: 350)
        ]
    }
}

// MARK: - TelcoPurchaseStore
// Holds in-progress purchase state for both funnels. Scoped to the CSQMobile
// subtree (injected at TelcoHomeView) so it never re-renders other tabs.

final class TelcoPurchaseStore: ObservableObject {
    @Published var kind: TelcoPurchaseKind = .device

    // Device path
    @Published var device: TelcoDevice?
    @Published var selectedColor: String = ""
    @Published var selectedStorage: TelcoStorageOption?
    @Published var financeMode: TelcoFinanceMode = .installment24
    @Published var attachedPlan: TelcoPlan?

    // Plan path
    @Published var plan: TelcoPlan?
    @Published var simType: TelcoSIMType = .esim
    @Published var numberChoice: TelcoNumberChoice = .newNumber

    // Shared checkout
    @Published var fulfillment: TelcoFulfillment = .delivery
    @Published var creditApproved: Bool = false

    func startDevice(_ d: TelcoDevice) {
        kind            = .device
        device          = d
        selectedColor   = d.colorOptions.first ?? ""
        selectedStorage = d.storageTiers.first
        financeMode     = .installment24
        attachedPlan    = nil
        fulfillment     = .delivery
        creditApproved  = false
    }

    func startPlan(_ p: TelcoPlan) {
        kind           = .plan
        plan           = p
        simType        = .esim
        numberChoice   = .newNumber
        fulfillment    = .esim
        creditApproved = false
    }

    // MARK: Totals (SG-scale; views scale for Tokyo)

    var storageDelta: Double { selectedStorage?.priceDelta ?? 0 }

    /// Amount due today (upfront).
    var dueToday: Double {
        switch kind {
        case .device:
            guard let d = device else { return 0 }
            return financeMode == .outright ? d.outrightPrice + storageDelta : 0
        case .plan:
            return 0   // plans bill monthly; nothing due today
        }
    }

    /// Recurring monthly charge.
    var monthlyTotal: Double {
        switch kind {
        case .device:
            guard let d = device else { return 0 }
            let planMonthly = attachedPlan?.monthlyPrice ?? 0
            switch financeMode {
            case .outright:     return planMonthly
            case .installment24: return d.monthlyPrice + (storageDelta / 24.0) + planMonthly
            }
        case .plan:
            return plan?.monthlyPrice ?? 0
        }
    }

    var itemLabel: String {
        switch kind {
        case .device: return [device?.brand, device?.model].compactMap { $0 }.joined(separator: " ")
        case .plan:   return plan?.displayName ?? ""
        }
    }

    /// Stable analytics key for the item (never localized).
    var itemKey: String {
        switch kind {
        case .device: return [device?.brand, device?.model].compactMap { $0 }.joined(separator: " ")
        case .plan:   return plan?.name ?? ""
        }
    }
}

// ════════════════════════════════════════════════════════════════════════════
// MARK: - Billing & Support (CSQMobile "frustration journey" demo)
//
// Powers the Bills → Payment-fails → Help-Center → Support-Article →
// Contact-Support → Bot → Live-Chat / Call-Us maze. The point of this content
// is to demonstrate, in Contentsquare, a user who wants to PAY A BILL or TALK
// TO A HUMAN but is repeatedly deflected into self-service FAQ content before
// the contact options finally surface, buried under many layers.
//
// All money is stored in Singapore-scale numbers (the same value for every
// market). Tokyo's ×100 yen scaling happens only at display via `telcoMoney`.
// Content follows the established per-section pattern: `xByMarket` + `x(for:)`
// with a Singapore fallback. Sydney shares the English copy; only Tokyo differs.
// ════════════════════════════════════════════════════════════════════════════

// MARK: Bill

enum TelcoBillStatus {
    case due, overdue, paid

    func label(for market: Market) -> String {
        let jp = market == .tokyo
        switch self {
        case .due:     return jp ? "お支払い待ち" : "Due"
        case .overdue: return jp ? "支払い期限超過" : "Overdue"
        case .paid:    return jp ? "支払い済み"   : "Paid"
        }
    }

    var color: Color {
        switch self {
        case .due:     return .csqWarning
        case .overdue: return .csqError
        case .paid:    return .csqSuccess
        }
    }
}

struct TelcoBillLineItem: Identifiable {
    let id = UUID()
    let label: String     // localized, user-visible
    let amount: Double    // SG-scale; negative for credits/discounts
}

struct TelcoBill: Identifiable {
    let id = UUID()
    let period: String          // "April 2026" / "2026年4月" — localized display
    let invoiceNo: String       // stable, e.g. "INV-2026-0428"
    let issueDate: String       // localized display
    let dueDate: String         // localized display
    let amount: Double          // SG-scale total
    let status: TelcoBillStatus
    let isCurrent: Bool         // the headline bill on the Bills screen
    let lineItems: [TelcoBillLineItem]

    static let billsByMarket: [Market: [TelcoBill]] = [
        .singapore: singaporeBills,
        .tokyo:     tokyoBills,
        .sydney:    sydneyBills
    ]

    static func bills(for market: Market) -> [TelcoBill] {
        billsByMarket[market] ?? singaporeBills
    }

    static func currentBill(for market: Market) -> TelcoBill {
        let all = bills(for: market)
        return all.first(where: { $0.isCurrent }) ?? all[0]
    }

    // MARK: Singapore (English) — shared verbatim by Sydney (currency differs only at display)
    private static let englishBills: [TelcoBill] = [
        TelcoBill(
            period: "April 2026", invoiceNo: "INV-2026-0428",
            issueDate: "14 Apr 2026", dueDate: "28 Apr 2026",
            amount: 86.40, status: .overdue, isCurrent: true,
            lineItems: [
                TelcoBillLineItem(label: "ValuePlus Postpaid — monthly plan", amount: 28.00),
                TelcoBillLineItem(label: "iPhone 16 Pro — instalment 9 of 24", amount: 49.00),
                TelcoBillLineItem(label: "Roaming day-pass — Japan & Korea", amount: 15.00),
                TelcoBillLineItem(label: "Data add-on — 5 GB", amount: 8.00),
                TelcoBillLineItem(label: "Loyalty discount", amount: -20.00),
                TelcoBillLineItem(label: "GST (9%)", amount: 6.40),
            ]
        ),
        TelcoBill(
            period: "March 2026", invoiceNo: "INV-2026-0328",
            issueDate: "14 Mar 2026", dueDate: "28 Mar 2026",
            amount: 77.00, status: .paid, isCurrent: false,
            lineItems: [
                TelcoBillLineItem(label: "ValuePlus Postpaid — monthly plan", amount: 28.00),
                TelcoBillLineItem(label: "iPhone 16 Pro — instalment 8 of 24", amount: 49.00),
                TelcoBillLineItem(label: "GST (9%)", amount: 6.93),
                TelcoBillLineItem(label: "Loyalty discount", amount: -6.93),
            ]
        ),
        TelcoBill(
            period: "February 2026", invoiceNo: "INV-2026-0228",
            issueDate: "14 Feb 2026", dueDate: "28 Feb 2026",
            amount: 77.00, status: .paid, isCurrent: false,
            lineItems: [
                TelcoBillLineItem(label: "ValuePlus Postpaid — monthly plan", amount: 28.00),
                TelcoBillLineItem(label: "iPhone 16 Pro — instalment 7 of 24", amount: 49.00),
            ]
        ),
    ]

    static let singaporeBills: [TelcoBill] = englishBills
    static let sydneyBills:    [TelcoBill] = englishBills

    // MARK: Tokyo (Japanese)
    static let tokyoBills: [TelcoBill] = [
        TelcoBill(
            period: "2026年4月", invoiceNo: "INV-2026-0428",
            issueDate: "2026年4月14日", dueDate: "2026年4月28日",
            amount: 86.40, status: .overdue, isCurrent: true,
            lineItems: [
                TelcoBillLineItem(label: "バリュープラス 月額プラン", amount: 28.00),
                TelcoBillLineItem(label: "iPhone 16 Pro — 分割 9/24回", amount: 49.00),
                TelcoBillLineItem(label: "ローミング 1日パス — 日本・韓国", amount: 15.00),
                TelcoBillLineItem(label: "データ追加 — 5 GB", amount: 8.00),
                TelcoBillLineItem(label: "継続割引", amount: -20.00),
                TelcoBillLineItem(label: "消費税 (10%)", amount: 6.40),
            ]
        ),
        TelcoBill(
            period: "2026年3月", invoiceNo: "INV-2026-0328",
            issueDate: "2026年3月14日", dueDate: "2026年3月28日",
            amount: 77.00, status: .paid, isCurrent: false,
            lineItems: [
                TelcoBillLineItem(label: "バリュープラス 月額プラン", amount: 28.00),
                TelcoBillLineItem(label: "iPhone 16 Pro — 分割 8/24回", amount: 49.00),
            ]
        ),
        TelcoBill(
            period: "2026年2月", invoiceNo: "INV-2026-0228",
            issueDate: "2026年2月14日", dueDate: "2026年2月28日",
            amount: 77.00, status: .paid, isCurrent: false,
            lineItems: [
                TelcoBillLineItem(label: "バリュープラス 月額プラン", amount: 28.00),
                TelcoBillLineItem(label: "iPhone 16 Pro — 分割 7/24回", amount: 49.00),
            ]
        ),
    ]
}

// MARK: Support Article (the deflection content)

struct TelcoSupportArticle: Identifiable {
    let id: String              // STABLE analytics key — never localized (e.g. "payment_declined")
    let category: String        // stable English category key
    let title: String           // localized, user-visible
    let snippet: String         // localized one-line preview
    let body: [String]          // localized paragraphs
    let relatedIDs: [String]    // drives the "related articles" deflection loop

    static let articlesByMarket: [Market: [TelcoSupportArticle]] = [
        .singapore: englishArticles,
        .tokyo:     japaneseArticles,
        .sydney:    englishArticles
    ]

    static func articles(for market: Market) -> [TelcoSupportArticle] {
        articlesByMarket[market] ?? englishArticles
    }

    static func article(_ id: String, for market: Market) -> TelcoSupportArticle? {
        articles(for: market).first { $0.id == id }
    }

    // MARK: English (Singapore + Sydney)
    static let englishArticles: [TelcoSupportArticle] = [
        TelcoSupportArticle(
            id: "payment_declined", category: "billing",
            title: "Why was my payment declined?",
            snippet: "Common reasons a card or wallet payment fails and how to fix them.",
            body: [
                "Payments can be declined for several reasons. The most common is that your bank flagged the transaction as unusual. CSQMobile never sees the specific reason your bank declines a charge — you'll need to confirm with your card issuer.",
                "Before trying again, check that: your card has not expired, you have sufficient available balance, and online or recurring payments are enabled for the card. International cards may require you to approve the charge in your banking app.",
                "If you saw error code CSQ-4012, this means the authorisation was rejected by the issuing bank. Wait a few minutes and retry, or use a different payment method. Repeated attempts in a short window can trigger an additional security hold.",
            ],
            relatedIDs: ["update_payment_method", "pay_your_bill", "autopay_setup"]
        ),
        TelcoSupportArticle(
            id: "pay_your_bill", category: "billing",
            title: "How to pay your bill",
            snippet: "Step-by-step: pay your monthly CSQMobile bill in the app.",
            body: [
                "Open CSQMobile and tap Bills & Payments. Your current balance and due date appear at the top. Tap Pay Bill, confirm the amount, choose a payment method, then tap Pay Now.",
                "We accept Visa, Mastercard, and your in-app wallet. Payments usually clear instantly, but bank transfers can take up to two business days to reflect.",
                "If your payment keeps failing, it is almost always an issue on the card-issuer side rather than with CSQMobile. See 'Why was my payment declined?' for the most common fixes.",
            ],
            relatedIDs: ["payment_declined", "update_payment_method", "autopay_setup"]
        ),
        TelcoSupportArticle(
            id: "update_payment_method", category: "billing",
            title: "Update your payment method",
            snippet: "Add a new card or change your default payment method.",
            body: [
                "To change the card on file, go to Bills & Payments, tap your payment method, then Add new card. Enter the card details and set it as default. Your old card stays on file until you remove it.",
                "A small temporary authorisation may appear on your statement when you add a card; this is reversed automatically within a few days.",
                "Still seeing a declined charge after updating your card? The new card may have the same online-payment restriction. Contact your bank to confirm recurring payments are allowed.",
            ],
            relatedIDs: ["payment_declined", "autopay_setup", "understanding_charges"]
        ),
        TelcoSupportArticle(
            id: "autopay_setup", category: "billing",
            title: "Set up AutoPay so you never miss a bill",
            snippet: "Automatic monthly payments — and a small loyalty discount.",
            body: [
                "AutoPay charges your default payment method automatically on your due date, so you avoid late fees. Enable it from Bills & Payments → AutoPay.",
                "Customers on AutoPay receive a S$2 monthly loyalty credit. You can turn AutoPay off at any time before your next billing date.",
                "If an AutoPay charge fails, we retry once after 48 hours and notify you. Persistent failures usually mean the card needs updating.",
            ],
            relatedIDs: ["update_payment_method", "payment_declined", "pay_your_bill"]
        ),
        TelcoSupportArticle(
            id: "understanding_charges", category: "billing",
            title: "Understanding the charges on your bill",
            snippet: "Plan fees, device instalments, roaming, add-ons and tax explained.",
            body: [
                "Your bill is made up of your monthly plan fee, any device instalment, usage-based charges such as roaming day-passes or data add-ons, applicable discounts, and tax.",
                "Device instalments appear as 'instalment X of 24' and continue until your contract completes. Roaming and data add-ons are one-off charges that only appear in the month you used them.",
                "If a charge looks unfamiliar, tap the bill to see the full itemised breakdown before contacting us — most questions are answered there.",
            ],
            relatedIDs: ["pay_your_bill", "refunds_overpayments", "payment_declined"]
        ),
        TelcoSupportArticle(
            id: "refunds_overpayments", category: "billing",
            title: "Refunds and overpayments",
            snippet: "What happens if you're charged twice or pay too much.",
            body: [
                "If you were charged twice for the same bill, one charge is typically a temporary authorisation that drops off automatically within 3–5 business days.",
                "Genuine overpayments are credited to your CSQMobile account and applied to your next bill automatically. You can request a refund to your original payment method instead.",
                "Refund requests are reviewed within 5 business days. We'll need your invoice number, which you can find at the top of any statement.",
            ],
            relatedIDs: ["understanding_charges", "pay_your_bill", "update_payment_method"]
        ),
    ]

    // MARK: Japanese (Tokyo)
    static let japaneseArticles: [TelcoSupportArticle] = [
        TelcoSupportArticle(
            id: "payment_declined", category: "billing",
            title: "お支払いが拒否されたのはなぜですか？",
            snippet: "カードやウォレット決済が失敗する主な原因と対処法。",
            body: [
                "お支払いが拒否される原因はいくつかあります。最も多いのは、ご利用の銀行が取引を異常と判断したケースです。CSQモバイルでは銀行が拒否した具体的な理由を確認できないため、カード発行会社にお問い合わせください。",
                "再試行の前に、カードの有効期限が切れていないか、利用可能残高が十分か、オンライン決済・継続課金が有効かをご確認ください。海外発行カードでは銀行アプリでの承認が必要な場合があります。",
                "エラーコード CSQ-4012 が表示された場合、発行銀行によって承認が拒否されたことを意味します。数分待って再試行するか、別のお支払い方法をご利用ください。短時間に何度も試すと追加のセキュリティ保留がかかることがあります。",
            ],
            relatedIDs: ["update_payment_method", "pay_your_bill", "autopay_setup"]
        ),
        TelcoSupportArticle(
            id: "pay_your_bill", category: "billing",
            title: "請求書のお支払い方法",
            snippet: "アプリで毎月のCSQモバイル料金を支払う手順。",
            body: [
                "CSQモバイルを開き「請求とお支払い」をタップします。上部に現在の残高と支払期限が表示されます。「支払う」をタップし、金額を確認、お支払い方法を選んで「今すぐ支払う」をタップします。",
                "Visa、Mastercard、アプリ内ウォレットがご利用いただけます。お支払いは通常即時に反映されますが、銀行振込は最大2営業日かかる場合があります。",
                "お支払いが繰り返し失敗する場合、ほとんどはCSQモバイル側ではなくカード発行会社側の問題です。「お支払いが拒否されたのはなぜですか？」をご覧ください。",
            ],
            relatedIDs: ["payment_declined", "update_payment_method", "autopay_setup"]
        ),
        TelcoSupportArticle(
            id: "update_payment_method", category: "billing",
            title: "お支払い方法の変更",
            snippet: "新しいカードの追加や既定のお支払い方法の変更。",
            body: [
                "登録カードを変更するには、「請求とお支払い」→お支払い方法→「新しいカードを追加」と進みます。カード情報を入力し、既定に設定します。古いカードは削除するまで残ります。",
                "カード追加時に少額の仮承認が明細に表示されることがありますが、数日以内に自動的に取り消されます。",
                "カードを更新しても拒否が続く場合、新しいカードにも同じオンライン決済制限がある可能性があります。継続課金が許可されているか銀行にご確認ください。",
            ],
            relatedIDs: ["payment_declined", "autopay_setup", "understanding_charges"]
        ),
        TelcoSupportArticle(
            id: "autopay_setup", category: "billing",
            title: "自動支払いの設定で支払い忘れを防ぐ",
            snippet: "毎月の自動引き落としと継続割引について。",
            body: [
                "自動支払いは支払期限日に既定のお支払い方法から自動的に引き落とすため、延滞料金を回避できます。「請求とお支払い」→「自動支払い」から有効にできます。",
                "自動支払いをご利用のお客様には月額¥200相当の継続クレジットが付与されます。次回請求日前であればいつでも解除できます。",
                "自動支払いが失敗した場合、48時間後に1回再試行し、通知します。失敗が続く場合は通常カードの更新が必要です。",
            ],
            relatedIDs: ["update_payment_method", "payment_declined", "pay_your_bill"]
        ),
        TelcoSupportArticle(
            id: "understanding_charges", category: "billing",
            title: "請求書の料金内訳について",
            snippet: "プラン料金・端末分割・ローミング・追加・税の説明。",
            body: [
                "請求書は、月額プラン料金、端末の分割金、ローミング1日パスやデータ追加などの従量料金、適用される割引、そして税で構成されます。",
                "端末分割は「分割 X/24回」と表示され、契約満了まで続きます。ローミングやデータ追加は、利用した月のみ表示される一回限りの料金です。",
                "見覚えのない料金がある場合は、お問い合わせの前に請求書をタップして明細をご確認ください。多くのご質問はそこで解決します。",
            ],
            relatedIDs: ["pay_your_bill", "refunds_overpayments", "payment_declined"]
        ),
        TelcoSupportArticle(
            id: "refunds_overpayments", category: "billing",
            title: "返金と過払いについて",
            snippet: "二重請求や払いすぎが発生した場合の対応。",
            body: [
                "同じ請求に対して二重に請求された場合、一方は通常3〜5営業日以内に自動的に消える仮承認です。",
                "実際の過払い分はCSQモバイルのアカウントにクレジットされ、次回の請求に自動的に充当されます。元のお支払い方法への返金をご希望いただくことも可能です。",
                "返金のご依頼は5営業日以内に審査します。各明細の上部に記載された請求書番号が必要です。",
            ],
            relatedIDs: ["understanding_charges", "pay_your_bill", "update_payment_method"]
        ),
    ]
}

// MARK: Support Category (Help Center hub)

struct TelcoSupportCategory: Identifiable {
    let id: String          // stable English key
    let icon: String        // SF Symbol
    let title: String       // localized
    let articleCount: Int

    static func categories(for market: Market) -> [TelcoSupportCategory] {
        let jp = market == .tokyo
        return [
            TelcoSupportCategory(id: "billing",  icon: "creditcard.fill",
                                 title: jp ? "請求とお支払い" : "Billing & Payments", articleCount: 12),
            TelcoSupportCategory(id: "plans",    icon: "simcard.fill",
                                 title: jp ? "プラン・データ" : "Plans & Data", articleCount: 9),
            TelcoSupportCategory(id: "device",   icon: "iphone",
                                 title: jp ? "端末・SIM" : "Device & SIM", articleCount: 7),
            TelcoSupportCategory(id: "account",  icon: "person.crop.circle.fill",
                                 title: jp ? "アカウント・設定" : "Account & Settings", articleCount: 6),
        ]
    }
}
