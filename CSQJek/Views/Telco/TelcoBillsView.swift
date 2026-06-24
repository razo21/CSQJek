import SwiftUI
import ContentsquareSDK

// ════════════════════════════════════════════════════════════════════════════
//  CSQMobile — Bills & Support "Frustration Journey"
//
//  Demo scenario (the Contentsquare story):
//    A user wants to PAY A BILL and, when it fails, to TALK TO A HUMAN.
//    Instead the app deflects them through self-service FAQ content, and the
//    contact options (live chat / phone) are buried under many layers. CS can
//    see exactly which content the user consumed, how deep they went, where the
//    funnel broke, and the moment they got frustrated and gave up.
//
//  The maze (each screen pushes onto TelcoHomeView's NavigationView):
//    Bills → Bill Detail → Payment (FAILS) → Help Center → Support Article
//          → Contact Support → Support Bot → Live Chat  (and/or → Call Us)
//
//  `depth` is threaded through every screen so analytics can see how many layers
//  deep the user is when they finally reach (or abandon) a human channel.
//
//  Localized via the established pattern: Tokyo gets Japanese, Singapore/Sydney
//  share English (currency differs only at display via `telcoMoney`). Long-form
//  content lives in TelcoModels.swift; short chrome uses inline `m == .tokyo`.
// ════════════════════════════════════════════════════════════════════════════

// MARK: - Canonical CS event names

private enum BillEvent {
    static let billsViewed        = "telco_bills_viewed"
    static let billDownloadTapped = "telco_bill_download_tapped"
    static let billOpened         = "telco_bill_opened"
    static let billDetailViewed   = "telco_bill_detail_viewed"
    static let pdfDownloaded      = "telco_bill_pdf_downloaded"
    static let paymentStarted     = "telco_bill_payment_started"
    static let paymentFailed      = "telco_bill_payment_failed"
    static let paymentRetried     = "telco_bill_payment_retried"
    static let paymentHelpTapped  = "telco_bill_payment_help_tapped"
    static let helpCenterViewed   = "telco_help_center_viewed"
    static let helpSearch         = "telco_help_search_performed"
    static let helpCategoryTapped = "telco_help_category_tapped"
    static let helpArticleTapped  = "telco_help_article_tapped"
    static let articleViewed      = "telco_support_article_viewed"
    static let articleFeedback    = "telco_support_article_feedback"
    static let relatedTapped      = "telco_support_article_related_tapped"
    static let stillNeedHelp      = "telco_support_still_need_help_tapped"
    static let contactViewed      = "telco_contact_options_viewed"
    static let contactDeflected   = "telco_contact_deflected"
    static let botOpened          = "telco_support_bot_opened"
    static let botMessageSent     = "telco_support_bot_message_sent"
    static let botEscalationReq    = "telco_support_bot_escalation_requested"
    static let botEscalated       = "telco_support_bot_escalated"
    static let liveChatQueued     = "telco_live_chat_queued"
    static let liveChatConnected  = "telco_live_chat_connected"
    static let liveChatMessage    = "telco_live_chat_message_sent"
    static let callUsViewed       = "telco_call_us_viewed"
    static let callNumberTapped   = "telco_call_number_tapped"
    static let supportAbandoned   = "telco_support_abandoned"   // the "pissed off and stop" signal
}

// Display a money value with an explicit sign for credits/discounts.
private func signedMoney(_ amount: Double, _ market: Market) -> String {
    (amount < 0 ? "−" : "") + telcoMoney(abs(amount), market)
}

// ════════════════════════════════════════════════════════════════════════════
// MARK: - 1. Bills (entry)
// ════════════════════════════════════════════════════════════════════════════

struct TelcoBillsView: View {
    @EnvironmentObject var marketConfig: MarketConfig
    @State private var downloadedInvoices: Set<String> = []

    private enum AID {
        static let payNow      = "bills_btn_pay_now"
        static let autopay     = "bills_card_autopay"
        static func billRow(_ inv: String) -> String { "bills_row_\(inv)" }
        static func download(_ inv: String) -> String { "bills_btn_download_\(inv)" }
    }

    var body: some View {
        let m = marketConfig.market
        let jp = m == .tokyo
        let current = TelcoBill.currentBill(for: m)

        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {

                // Headline "amount due" card
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text(jp ? "お支払い金額" : "Amount due")
                            .font(AppFont.body(13)).foregroundColor(.white.opacity(0.85))
                        Spacer()
                        Text(current.status.label(for: m))
                            .font(AppFont.body(11)).fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Color.white.opacity(0.22))
                            .clipShape(Capsule())
                    }
                    Text(telcoMoney(current.amount, m))
                        .font(.system(size: 40, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.system(size: 11))
                        Text((jp ? "支払期限 " : "Due ") + current.dueDate + " · " + current.invoiceNo)
                            .font(AppFont.body(12))
                    }
                    .foregroundColor(.white.opacity(0.9))

