import SwiftUI
import ContentsquareSDK

// MARK: - Accessibility IDs
private enum CashAccessID {
    static let closeButton      = "cash_home_btn_close"
    static let balanceCard      = "cash_home_card_balance"
    static let actionScanQR     = "cash_home_btn_scan_qr"
    static let actionSend       = "cash_home_btn_send"
    static let actionAdd        = "cash_home_btn_add"
    static let actionWithdraw   = "cash_home_btn_withdraw"
    static let txList           = "cash_home_list_transactions"
    static func txRow(_ i: Int) -> String { "cash_home_tx_\(i)" }
}

// MARK: - CSQCashHomeView

struct CSQCashHomeView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var marketConfig: MarketConfig
    @StateObject private var wallet = CashWalletStore()

    @State private var showQRScanner     = false
    @State private var showSend          = false
    @State private var showAdd           = false
    @State private var showWithdraw      = false
    @State private var showSuccessBanner = false
    @State private var successMessage    = ""
    @State private var balanceVisible    = true
    @State private var selectedTx        : CashTransaction? = nil
    @State private var showAllTx         = false

    var body: some View {
        ZStack(alignment: .top) {
            Color(hex: "#F0F4F8").ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        balanceCard
                            .padding(.horizontal, 16)
                            .padding(.top, 20)
                        quickActions
                            .padding(.horizontal, 16)
                        recentContactsRow
                            .padding(.horizontal, 16)
                        transactionList
                            .padding(.horizontal, 16)
                            .padding(.bottom, 32)
                    }
                }
            }

            // Success banner
            if showSuccessBanner {
                successBanner
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(10)
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showQRScanner) {
            QRScannerView(wallet: wallet) { payload in
                showQRScanner = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    successMessage = marketConfig.market == .tokyo
                        ? "\(payload.merchant)に\(marketConfig.market.formatPrice(payload.amount))を支払いました"
                        : "Paid \(marketConfig.market.formatPrice(payload.amount)) to \(payload.merchant)"
                    withAnimation(.spring()) { showSuccessBanner = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation { showSuccessBanner = false }
                    }
                }
            }
            .environmentObject(marketConfig)
        }
        .sheet(isPresented: $showSend) {
            SendMoneyView(wallet: wallet) { amount, recipient in
                showSend = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    successMessage = marketConfig.market == .tokyo
                        ? "\(recipient)に\(marketConfig.market.formatPrice(amount))を送金しました"
                        : "Sent \(marketConfig.market.formatPrice(amount)) to \(recipient)"
                    withAnimation(.spring()) { showSuccessBanner = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation { showSuccessBanner = false }
                    }
                }
            }
            .environmentObject(marketConfig)
        }
        .sheet(isPresented: $showAdd) {
            AddWithdrawView(wallet: wallet, mode: .add) { amount, source in
                showAdd = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    successMessage = marketConfig.market == .tokyo
                        ? "\(source)から\(marketConfig.market.formatPrice(amount))をチャージしました"
                        : "Added \(marketConfig.market.formatPrice(amount)) from \(source)"
                    withAnimation(.spring()) { showSuccessBanner = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation { showSuccessBanner = false }
                    }
                }
            }
            .environmentObject(marketConfig)
        }
        .sheet(isPresented: $showWithdraw) {
            AddWithdrawView(wallet: wallet, mode: .withdraw) { amount, dest in
                showWithdraw = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    successMessage = marketConfig.market == .tokyo
                        ? "\(dest)に\(marketConfig.market.formatPrice(amount))を引き出しました"
                        : "Withdrew \(marketConfig.market.formatPrice(amount)) to \(dest)"
                    withAnimation(.spring()) { showSuccessBanner = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation { showSuccessBanner = false }
                    }
                }
            }
            .environmentObject(marketConfig)
        }
        .sheet(item: $selectedTx) { tx in
            TransactionDetailSheet(tx: tx)
                .presentationDetents([.height(520)])
                .presentationDragIndicator(.visible)
                .environmentObject(marketConfig)
        }
        .sheet(isPresented: $showAllTx) {
            AllTransactionsSheet(transactions: wallet.transactions)
                .environmentObject(marketConfig)
        }
        .onAppear {
            CSQ.trackScreenview("Cash - Home")
            wallet.configure(market: marketConfig.market)
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        ZStack {
            LinearGradient(
                colors: [cashDark, cashNavy],
                startPoint: .leading, endPoint: .trailing
            )
            .ignoresSafeArea(edges: .top)

            HStack {
                Button { isPresented = false } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 34, height: 34)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Circle())
                }
                .accessibilityIdentifier(CashAccessID.closeButton)

                Spacer()

                HStack(spacing: 8) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(cashAmber)
                    Text(marketConfig.market == .tokyo ? "CSQキャッシュ" : "CSQCash")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }

                Spacer()

                Button {} label: {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.85))
                        .frame(width: 34, height: 34)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .frame(height: 64)
    }

    // MARK: - Balance Card

    private var balanceCard: some View {
        ZStack {
            // Card gradient — deep navy with green tint, like GCash/PayNow premium feel
            LinearGradient(
                colors: [Color(hex: "#0A1628"), Color(hex: "#0E3D2A"), Color(hex: "#0A2840")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: 22))

            // Decorative circles
            Circle()
                .fill(cashGreen.opacity(0.08))
                .frame(width: 200, height: 200)
                .offset(x: 110, y: -60)
            Circle()
                .fill(cashAmber.opacity(0.06))
                .frame(width: 140, height: 140)
                .offset(x: -80, y: 70)

            VStack(spacing: 0) {
                // Account ID row
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.6))
                        Text(marketConfig.strings.cashAccountLabel)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    Spacer()
                    // Eye toggle
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            balanceVisible.toggle()
                        }
                    } label: {
                        Image(systemName: balanceVisible ? "eye.slash.fill" : "eye.fill")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 22)

                Spacer(minLength: 12)

                // Balance
                VStack(spacing: 6) {
                    Text(marketConfig.strings.cashAvailableBalance)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.55))
                        .tracking(1)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(marketConfig.strings.cashCurrencyPrefix)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white.opacity(0.85))
                        Text(balanceVisible
                             ? amountDigits(wallet.balance)
                             : "••••••")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .contentTransition(.numericText())
                            .animation(.spring(response: 0.4), value: wallet.balance)
                    }
                }

                Spacer(minLength: 16)

                // Stats row
                HStack(spacing: 0) {
                    statPill(icon: "arrow.down.left.circle.fill",
                             label: marketConfig.strings.cashMoneyIn,
                             value: "+\(marketConfig.strings.cashCurrencyPrefix)\(String(format: "%.0f", wallet.transactions.filter { $0.amount > 0 }.reduce(0) { $0 + $1.amount }.rounded()))",
                             color: cashGreen)
                    Divider()
                        .frame(width: 1, height: 32)
                        .background(Color.white.opacity(0.15))
                    statPill(icon: "arrow.up.right.circle.fill",
                             label: marketConfig.strings.cashMoneyOut,
                             value: "-\(marketConfig.strings.cashCurrencyPrefix)\(String(format: "%.0f", abs(wallet.transactions.filter { $0.amount < 0 }.reduce(0) { $0 + $1.amount }).rounded()))",
                             color: Color(hex: "#FF6B6B"))
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 22)
                .padding(.top, 8)
            }
        }
        .frame(height: 210)
        .shadow(color: cashDark.opacity(0.4), radius: 20, x: 0, y: 10)
        .accessibilityIdentifier(CashAccessID.balanceCard)
    }

    /// Digits-only amount string (no currency prefix), market-aware:
    /// Tokyo → grouped whole yen ("284,750"); Singapore → "284,750.00".
    private func amountDigits(_ value: Double) -> String {
        if marketConfig.market == .tokyo {
            let f = NumberFormatter()
            f.numberStyle = .decimal
            f.groupingSeparator = ","
            f.groupingSize = 3
            f.maximumFractionDigits = 0
            return f.string(from: NSNumber(value: Int(value.rounded()))) ?? "\(Int(value.rounded()))"
        }
        return value.sgdString
    }

    private func statPill(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.5))
                Text(value)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Quick Actions

    private var quickActions: some View {
        HStack(spacing: 0) {
            actionButton(icon: "qrcode.viewfinder", label: marketConfig.strings.cashScanQR,
                         gradient: [Color(hex: "#1B3FAB"), Color(hex: "#0D2B8A")],
                         id: CashAccessID.actionScanQR) {
                CSQ.trackEvent("cash_scan_qr_opened", properties: [
                    "entry_point": "home_quick_actions",
                    "wallet_balance_sgd": String(format: "%.2f", wallet.balance),
                    "currency": "SGD"
                ])
                showQRScanner = true
            }
            actionButton(icon: "arrow.up.right.circle.fill", label: marketConfig.strings.cashSendMoney,
                         gradient: [cashAmber, Color(hex: "#D97706")],
                         id: CashAccessID.actionSend) {
                CSQ.trackEvent("cash_send_money_opened", properties: [
                    "entry_point": "home_quick_actions",
                    "wallet_balance_sgd": String(format: "%.2f", wallet.balance),
                    "currency": "SGD"
                ])
                showSend = true
            }
            actionButton(icon: "plus.circle.fill", label: marketConfig.strings.cashAddFunds,
                         gradient: [cashGreen, Color(hex: "#059669")],
                         id: CashAccessID.actionAdd) {
                CSQ.trackEvent("cash_add_funds_opened", properties: [
                    "entry_point": "home_quick_actions",
                    "wallet_balance_sgd": String(format: "%.2f", wallet.balance),
                    "currency": "SGD"
                ])
                showAdd = true
            }
            actionButton(icon: "arrow.down.circle.fill", label: marketConfig.strings.cashWithdraw,
                         gradient: [Color(hex: "#6366F1"), Color(hex: "#4F46E5")],
                         id: CashAccessID.actionWithdraw) {
                CSQ.trackEvent("cash_withdraw_opened", properties: [
                    "entry_point": "home_quick_actions",
                    "wallet_balance_sgd": String(format: "%.2f", wallet.balance),
                    "currency": "SGD"
                ])
                showWithdraw = true
            }
        }
        .padding(4)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
    }

    private func actionButton(icon: String, label: String,
                               gradient: [Color], id: String,
                               action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .frame(width: 52, height: 52)
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                }
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(hex: "#374151"))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .accessibilityIdentifier(id)
    }

    // MARK: - Recent Contacts

    private var recentContactsRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(marketConfig.strings.cashRecent)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: "#1C1C2E"))
                Spacer()
                Button { showSend = true } label: {
                    Text(marketConfig.strings.cashSeeAll)
                        .font(.system(size: 13))
                        .foregroundColor(cashAmber)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    // Add new
                    Button { showSend = true } label: {
                        VStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .stroke(Color(hex: "#E5E7EB"), style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                                    .frame(width: 48, height: 48)
                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Color(hex: "#9CA3AF"))
                            }
                            Text(marketConfig.strings.cashNewContact)
                                .font(.system(size: 11))
                                .foregroundColor(Color(hex: "#9CA3AF"))
                        }
                    }

                    ForEach(wallet.contacts) { contact in
                        Button {
                            showSend = true
                            CSQ.trackEvent("cash_contact_quick_send_tapped", properties: [
                                "contact_name": contact.name,
                                "last_amount_sgd": String(format: "%.2f", contact.lastAmount),
                                "currency": "SGD",
                                "entry_point": "home_recent_contacts"
                            ])
                        } label: {
                            VStack(spacing: 6) {
                                ZStack {
                                    Circle()
                                        .fill(contact.avatarColor)
                                        .frame(width: 48, height: 48)
                                    Text(contact.initials)
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                Text(contact.name.components(separatedBy: " ").first ?? "")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color(hex: "#374151"))
                                    .lineLimit(1)
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
    }

    // MARK: - Transaction List

    private var transactionList: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(marketConfig.strings.cashTransactions)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: "#1C1C2E"))
                Spacer()
                Text(marketConfig.strings.cashThisMonth)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#9CA3AF"))
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            ForEach(Array(wallet.transactions.prefix(10).enumerated()), id: \.element.id) { idx, tx in
                Button {
                    selectedTx = tx
                    CSQ.trackEvent("cash_transaction_tapped", properties: [
                        "transaction_type": "\(tx.type)",
                        "amount_sgd": String(format: "%.2f", abs(tx.amount)),
                        "currency": "SGD",
                        "reference": tx.reference
                    ])
                } label: {
                    transactionRow(tx, index: idx)
                }
                .buttonStyle(.plain)
                if idx < min(9, wallet.transactions.count - 1) {
                    Divider()
                        .padding(.leading, 68)
                }
            }

            Spacer(minLength: 8)

            Button {
                showAllTx = true
                CSQ.trackEvent("cash_view_all_transactions_tapped")
            } label: {
                Text(marketConfig.strings.cashViewAllTx)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(cashAmber)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .padding(.horizontal, 16)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
        .accessibilityIdentifier(CashAccessID.txList)
    }

    private func transactionRow(_ tx: CashTransaction, index: Int) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(tx.iconColor.opacity(0.12))
                    .frame(width: 42, height: 42)
                Image(systemName: tx.icon)
                    .font(.system(size: 16))
                    .foregroundColor(tx.iconColor)
            }
            .padding(.leading, 16)

            VStack(alignment: .leading, spacing: 2) {
                Text(tx.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "#1C1C2E"))
                    .lineLimit(1)
                Text(tx.subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#9CA3AF"))
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(tx.amount >= 0
                     ? "+\(marketConfig.strings.cashCurrencyPrefix)\(amountDigits(tx.amount))"
                     : "-\(marketConfig.strings.cashCurrencyPrefix)\(amountDigits(abs(tx.amount)))")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(tx.amount >= 0 ? cashGreen : Color(hex: "#1C1C2E"))
                Text(tx.date.transactionLabel(for: marketConfig.market))
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "#9CA3AF"))
            }
            .padding(.trailing, 16)
        }
        .padding(.vertical, 12)
        .accessibilityIdentifier(CashAccessID.txRow(index))
    }

    // MARK: - Success Banner

    private var successBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(.white)
            Text(successMessage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            LinearGradient(colors: [cashGreen, Color(hex: "#059669")],
                           startPoint: .leading, endPoint: .trailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: cashGreen.opacity(0.4), radius: 12, x: 0, y: 6)
        .padding(.horizontal, 16)
        .padding(.top, 70)
    }
}

