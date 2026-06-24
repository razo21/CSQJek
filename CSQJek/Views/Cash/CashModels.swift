import SwiftUI

// MARK: - Transaction Types

enum CashTransactionType {
    case qrPayment, sent, received, topUp, withdrawal, international
}

enum CashTransactionStatus: String {
    case completed = "Completed"   // rawValue kept stable for analytics
    case pending   = "Pending"
    case failed    = "Failed"

    /// User-facing label; rawValue stays English for analytics/keys.
    func displayName(for market: Market) -> String {
        guard market == .tokyo else { return rawValue }
        switch self {
        case .completed: return "完了"
        case .pending:   return "処理中"
        case .failed:    return "失敗"
        }
    }
}

// MARK: - Core Models

struct CashTransaction: Identifiable {
    let id            = UUID()
    let type          : CashTransactionType
    let title         : String
    let subtitle      : String
    let amount        : Double       // positive = credit, negative = debit
    let date          : Date
    let status        : CashTransactionStatus
    let icon          : String
    let iconColor     : Color
    let reference     : String       // transaction reference shown in detail view

    init(type: CashTransactionType, title: String, subtitle: String,
         amount: Double, date: Date, status: CashTransactionStatus,
         icon: String, iconColor: Color, reference: String = "") {
        self.type      = type
        self.title     = title
        self.subtitle  = subtitle
        self.amount    = amount
        self.date      = date
        self.status    = status
        self.icon      = icon
        self.iconColor = iconColor
        // Auto-generate a reference if none supplied
        self.reference = reference.isEmpty
            ? "CSQ-\(String(UUID().uuidString.prefix(8)).uppercased())"
            : reference
    }
}

struct CashContact: Identifiable {
    let id            = UUID()
    let name          : String
    let initials      : String
    let phone         : String
    let avatarColor   : Color
    let lastAmount    : Double
    let lastDate      : String
}

struct QRPaymentPayload: Identifiable {
    let id            = UUID()
    let merchant      : String
    let amount        : Double
    let reference     : String
    let merchantId    : String
    let category      : String
    let merchantColor : Color
    let merchantIcon  : String
}

// MARK: - Wallet Store

class CashWalletStore: ObservableObject {
    @Published var balance      : Double                = 2_847.50
    @Published var transactions : [CashTransaction]    = CashTransaction.mockList
    @Published var contacts     : [CashContact]        = CashContact.mockList
    @Published var recentPayment: QRPaymentPayload?    = nil

    /// Set in `configure(market:)`; drives the language of dynamically-created
    /// transaction titles/subtitles so the Tokyo wallet stays fully Japanese.
    private var market: Market = .singapore
    private var isTokyo: Bool { market == .tokyo }

    // MARK: Actions

    func payViaQR(_ payload: QRPaymentPayload) {
        guard balance >= payload.amount else { return }
        balance -= payload.amount
        let t = CashTransaction(
            type: .qrPayment, title: payload.merchant,
            subtitle: isTokyo ? "QR支払い · \(payload.reference)" : "QR Payment · \(payload.reference)",
            amount: -payload.amount, date: Date(),
            status: .completed, icon: "qrcode",
            iconColor: Color(hex: "#1B3FAB")
        )
        transactions.insert(t, at: 0)
        recentPayment = payload
    }

    func send(amount: Double, to recipient: String, note: String = "") {
        balance -= amount
        let defaultNote = isTokyo ? "CSQキャッシュ送金" : "CSQCash Transfer"
        let t = CashTransaction(
            type: .sent, title: isTokyo ? "\(recipient)へ送金" : "Sent to \(recipient)",
            subtitle: note.isEmpty ? defaultNote : note,
            amount: -amount, date: Date(),
            status: .completed, icon: "arrow.up.right.circle.fill",
            iconColor: cashAmber
        )
        transactions.insert(t, at: 0)
    }

    func sendInternational(amount: Double, recipient: String, bank: String, currency: String) {
        balance -= amount
        let defaultBank = isTokyo ? "海外送金" : "International Transfer"
        let t = CashTransaction(
            type: .international, title: isTokyo ? "海外送金 · \(recipient)" : "Intl · \(recipient)",
            subtitle: "\(bank.isEmpty ? defaultBank : bank) · \(currency)",
            amount: -amount, date: Date(),
            status: .completed, icon: "globe",
            iconColor: Color(hex: "#6366F1")
        )
        transactions.insert(t, at: 0)
    }

