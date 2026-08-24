import SwiftUI

// MARK: - CSQTix models (ticketing marketplace — concerts, sports, arts & shows)
//
// A Ticketmaster-style vertical. Phase 1 is the BUYER flow: browse → event
// detail → pick tier + quantity → checkout → confirmation. Artist / team / show
// names are LIGHTLY FICTIONALIZED (recognizable, not the real trademarks) — swap
// to real names with a find-replace if desired.
//
// Prices are in each market's local scale (SGD/AUD ~tens–hundreds, JPY ~thousands),
// matching the rest of the app; the view formats them with the market symbol.

enum TixCategory: String, CaseIterable, Identifiable {
    case concerts
    case sports
    case arts
    case family

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .concerts: return "Concerts"
        case .sports:   return "Sports"
        case .arts:     return "Arts & Theatre"
        case .family:   return "Family"
        }
    }

    func displayName(for market: Market) -> String {
        guard market == .tokyo else { return displayName }
        switch self {
        case .concerts: return "ライブ"
        case .sports:   return "スポーツ"
        case .arts:     return "演劇・アート"
        case .family:   return "ファミリー"
        }
    }

    var icon: String {
        switch self {
        case .concerts: return "music.mic"
        case .sports:   return "sportscourt.fill"
        case .arts:     return "theatermasks.fill"
        case .family:   return "figure.2.and.child.holdinghands"
        }
    }
}

struct TixTier: Identifiable {
    let id = UUID()
    let name: String        // user-visible tier name (localized in the data)
    let idKey: String       // stable analytics token — never localize (ga / lower / vip …)
    let price: Double       // face value, local scale
    let perks: String       // short blurb
    let soldOut: Bool

    init(_ name: String, idKey: String, price: Double, perks: String, soldOut: Bool = false) {
        self.name = name
        self.idKey = idKey
        self.price = price
        self.perks = perks
        self.soldOut = soldOut
    }
}

struct TixEvent: Identifiable {
    let id = UUID()
    let name: String        // headline, e.g. "Skylar Quinn — Eras Reimagined"
    let performer: String    // artist / team / company
    let category: TixCategory
    let venue: String
    let city: String
    let dateLabel: String   // "Sat, 14 Jun · 8:00 PM"
    let imageName: String   // asset name — empty/absent = accent-gradient fallback
    let accent: Color
    let tags: [String]      // ["Selling Fast", "Few Left"]
    let idKey: String       // stable analytics token for the event
    let tiers: [TixTier]

    var priceFrom: Double { tiers.filter { !$0.soldOut }.map(\.price).min() ?? tiers.map(\.price).min() ?? 0 }

    static func events(for market: Market) -> [TixEvent] {
        switch market {
        case .tokyo:     return tokyoEvents
        case .sydney:    return sydneyEvents
        default:         return singaporeEvents
        }
    }