                    NavigationLink(destination: TelcoBillPaymentView(bill: current, depth: 1)) {
                        Text(jp ? "今すぐ支払う" : "Pay Bill Now")
                            .font(AppFont.body(16)).fontWeight(.bold)
                            .foregroundColor(.csqTelcoTeal)
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                    }
                    .accessibilityIdentifier(AID.payNow)
                    .accessibilityLabel(jp ? "請求書を今すぐ支払う" : "Pay your bill now")
                }
                .padding(18)
                .background(
                    LinearGradient(colors: [Color.csqTelcoTeal, Color(hex: "#0B7FB8")],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                .shadow(color: Color.csqTelcoTeal.opacity(0.3), radius: 10, x: 0, y: 5)

                // AutoPay promo
                NavigationLink(destination: TelcoSupportArticleDestination(id: "autopay_setup", depth: 2, source: "bills_autopay")) {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 18)).foregroundColor(.white)
                            .frame(width: 42, height: 42)
                            .background(Color.csqSuccess).clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(jp ? "自動支払いを設定" : "Set up AutoPay")
                                .font(AppFont.body(14)).fontWeight(.semibold).foregroundColor(.csqTextPrimary)
                            Text(jp ? "支払い忘れなし · 継続割引つき" : "Never miss a bill · loyalty credit")
                                .font(AppFont.body(11)).foregroundColor(.csqTextSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption2).foregroundColor(.csqBorder)
                    }
                    .padding(14)
                    .background(Color.csqSurface)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(AID.autopay)

                // Statements
                Text(jp ? "明細書" : "Statements")
                    .font(AppFont.display(16)).fontWeight(.bold).foregroundColor(.csqTextPrimary)

                VStack(spacing: 10) {
                    ForEach(TelcoBill.bills(for: m)) { bill in
                        billRow(bill, m: m, jp: jp)
                    }
                }

                // The ONLY hint of support on this screen — deliberately low-key.
                NavigationLink(destination: TelcoHelpCenterView(entryPoint: "bills", depth: 2)) {
                    Text(jp ? "ヘルプが必要ですか？" : "Need help with a charge?")
                        .font(AppFont.body(12)).foregroundColor(.csqTelcoTeal)
                        .frame(maxWidth: .infinity).padding(.top, 4)
                }
                .accessibilityIdentifier("bills_link_help")

                Spacer().frame(height: 24)
            }
            .padding(16)
        }
        .background(Color.csqBackground.ignoresSafeArea())
        .navigationTitle(jp ? "請求とお支払い" : "Bills & Payments")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            CSQ.trackScreenview("Telco - Bills")
            CSQ.trackEvent(BillEvent.billsViewed, properties: [
                "current_amount": current.amount,
                "status":         "\(current.status)",
                "market":         m.trackingLabel
            ])
        }
    }

    private func billRow(_ bill: TelcoBill, m: Market, jp: Bool) -> some View {
        HStack(spacing: 12) {
            NavigationLink(destination: TelcoBillDetailView(bill: bill, depth: 2)) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: AppRadius.sm)
                            .fill(bill.status.color.opacity(0.12)).frame(width: 42, height: 42)
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(bill.status.color)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(bill.period)
                            .font(AppFont.body(14)).fontWeight(.semibold).foregroundColor(.csqTextPrimary)
                        HStack(spacing: 6) {
                            Text(telcoMoney(bill.amount, m))
                                .font(AppFont.body(12)).foregroundColor(.csqTextSecondary)
                            Text("·").foregroundColor(.csqTextTertiary)
                            Text(bill.status.label(for: m))
                                .font(AppFont.body(11)).fontWeight(.semibold)
                                .foregroundColor(bill.status.color)
                        }
                    }
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(AID.billRow(bill.invoiceNo))
            .simultaneousGesture(TapGesture().onEnded {
                CSQ.trackEvent(BillEvent.billOpened, properties: [
                    "invoice_no": bill.invoiceNo, "market": m.trackingLabel
                ])
            })

            // Download button
            Button {
                downloadedInvoices.insert(bill.invoiceNo)
                CSQ.trackEvent(BillEvent.billDownloadTapped, properties: [
                    "invoice_no": bill.invoiceNo, "market": m.trackingLabel
                ])
            } label: {
                Image(systemName: downloadedInvoices.contains(bill.invoiceNo)
                      ? "checkmark.circle.fill" : "arrow.down.circle")
                    .font(.system(size: 22))
                    .foregroundColor(downloadedInvoices.contains(bill.invoiceNo) ? .csqSuccess : .csqTelcoTeal)
            }
            .accessibilityIdentifier(AID.download(bill.invoiceNo))
            .accessibilityLabel(jp ? "明細書をダウンロード" : "Download statement")
        }
        .padding(12)
        .background(Color.csqSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 1)
    }
}

// ════════════════════════════════════════════════════════════════════════════
// MARK: - 2. Bill Detail
// ════════════════════════════════════════════════════════════════════════════

struct TelcoBillDetailView: View {
    let bill: TelcoBill
    let depth: Int
    @EnvironmentObject var marketConfig: MarketConfig
    @State private var pdfState: DownloadState = .idle

    enum DownloadState { case idle, downloading, done }

    var body: some View {
        let m = marketConfig.market
        let jp = m == .tokyo

        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {

                // Summary header
                VStack(alignment: .leading, spacing: 6) {
                    Text(bill.period)
                        .font(AppFont.display(22)).fontWeight(.bold).foregroundColor(.csqTextPrimary)
                    Text(bill.invoiceNo + " · " + (jp ? "発行 " : "Issued ") + bill.issueDate)
                        .font(AppFont.body(12)).foregroundColor(.csqTextSecondary)
                    HStack(spacing: 6) {
                        Text(bill.status.label(for: m))
                            .font(AppFont.body(11)).fontWeight(.bold).foregroundColor(.white)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(bill.status.color).clipShape(Capsule())
                        Text((jp ? "支払期限 " : "Due ") + bill.dueDate)
                            .font(AppFont.body(12)).foregroundColor(.csqTextSecondary)
                    }
                    .padding(.top, 2)
                }

                // Itemised breakdown
                VStack(spacing: 0) {
                    ForEach(bill.lineItems) { item in
                        HStack {
                            Text(item.label)
                                .font(AppFont.body(13))
                                .foregroundColor(item.amount < 0 ? .csqSuccess : .csqTextPrimary)
                            Spacer()
                            Text(signedMoney(item.amount, m))
                                .font(AppFont.body(13)).fontWeight(.semibold)
                                .foregroundColor(item.amount < 0 ? .csqSuccess : .csqTextPrimary)
                        }
                        .padding(.vertical, 11)
                        if item.id != bill.lineItems.last?.id {
                            Divider()
                        }
                    }
                    Divider().padding(.vertical, 2)
                    HStack {
                        Text(jp ? "合計" : "Total")
                            .font(AppFont.body(15)).fontWeight(.bold).foregroundColor(.csqTextPrimary)
                        Spacer()
                        Text(telcoMoney(bill.amount, m))
                            .font(AppFont.display(18)).fontWeight(.black).foregroundColor(.csqTelcoTeal)
                    }
                    .padding(.top, 6)
                }
                .padding(16)
                .background(Color.csqSurface)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))

                // Download PDF
                Button {
                    guard pdfState == .idle else { return }
                    pdfState = .downloading
                    CSQ.trackEvent(BillEvent.pdfDownloaded, properties: [
                        "invoice_no": bill.invoiceNo, "market": m.trackingLabel
                    ])
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) { pdfState = .done }
                } label: {
                    HStack(spacing: 8) {
                        switch pdfState {
                        case .idle:
                            Image(systemName: "arrow.down.doc.fill")
                            Text(jp ? "PDFをダウンロード" : "Download PDF")
                        case .downloading:
                            ProgressView().tint(.csqTelcoTeal)
                            Text(jp ? "ダウンロード中…" : "Downloading…")
                        case .done:
                            Image(systemName: "checkmark.circle.fill")
                            Text(jp ? "保存しました" : "Saved to Files")
                        }
                    }
                    .font(AppFont.body(14)).fontWeight(.semibold)
                    .foregroundColor(pdfState == .done ? .csqSuccess : .csqTelcoTeal)
                    .frame(maxWidth: .infinity).padding(.vertical, 13)
                    .background((pdfState == .done ? Color.csqSuccess : Color.csqTelcoTeal).opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                }
                .accessibilityIdentifier("bill_detail_btn_download_pdf")
                .accessibilityLabel(jp ? "PDF明細をダウンロード" : "Download bill PDF")

                // Pay this bill (only for unpaid)
                if bill.status != .paid {
                    NavigationLink(destination: TelcoBillPaymentView(bill: bill, depth: depth + 1)) {
                        TelcoCTALabel(text: jp ? "この請求書を支払う" : "Pay This Bill")
                    }
                    .accessibilityIdentifier("bill_detail_btn_pay")
                }

                Spacer().frame(height: 16)
            }
            .padding(16)
        }
        .background(Color.csqBackground.ignoresSafeArea())
        .navigationTitle(jp ? "請求書の詳細" : "Bill Detail")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            CSQ.trackScreenview("Telco - Bill Detail")
            CSQ.trackEvent(BillEvent.billDetailViewed, properties: [
                "invoice_no": bill.invoiceNo, "amount": bill.amount, "market": m.trackingLabel
            ])
        }
    }
}