    func addFunds(amount: Double, source: String) {
        balance += amount
        let t = CashTransaction(
            type: .topUp, title: isTokyo ? "チャージ" : "Top Up",
            subtitle: isTokyo ? "\(source)から" : "From \(source)",
            amount: +amount, date: Date(),
            status: .completed, icon: "plus.circle.fill",
            iconColor: cashGreen
        )
        transactions.insert(t, at: 0)
    }

    func withdraw(amount: Double, to dest: String) {
        balance -= amount
        let t = CashTransaction(
            type: .withdrawal, title: isTokyo ? "引き出し" : "Withdrawal",
            subtitle: isTokyo ? "\(dest)へ" : "To \(dest)",
            amount: -amount, date: Date(),
            status: .completed, icon: "arrow.down.circle.fill",
            iconColor: Color(hex: "#EF4444")
        )
        transactions.insert(t, at: 0)
    }

    /// Call this in .onAppear once marketConfig is available.
    func configure(market: Market) {
        self.market = market
        guard balance == 2_847.50 || balance == 284_750.0 else { return } // only reset if untouched
        switch market {
        case .tokyo:
            contacts     = CashContact.tokyoMockList
            transactions = CashTransaction.tokyoMockList
            balance      = 284_750.0
        case .sydney:
            // Sydney reuses Singapore-scale numeric values (A$ rendering handled in views).
            contacts     = CashContact.sydneyMockList
            transactions = CashTransaction.sydneyMockList
            balance      = 2_847.50
        default:
            // Singapore + any future market fall back to the Singapore dataset.
            contacts     = CashContact.mockList
            transactions = CashTransaction.mockList
            balance      = 2_847.50
        }
    }
}

// MARK: - Design Tokens (Cash-specific)

let cashGreen  = Color(hex: "#00A651")
let cashAmber  = Color(hex: "#F59E0B")
let cashDark   = Color(hex: "#0A1628")
let cashNavy   = Color(hex: "#0E2044")

// MARK: - Currency Formatter

extension Double {
    /// Formats a Double as "2,847.50" with thousands separators.
    /// Use as: wallet.balance.sgdString → "2,847.50" (prefix S$ in the UI)
    var sgdString: String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        f.groupingSeparator = ","
        f.groupingSize = 3
        return f.string(from: NSNumber(value: self)) ?? String(format: "%.2f", self)
    }
}

// MARK: - Mock Data

extension CashTransaction {
    static let tokyoMockList: [CashTransaction] = [
        CashTransaction(type: .qrPayment,     title: "浅草 天ぷら 鈴木",          subtitle: "QR支払い · テーブル3",              amount: -1_280,  date: .daysAgo(0),  status: .completed, icon: "qrcode",                    iconColor: Color(hex: "#1B3FAB"), reference: "CSQ-QR001842"),
        CashTransaction(type: .received,      title: "田中 健太から入金",           subtitle: "ランチ代",                          amount: +4_800,  date: .daysAgo(1),  status: .completed, icon: "arrow.down.left.circle.fill", iconColor: cashGreen,             reference: "CSQ-TX009910"),
        CashTransaction(type: .qrPayment,     title: "ローソン 渋谷店",            subtitle: "QR支払い · 渋谷スクランブル",        amount: -780,    date: .daysAgo(1),  status: .completed, icon: "qrcode",                    iconColor: Color(hex: "#1B3FAB"), reference: "CSQ-QR009921"),
        CashTransaction(type: .topUp,         title: "チャージ",                   subtitle: "みずほ銀行 ••4821から",             amount: +50_000, date: .daysAgo(2),  status: .completed, icon: "plus.circle.fill",          iconColor: cashGreen,             reference: "CSQ-TP004821"),
        CashTransaction(type: .sent,          title: "佐藤 美咲へ送金",            subtitle: "夕食代",                            amount: -6_500,  date: .daysAgo(3),  status: .completed, icon: "arrow.up.right.circle.fill", iconColor: cashAmber,             reference: "CSQ-TX007734"),
        CashTransaction(type: .received,      title: "鈴木 拓也から入金",           subtitle: "映画チケット代 · 新宿ピカデリー",   amount: +8_800,  date: .daysAgo(4),  status: .completed, icon: "arrow.down.left.circle.fill", iconColor: cashGreen,             reference: "CSQ-TX008856"),
        CashTransaction(type: .qrPayment,     title: "スターバックス 新宿店",       subtitle: "QR支払い · オーダー#5521",          amount: -850,    date: .daysAgo(5),  status: .completed, icon: "qrcode",                    iconColor: Color(hex: "#1B3FAB"), reference: "CSQ-QR005521"),
        CashTransaction(type: .sent,          title: "山田 裕子へ送金",            subtitle: "タクシー代",                        amount: -2_250,  date: .daysAgo(6),  status: .completed, icon: "arrow.up.right.circle.fill", iconColor: cashAmber,             reference: "CSQ-TX006643"),
        CashTransaction(type: .international, title: "海外送金",                   subtitle: "HSBC · USD",                       amount: -32_000, date: .daysAgo(7),  status: .completed, icon: "globe",                     iconColor: Color(hex: "#6366F1"), reference: "CSQ-IN007788"),
        CashTransaction(type: .received,      title: "中村 翔太から入金",           subtitle: "出張費用",                          amount: +5_500,  date: .daysAgo(8),  status: .completed, icon: "arrow.down.left.circle.fill", iconColor: cashGreen,             reference: "CSQ-TX008899"),
        CashTransaction(type: .withdrawal,    title: "引き出し",                   subtitle: "みずほ銀行 ••4821へ",               amount: -20_000, date: .daysAgo(10), status: .completed, icon: "arrow.down.circle.fill",    iconColor: Color(hex: "#EF4444"), reference: "CSQ-WD004821"),
        CashTransaction(type: .sent,          title: "小林 愛へ送金",              subtitle: "ホテル代",                          amount: -3_500,  date: .daysAgo(11), status: .completed, icon: "arrow.up.right.circle.fill", iconColor: cashAmber,             reference: "CSQ-TX011122"),
        CashTransaction(type: .topUp,         title: "チャージ",                   subtitle: "三井住友銀行 ••2139から",           amount: +20_000, date: .daysAgo(14), status: .completed, icon: "plus.circle.fill",          iconColor: cashGreen,             reference: "CSQ-TP002139"),
        CashTransaction(type: .qrPayment,     title: "吉野家 東京駅前店",          subtitle: "QR支払い · オーダー",               amount: -650,    date: .daysAgo(15), status: .completed, icon: "qrcode",                    iconColor: Color(hex: "#1B3FAB"), reference: "CSQ-QR015501"),
    ]