    // MARK: Singapore (SGD · English)
    static let singaporeEvents: [TixEvent] = [
        TixEvent(name: "Skylar Quinn — Eras Reimagined", performer: "Skylar Quinn", category: .concerts,
                 venue: "National Stadium", city: "Singapore", dateLabel: "Sat, 14 Jun · 7:00 PM",
                 imageName: "TixSkylarQuinn", accent: Color(hex: "#7C3AED"),
                 tags: ["Selling Fast"], idKey: "skylar_quinn_sg", tiers: [
                    TixTier("General Admission", idKey: "ga", price: 168, perks: "Standing, pitch access"),
                    TixTier("Lower Bowl Seated", idKey: "lower", price: 288, perks: "Reserved seat, level 1"),
                    TixTier("VIP Package", idKey: "vip", price: 688, perks: "Front standing + merch + early entry")
                 ]),
        TixEvent(name: "Ed Sheelan — Mathematics Tour", performer: "Ed Sheelan", category: .concerts,
                 venue: "Indoor Stadium", city: "Singapore", dateLabel: "Fri, 4 Jul · 8:00 PM",
                 imageName: "TixEdSheelan", accent: Color(hex: "#F97316"),
                 tags: ["Few Left"], idKey: "ed_sheelan_sg", tiers: [
                    TixTier("General Admission", idKey: "ga", price: 148, perks: "Standing"),
                    TixTier("Cat 1 Seated", idKey: "lower", price: 228, perks: "Reserved seat"),
                    TixTier("Golden Circle", idKey: "vip", price: 448, perks: "Closest standing + lanyard", soldOut: true)
                 ]),
        TixEvent(name: "Lions FC vs Harbour United", performer: "Premier League Asia", category: .sports,
                 venue: "National Stadium", city: "Singapore", dateLabel: "Sun, 22 Jun · 5:30 PM",
                 imageName: "TixFootball", accent: Color(hex: "#16A34A"),
                 tags: [], idKey: "lions_harbour_sg", tiers: [
                    TixTier("Category 3", idKey: "ga", price: 45, perks: "Upper tier"),
                    TixTier("Category 1", idKey: "lower", price: 95, perks: "Halfway line, lower tier"),
                    TixTier("Hospitality", idKey: "vip", price: 320, perks: "Lounge + buffet + premium seat")
                 ]),
        TixEvent(name: "Gridiron Global Series: Sharks vs Titans", performer: "National Gridiron League", category: .sports,
                 venue: "National Stadium", city: "Singapore", dateLabel: "Sun, 26 Oct · 1:00 PM",
                 imageName: "TixGridiron", accent: Color(hex: "#1D4ED8"),
                 tags: ["Selling Fast"], idKey: "gridiron_sg", tiers: [
                    TixTier("End Zone", idKey: "ga", price: 88, perks: "End zone seating"),
                    TixTier("Sideline", idKey: "lower", price: 188, perks: "Sideline, lower tier"),
                    TixTier("50-Yard Club", idKey: "vip", price: 520, perks: "Midfield + club access")
                 ]),
        TixEvent(name: "Cirque Lumina — Aurora", performer: "Cirque Lumina", category: .arts,
                 venue: "Marina Bay Sands Theatre", city: "Singapore", dateLabel: "Wed, 18 Jun · 8:00 PM",
                 imageName: "TixCirque", accent: Color(hex: "#DB2777"),
                 tags: [], idKey: "cirque_sg", tiers: [
                    TixTier("Balcony", idKey: "ga", price: 78, perks: "Upper balcony"),
                    TixTier("Stalls", idKey: "lower", price: 158, perks: "Main floor"),
                    TixTier("Premium Front", idKey: "vip", price: 268, perks: "Front rows + programme")
                 ]),
        TixEvent(name: "Marina Bay Orchid & Flower Expo", performer: "Gardens Festival", category: .family,
                 venue: "Gardens by the Bay", city: "Singapore", dateLabel: "Sat–Sun, 12–13 Jul · 10:00 AM",
                 imageName: "TixFlower", accent: Color(hex: "#0EA5E9"),
                 tags: [], idKey: "flower_expo_sg", tiers: [
                    TixTier("Day Pass", idKey: "ga", price: 28, perks: "General entry"),
                    TixTier("Guided Tour", idKey: "lower", price: 58, perks: "Entry + curator tour"),
                    TixTier("Family Bundle", idKey: "vip", price: 88, perks: "2 adults + 2 kids")
                 ]),
        TixEvent(name: "Coldsky — Music of the Spheres", performer: "Coldsky", category: .concerts,
                 venue: "National Stadium", city: "Singapore", dateLabel: "Sat, 9 Aug · 8:00 PM",
                 imageName: "TixColdsky", accent: Color(hex: "#2563EB"),
                 tags: ["Selling Fast"], idKey: "coldsky_sg", tiers: [
                    TixTier("General Admission", idKey: "ga", price: 168, perks: "Standing, pitch access"),
                    TixTier("Lower Bowl Seated", idKey: "lower", price: 268, perks: "Reserved seat, level 1"),
                    TixTier("VIP Package", idKey: "vip", price: 528, perks: "Front standing + merch + early entry")
                 ]),
        TixEvent(name: "Singapore Grand Prix — Night Race", performer: "Formula 1", category: .sports,
                 venue: "Marina Bay Street Circuit", city: "Singapore", dateLabel: "Sun, 21 Sep · 8:00 PM",
                 imageName: "TixF1", accent: Color(hex: "#DC2626"),
                 tags: ["Selling Fast"], idKey: "singapore_gp_sg", tiers: [
                    TixTier("Walkabout (3-Day)", idKey: "ga", price: 268, perks: "General standing, all zones"),
                    TixTier("Bay Grandstand", idKey: "lower", price: 498, perks: "Reserved grandstand"),
                    TixTier("Paddock Club", idKey: "vip", price: 1_288, perks: "Trackside suite + hospitality")
                 ]),
        TixEvent(name: "Lion City Sailors vs Tampines Rovers", performer: "Singapore Premier League", category: .sports,
                 venue: "Jalan Besar Stadium", city: "Singapore", dateLabel: "Sat, 5 Jul · 7:30 PM",
                 imageName: "TixFootball", accent: Color(hex: "#16A34A"),
                 tags: [], idKey: "sailors_tampines_sg", tiers: [
                    TixTier("Category 3", idKey: "ga", price: 18, perks: "Standing / upper"),
                    TixTier("Category 1", idKey: "lower", price: 38, perks: "Halfway line"),
                    TixTier("Premium", idKey: "vip", price: 78, perks: "Best seats + lounge")
                 ]),
        TixEvent(name: "Singapore Slingers vs Hong Kong Eastern", performer: "ASEAN Basketball League", category: .sports,
                 venue: "OCBC Arena", city: "Singapore", dateLabel: "Fri, 18 Jul · 8:00 PM",
                 imageName: "TixBasketball", accent: Color(hex: "#EA580C"),
                 tags: [], idKey: "slingers_eastern_sg", tiers: [
                    TixTier("General Admission", idKey: "ga", price: 25, perks: "Open seating"),
                    TixTier("Lower Tier", idKey: "lower", price: 55, perks: "Reserved lower bowl"),
                    TixTier("Courtside", idKey: "vip", price: 120, perks: "Courtside seats")
                 ]),
        TixEvent(name: "HYROX Singapore", performer: "HYROX", category: .sports,
                 venue: "Singapore Expo", city: "Singapore", dateLabel: "Sat–Sun, 16–17 Aug · 8:00 AM",
                 imageName: "TixHyrox", accent: Color(hex: "#0F172A"),
                 tags: ["New"], idKey: "hyrox_sg", tiers: [
                    TixTier("Spectator", idKey: "ga", price: 25, perks: "Watch all heats"),
                    TixTier("Competitor — Single", idKey: "lower", price: 145, perks: "Race entry + timing chip"),
                    TixTier("Competitor + Finisher Pack", idKey: "vip", price: 195, perks: "Entry + kit + finisher medal")
                 ]),
        TixEvent(name: "Monster Truck Mayhem", performer: "Monster Truck Mayhem Tour", category: .family,
                 venue: "National Stadium", city: "Singapore", dateLabel: "Sat, 30 Aug · 6:00 PM",
                 imageName: "TixMonsterTruck", accent: Color(hex: "#CA8A04"),
                 tags: ["Few Left"], idKey: "monster_truck_sg", tiers: [
                    TixTier("General Admission", idKey: "ga", price: 48, perks: "Grandstand seating"),
                    TixTier("Pit Party Pass", idKey: "lower", price: 88, perks: "Pre-show pit access + seating"),
                    TixTier("VIP Trackside", idKey: "vip", price: 148, perks: "Trackside + driver meet & greet")
                 ])
    ]