// ════════════════════════════════════════════════════════════════════════════
// MARK: - 3. Bill Payment (the failure)
// ════════════════════════════════════════════════════════════════════════════

struct TelcoBillPaymentView: View {
    let bill: TelcoBill
    let depth: Int
    @EnvironmentObject var marketConfig: MarketConfig

    @State private var method: PayMethod = .card
    @State private var phase: PayPhase = .ready
    @State private var attempts = 0

    enum PayMethod: String { case card, wallet }
    enum PayPhase { case ready, processing, failed }

    private let errorCode = "CSQ-4012"

    private func walletName(_ m: Market) -> String {
        switch m { case .tokyo: return "PayPay"; case .sydney: return "PayID"; default: return "PayNow" }
    }

    var body: some View {
        let m = marketConfig.market
        let jp = m == .tokyo

        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {

                // Amount
                VStack(spacing: 4) {
                    Text(jp ? "お支払い金額" : "You're paying")
                        .font(AppFont.body(13)).foregroundColor(.csqTextSecondary)
                    Text(telcoMoney(bill.amount, m))
                        .font(.system(size: 38, weight: .black, design: .rounded))
                        .foregroundColor(.csqTextPrimary)
                    Text(bill.period + " · " + bill.invoiceNo)
                        .font(AppFont.body(12)).foregroundColor(.csqTextTertiary)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 8)

                // Payment method
                Text(jp ? "お支払い方法" : "Payment method")
                    .font(AppFont.body(14)).fontWeight(.bold).foregroundColor(.csqTextPrimary)

                payMethodRow(.card, icon: "creditcard.fill",
                             title: "Visa •••• 4242",
                             sub: jp ? "既定のカード" : "Default card", m: m)
                payMethodRow(.wallet, icon: "wallet.pass.fill",
                             title: walletName(m),
                             sub: jp ? "ウォレット残高" : "Wallet balance", m: m)

                // Failure banner
                if phase == .failed {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 10) {
                            Image(systemName: "xmark.octagon.fill").foregroundColor(.csqError)
                            Text(jp ? "お支払いに失敗しました" : "Payment Failed")
                                .font(AppFont.body(15)).fontWeight(.bold).foregroundColor(.csqTextPrimary)
                            Spacer()
                        }
                        Text(jp
                             ? "ご利用の銀行がこの取引を拒否しました（エラー \(errorCode)）。しばらくしてからもう一度お試しください。"
                             : "Your bank declined this transaction (error \(errorCode)). Please wait a moment and try again.")
                            .font(AppFont.body(12)).foregroundColor(.csqTextSecondary)
                        if attempts >= 2 {
                            Text(jp ? "試行回数: \(attempts)回" : "Attempt \(attempts) of this session")
                                .font(AppFont.body(11)).foregroundColor(.csqError)
                        }
                    }
                    .padding(14).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.csqError.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                    .transition(.opacity)
                }

                // Primary action
                Button {
                    guard phase != .processing else { return }
                    attempts += 1
                    let wasRetry = phase == .failed
                    withAnimation { phase = .processing }
                    CSQ.trackEvent(wasRetry ? BillEvent.paymentRetried : BillEvent.paymentStarted, properties: [
                        "invoice_no": bill.invoiceNo, "amount": bill.amount,
                        "method": method.rawValue, "attempt": attempts, "market": m.trackingLabel
                    ])
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                        withAnimation { phase = .failed }
                        CSQ.trackEvent(BillEvent.paymentFailed, properties: [
                            "invoice_no": bill.invoiceNo, "amount": bill.amount,
                            "method": method.rawValue, "attempt": attempts,
                            "error_code": errorCode, "market": m.trackingLabel
                        ])
                        // Repeated failed retries = rage-retry frustration signal.
                        if attempts >= 3 {
                            FrustrationSignal.paymentRageRetry(
                                invoiceNo: bill.invoiceNo, tapCount: attempts,
                                amount: bill.amount, method: method.rawValue, market: m)
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        if phase == .processing {
                            ProgressView().tint(.white)
                            Text(jp ? "処理中…" : "Processing…")
                        } else {
                            Text(phase == .failed
                                 ? (jp ? "もう一度試す" : "Try Again")
                                 : (jp ? "今すぐ支払う " : "Pay ") + telcoMoney(bill.amount, m))
                        }
                    }
                    .font(AppFont.body(16)).fontWeight(.bold).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(phase == .failed ? Color.csqWarning : Color.csqTelcoTeal)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                }
                .accessibilityIdentifier("payment_btn_pay")
                .accessibilityLabel(jp ? "支払う" : "Pay bill")