// MARK: - Transaction Detail Sheet

struct TransactionDetailSheet: View {
    let tx: CashTransaction
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var marketConfig: MarketConfig

    private var isTokyo: Bool { marketConfig.market == .tokyo }

    private var typeLabel: String {
        switch tx.type {
        case .qrPayment:     return marketConfig.strings.cashTxQRPayment
        case .sent:          return marketConfig.strings.cashTxSent
        case .received:      return marketConfig.strings.cashTxReceived
        case .topUp:         return marketConfig.strings.cashTxTopUp
        case .withdrawal:    return marketConfig.strings.cashTxWithdrawal
        case .international: return marketConfig.strings.cashTxInternational
        }
    }

    /// Digits-only amount string (no prefix), market-aware.
    private func detailAmountDigits(_ value: Double) -> String {
        if isTokyo {
            let f = NumberFormatter()
            f.numberStyle = .decimal
            f.groupingSeparator = ","
            f.groupingSize = 3
            f.maximumFractionDigits = 0
            return f.string(from: NSNumber(value: Int(value.rounded()))) ?? "\(Int(value.rounded()))"
        }
        return value.sgdString
    }

    var body: some View {
        VStack(spacing: 0) {
            // Handle
            RoundedRectangle(cornerRadius: 2).fill(Color(hex: "#E5E7EB"))
                .frame(width: 40, height: 4).padding(.top, 12).padding(.bottom, 22)

            // Icon + amount
            ZStack {
                Circle().fill(tx.iconColor.opacity(0.12)).frame(width: 72, height: 72)
                Image(systemName: tx.icon).font(.system(size: 28)).foregroundColor(tx.iconColor)
            }

            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(tx.amount >= 0
                     ? "+\(marketConfig.strings.cashCurrencyPrefix)"
                     : "-\(marketConfig.strings.cashCurrencyPrefix)")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(tx.amount >= 0 ? cashGreen : Color(hex: "#1C1C2E"))
                Text(detailAmountDigits(abs(tx.amount)))
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundColor(tx.amount >= 0 ? cashGreen : Color(hex: "#1C1C2E"))
            }
            .padding(.top, 10)

            Text(tx.title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(hex: "#1C1C2E"))
                .padding(.top, 4)
            Text(tx.subtitle)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#9CA3AF"))
                .padding(.top, 2)

            // Status pill
            HStack(spacing: 6) {
                Circle()
                    .fill(tx.status == .completed ? cashGreen : tx.status == .pending ? cashAmber : Color(hex: "#EF4444"))
                    .frame(width: 7, height: 7)
                Text(tx.status.displayName(for: marketConfig.market))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(tx.status == .completed ? cashGreen : tx.status == .pending ? cashAmber : Color(hex: "#EF4444"))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background((tx.status == .completed ? cashGreen : cashAmber).opacity(0.10))
            .clipShape(Capsule())
            .padding(.top, 12)

            // Detail rows
            VStack(spacing: 0) {
                detailRow(isTokyo ? "取引種別" : "Transaction Type",  typeLabel)
                Divider().padding(.leading, 16)
                detailRow(isTokyo ? "日付" : "Date",  tx.date.formatted(date: .long, time: .omitted))
                Divider().padding(.leading, 16)
                detailRow(isTokyo ? "時刻" : "Time",  tx.date.formatted(date: .omitted, time: .shortened))
                Divider().padding(.leading, 16)
                detailRow(isTokyo ? "取引番号" : "Reference",  tx.reference)
            }
            .background(Color(hex: "#F9FAFB"))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "#E5E7EB"), lineWidth: 1))
            .padding(.horizontal, 20)
            .padding(.top, 20)

            // Report issue CTA
            Button {} label: {
                Text(isTokyo ? "問題を報告" : "Report an Issue")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "#6B7280"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(hex: "#F3F4F6"))
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.full))
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 32)
        }
        .background(Color.white)
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#6B7280"))
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(hex: "#1C1C2E"))
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }
}

