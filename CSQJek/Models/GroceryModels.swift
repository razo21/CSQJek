import SwiftUI
import Foundation

// MARK: - Grocery Models

struct GroceryCategory: Identifiable {
    let id = UUID()
    let name: String
    let iconName: String
    let color: Color
    let itemCount: Int
}

struct GroceryProduct: Identifiable {
    let id = UUID()
    let name: String
    let brand: String
    let category: String
    let price: Double
    let originalPrice: Double?
    let unit: String
    let rating: Double
    let reviewCount: Int
    let imageName: String // SF Symbol fallback
    let imageColor: Color
    let description: String
    let inStock: Bool
    var isFavorite: Bool = false

    var discountPercent: Int? {
        guard let original = originalPrice, original > price else { return nil }
        return Int(((original - price) / original) * 100)
    }

    // Per-product photo asset name. Drop a "Mart<AlphanumericName>" image into
    // Assets.xcassets to replace the SF-symbol placeholder.
    // e.g. "Free Range Eggs" -> "MartFreeRangeEggs", "Grass-Fed Beef Mince" -> "MartGrassFedBeefMince".
    var imageAssetName: String {
        "Mart" + name.filter { $0.isLetter || $0.isNumber }
    }
}

// Reusable product image: shows the per-product photo if its asset exists,
// then an optional fallback asset (e.g. a meat subcategory photo), then the
// tinted SF-symbol placeholder. Fills its frame; the call site sets size + shape.
struct GroceryProductImage: View {
    let product: GroceryProduct
    var fallbackAsset: String? = nil
    var symbolSize: CGFloat = 36

    var body: some View {
        if let ui = UIImage(named: product.imageAssetName) {
            Image(uiImage: ui).resizable().scaledToFill()
        } else if let fb = fallbackAsset, let ui = UIImage(named: fb) {
            Image(uiImage: ui).resizable().scaledToFill()
        } else {
            ZStack {
                product.imageColor.opacity(0.1)
                Image(systemName: product.imageName)
                    .font(.system(size: symbolSize))
                    .foregroundColor(product.imageColor.opacity(0.5))
            }
        }
    }
}

struct CartItem: Identifiable {
    let id = UUID()
    var product: GroceryProduct
    var quantity: Int
    var subtotal: Double { product.price * Double(quantity) }
}

struct DeliverySlot: Identifiable {
    let id = UUID()
    let label: String
    let time: String
    let fee: Double
    var isSelected: Bool = false
}

struct PaymentMethod: Identifiable {
    let id = UUID()
    let name: String
    let detail: String
    let iconName: String
    let color: Color
}

// MARK: - Sample Data

extension GroceryCategory {
    static let all: [GroceryCategory] = [
        GroceryCategory(name: "Fruits", iconName: "leaf.fill", color: Color(hex: "#2AC09A"), itemCount: 48),
        GroceryCategory(name: "Vegetables", iconName: "carrot.fill", color: Color(hex: "#4CAF50"), itemCount: 62),
        GroceryCategory(name: "Dairy", iconName: "cup.and.saucer.fill", color: Color(hex: "#4F7FFF"), itemCount: 35),
        GroceryCategory(name: "Bakery", iconName: "birthday.cake.fill", color: Color(hex: "#FF8C42"), itemCount: 28),
        GroceryCategory(name: "Beverages", iconName: "drop.fill", color: Color(hex: "#9B6DFF"), itemCount: 54),
        GroceryCategory(name: "Snacks", iconName: "popcorn.fill", color: Color(hex: "#FF6652"), itemCount: 41),
        GroceryCategory(name: "Meat", iconName: "fork.knife", color: Color(hex: "#E04D3A"), itemCount: 29),
        GroceryCategory(name: "Frozen", iconName: "snowflake", color: Color(hex: "#56CCF2"), itemCount: 33)
    ]
}