                // Help pivot — gets more prominent the more they fail (into the maze)
                if phase == .failed {
                    NavigationLink(destination: TelcoHelpCenterView(entryPoint: "payment_failed", depth: depth + 1)) {
                        HStack(spacing: 8) {
                            Image(systemName: "questionmark.circle.fill")
                            Text(jp ? "支払いができないのはなぜ？ヘルプを見る" : "Why won't my payment go through? Get help")
                        }
                        .font(AppFont.body(14)).fontWeight(attempts >= 2 ? .bold : .semibold)
                        .foregroundColor(.csqTelcoTeal)
                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(attempts >= 2 ? Color.csqTelcoTeal.opacity(0.1) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                    }
                    .accessibilityIdentifier("payment_btn_get_help")
                    .simultaneousGesture(TapGesture().onEnded {
                        CSQ.trackEvent(BillEvent.paymentHelpTapped, properties: [
                            "invoice_no": bill.invoiceNo, "attempt": attempts, "market": m.trackingLabel
                        ])
                    })
                }

                Spacer().frame(height: 16)
            }
            .padding(16)
        }
        .background(Color.csqBackground.ignoresSafeArea())
        .navigationTitle(jp ? "お支払い" : "Pay Bill")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { CSQ.trackScreenview("Telco - Bill Payment") }
    }

    private func payMethodRow(_ value: PayMethod, icon: String, title: String, sub: String, m: Market) -> some View {
        Button { method = value } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18)).foregroundColor(.csqTelcoTeal)
                    .frame(width: 40, height: 40)
                    .background(Color.csqTelcoTeal.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(AppFont.body(14)).fontWeight(.semibold).foregroundColor(.csqTextPrimary)
                    Text(sub).font(AppFont.body(11)).foregroundColor(.csqTextSecondary)
                }
                Spacer()
                Image(systemName: method == value ? "largecircle.fill.circle" : "circle")
                    .foregroundColor(method == value ? .csqTelcoTeal : .csqTextTertiary)
            }
            .padding(14)
            .background(Color.csqSurface)
            .overlay(RoundedRectangle(cornerRadius: AppRadius.md)
                .stroke(method == value ? Color.csqTelcoTeal : Color.csqBorder, lineWidth: 1.5))
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        }
        .accessibilityIdentifier("payment_method_\(value.rawValue)")
    }
}

// ════════════════════════════════════════════════════════════════════════════
// MARK: - 4. Help Center (the deflection hub)
// ════════════════════════════════════════════════════════════════════════════

struct TelcoHelpCenterView: View {
    let entryPoint: String
    let depth: Int
    @EnvironmentObject var marketConfig: MarketConfig
    @State private var query = ""

    var body: some View {
        let m = marketConfig.market
        let jp = m == .tokyo
        let articles = TelcoSupportArticle.articles(for: m)

        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {

                // Hero + search
                VStack(alignment: .leading, spacing: 12) {
                    Text(jp ? "どうされましたか？" : "How can we help?")
                        .font(AppFont.display(22)).fontWeight(.bold).foregroundColor(.csqTextPrimary)
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass").foregroundColor(.csqTextTertiary)
                        TextField(jp ? "ヘルプ記事を検索" : "Search help articles", text: $query)
                            .font(AppFont.body(14))
                            .csqMaskContents(true)
                            .onSubmit {
                                CSQ.trackEvent(BillEvent.helpSearch, properties: [
                                    "query_length": query.count, "entry_point": entryPoint, "market": m.trackingLabel
                                ])
                            }
                    }
                    .padding(.horizontal, 14).padding(.vertical, 12)
                    .background(Color.csqSurface)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.full))
                    .accessibilityIdentifier("help_input_search")
                }

                // Contextual "popular right now" — all deflection, given they failed a payment
                VStack(alignment: .leading, spacing: 10) {
                    Text(jp ? "よくある質問" : "Popular right now")
                        .font(AppFont.body(14)).fontWeight(.bold).foregroundColor(.csqTextPrimary)
                    ForEach(articles.prefix(3)) { article in
                        articleLink(article, m: m, source: "help_popular")
                    }
                }

                // Categories
                VStack(alignment: .leading, spacing: 10) {
                    Text(jp ? "カテゴリー" : "Browse topics")
                        .font(AppFont.body(14)).fontWeight(.bold).foregroundColor(.csqTextPrimary)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
                        ForEach(TelcoSupportCategory.categories(for: m)) { cat in
                            NavigationLink(destination: TelcoHelpCenterView(entryPoint: "category_\(cat.id)", depth: depth + 1)) {
                                categoryTile(cat, jp: jp)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("help_category_\(cat.id)")
                            .simultaneousGesture(TapGesture().onEnded {
                                CSQ.trackEvent(BillEvent.helpCategoryTapped, properties: [
                                    "category": cat.id, "market": m.trackingLabel
                                ])
                            })
                        }
                    }
                }

                // Buried, low-key contact entry
                NavigationLink(destination: TelcoContactSupportView(depth: depth + 1)) {
                    Text(jp ? "解決しませんか？" : "Didn't find your answer?")
                        .font(AppFont.body(12)).foregroundColor(.csqTextSecondary)
                        .underline()
                        .frame(maxWidth: .infinity).padding(.top, 4)
                }
                .accessibilityIdentifier("help_link_contact")

                Spacer().frame(height: 24)
            }
            .padding(16)
        }
        .background(Color.csqBackground.ignoresSafeArea())
        .navigationTitle(jp ? "ヘルプセンター" : "Help Center")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            CSQ.trackScreenview("Telco - Help Center")
            CSQ.trackEvent(BillEvent.helpCenterViewed, properties: [
                "entry_point": entryPoint, "depth": depth, "market": m.trackingLabel
            ])
        }
    }

    private func articleLink(_ article: TelcoSupportArticle, m: Market, source: String) -> some View {
        NavigationLink(destination: TelcoSupportArticleView(article: article, depth: depth + 1, source: source)) {
            HStack(spacing: 12) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 16)).foregroundColor(.csqTelcoTeal)
                    .frame(width: 36, height: 36)
                    .background(Color.csqTelcoTeal.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
                VStack(alignment: .leading, spacing: 2) {
                    Text(article.title)
                        .font(AppFont.body(13)).fontWeight(.semibold).foregroundColor(.csqTextPrimary)
                        .lineLimit(1)
                    Text(article.snippet)
                        .font(AppFont.body(11)).foregroundColor(.csqTextSecondary).lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption2).foregroundColor(.csqBorder)
            }
            .padding(12)
            .background(Color.csqSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("help_article_\(article.id)")
        .simultaneousGesture(TapGesture().onEnded {
            CSQ.trackEvent(BillEvent.helpArticleTapped, properties: [
                "article_id": article.id, "category": article.category,
                "source": source, "market": m.trackingLabel
            ])
        })
    }

    private func categoryTile(_ cat: TelcoSupportCategory, jp: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: cat.icon)
                .font(.system(size: 18)).foregroundColor(.csqTelcoTeal)
            Text(cat.title)
                .font(AppFont.body(13)).fontWeight(.semibold).foregroundColor(.csqTextPrimary)
            Text("\(cat.articleCount) " + (jp ? "記事" : "articles"))
                .font(AppFont.body(11)).foregroundColor(.csqTextTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.csqSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 1)
    }
}

// Convenience wrapper so other screens can deep-link an article by id.
struct TelcoSupportArticleDestination: View {
    let id: String
    let depth: Int
    let source: String
    @EnvironmentObject var marketConfig: MarketConfig
    var body: some View {
        if let article = TelcoSupportArticle.article(id, for: marketConfig.market) {
            TelcoSupportArticleView(article: article, depth: depth, source: source)
        } else {
            TelcoHelpCenterView(entryPoint: source, depth: depth)
        }
    }
}