    // MARK: Tokyo (JPY · 日本語)
    static let tokyoEvents: [TixEvent] = [
        TixEvent(name: "スカイラー・クイン — Eras Reimagined", performer: "スカイラー・クイン", category: .concerts,
                 venue: "東京ドーム", city: "東京", dateLabel: "6月14日(土) 18:00",
                 imageName: "TixSkylarQuinn", accent: Color(hex: "#7C3AED"),
                 tags: ["残りわずか"], idKey: "skylar_quinn_tk", tiers: [
                    TixTier("スタンディング", idKey: "ga", price: 16_800, perks: "アリーナ立見"),
                    TixTier("指定席（1階）", idKey: "lower", price: 22_800, perks: "1階指定席"),
                    TixTier("VIPパッケージ", idKey: "vip", price: 58_000, perks: "最前エリア＋グッズ＋優先入場")
                 ]),
        TixEvent(name: "エド・シーラン — Mathematics", performer: "エド・シーラン", category: .concerts,
                 venue: "さいたまスーパーアリーナ", city: "東京", dateLabel: "7月4日(金) 19:00",
                 imageName: "TixEdSheelan", accent: Color(hex: "#F97316"),
                 tags: ["完売間近"], idKey: "ed_sheelan_tk", tiers: [
                    TixTier("スタンディング", idKey: "ga", price: 13_800, perks: "立見"),
                    TixTier("指定席", idKey: "lower", price: 19_800, perks: "指定席"),
                    TixTier("ゴールデンサークル", idKey: "vip", price: 39_800, perks: "最前立見＋ラミネート", soldOut: true)
                 ]),
        TixEvent(name: "東京FC vs 横浜マリンズ", performer: "Jプレミアリーグ", category: .sports,
                 venue: "国立競技場", city: "東京", dateLabel: "6月22日(日) 17:30",
                 imageName: "TixFootball", accent: Color(hex: "#16A34A"),
                 tags: [], idKey: "tokyo_yokohama_tk", tiers: [
                    TixTier("カテゴリー3", idKey: "ga", price: 4_500, perks: "上層スタンド"),
                    TixTier("カテゴリー1", idKey: "lower", price: 9_500, perks: "センターライン下層"),
                    TixTier("ホスピタリティ", idKey: "vip", price: 32_000, perks: "ラウンジ＋ビュッフェ")
                 ]),
        TixEvent(name: "グローバルシリーズ: シャークス vs タイタンズ", performer: "ナショナル・グリッドアイアン・リーグ", category: .sports,
                 venue: "東京ドーム", city: "東京", dateLabel: "10月26日(日) 13:00",
                 imageName: "TixGridiron", accent: Color(hex: "#1D4ED8"),
                 tags: ["残りわずか"], idKey: "gridiron_tk", tiers: [
                    TixTier("エンドゾーン", idKey: "ga", price: 8_800, perks: "エンドゾーン席"),
                    TixTier("サイドライン", idKey: "lower", price: 18_800, perks: "サイドライン下層"),
                    TixTier("50ヤードクラブ", idKey: "vip", price: 52_000, perks: "センター＋クラブ入場")
                 ]),
        TixEvent(name: "シルク・ルミナ — オーロラ", performer: "シルク・ルミナ", category: .arts,
                 venue: "東急シアターオーブ", city: "東京", dateLabel: "6月18日(水) 19:00",
                 imageName: "TixCirque", accent: Color(hex: "#DB2777"),
                 tags: [], idKey: "cirque_tk", tiers: [
                    TixTier("バルコニー", idKey: "ga", price: 7_800, perks: "上階バルコニー"),
                    TixTier("1階席", idKey: "lower", price: 15_800, perks: "1階フロア"),
                    TixTier("プレミアム前方", idKey: "vip", price: 26_800, perks: "前列＋プログラム")
                 ]),
        TixEvent(name: "東京らん・フラワーエキスポ", performer: "ガーデンフェスティバル", category: .family,
                 venue: "東京ビッグサイト", city: "東京", dateLabel: "7月12–13日(土日) 10:00",
                 imageName: "TixFlower", accent: Color(hex: "#0EA5E9"),
                 tags: [], idKey: "flower_expo_tk", tiers: [
                    TixTier("1日券", idKey: "ga", price: 2_800, perks: "通常入場"),
                    TixTier("ガイドツアー", idKey: "lower", price: 5_800, perks: "入場＋ツアー"),
                    TixTier("ファミリー券", idKey: "vip", price: 8_800, perks: "大人2＋子供2")
                 ]),
        TixEvent(name: "コールドスカイ — Music of the Spheres", performer: "コールドスカイ", category: .concerts,
                 venue: "東京ドーム", city: "東京", dateLabel: "8月9日(土) 18:00",
                 imageName: "TixColdsky", accent: Color(hex: "#2563EB"),
                 tags: ["残りわずか"], idKey: "coldsky_tk", tiers: [
                    TixTier("スタンディング", idKey: "ga", price: 16_800, perks: "アリーナ立見"),
                    TixTier("指定席（1階）", idKey: "lower", price: 22_800, perks: "1階指定席"),
                    TixTier("VIPパッケージ", idKey: "vip", price: 52_000, perks: "最前エリア＋グッズ")
                 ]),
        TixEvent(name: "読売ジャイアンツ vs 阪神タイガース", performer: "プロ野球", category: .sports,
                 venue: "東京ドーム", city: "東京", dateLabel: "7月8日(火) 18:00",
                 imageName: "TixBaseball", accent: Color(hex: "#EA580C"),
                 tags: ["人気"], idKey: "giants_tigers_tk", tiers: [
                    TixTier("外野自由席", idKey: "ga", price: 2_800, perks: "外野自由"),
                    TixTier("内野指定席", idKey: "lower", price: 5_800, perks: "内野指定"),
                    TixTier("プレミアムシート", idKey: "vip", price: 12_000, perks: "バックネット裏＋飲食付")
                 ]),
        TixEvent(name: "FC東京 vs 川崎フロンターレ", performer: "Jリーグ", category: .sports,
                 venue: "国立競技場", city: "東京", dateLabel: "7月5日(土) 19:00",
                 imageName: "TixFootball", accent: Color(hex: "#1D4ED8"),
                 tags: [], idKey: "fctokyo_kawasaki_tk", tiers: [
                    TixTier("カテゴリー3", idKey: "ga", price: 3_500, perks: "上層スタンド"),
                    TixTier("カテゴリー1", idKey: "lower", price: 7_500, perks: "センターライン下層"),
                    TixTier("SS指定席", idKey: "vip", price: 12_000, perks: "最前列＋ラウンジ")
                 ]),
        TixEvent(name: "大相撲 東京場所", performer: "日本相撲協会", category: .sports,
                 venue: "両国国技館", city: "東京", dateLabel: "9月14日(日) 15:00",
                 imageName: "TixSumo", accent: Color(hex: "#9F1239"),
                 tags: ["人気"], idKey: "sumo_tk", tiers: [
                    TixTier("自由席", idKey: "ga", price: 3_800, perks: "2階自由席"),
                    TixTier("マス席（4人）", idKey: "lower", price: 11_800, perks: "1階マス席・4名"),
                    TixTier("溜席", idKey: "vip", price: 22_000, perks: "土俵際・最前")
                 ]),
        TixEvent(name: "HYROX 東京", performer: "HYROX", category: .sports,
                 venue: "幕張メッセ", city: "東京", dateLabel: "8月16–17日(土日) 8:00",
                 imageName: "TixHyrox", accent: Color(hex: "#0F172A"),
                 tags: ["新着"], idKey: "hyrox_tk", tiers: [
                    TixTier("観戦チケット", idKey: "ga", price: 2_800, perks: "全ヒート観戦"),
                    TixTier("参加（シングル）", idKey: "lower", price: 15_000, perks: "レース参加＋計測チップ"),
                    TixTier("参加＋フィニッシャーパック", idKey: "vip", price: 19_800, perks: "参加＋キット＋メダル")
                 ]),
        TixEvent(name: "モンスタートラック・メイヘム", performer: "モンスタートラック・メイヘム", category: .family,
                 venue: "東京ドーム", city: "東京", dateLabel: "8月30日(土) 18:00",
                 imageName: "TixMonsterTruck", accent: Color(hex: "#CA8A04"),
                 tags: ["残りわずか"], idKey: "monster_truck_tk", tiers: [
                    TixTier("一般席", idKey: "ga", price: 4_800, perks: "スタンド席"),
                    TixTier("ピットパス", idKey: "lower", price: 8_800, perks: "ピット入場＋席"),
                    TixTier("VIPトラックサイド", idKey: "vip", price: 14_800, perks: "トラックサイド＋ドライバー交流")
                 ])
    ]