extension GroceryProduct {
    static let featured: [GroceryProduct] = [
        GroceryProduct(
            name: "Organic Strawberries",
            brand: "FreshFarm",
            category: "Fruits",
            price: 4.99,
            originalPrice: 6.49,
            unit: "250g punnet",
            rating: 4.7,
            reviewCount: 312,
            imageName: "heart.fill",
            imageColor: Color(hex: "#FF6652"),
            description: "Sun-ripened organic strawberries picked at peak sweetness. No pesticides, no compromises.",
            inStock: true
        ),
        GroceryProduct(
            name: "Whole Milk",
            brand: "Green Valley",
            category: "Dairy",
            price: 3.49,
            originalPrice: nil,
            unit: "2L",
            rating: 4.5,
            reviewCount: 188,
            imageName: "drop.fill",
            imageColor: Color(hex: "#4F7FFF"),
            description: "Fresh whole milk from pasture-raised cows. Rich, creamy, and full of natural goodness.",
            inStock: true
        ),
        GroceryProduct(
            name: "Sourdough Loaf",
            brand: "Stone Hearth",
            category: "Bakery",
            price: 6.50,
            originalPrice: nil,
            unit: "800g loaf",
            rating: 4.8,
            reviewCount: 421,
            imageName: "birthday.cake.fill",
            imageColor: Color(hex: "#FF8C42"),
            description: "Authentic long-ferment sourdough baked fresh daily. Crisp crust, chewy crumb.",
            inStock: true
        ),
        GroceryProduct(
            name: "Sparkling Water",
            brand: "AquaPure",
            category: "Beverages",
            price: 2.99,
            originalPrice: 4.50,
            unit: "6 × 500ml",
            rating: 4.3,
            reviewCount: 97,
            imageName: "bubbles.and.sparkles.fill",
            imageColor: Color(hex: "#9B6DFF"),
            description: "Lightly carbonated natural spring water. Zero calories, zero sugar.",
            inStock: true
        ),
        GroceryProduct(
            name: "Baby Spinach",
            brand: "GreenLeaf",
            category: "Vegetables",
            price: 2.79,
            originalPrice: nil,
            unit: "200g bag",
            rating: 4.6,
            reviewCount: 156,
            imageName: "leaf.fill",
            imageColor: Color(hex: "#2AC09A"),
            description: "Tender young spinach leaves, triple-washed and ready to eat.",
            inStock: true
        ),
        GroceryProduct(
            name: "Dark Chocolate",
            brand: "Cacao & Co.",
            category: "Snacks",
            price: 4.29,
            originalPrice: 5.99,
            unit: "100g bar",
            rating: 4.9,
            reviewCount: 634,
            imageName: "square.fill",
            imageColor: Color(hex: "#4E342E"),
            description: "72% single-origin dark chocolate. Complex, intense, and deeply satisfying.",
            inStock: true
        )
    ]

    static let flashDeals: [GroceryProduct] = [
        GroceryProduct(
            name: "Free Range Eggs",
            brand: "Happy Hen",
            category: "Dairy",
            price: 4.99,
            originalPrice: 7.49,
            unit: "12 pack",
            rating: 4.8,
            reviewCount: 289,
            imageName: "circle.fill",
            imageColor: Color(hex: "#F59E0B"),
            description: "Eggs from free-range hens with access to outdoor spaces.",
            inStock: true
        ),
        GroceryProduct(
            name: "Chicken Breast",
            brand: "Farmer's Choice",
            category: "Meat",
            price: 8.99,
            originalPrice: 13.50,
            unit: "500g",
            rating: 4.4,
            reviewCount: 178,
            imageName: "fork.knife",
            imageColor: Color(hex: "#E04D3A"),
            description: "Hormone-free chicken breast, perfect for grilling or stir-fry.",
            inStock: true
        )
    ]

