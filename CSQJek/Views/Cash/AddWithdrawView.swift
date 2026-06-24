import SwiftUI
import ContentsquareSDK

// MARK: - AddWithdrawView

struct AddWithdrawView: View {
    @ObservedObject var wallet  : CashWalletStore
    let mode                    : Mode
    let onSuccess               : (Double, String) -> Void

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var marketConfig: MarketConfig

    enum Mode { case add, withdraw }

    @State private var selectedAccount = LinkedAccount.mockAccounts[0]
    @State private var customAmount    = ""
    @State private var selectedPreset  : String? = nil
    @State private var showConfirm     = false
    @State private var processing      = false

    private var linkedAccounts: [LinkedAccount] {
        LinkedAccount.mockAccounts(for: marketConfig.market)
    }

    private var presets: [String] {
        marketConfig.market == .tokyo
            ? ["3000", "5000", "10000", "30000", "50000"]
            : ["50", "100", "200", "500", "1000"]
    }

    private var effectiveAmount: Double {
        Double(selectedPreset ?? customAmount) ?? 0
    }

    private var amountValid: Bool { effectiveAmount > 0 }

    private var balanceAfter: Double {
        mode == .add
            ? wallet.balance + effectiveAmount
            : wallet.balance - effectiveAmount
    }

    private var insufficientFunds: Bool {
        mode == .withdraw && effectiveAmount > wallet.balance
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#F0F4F8").ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Mode header card
                        modeHeaderCard
                            .padding(.top, 4)

                        // Balance display
                        balanceCard

                        // Amount picker
                        amountSection

                        // Account selector
                        accountSection

                        // Processing info
                        processingInfoRow

                        // CTA
                        actionButton

                        Spacer(minLength: 32)
                    }
                    .padding(.horizontal, 16)
                }
            }
            .navigationTitle(mode == .add ? marketConfig.strings.cashAddFundsTitle : marketConfig.strings.cashWithdrawTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(marketConfig.strings.cashCancelButton) { dismiss() }.foregroundColor(cashAmber)
                }
            }
        }
        .sheet(isPresented: $showConfirm) {
            confirmSheet
                .environmentObject(marketConfig)
                .presentationDetents([.height(400)])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            CSQ.trackScreenview("Cash - \(mode == .add ? "Add Funds" : "Withdraw")")
            // Default to the first account for the active market so the
            // Tokyo flow shows Japanese banks rather than the SG default.
            if let first = linkedAccounts.first, !linkedAccounts.contains(where: { $0.id == selectedAccount.id }) {
                selectedAccount = first
            }
        }
    }

    // MARK: - Mode Header

    private var modeHeaderCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(modeColor.opacity(0.12))
                    .frame(width: 56, height: 56)
                Image(systemName: mode == .add ? "plus.circle.fill" : "arrow.down.circle.fill")
                    .font(.system(size: 26))
                    .foregroundColor(modeColor)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(mode == .add ? marketConfig.strings.cashAddFundsHeader : marketConfig.strings.cashWithdrawHeader)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: "#1C1C2E"))
                Text(mode == .add ? marketConfig.strings.cashInstantFromBank : marketConfig.strings.cashTransferToBank)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#9CA3AF"))
            }
            Spacer()
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
    }

    // MARK: - Balance Card

    private var balanceCard: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text(marketConfig.strings.cashWalletBalance)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.65))
                Text(marketConfig.market.formatPrice(wallet.balance))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                LinearGradient(colors: [cashDark, cashNavy],
                               startPoint: .leading, endPoint: .trailing)
            )

            if amountValid {
                Divider().frame(width: 1, height: 56).background(Color.white.opacity(0.2))
                VStack(alignment: .leading, spacing: 4) {
                    Text(mode == .add ? marketConfig.strings.cashAfterAdding : marketConfig.strings.cashAfterWithdrawal)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.65))
                    Text(marketConfig.market.formatPrice(balanceAfter))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(insufficientFunds ? Color(hex: "#FF6B6B") : cashGreen)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(
                    LinearGradient(colors: [cashNavy, Color(hex: "#0A2840")],
                                   startPoint: .leading, endPoint: .trailing)
                )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: cashDark.opacity(0.3), radius: 10, x: 0, y: 5)
    }

    // MARK: - Amount Section

    private var amountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(marketConfig.strings.cashSelectAmount)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(hex: "#6B7280"))

            // Preset grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 10) {
                ForEach(presets, id: \.self) { preset in
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedPreset = selectedPreset == preset ? nil : preset
                            if selectedPreset != nil { customAmount = "" }
                        }
                    } label: {
                        Text("\(marketConfig.strings.cashCurrencyPrefix)\(preset)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(selectedPreset == preset ? .white : cashAmber)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(selectedPreset == preset ? cashAmber : cashAmber.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }

            // Custom amount
            HStack(spacing: 0) {
                Text(marketConfig.strings.cashCurrencyPrefix)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(customAmount.isEmpty && selectedPreset == nil
                                     ? Color(hex: "#9CA3AF") : modeColor)
                    .padding(.leading, 16)
                TextField(marketConfig.strings.cashCustomAmount, text: $customAmount)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(hex: "#1C1C2E"))
                    .keyboardType(marketConfig.market == .tokyo ? .numberPad : .decimalPad)
                    .padding(14)
                    .onChange(of: customAmount) { _, _ in
                        if !customAmount.isEmpty { selectedPreset = nil }
                    }
            }
            .background(Color(hex: "#FFFBEB"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(customAmount.isEmpty && selectedPreset == nil
                            ? Color(hex: "#E5E7EB") : modeColor.opacity(0.4), lineWidth: 1)
            )

            if insufficientFunds {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(Color(hex: "#EF4444"))
                        .font(.system(size: 12))
                    Text(marketConfig.strings.cashInsufficientBalance)
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#EF4444"))
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
    }

    // MARK: - Account Section

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(mode == .add ? marketConfig.strings.cashFromAccount : marketConfig.strings.cashToAccountLabel)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(hex: "#6B7280"))

            ForEach(linkedAccounts) { account in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) { selectedAccount = account }
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(account.color.opacity(0.12))
                                .frame(width: 42, height: 42)
                            Image(systemName: account.icon)
                                .font(.system(size: 16))
                                .foregroundColor(account.color)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(account.bank)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(hex: "#1C1C2E"))
                            Text("\(account.type) •••• \(account.last4)")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "#9CA3AF"))
                        }
                        Spacer()
                        ZStack {
                            Circle()
                                .stroke(selectedAccount.id == account.id ? cashAmber : Color(hex: "#E5E7EB"), lineWidth: 2)
                                .frame(width: 20, height: 20)
                            if selectedAccount.id == account.id {
                                Circle().fill(cashAmber).frame(width: 11, height: 11)
                            }
                        }
                    }
                    .padding(14)
                    .background(selectedAccount.id == account.id
                                ? cashAmber.opacity(0.04) : Color(hex: "#F9FAFB"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedAccount.id == account.id ? cashAmber.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
    }

    // MARK: - Processing Info

    private var processingInfoRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 13))
                .foregroundColor(cashGreen)
            Text(marketConfig.strings.cashInstantProcessing)
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "#6B7280"))
            Spacer()
            Text(marketConfig.strings.cashNoFees)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(cashGreen)
        }
        .padding(14)
        .background(cashGreen.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Action Button

    private var actionButton: some View {
        Button {
            guard amountValid, !insufficientFunds else { return }
            showConfirm = true
            CSQ.trackEvent(mode == .add ? "cash_add_funds_cta_tapped" : "cash_withdraw_cta_tapped",
                           properties: [
                               "amount_sgd": String(format: "%.2f", effectiveAmount),
                               "currency": "SGD",
                               "amount_type": selectedPreset != nil ? "preset" : "custom",
                               mode == .add ? "bank_source" : "bank_destination": selectedAccount.bank
                           ])
        } label: {
            Text(mode == .add
                 ? marketConfig.strings.cashAddAmount(amountDigits(effectiveAmount))
                 : marketConfig.strings.cashWithdrawAmount(amountDigits(effectiveAmount)))
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor((!amountValid || insufficientFunds) ? Color(hex: "#9CA3AF") : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    (!amountValid || insufficientFunds)
                        ? AnyShapeStyle(Color(hex: "#E5E7EB"))
                        : AnyShapeStyle(LinearGradient(colors: [modeColor, modeColorDark],
                                                       startPoint: .leading, endPoint: .trailing))
                )
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.full))
                .shadow(color: (!amountValid || insufficientFunds) ? .clear : modeColor.opacity(0.35), radius: 8, x: 0, y: 4)
        }
        .disabled(!amountValid || insufficientFunds)
    }

    // MARK: - Confirm Sheet

    private var confirmSheet: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2).fill(Color(hex: "#E5E7EB"))
                .frame(width: 40, height: 4).padding(.top, 12).padding(.bottom, 20)

            ZStack {
                Circle().fill(modeColor.opacity(0.12)).frame(width: 72, height: 72)
                Image(systemName: mode == .add ? "plus.circle.fill" : "arrow.down.circle.fill")
                    .font(.system(size: 30)).foregroundColor(modeColor)
            }

            Text(mode == .add ? marketConfig.strings.cashConfirmTopUp : marketConfig.strings.cashConfirmWithdrawal)
                .font(.system(size: 18, weight: .bold)).foregroundColor(Color(hex: "#1C1C2E")).padding(.top, 10)
            Text(mode == .add
                 ? marketConfig.strings.cashFromAccount2("\(selectedAccount.bank) ••\(selectedAccount.last4)")
                 : marketConfig.strings.cashToAccount2("\(selectedAccount.bank) ••\(selectedAccount.last4)"))
                .font(.system(size: 13)).foregroundColor(Color(hex: "#9CA3AF")).padding(.bottom, 16)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(marketConfig.strings.cashCurrencyPrefix).font(.system(size: 20, weight: .semibold)).foregroundColor(Color(hex: "#1C1C2E"))
                Text(amountDigits(effectiveAmount))
                    .font(.system(size: 40, weight: .bold, design: .rounded)).foregroundColor(Color(hex: "#1C1C2E"))
            }
            .padding(.bottom, 20)

            HStack(spacing: 12) {
                Button {
                    showConfirm = false
                } label: {
                    Text(marketConfig.strings.cashCancelButton).font(.system(size: 15, weight: .semibold)).foregroundColor(Color(hex: "#374151"))
                        .frame(maxWidth: .infinity).padding(.vertical, 14).background(Color(hex: "#F3F4F6"))
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.full))
                }
                Button {
                    processing = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        let source = "\(selectedAccount.bank) ••\(selectedAccount.last4)"
                        if mode == .add { wallet.addFunds(amount: effectiveAmount, source: source) }
                        else            { wallet.withdraw(amount: effectiveAmount, to: source) }
                        showConfirm = false
                        dismiss()
                        onSuccess(effectiveAmount, source)
                        let balanceAfterTx = mode == .add
                            ? wallet.balance  // already updated by addFunds/withdraw
                            : wallet.balance
                        CSQ.trackEvent(mode == .add ? "cash_add_funds_confirmed" : "cash_withdraw_confirmed",
                                       properties: [
                                           "amount_sgd": String(format: "%.2f", effectiveAmount),
                                           "currency": "SGD",
                                           mode == .add ? "bank_source" : "bank_destination": selectedAccount.bank,
                                           "balance_after_sgd": String(format: "%.2f", balanceAfterTx),
                                           "amount_type": selectedPreset != nil ? "preset" : "custom"
                                       ])
                    }
                } label: {
                    Group {
                        if processing { ProgressView().progressViewStyle(.circular).tint(.white) }
                        else { Text(marketConfig.strings.cashConfirmButton).font(.system(size: 15, weight: .bold)).foregroundColor(.white) }
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(LinearGradient(colors: [modeColor, modeColorDark], startPoint: .leading, endPoint: .trailing))
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.full))
                    .shadow(color: modeColor.opacity(0.35), radius: 8, x: 0, y: 4)
                }
                .disabled(processing)
            }
            .padding(.horizontal, 24).padding(.bottom, 32)
        }
        .background(Color.white)
    }

    // MARK: - Amount formatting

    /// Digits-only amount string (no prefix), market-aware.
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

    // MARK: - Colour helpers

    private var modeColor: Color {
        mode == .add ? cashGreen : Color(hex: "#6366F1")
    }
    private var modeColorDark: Color {
        mode == .add ? Color(hex: "#059669") : Color(hex: "#4F46E5")
    }
}