    // Australian dataset. merchantId / reference stable keys mirror the Singapore
    // list (same positions); names, merchants and notes are Sydney-localized.
    // English text (Australian tone); amounts reuse Singapore-scale values.
    static let sydneyMockList: [CashTransaction] = [
        CashTransaction(type: .qrPayment,     title: "Bourke Street Bakery",   subtitle: "QR Payment · Table 7",         amount: -12.80,  date: .daysAgo(0),  status: .completed, icon: "qrcode",                    iconColor: Color(hex: "#1B3FAB"), reference: "CSQ-QR001842"),
        CashTransaction(type: .received,      title: "From Florian Korbella",  subtitle: "Team lunch split",              amount: +48.00,  date: .daysAgo(1),  status: .completed, icon: "arrow.down.left.circle.fill", iconColor: cashGreen,             reference: "CSQ-TX009910"),
        CashTransaction(type: .qrPayment,     title: "Woolworths Metro",       subtitle: "QR Payment · Town Hall",       amount: -47.20,  date: .daysAgo(1),  status: .completed, icon: "qrcode",                    iconColor: Color(hex: "#1B3FAB"), reference: "CSQ-QR009921"),
        CashTransaction(type: .topUp,         title: "Top Up",                 subtitle: "From Commonwealth Bank ••4821",amount: +500.00, date: .daysAgo(2),  status: .completed, icon: "plus.circle.fill",          iconColor: cashGreen,             reference: "CSQ-TP004821"),
        CashTransaction(type: .sent,          title: "Sent to Abhi Nair",      subtitle: "Client dinner share",          amount: -65.00,  date: .daysAgo(3),  status: .completed, icon: "arrow.up.right.circle.fill", iconColor: cashAmber,             reference: "CSQ-TX007734"),
        CashTransaction(type: .received,      title: "From Sebastien Barillot",subtitle: "Drinks · Opera Bar",           amount: +88.00,  date: .daysAgo(4),  status: .completed, icon: "arrow.down.left.circle.fill", iconColor: cashGreen,             reference: "CSQ-TX008856"),
        CashTransaction(type: .qrPayment,     title: "Campos Coffee Newtown",  subtitle: "QR Payment · Order #5521",     amount: -8.50,   date: .daysAgo(5),  status: .completed, icon: "qrcode",                    iconColor: Color(hex: "#1B3FAB"), reference: "CSQ-QR005521"),
        CashTransaction(type: .sent,          title: "Sent to Lynn Lertsumitkul", subtitle: "Uber ride split",           amount: -22.50,  date: .daysAgo(6),  status: .completed, icon: "arrow.up.right.circle.fill", iconColor: cashAmber,             reference: "CSQ-TX006643"),
        CashTransaction(type: .international, title: "Intl · Atsushi Okimoto",  subtitle: "HSBC UK · GBP",                amount: -320.00, date: .daysAgo(7),  status: .completed, icon: "globe",                     iconColor: Color(hex: "#6366F1"), reference: "CSQ-IN007788"),
        CashTransaction(type: .received,      title: "From Andrew Elturk",     subtitle: "Conference expenses",          amount: +55.00,  date: .daysAgo(8),  status: .completed, icon: "arrow.down.left.circle.fill", iconColor: cashGreen,             reference: "CSQ-TX008899"),
        CashTransaction(type: .withdrawal,    title: "Withdrawal",             subtitle: "To Commonwealth Bank ••4821",  amount: -200.00, date: .daysAgo(10), status: .completed, icon: "arrow.down.circle.fill",    iconColor: Color(hex: "#EF4444"), reference: "CSQ-WD004821"),
        CashTransaction(type: .sent,          title: "Sent to Jaewon Jang",    subtitle: "Hotel booking split",          amount: -35.00,  date: .daysAgo(11), status: .completed, icon: "arrow.up.right.circle.fill", iconColor: cashAmber,             reference: "CSQ-TX011122"),
        CashTransaction(type: .topUp,         title: "Top Up",                 subtitle: "From Westpac Choice ••2139",   amount: +200.00, date: .daysAgo(14), status: .completed, icon: "plus.circle.fill",          iconColor: cashGreen,             reference: "CSQ-TP002139"),
        CashTransaction(type: .qrPayment,     title: "Harry's Café de Wheels", subtitle: "QR Payment · Woolloomooloo",   amount: -6.50,   date: .daysAgo(15), status: .completed, icon: "qrcode",                    iconColor: Color(hex: "#1B3FAB"), reference: "CSQ-QR015501"),
    ]