// ════════════════════════════════════════════════════════════════════════════
// MARK: - 5. Support Article (deflection loop + "was this helpful")
// ════════════════════════════════════════════════════════════════════════════

struct TelcoSupportArticleView: View {
    let article: TelcoSupportArticle
    let depth: Int
    let source: String
    @EnvironmentObject var marketConfig: MarketConfig

    @State private var feedback: Bool? = nil   // nil = not answered, true/false = helpful?

    var body: some View {
        let m = marketConfig.market
        let jp = m == .tokyo
        let related = article.relatedIDs.compactMap { TelcoSupportArticle.article($0, for: m) }

        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {

                Text(article.title)
                    .font(AppFont.display(20)).fontWeight(.bold).foregroundColor(.csqTextPrimary)

                ForEach(Array(article.body.enumerated()), id: \.offset) { _, para in
                    Text(para)
                        .font(AppFont.body(14)).foregroundColor(.csqTextPrimary)
                        .lineSpacing(4).fixedSize(horizontal: false, vertical: true)
                }

                Divider().padding(.vertical, 4)

                // Was this helpful?
                VStack(alignment: .leading, spacing: 10) {
                    Text(jp ? "この記事は役に立ちましたか？" : "Was this article helpful?")
                        .font(AppFont.body(14)).fontWeight(.semibold).foregroundColor(.csqTextPrimary)
                    HStack(spacing: 12) {
                        feedbackButton(helpful: true, icon: "hand.thumbsup.fill",
                                       label: jp ? "はい" : "Yes", m: m)
                        feedbackButton(helpful: false, icon: "hand.thumbsdown.fill",
                                       label: jp ? "いいえ" : "No", m: m)
                    }
                    if feedback == true {
                        Text(jp ? "ご利用ありがとうございました！" : "Glad we could help!")
                            .font(AppFont.body(12)).foregroundColor(.csqSuccess)
                    }
                }
                .padding(14)
                .background(Color.csqSurface)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))

                // When NOT helpful → deflect into MORE articles, then a buried escalation link
                if feedback == false {
                    Text(jp ? "関連する記事" : "Related articles")
                        .font(AppFont.body(14)).fontWeight(.bold).foregroundColor(.csqTextPrimary)
                        .padding(.top, 4)
                    ForEach(related) { rel in
                        NavigationLink(destination: TelcoSupportArticleView(article: rel, depth: depth + 1, source: "related_\(article.id)")) {
                            HStack(spacing: 10) {
                                Image(systemName: "arrow.turn.down.right").foregroundColor(.csqTextTertiary)
                                Text(rel.title)
                                    .font(AppFont.body(13)).fontWeight(.medium).foregroundColor(.csqTelcoTeal)
                                    .lineLimit(2)
                                Spacer()
                            }
                            .padding(12)
                            .background(Color.csqSurface)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("article_related_\(rel.id)")
                        .simultaneousGesture(TapGesture().onEnded {
                            CSQ.trackEvent(BillEvent.relatedTapped, properties: [
                                "from_article_id": article.id, "to_article_id": rel.id,
                                "depth": depth, "market": m.trackingLabel
                            ])
                        })
                    }

                    NavigationLink(destination: TelcoContactSupportView(depth: depth + 1)) {
                        Text(jp ? "まだ解決していませんか？" : "Still need help?")
                            .font(AppFont.body(13)).fontWeight(.semibold).foregroundColor(.csqTextSecondary)
                            .underline()
                            .frame(maxWidth: .infinity).padding(.vertical, 10)
                    }
                    .accessibilityIdentifier("article_link_still_need_help")
                    .simultaneousGesture(TapGesture().onEnded {
                        CSQ.trackEvent(BillEvent.stillNeedHelp, properties: [
                            "article_id": article.id, "depth": depth, "market": m.trackingLabel
                        ])
                    })
                }

                Spacer().frame(height: 24)
            }
            .padding(16)
        }
        .background(Color.csqBackground.ignoresSafeArea())
        .navigationTitle(jp ? "ヘルプ記事" : "Help Article")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            CSQ.trackScreenview("Telco - Support Article")
            CSQ.trackEvent(BillEvent.articleViewed, properties: [
                "article_id": article.id, "category": article.category,
                "depth": depth, "source": source, "market": m.trackingLabel
            ])
        }
    }

    private func feedbackButton(helpful: Bool, icon: String, label: String, m: Market) -> some View {
        Button {
            withAnimation { feedback = helpful }
            CSQ.trackEvent(BillEvent.articleFeedback, properties: [
                "article_id": article.id, "helpful": helpful,
                "depth": depth, "market": m.trackingLabel
            ])
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 12))
                Text(label).font(AppFont.body(13)).fontWeight(.semibold)
            }
            .foregroundColor(feedback == helpful ? .white : .csqTextPrimary)
            .padding(.horizontal, 18).padding(.vertical, 9)
            .background(feedback == helpful ? (helpful ? Color.csqSuccess : Color.csqError) : Color.csqBackground)
            .overlay(RoundedRectangle(cornerRadius: AppRadius.full).stroke(Color.csqBorder, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.full))
        }
        .accessibilityIdentifier("article_feedback_\(helpful ? "yes" : "no")")
    }
}

// ════════════════════════════════════════════════════════════════════════════
// MARK: - 6. Contact Support (still mostly deflection; human options buried below)
// ════════════════════════════════════════════════════════════════════════════

struct TelcoContactSupportView: View {
    let depth: Int
    @EnvironmentObject var marketConfig: MarketConfig

