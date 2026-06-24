import SwiftUI

enum FoodCategory: String, CaseIterable {
    case all = "all"
    case hawker = "hawker"
    case japanese = "japanese"
    case western = "western"
    case chinese = "chinese"
    case indian = "indian"
    case desserts = "desserts"
    case halal = "halal"
    case healthy = "healthy"

    var displayName: String {
        switch self {
        case .all: return "All"
        case .hawker: return "Hawker"
        case .japanese: return "Japanese"
        case .western: return "Western"
        case .chinese: return "Chinese"
        case .indian: return "Indian"
        case .desserts: return "Desserts"
        case .halal: return "Halal"
        case .healthy: return "Healthy"
        }
    }

    func displayName(for market: Market) -> String {
        switch market {
        case .tokyo:
            switch self {
            case .all: return "すべて"
            case .hawker: return "屋台・定食"
            case .japanese: return "和食"
            case .western: return "洋食"
            case .chinese: return "中華"
            case .indian: return "インド料理"
            case .desserts: return "スイーツ"
            case .halal: return "ハラル"
            case .healthy: return "ヘルシー"
            }
        default:
            // Singapore, Sydney, and any future English-language market.
            return displayName
        }
    }

    var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .hawker: return "fork.knife"
        case .japanese: return "sushi"
        case .western: return "fork.knife"
        case .chinese: return "bowl.and.spoon"
        case .indian: return "curry.spoon"
        case .desserts: return "birthday.cake"
        case .halal: return "moon.stars"
        case .healthy: return "leaf"
        }
    }
}

struct MenuItem: Identifiable {
    let id: UUID = UUID()
    let name: String           // User-visible item name (localized per market).
    let description: String
    let price: Double
    let isPopular: Bool
    let tag: String?
    let idKey: String          // Stable ASCII key for accessibilityIdentifier. Never localize.

    init(name: String, description: String = "", price: Double, isPopular: Bool = false, tag: String? = nil, idKey: String? = nil) {
        self.name = name
        self.description = description
        self.price = price
        self.isPopular = isPopular
        self.tag = tag
        // Singapore items pass no idKey → derive from the (English) name so existing
        // identifiers are byte-for-byte unchanged. Tokyo items pass an explicit romaji idKey.
        self.idKey = idKey ?? name
    }

    // Per-dish photo asset name, derived from idKey: "Dish_" + idKey with each run of
    // non-ASCII-alphanumeric characters collapsed to a single underscore.
    // e.g. "Chicken Satay 10pcs" -> "Dish_Chicken_Satay_10pcs", "extra_chashu" -> "Dish_extra_chashu".
    // Drop a matching image into Assets.xcassets to replace the placeholder; absent = no thumbnail.
    var imageAssetName: String {
        let mapped = String(idKey.map { ($0.isASCII && ($0.isLetter || $0.isNumber)) ? $0 : "_" })
        let parts = mapped.split(separator: "_", omittingEmptySubsequences: true)
        return "Dish_" + parts.joined(separator: "_")
    }
}

struct MenuSection: Identifiable {
    let id: UUID = UUID()
    let name: String
    let items: [MenuItem]
}

struct Restaurant: Identifiable {
    let id: UUID = UUID()
    let name: String
    let cuisine: String
    let category: FoodCategory
    let rating: Double
    let reviewCount: Int
    let deliveryTime: String
    let deliveryFee: String
    let minOrder: String
    let distance: String
    let promo: String?
    let headerColor: Color
    let imageName: String          // Xcode asset name — empty = gradient fallback
    let menu: [MenuSection]