    // MARK: - Meat Products
    static let meatProducts: [GroceryProduct] = [

        // ── CHICKEN ──────────────────────────────────────────────────────────
        GroceryProduct(
            name: "Chicken Breast Fillets",
            brand: "Lilydale",
            category: "Chicken",
            price: 9.99,
            originalPrice: 13.00,
            unit: "500g",
            rating: 4.6,
            reviewCount: 412,
            imageName: "fork.knife",
            imageColor: Color(hex: "#F97316"),
            description: "Free range chicken breast fillets. Hormone-free, RSPCA approved. Perfect for grilling, poaching or stir-fry.",
            inStock: true
        ),
        GroceryProduct(
            name: "Chicken Thigh Fillets",
            brand: "Lilydale",
            category: "Chicken",
            price: 8.49,
            originalPrice: nil,
            unit: "500g",
            rating: 4.8,
            reviewCount: 631,
            imageName: "fork.knife",
            imageColor: Color(hex: "#F97316"),
            description: "Juicy free range chicken thigh fillets. More flavourful than breast — great for curries, roasting and BBQ.",
            inStock: true
        ),
        GroceryProduct(
            name: "Whole Free Range Chicken",
            brand: "Bannockburn",
            category: "Chicken",
            price: 14.99,
            originalPrice: 18.00,
            unit: "1.5–1.8 kg",
            rating: 4.7,
            reviewCount: 284,
            imageName: "fork.knife",
            imageColor: Color(hex: "#F97316"),
            description: "Ethically raised, free range whole chicken. No added hormones or antibiotics. Perfect for Sunday roast.",
            inStock: true
        ),
        GroceryProduct(
            name: "Chicken Wings",
            brand: "Steggles",
            category: "Chicken",
            price: 6.99,
            originalPrice: 9.50,
            unit: "1 kg",
            rating: 4.5,
            reviewCount: 198,
            imageName: "fork.knife",
            imageColor: Color(hex: "#F97316"),
            description: "Plump chicken wings ideal for marinating. Air-fry, BBQ or oven bake. Perfect for game night.",
            inStock: true
        ),

        // ── BEEF ─────────────────────────────────────────────────────────────
        GroceryProduct(
            name: "Grass-Fed Beef Mince",
            brand: "OBE Organic",
            category: "Beef",
            price: 12.99,
            originalPrice: 16.00,
            unit: "500g",
            rating: 4.7,
            reviewCount: 349,
            imageName: "flame.fill",
            imageColor: Color(hex: "#E04D3A"),
            description: "100% certified organic grass-fed beef mince. No added hormones. Perfect for bolognese, burgers and tacos.",
            inStock: true
        ),
        GroceryProduct(
            name: "Scotch Fillet Steak",
            brand: "Rangers Valley",
            category: "Beef",
            price: 22.99,
            originalPrice: 28.00,
            unit: "2 × 200g",
            rating: 4.9,
            reviewCount: 521,
            imageName: "flame.fill",
            imageColor: Color(hex: "#E04D3A"),
            description: "MSA graded scotch fillet from Rangers Valley, NSW. Marble score 3+. Pan-sear to a perfect medium-rare.",
            inStock: true
        ),
        GroceryProduct(
            name: "Beef Stir-Fry Strips",
            brand: "Farmer's Choice",
            category: "Beef",
            price: 10.49,
            originalPrice: nil,
            unit: "400g",
            rating: 4.4,
            reviewCount: 187,
            imageName: "flame.fill",
            imageColor: Color(hex: "#E04D3A"),
            description: "Pre-cut beef rump strips ready for the wok. Tender and quick to cook — dinner in 10 minutes.",
            inStock: true
        ),
        GroceryProduct(
            name: "Slow-Cook Beef Brisket",
            brand: "Mort & Co.",
            category: "Beef",
            price: 18.99,
            originalPrice: nil,
            unit: "1 kg",
            rating: 4.6,
            reviewCount: 142,
            imageName: "flame.fill",
            imageColor: Color(hex: "#E04D3A"),
            description: "100-day grain-fed beef brisket. Falls apart after 8 hours in the slow cooker — worth every minute.",
            inStock: true
        ),

        // ── PORK ─────────────────────────────────────────────────────────────
        GroceryProduct(
            name: "Pork Belly Slices",
            brand: "Borrowdale",
            category: "Pork",
            price: 11.49,
            originalPrice: 14.99,
            unit: "500g",
            rating: 4.8,
            reviewCount: 396,
            imageName: "fork.knife",
            imageColor: Color(hex: "#EC4899"),
            description: "Free range pork belly, sliced and ready for char siu, Korean BBQ or crispy oven roast.",
            inStock: true
        ),
        GroceryProduct(
            name: "Pork Mince",
            brand: "Borrowdale",
            category: "Pork",
            price: 9.49,
            originalPrice: nil,
            unit: "500g",
            rating: 4.5,
            reviewCount: 211,
            imageName: "fork.knife",
            imageColor: Color(hex: "#EC4899"),
            description: "Free range coarse-ground pork mince. Ideal for dumplings, meatballs and san choy bau.",
            inStock: true
        ),
        GroceryProduct(
            name: "Pork Spare Ribs",
            brand: "Borrowdale",
            category: "Pork",
            price: 16.99,
            originalPrice: 21.00,
            unit: "800g rack",
            rating: 4.7,
            reviewCount: 318,
            imageName: "fork.knife",
            imageColor: Color(hex: "#EC4899"),
            description: "Full rack of free range pork spare ribs. Slow roast or BBQ with your favourite sticky glaze.",
            inStock: true
        ),

        // ── LAMB ─────────────────────────────────────────────────────────────
        GroceryProduct(
            name: "Lamb Loin Chops",
            brand: "Cape Grim",
            category: "Lamb",
            price: 17.99,
            originalPrice: 22.00,
            unit: "500g (4 chops)",
            rating: 4.8,
            reviewCount: 267,
            imageName: "flame.fill",
            imageColor: Color(hex: "#7C3AED"),
            description: "Pasture-raised Tasmanian lamb loin chops. Pure grass-fed. Season simply, cook hot and fast.",
            inStock: true
        ),
        GroceryProduct(
            name: "Lamb Mince",
            brand: "Cape Grim",
            category: "Lamb",
            price: 13.49,
            originalPrice: nil,
            unit: "500g",
            rating: 4.6,
            reviewCount: 189,
            imageName: "flame.fill",
            imageColor: Color(hex: "#7C3AED"),
            description: "Lean grass-fed Tasmanian lamb mince. Great for shepherd's pie, kofta and moussaka.",
            inStock: true
        ),

        // ── SEAFOOD ───────────────────────────────────────────────────────────
        GroceryProduct(
            name: "Atlantic Salmon Fillets",
            brand: "Huon Aquaculture",
            category: "Seafood",
            price: 14.99,
            originalPrice: 18.50,
            unit: "2 × 150g",
            rating: 4.7,
            reviewCount: 534,
            imageName: "drop.fill",
            imageColor: Color(hex: "#0EA5E9"),
            description: "Sustainably farmed Tasmanian salmon. Rich in omega-3. Skin-on fillets — pan-fry or oven bake.",
            inStock: true
        ),
        GroceryProduct(
            name: "Jumbo Tiger Prawns",
            brand: "Queensland Fresh",
            category: "Seafood",
            price: 19.99,
            originalPrice: 26.00,
            unit: "500g raw, deveined",
            rating: 4.8,
            reviewCount: 412,
            imageName: "drop.fill",
            imageColor: Color(hex: "#0EA5E9"),
            description: "Wild-caught Queensland tiger prawns, deveined and ready to cook. BBQ, stir-fry or garlic butter.",
            inStock: true
        ),
        GroceryProduct(
            name: "Barramundi Fillets",
            brand: "Blue River",
            category: "Seafood",
            price: 13.49,
            originalPrice: nil,
            unit: "400g skin-on",
            rating: 4.5,
            reviewCount: 228,
            imageName: "drop.fill",
            imageColor: Color(hex: "#0EA5E9"),
            description: "Australian barramundi. Mild, flaky white fish. Crispy pan-fry or wrap in foil on the BBQ.",
            inStock: true
        )
    ]
}