    var body: some View {
        let m = marketConfig.market
        let jp = m == .tokyo
        let articles = TelcoSupportArticle.articles(for: m)

        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {

                // "Before you contact us…" — one more deflection wall
                VStack(alignment: .leading, spacing: 10) {
                    Text(jp ? "お問い合わせの前に" : "Before you contact us")
                        .font(AppFont.display(18)).fontWeight(.bold).foregroundColor(.csqTextPrimary)
                    Text(jp ? "よくあるご質問の多くは、以下で解決できます。" : "Most questions are answered by these quick guides.")
                        .font(AppFont.body(13)).foregroundColor(.csqTextSecondary)
                    ForEach(articles.prefix(3)) { article in
                        NavigationLink(destination: TelcoSupportArticleView(article: article, depth: depth + 1, source: "contact_deflect")) {
                            HStack(spacing: 10) {
                                Image(systemName: "lightbulb.fill").foregroundColor(.csqWarning)
                                Text(article.title)
                                    .font(AppFont.body(13)).fontWeight(.medium).foregroundColor(.csqTextPrimary).lineLimit(1)
                                Spacer()
                                Image(systemName: "chevron.right").font(.caption2).foregroundColor(.csqBorder)
                            }
                            .padding(12).background(Color.csqSurface)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("contact_deflect_\(article.id)")
                        .simultaneousGesture(TapGesture().onEnded {
                            CSQ.trackEvent(BillEvent.contactDeflected, properties: [
                                "channel": "article", "depth": depth, "market": m.trackingLabel
                            ])
                        })
                    }
                }

                // Self-service channels (the bot is pushed first; humans last)
                Text(jp ? "サポートチャンネル" : "Support channels")
                    .font(AppFont.body(14)).fontWeight(.bold).foregroundColor(.csqTextPrimary)
                    .padding(.top, 4)

                // Chatbot — recommended/"fastest"
                NavigationLink(destination: TelcoSupportBotView(depth: depth + 1)) {
                    channelCard(icon: "sparkles", iconBg: Color.csqTelcoTeal,
                                title: jp ? "CSQアシスタントに聞く" : "Ask CSQ Assistant",
                                sub: jp ? "AIが即時に回答 · 24時間対応" : "Instant AI answers · available 24/7",
                                badge: jp ? "最速" : "FASTEST", jp: jp)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("contact_btn_bot")
                .simultaneousGesture(TapGesture().onEnded {
                    CSQ.trackEvent(BillEvent.contactDeflected, properties: [
                        "channel": "bot", "depth": depth, "market": m.trackingLabel
                    ])
                })

                // Community forum — yet another deflection
                NavigationLink(destination: TelcoSupportArticleDestination(id: "understanding_charges", depth: depth + 1, source: "forum")) {
                    channelCard(icon: "person.3.fill", iconBg: Color.csqExpressPurple,
                                title: jp ? "コミュニティフォーラム" : "Community Forum",
                                sub: jp ? "他のお客様の解決事例を見る" : "See how other customers solved it",
                                badge: nil, jp: jp)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("contact_btn_forum")
                .simultaneousGesture(TapGesture().onEnded {
                    CSQ.trackEvent(BillEvent.contactDeflected, properties: [
                        "channel": "forum", "depth": depth, "market": m.trackingLabel
                    ])
                })

                // Divider with the "talk to a person" reveal, set apart and below the fold
                HStack {
                    VStack { Divider() }
                    Text(jp ? "それでも解決しない場合" : "Still stuck?")
                        .font(AppFont.body(11)).foregroundColor(.csqTextTertiary)
                    VStack { Divider() }
                }
                .padding(.top, 8)

                // Live chat with a human — buried near the bottom
                NavigationLink(destination: TelcoLiveChatView(depth: depth + 1)) {
                    channelCard(icon: "message.fill", iconBg: Color(hex: "#2563EB"),
                                title: jp ? "担当者とチャット" : "Chat with an agent",
                                sub: jp ? "現在の待ち時間: 約12分" : "Current wait: ~12 min",
                                badge: nil, jp: jp)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("contact_btn_live_chat")

                // Phone — the most buried of all
                NavigationLink(destination: TelcoCallUsView(depth: depth + 1)) {
                    channelCard(icon: "phone.fill", iconBg: Color.csqTextSecondary,
                                title: jp ? "電話で問い合わせる" : "Call us",
                                sub: jp ? "営業時間内のみ · 待ち時間長め" : "Business hours only · long wait times",
                                badge: nil, jp: jp)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("contact_btn_call")

                Spacer().frame(height: 24)
            }
            .padding(16)
        }
        .background(Color.csqBackground.ignoresSafeArea())
        .navigationTitle(jp ? "お問い合わせ" : "Contact Support")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            CSQ.trackScreenview("Telco - Contact Support")
            CSQ.trackEvent(BillEvent.contactViewed, properties: [
                "depth": depth, "market": m.trackingLabel
            ])
        }
    }

    private func channelCard(icon: String, iconBg: Color, title: String, sub: String, badge: String?, jp: Bool) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18)).foregroundColor(.white)
                .frame(width: 46, height: 46).background(iconBg)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(title).font(AppFont.body(14)).fontWeight(.semibold).foregroundColor(.csqTextPrimary)
                    if let badge = badge {
                        Text(badge).font(.system(size: 8, weight: .black)).foregroundColor(.white)
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(Color.csqSuccess).clipShape(Capsule())
                    }
                }
                Text(sub).font(AppFont.body(11)).foregroundColor(.csqTextSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption2).foregroundColor(.csqBorder)
        }
        .padding(14)
        .background(Color.csqSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 1)
    }
}

// ════════════════════════════════════════════════════════════════════════════
// MARK: - 7. Support Bot (the loop trap — deflects before escalating)
// ════════════════════════════════════════════════════════════════════════════

struct TelcoSupportBotView: View {
    let depth: Int
    @EnvironmentObject var marketConfig: MarketConfig

    @State private var messages: [SupportMsg] = []
    @State private var input = ""
    @State private var userTurns = 0
    @State private var escalationOffered = false
    @FocusState private var focused: Bool