    static let sampleRestaurants: [Restaurant] = [
        Restaurant(
            name: "Lau Pa Sat",
            cuisine: "Hawker · Mixed",
            category: .hawker,
            rating: 4.8,
            reviewCount: 9210,
            deliveryTime: "15–25 min",
            deliveryFee: "Free",
            minOrder: "S$10",
            distance: "1.1 km",
            promo: "Popular",
            headerColor: Color(hex: "#92400E"),
            imageName: "FoodLauPaSat",
            menu: [
                MenuSection(name: "Satay", items: [
                    MenuItem(name: "Chicken Satay 10pcs", description: "Grilled skewers with peanut sauce & ketupat", price: 14.00, isPopular: true, tag: "Bestseller"),
                    MenuItem(name: "Beef Satay 10pcs", description: "", price: 16.00, isPopular: false, tag: nil),
                    MenuItem(name: "Mixed Satay 20pcs", description: "", price: 28.00, isPopular: false, tag: "Popular")
                ]),
                MenuSection(name: "Hawker Plates", items: [
                    MenuItem(name: "Char Kway Teow", description: "Wok-fried rice noodles with cockles & Chinese sausage", price: 8.00, isPopular: true, tag: "Bestseller"),
                    MenuItem(name: "Hokkien Mee", description: "", price: 7.50, isPopular: false, tag: nil),
                    MenuItem(name: "Oyster Omelette", description: "", price: 9.00, isPopular: false, tag: "Popular")
                ]),
                MenuSection(name: "Drinks", items: [
                    MenuItem(name: "Fresh Sugar Cane Juice", description: "", price: 3.00, isPopular: false, tag: nil),
                    MenuItem(name: "Bandung", description: "", price: 2.50, isPopular: false, tag: nil)
                ])
            ]
        ),
        Restaurant(
            name: "Ya Kun Kaya Toast",
            cuisine: "Kaya Toast · Breakfast",
            category: .hawker,
            rating: 4.7,
            reviewCount: 2840,
            deliveryTime: "10–15 min",
            deliveryFee: "Free",
            minOrder: "S$8",
            distance: "0.3 km",
            promo: nil,
            headerColor: Color(hex: "#C8860A"),
            imageName: "FoodYaKun",
            menu: [
                MenuSection(
                    name: "Classic Sets",
                    items: [
                        MenuItem(name: "Set A", description: "Toast+Eggs+Kopi", price: 7.50, isPopular: true, tag: "Bestseller"),
                        MenuItem(name: "Set B", description: "French Toast+Eggs+Teh", price: 8.50, isPopular: false, tag: nil)
                    ]
                ),
                MenuSection(
                    name: "Toast",
                    items: [
                        MenuItem(name: "Kaya Toast", description: "", price: 3.20, isPopular: true, tag: "Bestseller"),
                        MenuItem(name: "French Toast", description: "", price: 4.50, isPopular: false, tag: nil),
                        MenuItem(name: "Thick Toast", description: "", price: 4.50, isPopular: false, tag: nil)
                    ]
                ),
                MenuSection(
                    name: "Eggs & Sides",
                    items: [
                        MenuItem(name: "Soft Boiled Eggs", description: "", price: 2.50, isPopular: true, tag: "Bestseller"),
                        MenuItem(name: "Half Boiled Egg", description: "", price: 1.30, isPopular: false, tag: nil)
                    ]
                ),
                MenuSection(
                    name: "Drinks",
                    items: [
                        MenuItem(name: "Kopi", description: "", price: 1.80, isPopular: false, tag: nil),
                        MenuItem(name: "Kopi C", description: "", price: 2.00, isPopular: false, tag: nil),
                        MenuItem(name: "Teh", description: "", price: 1.80, isPopular: false, tag: nil),
                        MenuItem(name: "Milo Dinosaur", description: "", price: 3.50, isPopular: false, tag: "Popular")
                    ]
                )
            ]
        ),
        Restaurant(
            name: "The Coconut Club",
            cuisine: "Nasi Lemak · Local",
            category: .hawker,
            rating: 4.8,
            reviewCount: 3210,
            deliveryTime: "15–20 min",
            deliveryFee: "Free",
            minOrder: "S$12",
            distance: "0.8 km",
            promo: "20% OFF",
            headerColor: Color(hex: "#2D6A4F"),
            imageName: "FoodCoconutClub",
            menu: [
                MenuSection(
                    name: "Nasi Lemak",
                    items: [
                        MenuItem(name: "The Classic Set", description: "Fragrant coconut rice, crispy ikan bilis, sambal, cucumber & egg", price: 14.00, isPopular: true, tag: "Bestseller"),
                        MenuItem(name: "Special with Prawn", description: "", price: 18.00, isPopular: false, tag: nil),
                        MenuItem(name: "With Chicken Wing", description: "", price: 16.00, isPopular: false, tag: "Popular"),
                        MenuItem(name: "With Otah", description: "", price: 16.00, isPopular: false, tag: nil)
                    ]
                ),
                MenuSection(
                    name: "Sides",
                    items: [
                        MenuItem(name: "Extra Sambal", description: "", price: 2.00, isPopular: false, tag: nil),
                        MenuItem(name: "Ikan Bilis & Peanuts", description: "", price: 3.00, isPopular: false, tag: nil),
                        MenuItem(name: "Achar", description: "", price: 3.00, isPopular: false, tag: "Veg"),
                        MenuItem(name: "Ayam Goreng", description: "", price: 8.00, isPopular: false, tag: nil)
                    ]
                ),
                MenuSection(
                    name: "Drinks",
                    items: [
                        MenuItem(name: "Bandung", description: "", price: 4.50, isPopular: false, tag: nil),
                        MenuItem(name: "Iced Coconut Water", description: "", price: 5.50, isPopular: false, tag: nil),
                        MenuItem(name: "Teh Tarik", description: "", price: 4.00, isPopular: false, tag: "Popular")
                    ]
                )
            ]
        ),
        Restaurant(
            name: "Tim Ho Wan",
            cuisine: "Dim Sum · Chinese",
            category: .chinese,
            rating: 4.6,
            reviewCount: 5420,
            deliveryTime: "20–25 min",
            deliveryFee: "S$1.99",
            minOrder: "S$15",
            distance: "1.2 km",
            promo: nil,
            headerColor: Color(hex: "#9B2335"),
            imageName: "FoodTimHoWan",
            menu: [
                MenuSection(
                    name: "Baked & Fried",
                    items: [
                        MenuItem(name: "Baked BBQ Pork Buns 3pcs", description: "", price: 7.50, isPopular: true, tag: "Bestseller"),
                        MenuItem(name: "Crispy Taro Dumpling 3pcs", description: "", price: 6.50, isPopular: false, tag: nil),
                        MenuItem(name: "Pan-Fried Carrot Cake", description: "", price: 6.50, isPopular: false, tag: nil)
                    ]
                ),
                MenuSection(
                    name: "Steamed",
                    items: [
                        MenuItem(name: "Ha Gao 4pcs", description: "", price: 8.50, isPopular: true, tag: "Popular"),
                        MenuItem(name: "Siu Mai 4pcs", description: "", price: 7.50, isPopular: false, tag: "Popular"),
                        MenuItem(name: "Cheung Fun Shrimp", description: "", price: 8.00, isPopular: false, tag: nil)
                    ]
                ),
                MenuSection(
                    name: "Rice & Congee",
                    items: [
                        MenuItem(name: "Glutinous Rice in Lotus Leaf", description: "", price: 9.50, isPopular: false, tag: nil),
                        MenuItem(name: "Pork & Century Egg Congee", description: "", price: 7.50, isPopular: false, tag: nil)
                    ]
                ),
                MenuSection(
                    name: "Desserts",
                    items: [
                        MenuItem(name: "Egg Tart 2pcs", description: "", price: 5.50, isPopular: true, tag: "Bestseller"),
                        MenuItem(name: "Mango Pudding", description: "", price: 5.00, isPopular: false, tag: nil)
                    ]
                )
            ]
        ),
        Restaurant(
            name: "Song Fa Bak Kut Teh",
            cuisine: "Bak Kut Teh · Singaporean",
            category: .chinese,
            rating: 4.7,
            reviewCount: 4180,
            deliveryTime: "25–35 min",
            deliveryFee: "S$1.99",
            minOrder: "S$18",
            distance: "1.5 km",
            promo: nil,
            headerColor: Color(hex: "#7C3A1E"),
            imageName: "FoodSongFa",
            menu: [
                MenuSection(
                    name: "Bak Kut Teh",
                    items: [
                        MenuItem(name: "Peppery Soup Solo", description: "", price: 13.90, isPopular: true, tag: "Bestseller"),
                        MenuItem(name: "Premium Spare Ribs", description: "", price: 16.90, isPopular: false, tag: nil),
                        MenuItem(name: "Mushroom & Tofu Soup", description: "", price: 8.90, isPopular: false, tag: "Veg")
                    ]
                ),
                MenuSection(
                    name: "Sides",
                    items: [
                        MenuItem(name: "Braised Pork Trotters", description: "", price: 12.90, isPopular: false, tag: nil),
                        MenuItem(name: "You Tiao", description: "", price: 3.50, isPopular: false, tag: "Bestseller"),
                        MenuItem(name: "Braised Peanuts", description: "", price: 4.50, isPopular: false, tag: nil)
                    ]
                ),
                MenuSection(
                    name: "Rice & Others",
                    items: [
                        MenuItem(name: "White Rice", description: "", price: 1.00, isPopular: false, tag: nil),
                        MenuItem(name: "Dark Soy Chicken", description: "", price: 14.90, isPopular: false, tag: nil)
                    ]
                )
            ]
        ),
        Restaurant(
            name: "Violet Oon Singapore",
            cuisine: "Peranakan · Nyonya",
            category: .western,
            rating: 4.7,
            reviewCount: 1890,
            deliveryTime: "30–40 min",
            deliveryFee: "S$2.99",
            minOrder: "S$25",
            distance: "2.1 km",
            promo: "Free Delivery",
            headerColor: Color(hex: "#6B21A8"),
            imageName: "FoodVioletOon",
            menu: [
                MenuSection(
                    name: "Peranakan Mains",
                    items: [
                        MenuItem(name: "Buah Keluak Pork Belly", description: "", price: 28.00, isPopular: true, tag: "Bestseller"),
                        MenuItem(name: "Ayam Buah Keluak", description: "", price: 26.00, isPopular: false, tag: nil),
                        MenuItem(name: "Babi Pongteh", description: "", price: 24.00, isPopular: false, tag: "Popular")
                    ]
                ),
                MenuSection(
                    name: "Nyonya Classics",
                    items: [
                        MenuItem(name: "Sambal Prawns", description: "", price: 26.00, isPopular: false, tag: "Spicy"),
                        MenuItem(name: "Chap Chye", description: "", price: 14.00, isPopular: false, tag: "Veg"),
                        MenuItem(name: "Hee Peow Soup", description: "", price: 18.00, isPopular: false, tag: nil)
                    ]
                ),
                MenuSection(
                    name: "Desserts",
                    items: [
                        MenuItem(name: "Kueh Dadar", description: "", price: 8.00, isPopular: false, tag: nil),
                        MenuItem(name: "Nonya Kueh Platter", description: "", price: 16.00, isPopular: true, tag: "Bestseller"),
                        MenuItem(name: "Chendol", description: "", price: 9.00, isPopular: false, tag: nil)
                    ]
                )
            ]
        ),
        Restaurant(
            name: "Komala Vilas",
            cuisine: "Indian Vegetarian",
            category: .indian,
            rating: 4.5,
            reviewCount: 2640,
            deliveryTime: "20–30 min",
            deliveryFee: "Free",
            minOrder: "S$12",
            distance: "1.0 km",
            promo: nil,
            headerColor: Color(hex: "#D97706"),
            imageName: "FoodKomala",
            menu: [
                MenuSection(
                    name: "Thali & Sets",
                    items: [
                        MenuItem(name: "Vegetarian Thali", description: "", price: 12.90, isPopular: true, tag: "Bestseller"),
                        MenuItem(name: "Mini Thali", description: "", price: 9.90, isPopular: false, tag: nil),
                        MenuItem(name: "South Indian Set", description: "", price: 11.90, isPopular: false, tag: nil)
                    ]
                ),
                MenuSection(
                    name: "Bread & Snacks",
                    items: [
                        MenuItem(name: "Roti Prata Plain", description: "", price: 1.40, isPopular: false, tag: nil),
                        MenuItem(name: "Roti Prata Egg", description: "", price: 1.80, isPopular: false, tag: "Popular"),
                        MenuItem(name: "Thosai", description: "", price: 2.50, isPopular: false, tag: nil),
                        MenuItem(name: "Vadai 2pcs", description: "", price: 3.00, isPopular: false, tag: nil)
                    ]
                ),
                MenuSection(
                    name: "Sweets",
                    items: [
                        MenuItem(name: "Gulab Jamun", description: "", price: 3.50, isPopular: true, tag: "Bestseller"),
                        MenuItem(name: "Kheer", description: "", price: 4.00, isPopular: false, tag: nil)
                    ]
                )
            ]
        ),
        Restaurant(
            name: "Birds of Paradise",
            cuisine: "Gelato · Botanical",
            category: .desserts,
            rating: 4.9,
            reviewCount: 6710,
            deliveryTime: "25–35 min",
            deliveryFee: "S$1.99",
            minOrder: "S$15",
            distance: "1.6 km",
            promo: "Trending",
            headerColor: Color(hex: "#DB2777"),
            imageName: "FoodBirds",
            menu: [
                MenuSection(
                    name: "Gelato",
                    items: [
                        MenuItem(name: "Single Scoop", description: "", price: 6.00, isPopular: true, tag: "Bestseller"),
                        MenuItem(name: "Double Scoop", description: "", price: 10.00, isPopular: false, tag: "Popular"),
                        MenuItem(name: "Triple Scoop", description: "", price: 13.00, isPopular: false, tag: nil)
                    ]
                ),
                MenuSection(
                    name: "Botanical Flavours",
                    items: [
                        MenuItem(name: "Strawberry Basil", description: "", price: 6.00, isPopular: false, tag: nil),
                        MenuItem(name: "Pandan Coconut", description: "", price: 6.00, isPopular: false, tag: "Popular"),
                        MenuItem(name: "Earl Grey Lavender", description: "", price: 6.00, isPopular: false, tag: nil),
                        MenuItem(name: "Mao Shan Wang Durian", description: "", price: 12.00, isPopular: false, tag: "New")
                    ]
                ),
                MenuSection(
                    name: "Waffles",
                    items: [
                        MenuItem(name: "Fresh Waffle with 1 Scoop", description: "", price: 11.00, isPopular: true, tag: "Bestseller"),
                        MenuItem(name: "Banana Split", description: "", price: 16.00, isPopular: false, tag: nil)
                    ]
                )
            ]
        ),
        Restaurant(
            name: "Old Chang Kee",
            cuisine: "Local Snacks · Curry Puffs",
            category: .hawker,
            rating: 4.4,
            reviewCount: 3920,
            deliveryTime: "15–25 min",
            deliveryFee: "Free",
            minOrder: "S$8",
            distance: "0.5 km",
            promo: nil,
            headerColor: Color(hex: "#B45309"),
            imageName: "FoodOldChangKee",
            menu: [
                MenuSection(
                    name: "Curry Puffs",
                    items: [
                        MenuItem(name: "Original Curry Puff", description: "", price: 1.60, isPopular: true, tag: "Bestseller"),
                        MenuItem(name: "Chicken Curry Puff", description: "", price: 1.60, isPopular: false, tag: nil),
                        MenuItem(name: "Sardine Puff", description: "", price: 1.60, isPopular: false, tag: "Popular"),
                        MenuItem(name: "Cheese Puff", description: "", price: 1.80, isPopular: false, tag: "New")
                    ]
                ),
                MenuSection(
                    name: "Hot Snacks",
                    items: [
                        MenuItem(name: "Fish Ball on Stick", description: "", price: 1.40, isPopular: false, tag: nil),
                        MenuItem(name: "Sotong Head", description: "", price: 2.50, isPopular: false, tag: "Bestseller"),
                        MenuItem(name: "Prawn Roll", description: "", price: 2.20, isPopular: false, tag: nil)
                    ]
                ),
                MenuSection(
                    name: "Snack Sets",
                    items: [
                        MenuItem(name: "Any 4 Puffs", description: "", price: 6.00, isPopular: false, tag: "Popular"),
                        MenuItem(name: "Snack Box 6pcs", description: "", price: 9.50, isPopular: true, tag: "Bestseller")
                    ]
                )
            ]
        ),
        Restaurant(
            name: "Jumbo Seafood",
            cuisine: "Chilli Crab · Seafood",
            category: .chinese,
            rating: 4.6,
            reviewCount: 7840,
            deliveryTime: "30–40 min",
            deliveryFee: "S$1.99",
            minOrder: "S$30",
            distance: "2.4 km",
            promo: "Must Try",
            headerColor: Color(hex: "#C2410C"),
            imageName: "FoodJumbo",
            menu: [
                MenuSection(name: "Crab", items: [
                    MenuItem(name: "Chilli Crab (800g)", description: "Singapore's iconic dish — wok-tossed in spicy tomato gravy", price: 88.00, isPopular: true, tag: "Bestseller"),
                    MenuItem(name: "Black Pepper Crab (800g)", description: "Wok-fried with coarsely ground black pepper", price: 85.00, isPopular: false, tag: "Popular"),
                    MenuItem(name: "Butter Milk Crab (800g)", description: "", price: 82.00, isPopular: false, tag: nil)
                ]),
                MenuSection(name: "Must Orders", items: [
                    MenuItem(name: "Mantou 3pcs", description: "Deep-fried bun — perfect for dipping in chilli crab gravy", price: 6.00, isPopular: true, tag: "Bestseller"),
                    MenuItem(name: "Cereal Prawn", description: "", price: 28.00, isPopular: false, tag: "Popular"),
                    MenuItem(name: "Sambal Kangkong", description: "", price: 14.00, isPopular: false, tag: nil)
                ]),
                MenuSection(name: "Rice & Noodles", items: [
                    MenuItem(name: "Fried Rice", description: "", price: 12.00, isPopular: false, tag: nil),
                    MenuItem(name: "Ee Fu Noodles", description: "", price: 14.00, isPopular: false, tag: nil)
                ])
            ]
        ),
        Restaurant(
            name: "Odette",
            cuisine: "French · Fine Dining",
            category: .western,
            rating: 4.9,
            reviewCount: 2140,
            deliveryTime: "35–45 min",
            deliveryFee: "S$2.99",
            minOrder: "S$60",
            distance: "3.1 km",
            promo: "Premium",
            headerColor: Color(hex: "#4338CA"),
            imageName: "FoodOdette",
            menu: [
                MenuSection(name: "À La Carte", items: [
                    MenuItem(name: "Hokkaido Uni & Caviar", description: "Sea urchin, Kristal caviar, smoked potato cream", price: 78.00, isPopular: true, tag: "Bestseller"),
                    MenuItem(name: "Brittany Langoustine", description: "Bisque, black garlic, Périgord truffle", price: 68.00, isPopular: false, tag: nil),
                    MenuItem(name: "A5 Kagoshima Wagyu", description: "Wasabi, pickled shallots, bone marrow jus", price: 95.00, isPopular: false, tag: "Popular")
                ]),
                MenuSection(name: "Set Menus", items: [
                    MenuItem(name: "3-Course Déjeuner", description: "Starter, main, dessert", price: 148.00, isPopular: false, tag: nil),
                    MenuItem(name: "Experience Menu 6-Course", description: "Chef's seasonal tasting menu", price: 298.00, isPopular: true, tag: "Signature")
                ]),
                MenuSection(name: "Desserts", items: [
                    MenuItem(name: "Tarte au Citron", description: "", price: 28.00, isPopular: false, tag: nil),
                    MenuItem(name: "Valrhona Chocolate", description: "", price: 30.00, isPopular: false, tag: nil)
                ])
            ]
        )
    ]