    static let mockList: [CashTransaction] = [
        CashTransaction(type: .qrPayment,     title: "Lau Pa Sat",             subtitle: "QR Payment · Table 7",         amount: -12.80,  date: .daysAgo(0),  status: .completed, icon: "qrcode",                    iconColor: Color(hex: "#1B3FAB"), reference: "CSQ-QR001842"),
        CashTransaction(type: .received,      title: "From Florian Korbella",  subtitle: "Team lunch split",              amount: +48.00,  date: .daysAgo(1),  status: .completed, icon: "arrow.down.left.circle.fill", iconColor: cashGreen,             reference: "CSQ-TX009910"),
        CashTransaction(type: .qrPayment,     title: "Cold Storage",           subtitle: "QR Payment · Bugis Junction",  amount: -47.20,  date: .daysAgo(1),  status: .completed, icon: "qrcode",                    iconColor: Color(hex: "#1B3FAB"), reference: "CSQ-QR009921"),
        CashTransaction(type: .topUp,         title: "Top Up",                 subtitle: "From DBS Savings ••4821",      amount: +500.00, date: .daysAgo(2),  status: .completed, icon: "plus.circle.fill",          iconColor: cashGreen,             reference: "CSQ-TP004821"),
        CashTransaction(type: .sent,          title: "Sent to Abhi Nair",      subtitle: "Client dinner share",          amount: -65.00,  date: .daysAgo(3),  status: .completed, icon: "arrow.up.right.circle.fill", iconColor: cashAmber,             reference: "CSQ-TX007734"),
        CashTransaction(type: .received,      title: "From Sebastien Barillot",subtitle: "Drinks · Marina Bay Sands",    amount: +88.00,  date: .daysAgo(4),  status: .completed, icon: "arrow.down.left.circle.fill", iconColor: cashGreen,             reference: "CSQ-TX008856"),
        CashTransaction(type: .qrPayment,     title: "Starbucks ION Orchard",  subtitle: "QR Payment · Order #5521",     amount: -8.50,   date: .daysAgo(5),  status: .completed, icon: "qrcode",                    iconColor: Color(hex: "#1B3FAB"), reference: "CSQ-QR005521"),
        CashTransaction(type: .sent,          title: "Sent to Lynn Lertsumitkul", subtitle: "Grab ride split",           amount: -22.50,  date: .daysAgo(6),  status: .completed, icon: "arrow.up.right.circle.fill", iconColor: cashAmber,             reference: "CSQ-TX006643"),
        CashTransaction(type: .international, title: "Atsushi Okimoto",        subtitle: "MUFG Bank · JPY",              amount: -320.00, date: .daysAgo(7),  status: .completed, icon: "globe",                     iconColor: Color(hex: "#6366F1"), reference: "CSQ-IN007788"),
        CashTransaction(type: .received,      title: "From Andrew Elturk",     subtitle: "Conference expenses",          amount: +55.00,  date: .daysAgo(8),  status: .completed, icon: "arrow.down.left.circle.fill", iconColor: cashGreen,             reference: "CSQ-TX008899"),
        CashTransaction(type: .withdrawal,    title: "Withdrawal",             subtitle: "To DBS Savings ••4821",        amount: -200.00, date: .daysAgo(10), status: .completed, icon: "arrow.down.circle.fill",    iconColor: Color(hex: "#EF4444"), reference: "CSQ-WD004821"),
        CashTransaction(type: .sent,          title: "Sent to Jaewon Jang",    subtitle: "Hotel booking split",          amount: -35.00,  date: .daysAgo(11), status: .completed, icon: "arrow.up.right.circle.fill", iconColor: cashAmber,             reference: "CSQ-TX011122"),
        CashTransaction(type: .topUp,         title: "Top Up",                 subtitle: "From OCBC 360 ••2139",         amount: +200.00, date: .daysAgo(14), status: .completed, icon: "plus.circle.fill",          iconColor: cashGreen,             reference: "CSQ-TP002139"),
        CashTransaction(type: .qrPayment,     title: "Hawker Chan",            subtitle: "QR Payment · Orchard",         amount: -6.50,   date: .daysAgo(15), status: .completed, icon: "qrcode",                    iconColor: Color(hex: "#1B3FAB"), reference: "CSQ-QR015501"),
    ]
}