    // MARK: Sydney (AUD · English)
    static let sydneyEvents: [TixEvent] = [
        TixEvent(name: "Skylar Quinn — Eras Reimagined", performer: "Skylar Quinn", category: .concerts,
                 venue: "Accor Stadium", city: "Sydney", dateLabel: "Sat, 14 Jun · 7:00 PM",
                 imageName: "TixSkylarQuinn", accent: Color(hex: "#7C3AED"),
                 tags: ["Selling Fast"], idKey: "skylar_quinn_syd", tiers: [
                    TixTier("General Admission", idKey: "ga", price: 179, perks: "Standing, floor access"),
                    TixTier("Lower Grandstand", idKey: "lower", price: 299, perks: "Reserved seat, lower tier"),
                    TixTier("VIP Package", idKey: "vip", price: 720, perks: "Front standing + merch + early entry")
                 ]),
        TixEvent(name: "Ed Sheelan — Mathematics Tour", performer: "Ed Sheelan", category: .concerts,
                 venue: "Qudos Bank Arena", city: "Sydney", dateLabel: "Fri, 4 Jul · 8:00 PM",
                 imageName: "TixEdSheelan", accent: Color(hex: "#F97316"),
                 tags: ["Few Left"], idKey: "ed_sheelan_syd", tiers: [
                    TixTier("General Admission", idKey: "ga", price: 159, perks: "Standing"),
                    TixTier("Cat 1 Seated", idKey: "lower", price: 239, perks: "Reserved seat"),
                    TixTier("Golden Circle", idKey: "vip", price: 469, perks: "Closest standing + lanyard", soldOut: true)
                 ]),
        TixEvent(name: "Sydney FC vs Melbourne Victory", performer: "A-League", category: .sports,
                 venue: "Allianz Stadium", city: "Sydney", dateLabel: "Sun, 22 Jun · 5:00 PM",
                 imageName: "TixFootball", accent: Color(hex: "#16A34A"),
                 tags: [], idKey: "sydney_melbourne_syd", tiers: [
                    TixTier("General Admission", idKey: "ga", price: 39, perks: "GA bay"),
                    TixTier("Premium Reserved", idKey: "lower", price: 89, perks: "Halfway, lower tier"),
                    TixTier("Corporate Box", idKey: "vip", price: 340, perks: "Box + catering")
                 ]),
        TixEvent(name: "Gridiron Global Series: Sharks vs Titans", performer: "National Gridiron League", category: .sports,
                 venue: "Accor Stadium", city: "Sydney", dateLabel: "Sun, 26 Oct · 1:00 PM",
                 imageName: "TixGridiron", accent: Color(hex: "#1D4ED8"),
                 tags: ["Selling Fast"], idKey: "gridiron_syd", tiers: [
                    TixTier("End Zone", idKey: "ga", price: 95, perks: "End zone seating"),
                    TixTier("Sideline", idKey: "lower", price: 199, perks: "Sideline, lower tier"),
                    TixTier("50-Yard Club", idKey: "vip", price: 540, perks: "Midfield + club access")
                 ]),
        TixEvent(name: "Cirque Lumina — Aurora", performer: "Cirque Lumina", category: .arts,
                 venue: "Sydney Opera House", city: "Sydney", dateLabel: "Wed, 18 Jun · 8:00 PM",
                 imageName: "TixCirque", accent: Color(hex: "#DB2777"),
                 tags: [], idKey: "cirque_syd", tiers: [
                    TixTier("Balcony", idKey: "ga", price: 85, perks: "Upper balcony"),
                    TixTier("Stalls", idKey: "lower", price: 169, perks: "Main floor"),
                    TixTier("Premium Front", idKey: "vip", price: 289, perks: "Front rows + programme")
                 ]),
        TixEvent(name: "Royal Sydney Flower & Garden Show", performer: "Gardens Festival", category: .family,
                 venue: "Royal Botanic Garden", city: "Sydney", dateLabel: "Sat–Sun, 12–13 Jul · 10:00 AM",
                 imageName: "TixFlower", accent: Color(hex: "#0EA5E9"),
                 tags: [], idKey: "flower_expo_syd", tiers: [
                    TixTier("Day Pass", idKey: "ga", price: 32, perks: "General entry"),
                    TixTier("Guided Tour", idKey: "lower", price: 62, perks: "Entry + curator tour"),
                    TixTier("Family Bundle", idKey: "vip", price: 95, perks: "2 adults + 2 kids")
                 ]),
        TixEvent(name: "Coldsky — Music of the Spheres", performer: "Coldsky", category: .concerts,
                 venue: "Accor Stadium", city: "Sydney", dateLabel: "Sat, 9 Aug · 7:30 PM",
                 imageName: "TixColdsky", accent: Color(hex: "#2563EB"),
                 tags: ["Selling Fast"], idKey: "coldsky_syd", tiers: [
                    TixTier("General Admission", idKey: "ga", price: 179, perks: "Standing, floor access"),
                    TixTier("Lower Grandstand", idKey: "lower", price: 289, perks: "Reserved seat, lower tier"),
                    TixTier("VIP Package", idKey: "vip", price: 549, perks: "Front standing + merch + early entry")
                 ]),
        TixEvent(name: "Sydney Swans vs Collingwood", performer: "AFL", category: .sports,
                 venue: "Sydney Cricket Ground", city: "Sydney", dateLabel: "Sat, 12 Jul · 1:45 PM",
                 imageName: "TixAFL", accent: Color(hex: "#DC2626"),
                 tags: ["Selling Fast"], idKey: "swans_collingwood_syd", tiers: [
                    TixTier("General Admission", idKey: "ga", price: 35, perks: "GA bays"),
                    TixTier("Reserved Seating", idKey: "lower", price: 79, perks: "Reserved grandstand"),
                    TixTier("Premium", idKey: "vip", price: 149, perks: "Best seats + lounge access")
                 ]),
        TixEvent(name: "Sydney Roosters vs South Sydney Rabbitohs", performer: "NRL", category: .sports,
                 venue: "Allianz Stadium", city: "Sydney", dateLabel: "Fri, 18 Jul · 8:00 PM",
                 imageName: "TixNRL", accent: Color(hex: "#1E3A8A"),
                 tags: ["Few Left"], idKey: "roosters_rabbitohs_syd", tiers: [
                    TixTier("General Admission", idKey: "ga", price: 39, perks: "GA bays"),
                    TixTier("Grandstand", idKey: "lower", price: 89, perks: "Reserved grandstand"),
                    TixTier("Members Reserve", idKey: "vip", price: 159, perks: "Halfway + lounge")
                 ]),
        TixEvent(name: "Australia vs India — 3rd Test", performer: "Cricket Australia", category: .sports,
                 venue: "Sydney Cricket Ground", city: "Sydney", dateLabel: "Thu–Mon, 3–7 Jan · 10:30 AM",
                 imageName: "TixCricket", accent: Color(hex: "#15803D"),
                 tags: [], idKey: "aus_india_test_syd", tiers: [
                    TixTier("General Admission (Day 1)", idKey: "ga", price: 45, perks: "GA hill / bays"),
                    TixTier("Reserved (Day 1)", idKey: "lower", price: 99, perks: "Reserved grandstand"),
                    TixTier("Pavilion (Day 1)", idKey: "vip", price: 220, perks: "Members pavilion + dining")
                 ]),
        TixEvent(name: "HYROX Sydney", performer: "HYROX", category: .sports,
                 venue: "Sydney Olympic Park", city: "Sydney", dateLabel: "Sat–Sun, 16–17 Aug · 8:00 AM",
                 imageName: "TixHyrox", accent: Color(hex: "#0F172A"),
                 tags: ["New"], idKey: "hyrox_syd", tiers: [
                    TixTier("Spectator", idKey: "ga", price: 29, perks: "Watch all heats"),
                    TixTier("Competitor — Single", idKey: "lower", price: 149, perks: "Race entry + timing chip"),
                    TixTier("Competitor + Finisher Pack", idKey: "vip", price: 199, perks: "Entry + kit + finisher medal")
                 ]),
        TixEvent(name: "Monster Truck Mayhem", performer: "Monster Truck Mayhem Tour", category: .family,
                 venue: "Accor Stadium", city: "Sydney", dateLabel: "Sat, 30 Aug · 6:00 PM",
                 imageName: "TixMonsterTruck", accent: Color(hex: "#CA8A04"),
                 tags: ["Few Left"], idKey: "monster_truck_syd", tiers: [
                    TixTier("General Admission", idKey: "ga", price: 45, perks: "Grandstand seating"),
                    TixTier("Pit Party Pass", idKey: "lower", price: 89, perks: "Pre-show pit access + seating"),
                    TixTier("VIP Trackside", idKey: "vip", price: 159, perks: "Trackside + driver meet & greet")
                 ])
    ]
}