    static let tokyoRestaurants: [Restaurant] = [
        Restaurant(
            name: "一風堂",
            cuisine: "ラーメン · 博多豚骨",
            category: .japanese,
            rating: 4.8,
            reviewCount: 12_400,
            deliveryTime: "15〜25分",
            deliveryFee: "無料",
            minOrder: "¥800",
            distance: "0.4 km",
            promo: "人気",
            headerColor: Color(hex: "#B91C1C"),
            imageName: "FoodIppudo",
            menu: [
                MenuSection(name: "ラーメン", items: [
                    MenuItem(name: "白丸元味", description: "豚骨スープ、細麺、チャーシュー", price: 980, isPopular: true, tag: "定番", idKey: "shiromaru"),
                    MenuItem(name: "赤丸新味", description: "濃厚豚骨スープ、辛味噌", price: 1_050, isPopular: true, tag: "人気", idKey: "akamaru"),
                    MenuItem(name: "黒丸豚王", description: "黒マー油、旨味豚骨", price: 1_100, isPopular: false, tag: nil, idKey: "kuromaru")
                ]),
                MenuSection(name: "トッピング", items: [
                    MenuItem(name: "半熟玉子", description: "", price: 150, isPopular: false, tag: nil, idKey: "ajitama"),
                    MenuItem(name: "追いチャーシュー", description: "", price: 380, isPopular: false, tag: "おすすめ", idKey: "extra_chashu"),
                    MenuItem(name: "辛味噌", description: "", price: 120, isPopular: false, tag: nil, idKey: "karamiso")
                ]),
                MenuSection(name: "サイドメニュー", items: [
                    MenuItem(name: "餃子 5個", description: "パリパリ皮、肉汁たっぷり", price: 420, isPopular: true, tag: "人気", idKey: "gyoza_5"),
                    MenuItem(name: "チャーハン", description: "", price: 550, isPopular: false, tag: nil, idKey: "chahan")
                ])
            ]
        ),
        Restaurant(
            name: "すし三崎丸",
            cuisine: "寿司 · 新鮮ネタ",
            category: .japanese,
            rating: 4.7,
            reviewCount: 8_820,
            deliveryTime: "20〜30分",
            deliveryFee: "無料",
            minOrder: "¥1,200",
            distance: "0.7 km",
            promo: "20%オフ",
            headerColor: Color(hex: "#1E3A5F"),
            imageName: "FoodSushi",
            menu: [
                MenuSection(name: "にぎり盛り合わせ", items: [
                    MenuItem(name: "特上にぎり 10貫", description: "大トロ、うに、いくら入り", price: 3_800, isPopular: true, tag: "ベストセラー", idKey: "tokujo_nigiri_10"),
                    MenuItem(name: "上にぎり 10貫", description: "サーモン、マグロ、ハマチほか", price: 2_200, isPopular: true, tag: "人気", idKey: "jo_nigiri_10"),
                    MenuItem(name: "旬のにぎり 8貫", description: "季節のネタ", price: 1_600, isPopular: false, tag: nil, idKey: "shun_nigiri_8")
                ]),
                MenuSection(name: "巻物", items: [
                    MenuItem(name: "鉄火巻", description: "", price: 580, isPopular: false, tag: nil, idKey: "tekkamaki"),
                    MenuItem(name: "かっぱ巻", description: "", price: 480, isPopular: false, tag: nil, idKey: "kappamaki"),
                    MenuItem(name: "カリフォルニアロール", description: "", price: 720, isPopular: true, tag: "人気", idKey: "california_roll")
                ]),
                MenuSection(name: "一品料理", items: [
                    MenuItem(name: "茶碗蒸し", description: "", price: 350, isPopular: false, tag: nil, idKey: "chawanmushi"),
                    MenuItem(name: "味噌汁", description: "", price: 180, isPopular: false, tag: nil, idKey: "misoshiru")
                ])
            ]
        ),
        Restaurant(
            name: "天ぷら近藤",
            cuisine: "天ぷら · 和食",
            category: .japanese,
            rating: 4.9,
            reviewCount: 3_210,
            deliveryTime: "25〜35分",
            deliveryFee: "¥299",
            minOrder: "¥3,000",
            distance: "1.2 km",
            promo: "プレミアム",
            headerColor: Color(hex: "#92400E"),
            imageName: "FoodTempura",
            menu: [
                MenuSection(name: "天ぷらコース", items: [
                    MenuItem(name: "野菜天ぷら盛り合わせ", description: "旬の野菜8種、揚げたて", price: 2_800, isPopular: true, tag: "ベストセラー", idKey: "yasai_tempura"),
                    MenuItem(name: "海鮮天ぷら盛り合わせ", description: "えび、いか、あなご入り", price: 3_500, isPopular: true, tag: "人気", idKey: "kaisen_tempura"),
                    MenuItem(name: "特選天丼", description: "海老2本、野菜4種", price: 2_200, isPopular: false, tag: nil, idKey: "tokusen_tendon")
                ]),
                MenuSection(name: "単品天ぷら", items: [
                    MenuItem(name: "えび天", description: "", price: 680, isPopular: false, tag: nil, idKey: "ebi_ten"),
                    MenuItem(name: "かぼちゃ天", description: "", price: 320, isPopular: false, tag: nil, idKey: "kabocha_ten"),
                    MenuItem(name: "なす天", description: "", price: 300, isPopular: false, tag: nil, idKey: "nasu_ten")
                ]),
                MenuSection(name: "セット", items: [
                    MenuItem(name: "天ざる", description: "天ぷら盛り + ざる蕎麦", price: 1_980, isPopular: true, tag: "おすすめ", idKey: "tenzaru"),
                    MenuItem(name: "天茶漬け", description: "", price: 1_200, isPopular: false, tag: nil, idKey: "tenchazuke")
                ])
            ]
        ),
        Restaurant(
            name: "焼肉叙々苑",
            cuisine: "焼肉 · 和牛",
            category: .japanese,
            rating: 4.7,
            reviewCount: 6_540,
            deliveryTime: "25〜40分",
            deliveryFee: "¥399",
            minOrder: "¥2,500",
            distance: "1.5 km",
            promo: "必食",
            headerColor: Color(hex: "#7C3A1E"),
            imageName: "FoodYakiniku",
            menu: [
                MenuSection(name: "和牛", items: [
                    MenuItem(name: "A5和牛カルビ", description: "霜降り黒毛和牛、とろける旨さ", price: 3_800, isPopular: true, tag: "ベストセラー", idKey: "wagyu_karubi"),
                    MenuItem(name: "A5和牛ロース", description: "上質な脂と赤身のバランス", price: 4_200, isPopular: true, tag: "プレミアム", idKey: "wagyu_rosu"),
                    MenuItem(name: "タン塩", description: "牛タン、ねぎ塩ダレ", price: 1_800, isPopular: false, tag: "人気", idKey: "tanshio")
                ]),
                MenuSection(name: "セット・定食", items: [
                    MenuItem(name: "焼肉御膳", description: "カルビ・ロース・サラダ・スープ・ご飯", price: 3_200, isPopular: false, tag: nil, idKey: "yakiniku_gozen"),
                    MenuItem(name: "叙々苑弁当", description: "焼肉盛り合わせ + ご飯", price: 2_200, isPopular: true, tag: "人気", idKey: "jojoen_bento")
                ]),
                MenuSection(name: "サイド", items: [
                    MenuItem(name: "ナムル盛り合わせ", description: "", price: 680, isPopular: false, tag: nil, idKey: "namul"),
                    MenuItem(name: "クッパ", description: "", price: 780, isPopular: false, tag: nil, idKey: "kuppa"),
                    MenuItem(name: "冷麺", description: "", price: 850, isPopular: false, tag: "人気", idKey: "reimen")
                ])
            ]
        ),
        Restaurant(
            name: "吉野家",
            cuisine: "牛丼 · ファスト",
            category: .japanese,
            rating: 4.3,
            reviewCount: 21_000,
            deliveryTime: "10〜15分",
            deliveryFee: "無料",
            minOrder: "¥400",
            distance: "0.1 km",
            promo: nil,
            headerColor: Color(hex: "#B45309"),
            imageName: "FoodGyudon",
            menu: [
                MenuSection(name: "牛丼", items: [
                    MenuItem(name: "牛丼 並盛", description: "やわらか牛肉、甘辛タレ", price: 468, isPopular: true, tag: "定番", idKey: "gyudon_nami"),
                    MenuItem(name: "牛丼 大盛", description: "", price: 528, isPopular: false, tag: nil, idKey: "gyudon_omori"),
                    MenuItem(name: "牛丼 特盛", description: "", price: 638, isPopular: false, tag: "ボリューム", idKey: "gyudon_tokumori")
                ]),
                MenuSection(name: "定食", items: [
                    MenuItem(name: "牛丼定食", description: "牛丼 + 味噌汁 + 小鉢", price: 628, isPopular: true, tag: "おすすめ", idKey: "gyudon_teishoku"),
                    MenuItem(name: "親子丼定食", description: "鶏肉と卵の丼 + 味噌汁", price: 598, isPopular: false, tag: nil, idKey: "oyakodon_teishoku")
                ]),
                MenuSection(name: "サイド", items: [
                    MenuItem(name: "味噌汁", description: "", price: 88, isPopular: false, tag: nil, idKey: "misoshiru_side"),
                    MenuItem(name: "サラダ", description: "", price: 198, isPopular: false, tag: nil, idKey: "salad"),
                    MenuItem(name: "漬物", description: "", price: 88, isPopular: false, tag: nil, idKey: "tsukemono")
                ])
            ]
        ),
        Restaurant(
            name: "餃子の王将",
            cuisine: "中華 · 餃子",
            category: .chinese,
            rating: 4.5,
            reviewCount: 15_200,
            deliveryTime: "15〜25分",
            deliveryFee: "無料",
            minOrder: "¥600",
            distance: "0.3 km",
            promo: nil,
            headerColor: Color(hex: "#C2410C"),
            imageName: "FoodGyoza",
            menu: [
                MenuSection(name: "餃子", items: [
                    MenuItem(name: "餃子 6個", description: "肉汁じゅわっと、パリパリ皮", price: 270, isPopular: true, tag: "ベストセラー", idKey: "gyoza_6"),
                    MenuItem(name: "餃子 12個", description: "", price: 540, isPopular: false, tag: "お得", idKey: "gyoza_12"),
                    MenuItem(name: "水餃子 6個", description: "", price: 320, isPopular: false, tag: nil, idKey: "sui_gyoza_6")
                ]),
                MenuSection(name: "炒め物", items: [
                    MenuItem(name: "チャーハン", description: "パラパラ黄金炒飯", price: 520, isPopular: true, tag: "人気", idKey: "chahan_osho"),
                    MenuItem(name: "麻婆豆腐", description: "", price: 590, isPopular: false, tag: "辛口", idKey: "mapo_tofu"),
                    MenuItem(name: "回鍋肉", description: "", price: 620, isPopular: false, tag: nil, idKey: "hoikoro")
                ]),
                MenuSection(name: "定食セット", items: [
                    MenuItem(name: "餃子定食", description: "餃子 + ご飯 + スープ", price: 680, isPopular: true, tag: "おすすめ", idKey: "gyoza_teishoku"),
                    MenuItem(name: "チャーハンセット", description: "チャーハン + 餃子 + スープ", price: 820, isPopular: false, tag: nil, idKey: "chahan_set")
                ])
            ]
        ),
        Restaurant(
            name: "サーティワン アイスクリーム",
            cuisine: "アイスクリーム · デザート",
            category: .desserts,
            rating: 4.4,
            reviewCount: 4_300,
            deliveryTime: "20〜30分",
            deliveryFee: "¥199",
            minOrder: "¥600",
            distance: "0.6 km",
            promo: "話題",
            headerColor: Color(hex: "#DB2777"),
            imageName: "FoodIceCream",
            menu: [
                MenuSection(name: "アイスクリーム", items: [
                    MenuItem(name: "ダブルカップ/コーン", description: "31種類から2種選択", price: 680, isPopular: true, tag: "人気", idKey: "double_cup"),
                    MenuItem(name: "シングルカップ/コーン", description: "31種類から1種選択", price: 420, isPopular: false, tag: nil, idKey: "single_cup"),
                    MenuItem(name: "トリプルカップ", description: "31種類から3種選択", price: 920, isPopular: false, tag: nil, idKey: "triple_cup")
                ]),
                MenuSection(name: "人気フレーバー", items: [
                    MenuItem(name: "チョコレートムース", description: "", price: 420, isPopular: true, tag: "定番", idKey: "chocolate_mousse"),
                    MenuItem(name: "ストロベリーチーズケーキ", description: "", price: 420, isPopular: false, tag: nil, idKey: "strawberry_cheesecake"),
                    MenuItem(name: "抹茶きなこもち", description: "", price: 420, isPopular: true, tag: "和風", idKey: "matcha_kinako")
                ]),
                MenuSection(name: "セット", items: [
                    MenuItem(name: "パーティーパック 8カップ", description: "", price: 3_200, isPopular: false, tag: nil, idKey: "party_pack_8"),
                    MenuItem(name: "ホールケーキ", description: "誕生日などに", price: 4_500, isPopular: false, tag: "予約", idKey: "whole_cake")
                ])
            ]
        ),
        Restaurant(
            name: "銀座久兵衛",
            cuisine: "寿司 · 銀座",
            category: .japanese,
            rating: 4.8,
            reviewCount: 2_140,
            deliveryTime: "35〜50分",
            deliveryFee: "¥599",
            minOrder: "¥5,000",
            distance: "2.8 km",
            promo: "プレミアム",
            headerColor: Color(hex: "#4338CA"),
            imageName: "FoodGinzaSushi",
            menu: [
                MenuSection(name: "特上にぎり", items: [
                    MenuItem(name: "特上にぎり 12貫", description: "本日のおすすめネタ、大将おまかせ", price: 12_000, isPopular: true, tag: "シグネチャー", idKey: "tokujo_nigiri_12"),
                    MenuItem(name: "上にぎり 10貫", description: "サーモン大トロ、ウニほか", price: 8_500, isPopular: true, tag: "人気", idKey: "jo_nigiri_10_ginza")
                ]),
                MenuSection(name: "おまかせコース", items: [
                    MenuItem(name: "おまかせ松", description: "前菜 + にぎり12貫 + デザート", price: 18_000, isPopular: false, tag: nil, idKey: "omakase_matsu"),
                    MenuItem(name: "おまかせ竹", description: "前菜 + にぎり10貫", price: 14_000, isPopular: false, tag: nil, idKey: "omakase_take")
                ]),
                MenuSection(name: "一品", items: [
                    MenuItem(name: "茶碗蒸し", description: "", price: 1_200, isPopular: false, tag: nil, idKey: "chawanmushi_ginza"),
                    MenuItem(name: "あら汁", description: "", price: 800, isPopular: false, tag: nil, idKey: "arajiru")
                ])
            ]
        ),
    ]