    var body: some View {
        let m = marketConfig.market
        let jp = m == .tokyo

        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 12) {
                        SupportChatBubble(
                            text: jp
                            ? "こんにちは、CSQアシスタントです。ご用件を教えてください。よくあるご質問にすぐお答えできます。"
                            : "Hi, I'm CSQ Assistant. Tell me what's going on — I can answer most questions instantly.",
                            isUser: false)

                        if messages.isEmpty {
                            quickChips(jp: jp, m: m)
                        }

                        ForEach(messages) { msg in
                            SupportChatBubble(text: msg.text, isUser: msg.isUser)
                                .id(msg.id)
                        }

                        if escalationOffered {
                            NavigationLink(destination: TelcoLiveChatView(depth: depth + 1)) {
                                HStack(spacing: 8) {
                                    Image(systemName: "person.fill.badge.plus")
                                    Text(jp ? "担当者におつなぎする" : "Connect me to a human agent")
                                }
                                .font(AppFont.body(14)).fontWeight(.bold).foregroundColor(.white)
                                .frame(maxWidth: .infinity).padding(.vertical, 13)
                                .background(Color(hex: "#2563EB"))
                                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                            }
                            .accessibilityIdentifier("bot_btn_escalate")
                            .simultaneousGesture(TapGesture().onEnded {
                                CSQ.trackEvent(BillEvent.botEscalated, properties: ["market": m.trackingLabel])
                            })
                            .transition(.opacity)
                        }
                        Color.clear.frame(height: 4).id("bottom")
                    }
                    .padding(16)
                }
                .onChange(of: messages.count) { _, _ in withAnimation { proxy.scrollTo("bottom") } }
                .onChange(of: escalationOffered) { _, _ in withAnimation { proxy.scrollTo("bottom") } }
            }

            Divider()

            HStack(spacing: 10) {
                TextField(jp ? "メッセージを入力…" : "Type a message…", text: $input, axis: .vertical)
                    .font(AppFont.body(14)).lineLimit(3)
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(Color.csqBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .focused($focused)
                    .csqMaskContents(true)
                Button { send(input, jp: jp, m: m) } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(input.trimmingCharacters(in: .whitespaces).isEmpty ? .csqTextTertiary : .csqTelcoTeal)
                }
                .disabled(input.trimmingCharacters(in: .whitespaces).isEmpty)
                .accessibilityIdentifier("bot_btn_send")
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(Color.csqSurface)
        }
        .background(Color.csqBackground.ignoresSafeArea())
        .navigationTitle(jp ? "CSQアシスタント" : "CSQ Assistant")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            CSQ.trackScreenview("Telco - Support Bot")
            CSQ.trackEvent(BillEvent.botOpened, properties: ["depth": depth, "market": m.trackingLabel])
        }
    }

    private func quickChips(jp: Bool, m: Market) -> some View {
        let chips = jp
            ? ["支払いが失敗する", "請求内容について", "担当者と話したい"]
            : ["My payment keeps failing", "Question about my bill", "I want to talk to a person"]
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(chips, id: \.self) { chip in
                    Button { send(chip, jp: jp, m: m) } label: {
                        Text(chip)
                            .font(AppFont.body(12)).fontWeight(.medium).foregroundColor(.csqTelcoTeal)
                            .padding(.horizontal, 12).padding(.vertical, 7)
                            .background(Color.csqTelcoTeal.opacity(0.1))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.csqTelcoTeal.opacity(0.3), lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .accessibilityIdentifier("bot_chip_\(chip.prefix(6))")
                }
            }
        }
    }

    private func send(_ text: String, jp: Bool, m: Market) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        withAnimation { messages.append(SupportMsg(text: trimmed, isUser: true)) }
        input = ""
        userTurns += 1
        focused = false

        let wantsHuman = ["human", "person", "agent", "担当", "人間", "話"].contains { trimmed.lowercased().contains($0) }
        CSQ.trackEvent(BillEvent.botMessageSent, properties: [
            "message_index": userTurns, "wants_human": wantsHuman, "market": m.trackingLabel
        ])

        // Bot deflects for the first couple of turns, then finally offers a human.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let reply: String
            let shouldEscalate = wantsHuman || userTurns >= 2
            if shouldEscalate {
                reply = jp
                    ? "承知しました。担当者におつなぎします。少々お待ちください。"
                    : "Understood — let me connect you to a support agent. One moment."
                if !escalationOffered {
                    CSQ.trackEvent(BillEvent.botEscalationReq, properties: [
                        "attempts_before_escalation": userTurns, "market": m.trackingLabel
                    ])
                }
                withAnimation { escalationOffered = true }
            } else {
                reply = jp
                    ? "こちらのヘルプ記事で解決できるかもしれません。「お支払いが拒否されたのはなぜですか？」をご確認ください。解決しましたか？"
                    : "This help article usually solves it: 'Why was my payment declined?'. Did that resolve your issue?"
                CSQ.trackEvent(BillEvent.contactDeflected, properties: [
                    "channel": "bot_article", "depth": depth, "market": m.trackingLabel
                ])
            }
            withAnimation { messages.append(SupportMsg(text: reply, isUser: false)) }
        }
    }
}

private struct SupportMsg: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

private struct SupportChatBubble: View {
    let text: String
    let isUser: Bool
    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 40) }
            Text(text)
                .font(AppFont.body(13))
                .foregroundColor(isUser ? .white : .csqTextPrimary)
                .padding(.horizontal, 13).padding(.vertical, 9)
                .background(isUser ? Color.csqTelcoTeal : Color.csqSurface)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: .black.opacity(0.04), radius: 2, x: 0, y: 1)
            if !isUser { Spacer(minLength: 40) }
        }
    }
}

// ════════════════════════════════════════════════════════════════════════════
// MARK: - 8. Live Chat (the payoff — a real human, finally)
// ════════════════════════════════════════════════════════════════════════════

struct TelcoLiveChatView: View {
    let depth: Int
    @EnvironmentObject var marketConfig: MarketConfig

    @State private var connected = false
    @State private var queuePos = 14
    @State private var messages: [SupportMsg] = []
    @State private var input = ""
    @State private var userTurns = 0
    @FocusState private var focused: Bool

    private func agentName(_ m: Market) -> String {
        switch m { case .tokyo: return "ユウキ"; case .sydney: return "Chloe"; default: return "Priya" }
    }

    var body: some View {
        let m = marketConfig.market
        let jp = m == .tokyo

        VStack(spacing: 0) {
            // Status banner
            HStack(spacing: 10) {
                Circle().fill(connected ? Color.csqSuccess : Color.csqWarning).frame(width: 9, height: 9)
                Text(connected
                     ? (jp ? "\(agentName(m)) が対応中" : "\(agentName(m)) · CSQMobile Support")
                     : (jp ? "順番待ち #\(queuePos) · 約12分" : "In queue · position #\(queuePos) · ~12 min"))
                    .font(AppFont.body(12)).fontWeight(.semibold).foregroundColor(.csqTextPrimary)
                Spacer()
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(Color.csqSurface)

            Divider()

            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 12) {
                        if !connected {
                            VStack(spacing: 8) {
                                ProgressView().tint(.csqTelcoTeal)
                                Text(jp ? "担当者におつなぎしています…" : "Connecting you to an agent…")
                                    .font(AppFont.body(12)).foregroundColor(.csqTextSecondary)
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 30)
                        } else {
                            SupportChatBubble(
                                text: jp
                                ? "お待たせしました、\(agentName(m))と申します。お支払いの件、確認いたします。請求書番号を教えていただけますか？"
                                : "Hi, you're through to \(agentName(m)) from CSQMobile. I can see your payment failed — let me sort this out. Can you confirm your invoice number?",
                                isUser: false)
                            ForEach(messages) { msg in
                                SupportChatBubble(text: msg.text, isUser: msg.isUser).id(msg.id)
                            }
                        }
                        Color.clear.frame(height: 4).id("bottom")
                    }
                    .padding(16)
                }
                .onChange(of: messages.count) { _, _ in withAnimation { proxy.scrollTo("bottom") } }
                .onChange(of: connected) { _, _ in withAnimation { proxy.scrollTo("bottom") } }
            }

            Divider()