// MARK: - All Transactions Sheet

struct AllTransactionsSheet: View {
    let transactions: [CashTransaction]
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var marketConfig: MarketConfig
    @State private var query  = ""
    @State private var filter : TxFilter = .all
    @State private var selectedTx: CashTransaction? = nil

    enum TxFilter: CaseIterable { case all, moneyIn, moneyOut }

    private func filterLabel(_ f: TxFilter) -> String {
        switch f {
        case .all:     return marketConfig.strings.cashFilterAll
        case .moneyIn: return marketConfig.strings.cashFilterIn
        case .moneyOut: return marketConfig.strings.cashFilterOut
        }
    }

    /// Digits-only amount string (no prefix), market-aware.
    private func allTxAmountDigits(_ value: Double) -> String {
        if marketConfig.market == .tokyo {
            let f = NumberFormatter()
            f.numberStyle = .decimal
            f.groupingSeparator = ","
            f.groupingSize = 3
            f.maximumFractionDigits = 0
            return f.string(from: NSNumber(value: Int(value.rounded()))) ?? "\(Int(value.rounded()))"
        }
        return value.sgdString
    }

    private var filtered: [CashTransaction] {
        transactions.filter { tx in
            let matchesQuery = query.isEmpty ||
                tx.title.lowercased().contains(query.lowercased()) ||
                tx.subtitle.lowercased().contains(query.lowercased())
            let matchesFilter: Bool
            switch filter {
            case .all:     matchesFilter = true
            case .moneyIn: matchesFilter = tx.amount > 0
            case .moneyOut: matchesFilter = tx.amount < 0
            }
            return matchesQuery && matchesFilter
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter chips
                HStack(spacing: 8) {
                    ForEach(TxFilter.allCases, id: \.self) { f in
                        Button { withAnimation(.easeInOut(duration: 0.15)) { filter = f } } label: {
                            Text(filterLabel(f))
                                .font(.system(size: 13, weight: filter == f ? .semibold : .regular))
                                .foregroundColor(filter == f ? .white : Color(hex: "#374151"))
                                .padding(.horizontal, 18).padding(.vertical, 8)
                                .background(filter == f ? cashAmber : Color(hex: "#F3F4F6"))
                                .clipShape(Capsule())
                        }
                    }
                    Spacer()
                    Text(marketConfig.strings.cashTxCount(filtered.count))
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#9CA3AF"))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white)
                .overlay(Divider(), alignment: .bottom)

                // List
                if filtered.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(Color(hex: "#E5E7EB"))
                        Text(marketConfig.strings.cashNoTransactions)
                            .font(.system(size: 15))
                            .foregroundColor(Color(hex: "#9CA3AF"))
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(filtered) { tx in
                            Button {
                                selectedTx = tx
                                CSQ.trackEvent("cash_transaction_tapped", properties: [
                                    "transaction_type": "\(tx.type)",
                                    "amount_sgd": String(format: "%.2f", abs(tx.amount)),
                                    "currency": "SGD",
                                    "reference": tx.reference,
                                    "entry_point": "all_transactions_list"
                                ])
                            } label: {
                                allTxRow(tx)
                            }
                            .buttonStyle(.plain)
                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                            .listRowSeparatorTint(Color(hex: "#F3F4F6"))
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .background(Color(hex: "#F9FAFB"))
            .navigationTitle(marketConfig.strings.cashAllTransactionsTitle)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: marketConfig.strings.cashSearchTransactions)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(marketConfig.strings.cashDoneButton) { dismiss() }.foregroundColor(cashAmber)
                }
            }
        }
        .sheet(item: $selectedTx) { tx in
            TransactionDetailSheet(tx: tx)
                .presentationDetents([.height(520)])
                .presentationDragIndicator(.visible)
                .environmentObject(marketConfig)
        }
        .onAppear { CSQ.trackScreenview("Cash - All Transactions") }
    }

    private func allTxRow(_ tx: CashTransaction) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(tx.iconColor.opacity(0.12)).frame(width: 42, height: 42)
                Image(systemName: tx.icon).font(.system(size: 16)).foregroundColor(tx.iconColor)
            }
            .padding(.leading, 16)

            VStack(alignment: .leading, spacing: 2) {
                Text(tx.title).font(.system(size: 14, weight: .semibold)).foregroundColor(Color(hex: "#1C1C2E")).lineLimit(1)
                Text(tx.subtitle).font(.system(size: 12)).foregroundColor(Color(hex: "#9CA3AF")).lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(tx.amount >= 0
                     ? "+\(marketConfig.strings.cashCurrencyPrefix)\(allTxAmountDigits(tx.amount))"
                     : "-\(marketConfig.strings.cashCurrencyPrefix)\(allTxAmountDigits(abs(tx.amount)))")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(tx.amount >= 0 ? cashGreen : Color(hex: "#1C1C2E"))
                Text(tx.date.transactionLabel(for: marketConfig.market)).font(.system(size: 11)).foregroundColor(Color(hex: "#9CA3AF"))
            }
            .padding(.trailing, 16)
        }
        .padding(.vertical, 12)
        .background(Color.white)
    }
}