    static let sydneyRestaurants: [Restaurant] = [
        Restaurant(
            name: "Bills Surry Hills",
            cuisine: "Brunch · Cafe",
            category: .western,
            rating: 4.8,
            reviewCount: 8_940,
            deliveryTime: "15–25 min",
            deliveryFee: "Free",
            minOrder: "A$12",
            distance: "0.6 km",
            promo: "Popular",
            headerColor: Color(hex: "#C8860A"),
            imageName: "FoodBills",
            menu: [
                MenuSection(name: "All-Day Brunch", items: [
                    MenuItem(name: "Ricotta Hotcakes", description: "Fluffy hotcakes with fresh banana & honeycomb butter", price: 26.00, isPopular: true, tag: "Bestseller", idKey: "ricotta_hotcakes"),
                    MenuItem(name: "Smashed Avo on Sourdough", description: "Smashed avocado, feta, lime & dukkah", price: 22.00, isPopular: true, tag: "Popular", idKey: "smashed_avo"),
                    MenuItem(name: "The Big Breakfast", description: "Eggs, bacon, sausage, mushrooms, roast tomato & toast", price: 28.00, isPopular: false, tag: nil, idKey: "big_breakfast")
                ]),
                MenuSection(name: "Eggs", items: [
                    MenuItem(name: "Sweetcorn Fritters", description: "With roast tomato, spinach & bacon", price: 24.00, isPopular: true, tag: "Bestseller", idKey: "corn_fritters"),
                    MenuItem(name: "Scrambled Eggs on Toast", description: "Free-range eggs on sourdough", price: 18.00, isPopular: false, tag: nil, idKey: "scrambled_eggs"),
                    MenuItem(name: "Eggs Benedict", description: "Poached eggs, ham, hollandaise", price: 23.00, isPopular: false, tag: "Popular", idKey: "eggs_benedict")
                ]),
                MenuSection(name: "Coffee", items: [
                    MenuItem(name: "Flat White", description: "Single-origin, locally roasted", price: 4.50, isPopular: true, tag: "Bestseller", idKey: "flat_white"),
                    MenuItem(name: "Long Black", description: "", price: 4.20, isPopular: false, tag: nil, idKey: "long_black"),
                    MenuItem(name: "Iced Latte", description: "", price: 5.50, isPopular: false, tag: nil, idKey: "iced_latte")
                ])
            ]
        ),
        Restaurant(
            name: "Chat Thai",
            cuisine: "Thai · Authentic",
            category: .chinese,
            rating: 4.7,
            reviewCount: 11_200,
            deliveryTime: "20–30 min",
            deliveryFee: "Free",
            minOrder: "A$15",
            distance: "0.9 km",
            promo: "20% OFF",
            headerColor: Color(hex: "#9B2335"),
            imageName: "FoodChatThai",
            menu: [
                MenuSection(name: "Street Eats", items: [
                    MenuItem(name: "Pad Thai Goong", description: "Wok-fried rice noodles, prawns, tamarind & peanuts", price: 19.00, isPopular: true, tag: "Bestseller", idKey: "pad_thai_goong"),
                    MenuItem(name: "Chicken Satay 6pcs", description: "Charcoal-grilled skewers with peanut sauce", price: 14.00, isPopular: true, tag: "Popular", idKey: "chicken_satay_6"),
                    MenuItem(name: "Som Tum", description: "Green papaya salad, dried prawns, chilli & lime", price: 15.00, isPopular: false, tag: "Spicy", idKey: "som_tum")
                ]),
                MenuSection(name: "Curries", items: [
                    MenuItem(name: "Green Curry Chicken", description: "Coconut curry with Thai basil & eggplant", price: 22.00, isPopular: true, tag: "Bestseller", idKey: "green_curry"),
                    MenuItem(name: "Massaman Beef", description: "Slow-braised beef, potato & peanuts", price: 24.00, isPopular: false, tag: nil, idKey: "massaman_beef"),
                    MenuItem(name: "Panang Pork", description: "", price: 23.00, isPopular: false, tag: nil, idKey: "panang_pork")
                ]),
                MenuSection(name: "Drinks", items: [
                    MenuItem(name: "Thai Iced Tea", description: "", price: 5.50, isPopular: false, tag: "Popular", idKey: "thai_iced_tea"),
                    MenuItem(name: "Coconut Water", description: "", price: 5.00, isPopular: false, tag: nil, idKey: "coconut_water")
                ])
            ]
        ),
        Restaurant(
            name: "Sushi Hub",
            cuisine: "Sushi · Japanese",
            category: .japanese,
            rating: 4.6,
            reviewCount: 6_730,
            deliveryTime: "20–30 min",
            deliveryFee: "A$2.99",
            minOrder: "A$18",
            distance: "1.2 km",
            promo: nil,
            headerColor: Color(hex: "#1E3A5F"),
            imageName: "FoodSushiHub",
            menu: [
                MenuSection(name: "Sushi Packs", items: [
                    MenuItem(name: "Deluxe Sashimi Pack", description: "Salmon, tuna & kingfish, 18 pieces", price: 32.00, isPopular: true, tag: "Bestseller", idKey: "deluxe_sashimi"),
                    MenuItem(name: "Salmon Lover Pack", description: "Salmon nigiri & rolls, 12 pieces", price: 24.00, isPopular: true, tag: "Popular", idKey: "salmon_lover"),
                    MenuItem(name: "Mixed Sushi Pack", description: "Assorted nigiri & maki, 10 pieces", price: 18.00, isPopular: false, tag: nil, idKey: "mixed_sushi")
                ]),
                MenuSection(name: "Hand Rolls", items: [
                    MenuItem(name: "Teriyaki Chicken Roll", description: "", price: 4.50, isPopular: false, tag: nil, idKey: "teriyaki_chicken_roll"),
                    MenuItem(name: "Tempura Prawn Roll", description: "", price: 5.50, isPopular: true, tag: "Popular", idKey: "tempura_prawn_roll"),
                    MenuItem(name: "Avocado Roll", description: "", price: 3.80, isPopular: false, tag: "Veg", idKey: "avocado_roll")
                ]),
                MenuSection(name: "Sides", items: [
                    MenuItem(name: "Edamame", description: "Lightly salted soy beans", price: 6.00, isPopular: false, tag: nil, idKey: "edamame"),
                    MenuItem(name: "Miso Soup", description: "", price: 3.50, isPopular: false, tag: nil, idKey: "miso_soup")
                ])
            ]
        ),
        Restaurant(
            name: "Mary's Burgers",
            cuisine: "Burgers · American",
            category: .western,
            rating: 4.7,
            reviewCount: 9_410,
            deliveryTime: "20–30 min",
            deliveryFee: "A$1.99",
            minOrder: "A$15",
            distance: "1.0 km",
            promo: "Must Try",
            headerColor: Color(hex: "#7C3A1E"),
            imageName: "FoodMarys",
            menu: [
                MenuSection(name: "Burgers", items: [
                    MenuItem(name: "Mary's Cheeseburger", description: "Double beef, American cheese, pickles & secret sauce", price: 16.00, isPopular: true, tag: "Bestseller", idKey: "marys_cheeseburger"),
                    MenuItem(name: "Fried Chicken Burger", description: "Buttermilk fried chicken, slaw & aioli", price: 17.00, isPopular: true, tag: "Popular", idKey: "fried_chicken_burger"),
                    MenuItem(name: "Veggie Burger", description: "Plant-based patty, lettuce & tomato", price: 15.00, isPopular: false, tag: "Veg", idKey: "veggie_burger")
                ]),
                MenuSection(name: "Sides", items: [
                    MenuItem(name: "Loaded Fries", description: "Cheese, bacon & jalapenos", price: 12.00, isPopular: true, tag: "Bestseller", idKey: "loaded_fries"),
                    MenuItem(name: "Onion Rings", description: "", price: 8.00, isPopular: false, tag: nil, idKey: "onion_rings"),
                    MenuItem(name: "Chips", description: "Sea salt & rosemary", price: 6.00, isPopular: false, tag: nil, idKey: "chips")
                ]),
                MenuSection(name: "Drinks", items: [
                    MenuItem(name: "Thickshake", description: "Chocolate, vanilla or salted caramel", price: 9.00, isPopular: false, tag: "Popular", idKey: "thickshake"),
                    MenuItem(name: "Lemon Lime Bitters", description: "", price: 5.00, isPopular: false, tag: nil, idKey: "lemon_lime_bitters")
                ])
            ]
        ),
        Restaurant(
            name: "Da Mario Pizzeria",
            cuisine: "Pizza · Wood-Fired",
            category: .western,
            rating: 4.6,
            reviewCount: 5_280,
            deliveryTime: "25–35 min",
            deliveryFee: "A$2.99",
            minOrder: "A$20",
            distance: "1.6 km",
            promo: nil,
            headerColor: Color(hex: "#2D6A4F"),
            imageName: "FoodDaMario",
            menu: [
                MenuSection(name: "Wood-Fired Pizza", items: [
                    MenuItem(name: "Margherita", description: "San Marzano tomato, fior di latte & basil", price: 21.00, isPopular: true, tag: "Bestseller", idKey: "margherita"),
                    MenuItem(name: "Diavola", description: "Spicy salami, chilli & mozzarella", price: 25.00, isPopular: false, tag: "Spicy", idKey: "diavola"),
                    MenuItem(name: "Prosciutto e Rucola", description: "Prosciutto, rocket & shaved parmesan", price: 27.00, isPopular: false, tag: "Popular", idKey: "prosciutto_rucola")
                ]),
                MenuSection(name: "Pasta", items: [
                    MenuItem(name: "Spaghetti Carbonara", description: "Guanciale, egg, pecorino & pepper", price: 24.00, isPopular: true, tag: "Popular", idKey: "carbonara"),
                    MenuItem(name: "Penne Arrabbiata", description: "", price: 21.00, isPopular: false, tag: nil, idKey: "arrabbiata"),
                    MenuItem(name: "Lasagne", description: "", price: 23.00, isPopular: false, tag: nil, idKey: "lasagne")
                ]),
                MenuSection(name: "Starters", items: [
                    MenuItem(name: "Garlic Bread", description: "Wood-fired with garlic butter", price: 9.00, isPopular: true, tag: "Bestseller", idKey: "garlic_bread"),
                    MenuItem(name: "Bruschetta", description: "", price: 11.00, isPopular: false, tag: nil, idKey: "bruschetta")
                ])
            ]
        ),
        Restaurant(
            name: "Pho An",
            cuisine: "Vietnamese · Pho",
            category: .healthy,
            rating: 4.7,
            reviewCount: 7_640,
            deliveryTime: "20–30 min",
            deliveryFee: "Free",
            minOrder: "A$12",
            distance: "1.4 km",
            promo: "Free Delivery",
            headerColor: Color(hex: "#D97706"),
            imageName: "FoodPhoAn",
            menu: [
                MenuSection(name: "Pho", items: [
                    MenuItem(name: "Beef Pho", description: "Slow-simmered broth, rice noodles & rare beef", price: 16.00, isPopular: true, tag: "Bestseller", idKey: "beef_pho"),
                    MenuItem(name: "Chicken Pho", description: "Aromatic broth with poached chicken", price: 15.00, isPopular: false, tag: nil, idKey: "chicken_pho"),
                    MenuItem(name: "Combination Pho", description: "Brisket, meatballs & rare beef", price: 18.00, isPopular: false, tag: "Popular", idKey: "combination_pho")
                ]),
                MenuSection(name: "Rolls & Sides", items: [
                    MenuItem(name: "Fresh Rice Paper Rolls 2pcs", description: "Prawn, mint & vermicelli", price: 9.00, isPopular: true, tag: "Popular", idKey: "rice_paper_rolls"),
                    MenuItem(name: "Spring Rolls 4pcs", description: "", price: 8.00, isPopular: false, tag: nil, idKey: "spring_rolls"),
                    MenuItem(name: "Lemongrass Chicken Rice", description: "", price: 16.00, isPopular: false, tag: nil, idKey: "lemongrass_chicken")
                ]),
                MenuSection(name: "Drinks", items: [
                    MenuItem(name: "Vietnamese Iced Coffee", description: "Condensed milk & strong drip coffee", price: 5.50, isPopular: false, tag: "Popular", idKey: "viet_iced_coffee"),
                    MenuItem(name: "Sugar Cane Juice", description: "", price: 5.00, isPopular: false, tag: nil, idKey: "sugar_cane_juice")
                ])
            ]
        ),
        Restaurant(
            name: "Bourke St Bakery",
            cuisine: "Pies · Bakery",
            category: .hawker,
            rating: 4.5,
            reviewCount: 4_120,
            deliveryTime: "15–25 min",
            deliveryFee: "Free",
            minOrder: "A$10",
            distance: "0.4 km",
            promo: nil,
            headerColor: Color(hex: "#B45309"),
            imageName: "FoodBourkeSt",
            menu: [
                MenuSection(name: "Pies & Sausage Rolls", items: [
                    MenuItem(name: "Beef Brisket Pie", description: "Slow-cooked brisket in flaky pastry", price: 8.50, isPopular: true, tag: "Bestseller", idKey: "beef_brisket_pie"),
                    MenuItem(name: "Chicken & Leek Pie", description: "", price: 8.00, isPopular: false, tag: "Popular", idKey: "chicken_leek_pie"),
                    MenuItem(name: "Pork & Fennel Sausage Roll", description: "", price: 7.00, isPopular: false, tag: nil, idKey: "sausage_roll")
                ]),
                MenuSection(name: "Bakery", items: [
                    MenuItem(name: "Sourdough Loaf", description: "Naturally leavened, baked daily", price: 9.00, isPopular: true, tag: "Bestseller", idKey: "sourdough_loaf"),
                    MenuItem(name: "Ham & Cheese Croissant", description: "", price: 7.50, isPopular: false, tag: nil, idKey: "ham_cheese_croissant"),
                    MenuItem(name: "Almond Croissant", description: "", price: 6.50, isPopular: false, tag: "Popular", idKey: "almond_croissant")
                ]),
                MenuSection(name: "Sweets", items: [
                    MenuItem(name: "Lamington", description: "Sponge, chocolate & coconut", price: 5.50, isPopular: true, tag: "Bestseller", idKey: "lamington"),
                    MenuItem(name: "Caramel Slice", description: "", price: 5.00, isPopular: false, tag: nil, idKey: "caramel_slice")
                ])
            ]
        ),
        Restaurant(
            name: "Gelato Messina",
            cuisine: "Gelato · Dessert",
            category: .desserts,
            rating: 4.9,
            reviewCount: 14_300,
            deliveryTime: "25–35 min",
            deliveryFee: "A$1.99",
            minOrder: "A$12",
            distance: "1.1 km",
            promo: "Trending",
            headerColor: Color(hex: "#DB2777"),
            imageName: "FoodGelatoMessina",
            menu: [
                MenuSection(name: "Gelato", items: [
                    MenuItem(name: "Single Scoop", description: "Choose any flavour", price: 5.50, isPopular: true, tag: "Bestseller", idKey: "single_scoop"),
                    MenuItem(name: "Double Scoop", description: "Choose any two flavours", price: 9.00, isPopular: false, tag: "Popular", idKey: "double_scoop"),
                    MenuItem(name: "Triple Scoop", description: "", price: 12.00, isPopular: false, tag: nil, idKey: "triple_scoop")
                ]),
                MenuSection(name: "Signature Flavours", items: [
                    MenuItem(name: "Salted Caramel", description: "", price: 5.50, isPopular: true, tag: "Bestseller", idKey: "salted_caramel"),
                    MenuItem(name: "Dulce de Leche", description: "", price: 5.50, isPopular: false, tag: "Popular", idKey: "dulce_de_leche"),
                    MenuItem(name: "Pavlova", description: "Inspired by the Aussie classic", price: 5.50, isPopular: false, tag: "New", idKey: "pavlova"),
                    MenuItem(name: "Mango Sorbet", description: "", price: 5.50, isPopular: false, tag: nil, idKey: "mango_sorbet")
                ]),
                MenuSection(name: "Cakes & Tubs", items: [
                    MenuItem(name: "Gelato Tub 500ml", description: "Take-home tub", price: 16.00, isPopular: true, tag: "Bestseller", idKey: "gelato_tub"),
                    MenuItem(name: "Ice Cream Cake", description: "Serves 6–8", price: 45.00, isPopular: false, tag: nil, idKey: "ice_cream_cake")
                ])
            ]
        ),
        Restaurant(
            name: "Three Blue Ducks",
            cuisine: "Modern Australian · Brunch",
            category: .western,
            rating: 4.7,
            reviewCount: 6_840,
            deliveryTime: "25–35 min",
            deliveryFee: "A$2.99",
            minOrder: "A$20",
            distance: "2.3 km",
            promo: "Trending",
            headerColor: Color(hex: "#2F855A"),
            imageName: "FoodThreeBlueDucks",
            menu: [
                MenuSection(name: "All Day Brunch", items: [
                    MenuItem(name: "Brekkie Bowl", description: "Grains, avo, poached eggs, greens", price: 22.00, isPopular: true, tag: "Bestseller", idKey: "tbd_brekkie_bowl"),
                    MenuItem(name: "Grass-fed Steak Sandwich", description: "Caramelised onion, chimichurri", price: 26.00, isPopular: true, tag: "Popular", idKey: "tbd_steak_sando"),
                    MenuItem(name: "Banana Bread", description: "Toasted, whipped butter", price: 12.00, isPopular: false, tag: nil, idKey: "tbd_banana_bread")
                ]),
                MenuSection(name: "Mains", items: [
                    MenuItem(name: "Crispy-skin Barramundi", description: "Seasonal vegetables", price: 32.00, isPopular: false, tag: nil, idKey: "tbd_barramundi"),
                    MenuItem(name: "Roast Cauliflower Salad", description: "Tahini, pomegranate", price: 21.00, isPopular: false, tag: "Healthy", idKey: "tbd_cauliflower_salad")
                ]),
                MenuSection(name: "Drinks", items: [
                    MenuItem(name: "Cold Pressed Green Juice", description: "", price: 9.50, isPopular: false, tag: nil, idKey: "tbd_green_juice")
                ])
            ]
        ),
        Restaurant(
            name: "Din Tai Fung",
            cuisine: "Chinese · Dumplings",
            category: .chinese,
            rating: 4.8,
            reviewCount: 19_500,
            deliveryTime: "30–40 min",
            deliveryFee: "A$3.99",
            minOrder: "A$25",
            distance: "1.6 km",
            promo: "Popular",
            headerColor: Color(hex: "#B91C1C"),
            imageName: "FoodDinTaiFung",
            menu: [
                MenuSection(name: "Dumplings", items: [
                    MenuItem(name: "Xiao Long Bao (8 pc)", description: "Steamed pork soup dumplings", price: 14.80, isPopular: true, tag: "Bestseller", idKey: "dtf_xlb"),
                    MenuItem(name: "Prawn & Pork Wontons", description: "Spicy chilli oil", price: 13.50, isPopular: true, tag: "Popular", idKey: "dtf_wontons"),
                    MenuItem(name: "Vegetable & Mushroom Dumplings", description: "", price: 12.80, isPopular: false, tag: nil, idKey: "dtf_veg_dumplings")
                ]),
                MenuSection(name: "Rice & Noodles", items: [
                    MenuItem(name: "Pork Fried Rice", description: "", price: 16.80, isPopular: false, tag: nil, idKey: "dtf_fried_rice"),
                    MenuItem(name: "Dan Dan Noodles", description: "", price: 15.80, isPopular: false, tag: "Spicy", idKey: "dtf_dan_dan")
                ]),
                MenuSection(name: "Sides", items: [
                    MenuItem(name: "Stir-fried Greens", description: "Garlic", price: 11.80, isPopular: false, tag: nil, idKey: "dtf_greens"),
                    MenuItem(name: "Hot & Sour Soup", description: "", price: 9.80, isPopular: false, tag: nil, idKey: "dtf_hot_sour_soup")
                ])
            ]
        ),
        Restaurant(
            name: "Guzman y Gomez",
            cuisine: "Mexican · Fast Casual",
            category: .western,
            rating: 4.5,
            reviewCount: 22_100,
            deliveryTime: "15–25 min",
            deliveryFee: "Free",
            minOrder: "A$10",
            distance: "0.7 km",
            promo: "Free Delivery",
            headerColor: Color(hex: "#16A34A"),
            imageName: "FoodGuzman",
            menu: [
                MenuSection(name: "Burritos & Bowls", items: [
                    MenuItem(name: "Chicken Burrito", description: "Rice, beans, salsa, cheese", price: 14.90, isPopular: true, tag: "Bestseller", idKey: "gyg_burrito"),
                    MenuItem(name: "Nourish Bowl", description: "Brown rice, slaw, guac", price: 15.90, isPopular: false, tag: "Healthy", idKey: "gyg_bowl"),
                    MenuItem(name: "Beef Quesadilla", description: "", price: 13.90, isPopular: false, tag: nil, idKey: "gyg_quesadilla")
                ]),
                MenuSection(name: "Tacos", items: [
                    MenuItem(name: "Soft Tacos (3 pc)", description: "Choice of filling", price: 13.50, isPopular: true, tag: "Popular", idKey: "gyg_tacos"),
                    MenuItem(name: "Loaded Nachos", description: "Corn chips, cheese, jalapeños", price: 12.90, isPopular: false, tag: nil, idKey: "gyg_nachos")
                ]),
                MenuSection(name: "Sides", items: [
                    MenuItem(name: "Churros (5 pc)", description: "Cinnamon sugar", price: 7.50, isPopular: false, tag: nil, idKey: "gyg_churros")
                ])
            ]
        ),
        Restaurant(
            name: "Fishbowl",
            cuisine: "Poké · Healthy",
            category: .healthy,
            rating: 4.6,
            reviewCount: 8_960,
            deliveryTime: "20–30 min",
            deliveryFee: "A$1.99",
            minOrder: "A$15",
            distance: "1.0 km",
            promo: "Healthy",
            headerColor: Color(hex: "#0E7490"),
            imageName: "FoodFishBowl",
            menu: [
                MenuSection(name: "Signature Bowls", items: [
                    MenuItem(name: "Salmon Poké Bowl", description: "Brown rice, edamame, avo", price: 17.90, isPopular: true, tag: "Bestseller", idKey: "fb_salmon_poke"),
                    MenuItem(name: "Tuna Poké Bowl", description: "Soy, sesame, seaweed", price: 18.90, isPopular: true, tag: "Popular", idKey: "fb_tuna_poke"),
                    MenuItem(name: "Teriyaki Chicken Bowl", description: "", price: 16.90, isPopular: false, tag: nil, idKey: "fb_chicken_bowl"),
                    MenuItem(name: "Veggie Bowl", description: "Tofu, pickles, greens", price: 15.90, isPopular: false, tag: "Vegan", idKey: "fb_veggie_bowl")
                ]),
                MenuSection(name: "Sides", items: [
                    MenuItem(name: "Miso Soup", description: "", price: 4.50, isPopular: false, tag: nil, idKey: "fb_miso_soup"),
                    MenuItem(name: "Seaweed Salad", description: "", price: 6.50, isPopular: false, tag: nil, idKey: "fb_seaweed_salad")
                ])
            ]
        ),
        Restaurant(
            name: "Maya Da Dhaba",
            cuisine: "Indian · Surry Hills",
            category: .indian,
            rating: 4.6,
            reviewCount: 7_420,
            deliveryTime: "30–40 min",
            deliveryFee: "A$2.99",
            minOrder: "A$20",
            distance: "1.4 km",
            promo: nil,
            headerColor: Color(hex: "#C2410C"),
            imageName: "FoodMaya",
            menu: [
                MenuSection(name: "Curries", items: [
                    MenuItem(name: "Butter Chicken", description: "Creamy tomato, fenugreek", price: 21.00, isPopular: true, tag: "Bestseller", idKey: "maya_butter_chicken"),
                    MenuItem(name: "Lamb Rogan Josh", description: "", price: 23.00, isPopular: true, tag: "Popular", idKey: "maya_lamb_rogan"),
                    MenuItem(name: "Paneer Tikka Masala", description: "", price: 19.00, isPopular: false, tag: nil, idKey: "maya_paneer")
                ]),
                MenuSection(name: "Biryani & Rice", items: [
                    MenuItem(name: "Chicken Biryani", description: "Basmati, saffron", price: 20.00, isPopular: false, tag: "Spicy", idKey: "maya_biryani")
                ]),
                MenuSection(name: "Sides & Sweets", items: [
                    MenuItem(name: "Garlic Naan", description: "", price: 5.00, isPopular: true, tag: "Popular", idKey: "maya_garlic_naan"),
                    MenuItem(name: "Vegetable Samosa (2 pc)", description: "", price: 7.00, isPopular: false, tag: nil, idKey: "maya_samosa"),
                    MenuItem(name: "Gulab Jamun", description: "", price: 6.50, isPopular: false, tag: nil, idKey: "maya_gulab")
                ])
            ]
        ),
    ]

    static let byMarket: [Market: [Restaurant]] = [
        .singapore: sampleRestaurants,
        .tokyo:     tokyoRestaurants,
        .sydney:    sydneyRestaurants
    ]

    static func restaurants(for market: Market) -> [Restaurant] {
        byMarket[market] ?? sampleRestaurants
    }
}

struct FoodCartItem: Identifiable {
    let id: UUID = UUID()
    let menuItem: MenuItem
    var quantity: Int
}

class FoodCartStore: ObservableObject {
    @Published var items: [FoodCartItem] = []

    func add(_ item: MenuItem) {
        if let index = items.firstIndex(where: { $0.menuItem.id == item.id }) {
            items[index].quantity += 1
        } else {
            items.append(FoodCartItem(menuItem: item, quantity: 1))
        }
    }

    func remove(_ item: MenuItem) {
        items.removeAll { $0.menuItem.id == item.id }
    }

    func quantity(for item: MenuItem) -> Int {
        items.first { $0.menuItem.id == item.id }?.quantity ?? 0
    }

    var subtotal: Double {
        items.reduce(0) { $0 + ($1.menuItem.price * Double($1.quantity)) }
    }

    var itemCount: Int {
        items.reduce(0) { $0 + $1.quantity }
    }
}