extension DeliverySlot {
    static let available: [DeliverySlot] = [
        DeliverySlot(label: "Express", time: "30–45 min", fee: 4.99, isSelected: true),
        DeliverySlot(label: "Standard", time: "2–4 hours", fee: 2.99),
        DeliverySlot(label: "Scheduled", time: "Tomorrow 9am–12pm", fee: 0.00)
    ]
}

extension PaymentMethod {
    static let available: [PaymentMethod] = [
        PaymentMethod(name: "Visa •••• 4821", detail: "Expires 09/27", iconName: "creditcard.fill", color: Color(hex: "#4F7FFF")),
        PaymentMethod(name: "Apple Pay", detail: "Touch ID", iconName: "apple.logo", color: Color(hex: "#1C1C2E")),
        PaymentMethod(name: "CSQ Wallet", detail: "$24.50 balance", iconName: "wallet.pass.fill", color: Color.csqPrimary),
        PaymentMethod(name: "PayPal", detail: "jeff.lin@contentsquare.com", iconName: "p.circle.fill", color: Color(hex: "#0070BA"))
    ]
}

// MARK: - Cart Store (Observable)
class CartStore: ObservableObject {
    @Published var items: [CartItem] = []

    var totalItems: Int { items.reduce(0) { $0 + $1.quantity } }
    var subtotal: Double { items.reduce(0) { $0 + $1.subtotal } }
    var deliveryFee: Double { subtotal > 0 ? 2.99 : 0 }
    var serviceFee: Double { subtotal > 0 ? 0.99 : 0 }
    var total: Double { subtotal + deliveryFee + serviceFee }

    func add(_ product: GroceryProduct) {
        if let index = items.firstIndex(where: { $0.product.id == product.id }) {
            items[index].quantity += 1
        } else {
            items.append(CartItem(product: product, quantity: 1))
        }
    }

    func remove(_ product: GroceryProduct) {
        if let index = items.firstIndex(where: { $0.product.id == product.id }) {
            if items[index].quantity > 1 {
                items[index].quantity -= 1
            } else {
                items.remove(at: index)
            }
        }
    }

    func quantity(of product: GroceryProduct) -> Int {
        items.first(where: { $0.product.id == product.id })?.quantity ?? 0
    }

    func clear() { items = [] }
}