extension CashContact {
    // Australian contacts — plausible Sydney names, +61 mobile numbers,
    // Singapore-scale amounts. English (Australian tone).
    // Sydney contacts use the same people (the SC team) as the Singapore version,
    // with Australian +61 numbers and A$-scale amounts.
    static let sydneyMockList: [CashContact] = [
        CashContact(name: "Florian Korbella",   initials: "FK", phone: "+61 412 345 401", avatarColor: Color(hex: "#7C3AED"), lastAmount: 48.00,  lastDate: "Yesterday"),
        CashContact(name: "Lynn Lertsumitkul",  initials: "LL", phone: "+61 423 456 512", avatarColor: Color(hex: "#EC4899"), lastAmount: 22.50,  lastDate: "2 days ago"),
        CashContact(name: "Abhi Nair",          initials: "AN", phone: "+61 434 567 623", avatarColor: Color(hex: "#2563EB"), lastAmount: 65.00,  lastDate: "3 days ago"),
        CashContact(name: "Atsushi Okimoto",    initials: "AO", phone: "+61 445 678 734", avatarColor: Color(hex: "#059669"), lastAmount: 120.00, lastDate: "5 days ago"),
        CashContact(name: "Jaewon Jang",        initials: "JJ", phone: "+61 456 789 845", avatarColor: Color(hex: "#F59E0B"), lastAmount: 35.00,  lastDate: "1 week ago"),
        CashContact(name: "Sebastien Barillot", initials: "SB", phone: "+61 467 890 956", avatarColor: Color(hex: "#0EA5E9"), lastAmount: 88.00,  lastDate: "1 week ago"),
        CashContact(name: "Andrew Elturk",      initials: "AE", phone: "+61 478 900 067", avatarColor: Color(hex: "#EF4444"), lastAmount: 55.00,  lastDate: "2 weeks ago"),
        CashContact(name: "Marcus Lim",         initials: "ML", phone: "+61 489 011 178", avatarColor: Color(hex: "#10B981"), lastAmount: 30.00,  lastDate: "2 weeks ago"),
        CashContact(name: "Priya Sharma",       initials: "PS", phone: "+61 490 122 289", avatarColor: Color(hex: "#D97706"), lastAmount: 15.00,  lastDate: "3 weeks ago"),
    ]