            HStack(spacing: 10) {
                TextField(jp ? "メッセージを入力…" : "Type a message…", text: $input, axis: .vertical)
                    .font(AppFont.body(14)).lineLimit(3)
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(Color.csqBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .focused($focused)
                    .csqMaskContents(true)
                    .disabled(!connected)
                Button { send(input, jp: jp, m: m) } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor((connected && !input.trimmingCharacters(in: .whitespaces).isEmpty) ? Color(hex: "#2563EB") : .csqTextTertiary)
                }
                .disabled(!connected || input.trimmingCharacters(in: .whitespaces).isEmpty)
                .accessibilityIdentifier("livechat_btn_send")
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(Color.csqSurface)
        }
        .background(Color.csqBackground.ignoresSafeArea())
        .navigationTitle(jp ? "ライブチャット" : "Live Chat")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            CSQ.trackScreenview("Telco - Live Chat")
            CSQ.trackEvent(BillEvent.liveChatQueued, properties: [
                "queue_position": queuePos, "est_wait_min": 12, "depth": depth, "market": m.trackingLabel
            ])
            // Simulate the queue clearing and a human picking up.
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
                withAnimation { connected = true }
                CSQ.trackEvent(BillEvent.liveChatConnected, properties: [
                    "agent_name": agentName(m), "wait_sec": 144, "depth": depth, "market": m.trackingLabel
                ])
            }
        }
    }

    private func send(_ text: String, jp: Bool, m: Market) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        withAnimation { messages.append(SupportMsg(text: trimmed, isUser: true)) }
        input = ""
        userTurns += 1
        focused = false
        CSQ.trackEvent(BillEvent.liveChatMessage, properties: [
            "message_index": userTurns, "market": m.trackingLabel
        ])
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            let reply = jp
                ? "ありがとうございます。確認したところ、銀行側の一時的な拒否でした。こちらで再請求の手配をいたしますので、ご安心ください。"
                : "Thanks! I can see the charge was blocked by your bank, not us. I've flagged your account and we'll re-attempt the charge for you — no action needed on your side."
            withAnimation { messages.append(SupportMsg(text: reply, isUser: false)) }
        }
    }
}

// ════════════════════════════════════════════════════════════════════════════
// MARK: - 9. Call Us (phone numbers, the most buried channel)
// ════════════════════════════════════════════════════════════════════════════

struct TelcoCallUsView: View {
    let depth: Int
    @EnvironmentObject var marketConfig: MarketConfig

    // (line key, label, number, hours, wait) — regional.
    private func lines(_ m: Market, jp: Bool) -> [(String, String, String, String, String)] {
        switch m {
        case .tokyo:
            return [
                ("general", "総合窓口", "0120-555-010", "平日 9:00–18:00", "待ち時間 約47分"),
                ("billing", "請求・お支払い窓口", "0120-555-024", "平日 9:00–17:00", "待ち時間 約32分"),
                ("premium", "プレミアム会員専用", "0570-555-099", "年中無休 24時間", "通話料 ¥220/分"),
            ]
        case .sydney:
            return [
                ("general", "General enquiries", "13 79 37", "Mon–Fri 8am–8pm AEST", "~47 min wait"),
                ("billing", "Billing & payments", "1800 555 024", "Mon–Fri 9am–6pm AEST", "~32 min wait"),
                ("premium", "Priority line (Plus members)", "1300 555 099", "24/7", "A$1.10/min"),
            ]
        default:
            return [
                ("general", "General enquiries", "1800 555 010", "Mon–Fri 9am–9pm SGT", "~47 min wait"),
                ("billing", "Billing & payments", "1800 555 024", "Mon–Fri 9am–6pm SGT", "~32 min wait"),
                ("premium", "Priority line (Plus members)", "+65 6555 0099", "24/7", "Premium charges apply"),
            ]
        }
    }

    var body: some View {
        let m = marketConfig.market
        let jp = m == .tokyo

        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {

                // Discouraging banner — wait times up front
                HStack(spacing: 12) {
                    Image(systemName: "clock.badge.exclamationmark.fill")
                        .font(.system(size: 20)).foregroundColor(.csqWarning)
                    Text(jp
                         ? "現在、電話が大変混み合っています。チャットの方が早く解決できます。"
                         : "Phone lines are busier than usual. Live chat is usually faster.")
                        .font(AppFont.body(12)).foregroundColor(.csqTextPrimary)
                }
                .padding(14).frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.csqWarning.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))

                ForEach(lines(m, jp: jp), id: \.0) { line in
                    Button {
                        CSQ.trackEvent(BillEvent.callNumberTapped, properties: [
                            "line": line.0, "depth": depth, "market": m.trackingLabel
                        ])
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "phone.fill")
                                .font(.system(size: 16)).foregroundColor(.white)
                                .frame(width: 44, height: 44).background(Color.csqTelcoTeal)
                                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                            VStack(alignment: .leading, spacing: 3) {
                                Text(line.1).font(AppFont.body(14)).fontWeight(.semibold).foregroundColor(.csqTextPrimary)
                                Text(line.2).font(AppFont.body(15)).fontWeight(.bold).foregroundColor(.csqTelcoTeal)
                                HStack(spacing: 8) {
                                    Text(line.3).font(AppFont.body(10)).foregroundColor(.csqTextTertiary)
                                    Text("·").foregroundColor(.csqTextTertiary)
                                    Text(line.4).font(AppFont.body(10)).foregroundColor(.csqWarning)
                                }
                            }
                            Spacer()
                        }
                        .padding(14).background(Color.csqSurface)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 1)
                    }
                    .accessibilityIdentifier("callus_btn_\(line.0)")
                    .accessibilityLabel(jp ? "電話をかける \(line.1)" : "Call \(line.1)")
                }

                // The explicit "give up" exit — the frustrated-abandonment signal for CS
                Button {
                    CSQ.trackEvent(BillEvent.supportAbandoned, properties: [
                        "last_screen": "Telco - Call Us", "depth": depth, "market": m.trackingLabel
                    ])
                } label: {
                    Text(jp ? "あとで対応する" : "I'll deal with this later")
                        .font(AppFont.body(13)).foregroundColor(.csqTextSecondary).underline()
                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                }
                .accessibilityIdentifier("callus_btn_give_up")

                Spacer().frame(height: 16)
            }
            .padding(16)
        }
        .background(Color.csqBackground.ignoresSafeArea())
        .navigationTitle(jp ? "電話でのお問い合わせ" : "Call Us")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            CSQ.trackScreenview("Telco - Call Us")
            CSQ.trackEvent(BillEvent.callUsViewed, properties: [
                "depth": depth, "market": m.trackingLabel
            ])
        }
    }
}