    static let mockList: [CashContact] = [
        CashContact(name: "Florian Korbella",     initials: "FK", phone: "+65 9123 4401", avatarColor: Color(hex: "#7C3AED"), lastAmount: 48.00,  lastDate: "Yesterday"),
        CashContact(name: "Lynn Lertsumitkul",    initials: "LL", phone: "+65 9234 5512", avatarColor: Color(hex: "#EC4899"), lastAmount: 22.50,  lastDate: "2 days ago"),
        CashContact(name: "Abhi Nair",            initials: "AN", phone: "+65 8345 6623", avatarColor: Color(hex: "#2563EB"), lastAmount: 65.00,  lastDate: "3 days ago"),
        CashContact(name: "Atsushi Okimoto",      initials: "AO", phone: "+65 9456 7734", avatarColor: Color(hex: "#059669"), lastAmount: 120.00, lastDate: "5 days ago"),
        CashContact(name: "Jaewon Jang",          initials: "JJ", phone: "+65 8567 8845", avatarColor: Color(hex: "#F59E0B"), lastAmount: 35.00,  lastDate: "1 week ago"),
        CashContact(name: "Sebastien Barillot",   initials: "SB", phone: "+65 9678 9956", avatarColor: Color(hex: "#0EA5E9"), lastAmount: 88.00,  lastDate: "1 week ago"),
        CashContact(name: "Andrew Elturk",        initials: "AE", phone: "+65 8789 0067", avatarColor: Color(hex: "#EF4444"), lastAmount: 55.00,  lastDate: "2 weeks ago"),
        CashContact(name: "Marcus Lim",           initials: "ML", phone: "+65 9890 1178", avatarColor: Color(hex: "#10B981"), lastAmount: 30.00,  lastDate: "2 weeks ago"),
        CashContact(name: "Priya Sharma",         initials: "PS", phone: "+65 8901 2289", avatarColor: Color(hex: "#D97706"), lastAmount: 15.00,  lastDate: "3 weeks ago"),
    ]

    static let tokyoMockList: [CashContact] = [
        CashContact(name: "田中 健太",   initials: "田健", phone: "+81 90-1234-5501", avatarColor: Color(hex: "#7C3AED"), lastAmount: 4_800,  lastDate: "昨日"),
        CashContact(name: "佐藤 美咲",   initials: "佐美", phone: "+81 80-2345-6612", avatarColor: Color(hex: "#EC4899"), lastAmount: 2_250,  lastDate: "2日前"),
        CashContact(name: "鈴木 拓也",   initials: "鈴拓", phone: "+81 90-3456-7723", avatarColor: Color(hex: "#2563EB"), lastAmount: 6_500,  lastDate: "3日前"),
        CashContact(name: "山田 裕子",   initials: "山裕", phone: "+81 80-4567-8834", avatarColor: Color(hex: "#059669"), lastAmount: 12_000, lastDate: "5日前"),
        CashContact(name: "中村 翔太",   initials: "中翔", phone: "+81 90-5678-9945", avatarColor: Color(hex: "#F59E0B"), lastAmount: 3_500,  lastDate: "1週間前"),
        CashContact(name: "小林 愛",     initials: "小愛", phone: "+81 80-6789-0056", avatarColor: Color(hex: "#0EA5E9"), lastAmount: 8_800,  lastDate: "1週間前"),
        CashContact(name: "伊藤 大輝",   initials: "伊大", phone: "+81 90-7890-1167", avatarColor: Color(hex: "#EF4444"), lastAmount: 5_500,  lastDate: "2週間前"),
        CashContact(name: "渡辺 さくら", initials: "渡桜", phone: "+81 80-8901-2278", avatarColor: Color(hex: "#10B981"), lastAmount: 3_000,  lastDate: "2週間前"),
        CashContact(name: "加藤 誠",     initials: "加誠", phone: "+81 90-9012-3389", avatarColor: Color(hex: "#D97706"), lastAmount: 1_500,  lastDate: "3週間前"),
    ]
}

// QR demo payloads
extension QRPaymentPayload {
    static let demoMerchants: [QRPaymentPayload] = [
        QRPaymentPayload(merchant: "Lau Pa Sat",           amount: 12.80, reference: "Table 7 · Order #1842", merchantId: "SG-HAWKER-001", category: "Food & Beverage", merchantColor: Color(hex: "#F59E0B"), merchantIcon: "fork.knife"),
        QRPaymentPayload(merchant: "Cold Storage",         amount: 47.20, reference: "Bugis · Ref #CS-9921",  merchantId: "SG-RETAIL-042", category: "Groceries",       merchantColor: Color(hex: "#EF4444"), merchantIcon: "cart.fill"),
        QRPaymentPayload(merchant: "Starbucks ION Orchard",amount: 8.50,  reference: "Order #5521 · Venti",   merchantId: "SG-CAFE-012",   category: "Café",            merchantColor: Color(hex: "#00704A"), merchantIcon: "cup.and.saucer.fill"),
    ]

    // merchantId + reference are stable keys (not translated). Categories/names
    // are Japan-localized; amounts are whole-yen values.
    static let tokyoDemoMerchants: [QRPaymentPayload] = [
        QRPaymentPayload(merchant: "セブン-イレブン 渋谷店", amount: 780,  reference: "Table 7 · Order #1842", merchantId: "SG-HAWKER-001", category: "コンビニ",         merchantColor: Color(hex: "#F59E0B"), merchantIcon: "fork.knife"),
        QRPaymentPayload(merchant: "マツモトキヨシ 新宿店",  amount: 2_480, reference: "Bugis · Ref #CS-9921",  merchantId: "SG-RETAIL-042", category: "ドラッグストア",   merchantColor: Color(hex: "#EF4444"), merchantIcon: "cart.fill"),
        QRPaymentPayload(merchant: "スターバックス 表参道店", amount: 620,  reference: "Order #5521 · Venti",   merchantId: "SG-CAFE-012",   category: "カフェ",           merchantColor: Color(hex: "#00704A"), merchantIcon: "cup.and.saucer.fill"),
    ]

    // merchantId + reference are stable keys (not translated). Names/categories
    // are Sydney-localized; amounts reuse Singapore-scale values. English text.
    static let sydneyDemoMerchants: [QRPaymentPayload] = [
        QRPaymentPayload(merchant: "Woolworths Metro",     amount: 12.80, reference: "Table 7 · Order #1842", merchantId: "SG-HAWKER-001", category: "Supermarket", merchantColor: Color(hex: "#F59E0B"), merchantIcon: "fork.knife"),
        QRPaymentPayload(merchant: "Coles Express",        amount: 47.20, reference: "Bugis · Ref #CS-9921",  merchantId: "SG-RETAIL-042", category: "Fuel",        merchantColor: Color(hex: "#EF4444"), merchantIcon: "cart.fill"),
        QRPaymentPayload(merchant: "Reuben Hills Café",    amount: 8.50,  reference: "Order #5521 · Venti",   merchantId: "SG-CAFE-012",   category: "Cafe",        merchantColor: Color(hex: "#00704A"), merchantIcon: "cup.and.saucer.fill"),
    ]

    // Singapore is the default/fallback; future markets resolve to it until localized.
    static let demoMerchantsByMarket: [Market: [QRPaymentPayload]] = [
        .tokyo:     tokyoDemoMerchants,
        .sydney:    sydneyDemoMerchants,
        .singapore: demoMerchants,
    ]

    static func demoMerchants(for market: Market) -> [QRPaymentPayload] {
        demoMerchantsByMarket[market] ?? demoMerchants
    }

    static var demo: QRPaymentPayload { demoMerchants[0] }
}

// MARK: - Helpers

extension Date {
    static func daysAgo(_ n: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -n, to: Date()) ?? Date()
    }

    var transactionLabel: String {
        let cal = Calendar.current
        if cal.isDateInToday(self)     { return "Today" }
        if cal.isDateInYesterday(self) { return "Yesterday" }
        let fmt = DateFormatter(); fmt.dateFormat = "d MMM"
        return fmt.string(from: self)
    }

    /// Market-aware relative/short date label for transaction rows.
    func transactionLabel(for market: Market) -> String {
        guard market == .tokyo else { return transactionLabel }
        let cal = Calendar.current
        if cal.isDateInToday(self)     { return "今日" }
        if cal.isDateInYesterday(self) { return "昨日" }
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "ja_JP")
        fmt.dateFormat = "M月d日"
        return fmt.string(from: self)
    }

    var timeLabel: String {
        let fmt = DateFormatter(); fmt.dateFormat = "h:mm a"
        return fmt.string(from: self)
    }
}

// MARK: - Saved bank accounts (for Add/Withdraw + International)

struct LinkedAccount: Identifiable {
    let id     = UUID()
    let bank   : String
    let type   : String
    let last4  : String
    let icon   : String
    let color  : Color
}

extension LinkedAccount {
    static let mockAccounts: [LinkedAccount] = [
        LinkedAccount(bank: "DBS Bank",  type: "Savings", last4: "4821", icon: "building.columns.fill", color: Color(hex: "#CC0001")),
        LinkedAccount(bank: "OCBC Bank", type: "360 Account", last4: "2139", icon: "building.columns.fill", color: Color(hex: "#CC4600")),
        LinkedAccount(bank: "UOB Bank",  type: "One Account", last4: "7763", icon: "building.columns.fill", color: Color(hex: "#00539B")),
    ]

    static let tokyoMockAccounts: [LinkedAccount] = [
        LinkedAccount(bank: "みずほ銀行",   type: "普通預金", last4: "4821", icon: "building.columns.fill", color: Color(hex: "#1A3C6E")),
        LinkedAccount(bank: "三井住友銀行", type: "総合口座", last4: "2139", icon: "building.columns.fill", color: Color(hex: "#00A040")),
        LinkedAccount(bank: "三菱UFJ銀行",  type: "普通預金", last4: "7763", icon: "building.columns.fill", color: Color(hex: "#CC0000")),
    ]

    // Australian banks. last4 mirror the Singapore accounts so they stay
    // consistent with the Sydney transaction history (CommBank ••4821 etc.).
    static let sydneyMockAccounts: [LinkedAccount] = [
        LinkedAccount(bank: "Commonwealth Bank", type: "Smart Access", last4: "4821", icon: "building.columns.fill", color: Color(hex: "#FFCC00")),
        LinkedAccount(bank: "Westpac",           type: "Choice",       last4: "2139", icon: "building.columns.fill", color: Color(hex: "#DA1710")),
        LinkedAccount(bank: "NAB",               type: "Classic Banking", last4: "7763", icon: "building.columns.fill", color: Color(hex: "#E50000")),
    ]

    // Singapore is the default/fallback; future markets resolve to it until localized.
    static let mockAccountsByMarket: [Market: [LinkedAccount]] = [
        .tokyo:     tokyoMockAccounts,
        .sydney:    sydneyMockAccounts,
        .singapore: mockAccounts,
    ]

    static func mockAccounts(for market: Market) -> [LinkedAccount] {
        mockAccountsByMarket[market] ?? mockAccounts
    }
}

// MARK: - SWIFT / International

struct SWIFTCountry: Identifiable {
    let id       = UUID()
    let flag     : String
    let country  : String
    let currency : String
    let code     : String   // ISO

    /// Localized display name; `country` stays English for analytics/filtering.
    func displayName(for market: Market) -> String {
        guard market == .tokyo else { return country }
        switch code {
        case "MY": return "マレーシア"
        case "TH": return "タイ"
        case "PH": return "フィリピン"
        case "ID": return "インドネシア"
        case "VN": return "ベトナム"
        case "IN": return "インド"
        case "CN": return "中国"
        case "JP": return "日本"
        case "AU": return "オーストラリア"
        case "GB": return "イギリス"
        case "US": return "アメリカ"
        case "EU": return "ヨーロッパ"
        case "HK": return "香港"
        case "AE": return "アラブ首長国連邦"
        default:   return country
        }
    }
}

extension SWIFTCountry {
    static let list: [SWIFTCountry] = [
        SWIFTCountry(flag: "🇲🇾", country: "Malaysia",     currency: "MYR", code: "MY"),
        SWIFTCountry(flag: "🇹🇭", country: "Thailand",     currency: "THB", code: "TH"),
        SWIFTCountry(flag: "🇵🇭", country: "Philippines",  currency: "PHP", code: "PH"),
        SWIFTCountry(flag: "🇮🇩", country: "Indonesia",    currency: "IDR", code: "ID"),
        SWIFTCountry(flag: "🇻🇳", country: "Vietnam",      currency: "VND", code: "VN"),
        SWIFTCountry(flag: "🇮🇳", country: "India",        currency: "INR", code: "IN"),
        SWIFTCountry(flag: "🇨🇳", country: "China",        currency: "CNY", code: "CN"),
        SWIFTCountry(flag: "🇯🇵", country: "Japan",        currency: "JPY", code: "JP"),
        SWIFTCountry(flag: "🇦🇺", country: "Australia",    currency: "AUD", code: "AU"),
        SWIFTCountry(flag: "🇬🇧", country: "UK",           currency: "GBP", code: "GB"),
        SWIFTCountry(flag: "🇺🇸", country: "USA",          currency: "USD", code: "US"),
        SWIFTCountry(flag: "🇪🇺", country: "Europe",       currency: "EUR", code: "EU"),
        SWIFTCountry(flag: "🇭🇰", country: "Hong Kong",    currency: "HKD", code: "HK"),
        SWIFTCountry(flag: "🇦🇪", country: "UAE",          currency: "AED", code: "AE"),
    ]
}
