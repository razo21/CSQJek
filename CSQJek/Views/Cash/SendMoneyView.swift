import SwiftUI
import ContentsquareSDK

// MARK: - SendMoneyView

struct SendMoneyView: View {
    @ObservedObject var wallet   : CashWalletStore
    let onSuccess                : (Double, String) -> Void

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var marketConfig: MarketConfig
    @State private var tab       : SendTab = .contacts
    @State private var showConfirm       = false
    @State private var confirmAmount     : Double  = 0
    @State private var confirmRecipient  : String  = ""
    @State private var confirmNote       : String  = ""
    @State private var isInternational   = false

    enum SendTab: String, CaseIterable {
        case contacts     = "contacts"
        case transfer     = "transfer"
        case international = "overseas"
    }

    private func tabLabel(_ t: SendTab) -> String {
        switch t {
        case .contacts:      return marketConfig.strings.cashTabContacts
        case .transfer:      return marketConfig.strings.cashTabTransfer
        case .international: return marketConfig.strings.cashTabOverseas
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#F0F4F8").ignoresSafeArea()

                VStack(spacing: 0) {
                    // Tab selector
                    HStack(spacing: 0) {
                        ForEach(SendTab.allCases, id: \.self) { t in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) { tab = t }
                            } label: {
                                VStack(spacing: 4) {
                                    Text(tabLabel(t))
                                        .font(.system(size: 13, weight: tab == t ? .semibold : .regular))
                                        .foregroundColor(tab == t ? cashAmber : Color(hex: "#6B7280"))
                                    Rectangle()
                                        .fill(tab == t ? cashAmber : Color.clear)
                                        .frame(height: 2)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                            }
                        }
                    }
                    .background(Color.white)
                    .overlay(Divider(), alignment: .bottom)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            switch tab {
                            case .contacts:      contactsTab
                            case .transfer:      transferTab
                            case .international: internationalTab
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle(marketConfig.strings.cashSendMoneyTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(marketConfig.strings.cashCancelButton) { dismiss() }
                        .foregroundColor(cashAmber)
                }
            }
        }
        .sheet(isPresented: $showConfirm) {
            SendConfirmSheet(
                amount: confirmAmount,
                recipient: confirmRecipient,
                note: confirmNote,
                walletBalance: wallet.balance,
                isInternational: isInternational
            ) { confirmed in
                showConfirm = false
                if confirmed {
                    if isInternational {
                        wallet.sendInternational(amount: confirmAmount, recipient: confirmRecipient, bank: confirmNote, currency: selectedCountry.currency)
                    } else {
                        wallet.send(amount: confirmAmount, to: confirmRecipient, note: confirmNote)
                    }
                    dismiss()
                    onSuccess(confirmAmount, confirmRecipient)
                }
            }
            .environmentObject(marketConfig)
            .presentationDetents([.height(420)])
            .presentationDragIndicator(.visible)
        }
        .onAppear { CSQ.trackScreenview("Cash - Send Money") }
    }

    // MARK: - Contacts Tab

    private var contactsTab: some View {
        VStack(spacing: 12) {
            // Balance pill
            balancePill

            ForEach(wallet.contacts) { contact in
                ContactSendRow(contact: contact) { amount, note in
                    confirmAmount    = amount
                    confirmRecipient = contact.name
                    confirmNote      = note
                    isInternational  = false
                    showConfirm      = true
                    CSQ.trackEvent("cash_send_contact_tapped", properties: [
                        "contact_name": contact.name,
                        "last_amount_sgd": String(format: "%.2f", contact.lastAmount),
                        "currency": "SGD",
                        "entry_point": "contacts_tab"
                    ])
                }
            }
        }
    }

    // MARK: - Manual Transfer Tab

    @State private var recipientType  : RecipientType = .phone
    @State private var recipientValue = ""
    @State private var transferAmount = ""
    @State private var transferNote   = ""

    enum RecipientType: String, CaseIterable {
        case phone = "phone"
        case email = "email"
        case bank  = "bank"
    }

    private func recipientLabel(_ rt: RecipientType) -> String {
        switch rt {
        case .phone: return marketConfig.strings.cashPhoneLabel
        case .email: return marketConfig.strings.cashEmailLabel
        case .bank:  return marketConfig.strings.cashBankAcctLabel
        }
    }

    private var transferTab: some View {
        VStack(spacing: 14) {
            balancePill

            // Recipient type
            VStack(alignment: .leading, spacing: 8) {
                Text(marketConfig.strings.cashSendVia)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "#6B7280"))
                HStack(spacing: 8) {
                    ForEach(RecipientType.allCases, id: \.self) { rt in
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) { recipientType = rt }
                        } label: {
                            Text(recipientLabel(rt))
                                .font(.system(size: 13, weight: recipientType == rt ? .semibold : .regular))
                                .foregroundColor(recipientType == rt ? .white : Color(hex: "#374151"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 9)
                                .background(recipientType == rt ? cashAmber : Color(hex: "#F3F4F6"))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            .cardStyle()

            // Recipient field
            VStack(alignment: .leading, spacing: 8) {
                Text(recipientType == .phone ? marketConfig.strings.cashPhoneNumber
                     : recipientType == .email ? marketConfig.strings.cashEmailAddress : marketConfig.strings.cashBankAccountNo)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "#6B7280"))

                HStack(spacing: 10) {
                    Image(systemName: recipientType == .phone ? "phone.fill"
                          : recipientType == .email ? "envelope.fill" : "building.columns.fill")
                        .font(.system(size: 14))
                        .foregroundColor(cashAmber)
                        .frame(width: 32)

                    TextField(
                        recipientType == .phone ? marketConfig.strings.cashPhonePlaceholder
                        : recipientType == .email ? (marketConfig.market == .tokyo ? "name@example.jp" : "name@email.com") : marketConfig.strings.cashBankAcctPlaceholder,
                        text: $recipientValue
                    )
                    .font(.system(size: 15))
                    .keyboardType(recipientType == .phone ? .phonePad : .emailAddress)
                    .autocapitalization(.none)
                }
                .padding(14)
                .background(Color(hex: "#F9FAFB"))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#E5E7EB"), lineWidth: 1))
            }
            .cardStyle()

            amountAndNoteFields(amount: $transferAmount, note: $transferNote)

            sendButton(
                disabled: recipientValue.isEmpty || transferAmount.isEmpty,
                label: marketConfig.strings.cashSendMoneyButton
            ) {
                let amt = Double(transferAmount) ?? 0
                guard amt > 0 else { return }
                confirmAmount    = amt
                confirmRecipient = recipientValue
                confirmNote      = transferNote
                isInternational  = false
                showConfirm      = true
                CSQ.trackEvent("cash_send_manual_initiated", properties: [
                    "recipient_type": recipientType.rawValue.lowercased(),
                    "amount_sgd": String(format: "%.2f", Double(transferAmount) ?? 0),
                    "currency": "SGD",
                    "transaction_type": "domestic_transfer"
                ])
            }
        }
    }

    // MARK: - International Tab

    @State private var selectedCountry    = SWIFTCountry.list[0]
    @State private var swiftCode          = ""
    @State private var recipientName      = ""
    @State private var bankName           = ""
    @State private var intlAccountNum     = ""
    @State private var intlAmount         = ""
    @State private var transferPurpose    = "Family Support"
    @State private var showCountryPicker  = false

    // Stable analytics keys (sent as transfer_purpose). Display label localized separately.
    private let purposes = ["Family Support", "Business Payment", "Education", "Medical", "Investment", "Personal Savings", "Other"]

    private func purposeLabel(_ key: String) -> String {
        guard marketConfig.market == .tokyo else { return key }
        switch key {
        case "Family Support":   return "家族への仕送り"
        case "Business Payment": return "ビジネス支払い"
        case "Education":        return "教育費"
        case "Medical":          return "医療費"
        case "Investment":       return "投資"
        case "Personal Savings": return "個人貯蓄"
        case "Other":            return "その他"
        default:                 return key
        }
    }

    private var intlFee: Double { 3.50 }
    private var intlRate: Double { selectedCountry.currency == "USD" ? 1.35 : selectedCountry.currency == "MYR" ? 3.32 : selectedCountry.currency == "THB" ? 37.20 : selectedCountry.currency == "IDR" ? 11_200 : selectedCountry.currency == "PHP" ? 75.40 : selectedCountry.currency == "INR" ? 62.80 : selectedCountry.currency == "GBP" ? 1.06 : selectedCountry.currency == "EUR" ? 1.23 : selectedCountry.currency == "AUD" ? 2.01 : selectedCountry.currency == "JPY" ? 201.20 : selectedCountry.currency == "HKD" ? 10.52 : selectedCountry.currency == "CNY" ? 9.76 : 1.0 }

    private var internationalTab: some View {
        VStack(spacing: 14) {
            balancePill

            // Country selector
            VStack(alignment: .leading, spacing: 8) {
                Text(marketConfig.strings.cashDestCountry)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "#6B7280"))
                Button { showCountryPicker = true } label: {
                    HStack(spacing: 12) {
                        Text(selectedCountry.flag)
                            .font(.system(size: 24))
                        VStack(alignment: .leading, spacing: 1) {
                            Text(selectedCountry.displayName(for: marketConfig.market))
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color(hex: "#1C1C2E"))
                            Text(marketConfig.market == .tokyo ? "通貨: \(selectedCountry.currency)" : "Currency: \(selectedCountry.currency)")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "#9CA3AF"))
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "#9CA3AF"))
                    }
                    .padding(14)
                    .background(Color(hex: "#F9FAFB"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#E5E7EB"), lineWidth: 1))
                }
            }
            .cardStyle()
            .sheet(isPresented: $showCountryPicker) {
                CountryPickerSheet(selected: $selectedCountry)
                    .environmentObject(marketConfig)
            }

            // Recipient details
            VStack(alignment: .leading, spacing: 12) {
                Text(marketConfig.strings.cashRecipientDetails)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "#6B7280"))
                let jp = marketConfig.market == .tokyo
                intlField("person.fill",        jp ? "受取人氏名" : "Full Name",          $recipientName, .default)
                intlField("building.columns.fill",jp ? "銀行名" : "Bank Name",        $bankName,      .default)
                intlField("number",              jp ? "SWIFT / BICコード" : "SWIFT / BIC Code",  $swiftCode,     .default, placeholder: marketConfig.market == .sydney ? "e.g. CTBAAU2S" : "e.g. DBSSSGSG")
                intlField("creditcard.fill",     jp ? "口座番号" : "Account Number",    $intlAccountNum,.numberPad)
            }
            .cardStyle()

            // Amount + purpose
            VStack(alignment: .leading, spacing: 12) {
                Text(marketConfig.strings.cashTransferDetails)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "#6B7280"))

                HStack(spacing: 10) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(cashAmber)
                        .frame(width: 32)
                    TextField(marketConfig.strings.cashAmountIn, text: $intlAmount)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 15))
                    if let amt = Double(intlAmount) {
                        Text("≈ \(selectedCountry.currency) \(String(format: "%.0f", amt * intlRate))")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "#9CA3AF"))
                    }
                }
                .padding(14)
                .background(Color(hex: "#F9FAFB"))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#E5E7EB"), lineWidth: 1))

                // Purpose picker
                HStack(spacing: 10) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 14))
                        .foregroundColor(cashAmber)
                        .frame(width: 32)
                    Picker(marketConfig.market == .tokyo ? "送金目的" : "Purpose", selection: $transferPurpose) {
                        ForEach(purposes, id: \.self) { Text(purposeLabel($0)).tag($0) }
                    }
                    .tint(Color(hex: "#374151"))
                    .font(.system(size: 15))
                }
                .padding(14)
                .background(Color(hex: "#F9FAFB"))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#E5E7EB"), lineWidth: 1))
            }
            .cardStyle()

            // Fee summary
            if let amt = Double(intlAmount), amt > 0 {
                VStack(spacing: 8) {
                    feeRow(marketConfig.strings.cashYouSend,       marketConfig.market.formatPrice(amt))
                    feeRow(marketConfig.strings.cashTransferFee,   marketConfig.market.formatPrice(intlFee))
                    feeRow(marketConfig.strings.cashTotalDeducted, marketConfig.market.formatPrice(amt + intlFee), bold: true)
                    Divider()
                    feeRow(marketConfig.strings.cashExchangeRate,  "1 \(marketConfig.market.currencyCode) ≈ \(selectedCountry.currency) \(String(format: "%.4f", intlRate))")
                    feeRow(marketConfig.strings.cashRecipientGets, "≈ \(selectedCountry.currency) \(formattedForeignAmount(amt * intlRate, currency: selectedCountry.currency))")
                }
                .cardStyle()
            }

            sendButton(
                disabled: swiftCode.isEmpty || recipientName.isEmpty || intlAccountNum.isEmpty || intlAmount.isEmpty,
                label: marketConfig.strings.cashSendInternational
            ) {
                let amt = Double(intlAmount) ?? 0
                guard amt > 0 else { return }
                confirmAmount    = amt + intlFee
                confirmRecipient = "\(recipientName) · \(selectedCountry.displayName(for: marketConfig.market))"
                confirmNote      = bankName.isEmpty ? (marketConfig.market == .tokyo ? "海外送金" : "International Transfer") : bankName
                isInternational  = true
                showConfirm      = true
                CSQ.trackEvent("cash_send_international_initiated", properties: [
                    "destination_country": selectedCountry.country,
                    "destination_currency": selectedCountry.currency,
                    "amount_sgd": String(format: "%.2f", Double(intlAmount) ?? 0),
                    "currency": "SGD",
                    "transfer_purpose": transferPurpose,
                    "transaction_type": "international_transfer"
                ])
            }
        }
    }

    // MARK: - Reusable Sub-Views

    private var balancePill: some View {
        HStack(spacing: 8) {
            Image(systemName: "dollarsign.circle.fill")
                .foregroundColor(cashGreen)
                .font(.system(size: 15))
            Text("\(marketConfig.strings.cashAvailablePrefix)\(marketConfig.market.formatPrice(wallet.balance))")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(hex: "#374151"))
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(cashGreen.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func amountAndNoteFields(amount: Binding<String>, note: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Amount
            HStack(spacing: 0) {
                Text(marketConfig.strings.cashCurrencyPrefix)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(cashAmber)
                    .padding(.leading, 14)
                TextField(marketConfig.market == .tokyo ? "0" : "0.00", text: amount)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color(hex: "#1C1C2E"))
                    .keyboardType(marketConfig.market == .tokyo ? .numberPad : .decimalPad)
                    .padding(14)
                Spacer()
            }
            .background(Color(hex: "#FFFBEB"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(cashAmber.opacity(0.4), lineWidth: 1))

            // Preset amounts
            let presets = marketConfig.market == .tokyo
                ? ["1000", "3000", "5000", "10000"]
                : ["10",   "20",   "50",   "100"]
            HStack(spacing: 8) {
                ForEach(presets, id: \.self) { preset in
                    Button { amount.wrappedValue = preset } label: {
                        Text("\(marketConfig.strings.cashCurrencyPrefix)\(preset)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(cashAmber)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(cashAmber.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }

            // Note
            HStack(spacing: 10) {
                Image(systemName: "note.text")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#9CA3AF"))
                    .frame(width: 32)
                TextField(marketConfig.strings.cashAddNote, text: note)
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#374151"))
            }
            .padding(14)
            .background(Color(hex: "#F9FAFB"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#E5E7EB"), lineWidth: 1))
        }
        .cardStyle()
    }

    private func sendButton(disabled: Bool, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(disabled ? Color(hex: "#9CA3AF") : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    disabled
                        ? AnyShapeStyle(Color(hex: "#E5E7EB"))
                        : AnyShapeStyle(LinearGradient(colors: [cashAmber, Color(hex: "#D97706")],
                                                       startPoint: .leading, endPoint: .trailing))
                )
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.full))
                .shadow(color: disabled ? .clear : cashAmber.opacity(0.35), radius: 8, x: 0, y: 4)
        }
        .disabled(disabled)
    }

    private func intlField(_ icon: String, _ placeholder: String,
                           _ binding: Binding<String>, _ keyboard: UIKeyboardType,
                           placeholder textOverride: String? = nil) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(cashAmber)
                .frame(width: 32)
            TextField(textOverride ?? placeholder, text: binding)
                .font(.system(size: 15))
                .keyboardType(keyboard)
                .autocapitalization(.words)
        }
        .padding(14)
        .background(Color(hex: "#F9FAFB"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#E5E7EB"), lineWidth: 1))
    }

    private func formattedForeignAmount(_ value: Double, currency: String) -> String {
        // Whole-number currencies (no cents)
        let noDecimals = ["IDR", "JPY", "KRW", "VND", "CLP", "HUF"]
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        if noDecimals.contains(currency) {
            formatter.maximumFractionDigits = 0
            return formatter.string(from: NSNumber(value: value.rounded())) ?? String(format: "%.0f", value)
        } else {
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 2
            return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
        }
    }

    private func feeRow(_ label: String, _ value: String, bold: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: bold ? .semibold : .regular))
                .foregroundColor(bold ? Color(hex: "#1C1C2E") : Color(hex: "#6B7280"))
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: bold ? .bold : .medium))
                .foregroundColor(bold ? cashGreen : Color(hex: "#374151"))
        }
    }
}

// MARK: - Contact Send Row

struct ContactSendRow: View {
    let contact  : CashContact
    let onSend   : (Double, String) -> Void

    @EnvironmentObject var marketConfig: MarketConfig
    @State private var amount = ""
    @State private var expanded = false

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.3)) { expanded.toggle() }
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        Circle().fill(contact.avatarColor).frame(width: 46, height: 46)
                        Text(contact.initials)
                            .font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(contact.name).font(.system(size: 15, weight: .semibold)).foregroundColor(Color(hex: "#1C1C2E"))
                        Text(contact.phone).font(.system(size: 12)).foregroundColor(Color(hex: "#9CA3AF"))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(marketConfig.strings.cashLastAmount)\(marketConfig.market.formatPrice(contact.lastAmount))")
                            .font(.system(size: 11, weight: .medium)).foregroundColor(cashAmber)
                        Text(contact.lastDate)
                            .font(.system(size: 11)).foregroundColor(Color(hex: "#9CA3AF"))
                    }
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "#9CA3AF"))
                }
                .padding(14)
            }

            if expanded {
                Divider().padding(.horizontal, 14)
                HStack(spacing: 10) {
                    Text(marketConfig.strings.cashCurrencyPrefix).font(.system(size: 18, weight: .bold)).foregroundColor(cashAmber).padding(.leading, 14)
                    TextField(marketConfig.market == .tokyo ? "金額" : "Amount", text: $amount)
                        .keyboardType(marketConfig.market == .tokyo ? .numberPad : .decimalPad)
                        .font(.system(size: 18, weight: .bold))
                    Button {
                        let a = Double(amount) ?? 0
                        guard a > 0 else { return }
                        onSend(a, contact.name)
                    } label: {
                        Text(marketConfig.strings.cashSendMoneyConfirmTitle)
                            .font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                            .padding(.horizontal, 20).padding(.vertical, 10)
                            .background(cashAmber).clipShape(Capsule())
                    }
                    .padding(.trailing, 14)
                }
                .padding(.vertical, 12)
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Country Picker Sheet

struct CountryPickerSheet: View {
    @Binding var selected: SWIFTCountry
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var marketConfig: MarketConfig
    @State private var query = ""

    private var filtered: [SWIFTCountry] {
        query.isEmpty ? SWIFTCountry.list
        : SWIFTCountry.list.filter {
            $0.country.lowercased().contains(query.lowercased()) ||
            $0.displayName(for: marketConfig.market).contains(query) ||
            $0.currency.lowercased().contains(query.lowercased())
        }
    }

    var body: some View {
        NavigationView {
            List(filtered) { c in
                Button {
                    selected = c
                    dismiss()
                } label: {
                    HStack(spacing: 14) {
                        Text(c.flag).font(.system(size: 28))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(c.displayName(for: marketConfig.market)).font(.system(size: 15, weight: .semibold)).foregroundColor(Color(hex: "#1C1C2E"))
                            Text(c.currency).font(.system(size: 12)).foregroundColor(Color(hex: "#9CA3AF"))
                        }
                        Spacer()
                        if selected.code == c.code {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(cashAmber)
                        }
                    }
                }
                .listRowBackground(Color.white)
            }
            .listStyle(.plain)
            .searchable(text: $query, prompt: marketConfig.market == .tokyo ? "国または通貨を検索" : "Search country or currency")
            .navigationTitle(marketConfig.strings.cashSelectCountry)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(marketConfig.strings.cashDoneButton) { dismiss() }.foregroundColor(cashAmber)
                }
            }
        }
    }
}

// MARK: - Send Confirmation Sheet

struct SendConfirmSheet: View {
    let amount          : Double
    let recipient       : String
    let note            : String
    let walletBalance   : Double
    let isInternational : Bool
    let onResult        : (Bool) -> Void

    @EnvironmentObject var marketConfig: MarketConfig
    @State private var processing = false

    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2).fill(Color(hex: "#E5E7EB"))
                .frame(width: 40, height: 4).padding(.top, 12).padding(.bottom, 20)

            ZStack {
                Circle().fill(cashAmber.opacity(0.12)).frame(width: 72, height: 72)
                Image(systemName: isInternational ? "globe" : "arrow.up.right.circle.fill")
                    .font(.system(size: 28)).foregroundColor(cashAmber)
            }

            Text(isInternational ? marketConfig.strings.cashInternationalTransfer : marketConfig.strings.cashSendMoneyConfirmTitle)
                .font(.system(size: 18, weight: .bold)).foregroundColor(Color(hex: "#1C1C2E")).padding(.top, 10)
            Text(marketConfig.market == .tokyo ? "送金先: \(recipient)" : "To \(recipient)").font(.system(size: 13)).foregroundColor(Color(hex: "#9CA3AF")).padding(.bottom, 16)

            Text(marketConfig.market.formatPrice(amount))
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: "#1C1C2E"))
            if !note.isEmpty {
                Text(note).font(.system(size: 13)).foregroundColor(Color(hex: "#9CA3AF")).padding(.top, 4)
            }

            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill").foregroundColor(cashGreen).font(.system(size: 13))
                Text("\(marketConfig.strings.cashBalanceAfter)\(marketConfig.market.formatPrice(walletBalance - amount))")
                    .font(.system(size: 13)).foregroundColor(Color(hex: "#6B7280"))
            }
            .padding(.top, 12).padding(.bottom, 22)

            HStack(spacing: 12) {
                Button { onResult(false) } label: {
                    Text(marketConfig.strings.cashCancelButton).font(.system(size: 15, weight: .semibold)).foregroundColor(Color(hex: "#374151"))
                        .frame(maxWidth: .infinity).padding(.vertical, 14).background(Color(hex: "#F3F4F6"))
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.full))
                }
                Button {
                    processing = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { onResult(true) }
                    CSQ.trackEvent("cash_send_confirmed", properties: [
                        "amount_sgd": String(format: "%.2f", amount),
                        "currency": "SGD",
                        "transaction_type": isInternational ? "international_transfer" : "domestic_transfer",
                        "recipient": recipient,
                        "is_international": isInternational ? "true" : "false"
                    ])
                } label: {
                    Group {
                        if processing { ProgressView().progressViewStyle(.circular).tint(.white) }
                        else { Text(marketConfig.strings.cashConfirmSend).font(.system(size: 15, weight: .bold)).foregroundColor(.white) }
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(LinearGradient(colors: [cashAmber, Color(hex: "#D97706")], startPoint: .leading, endPoint: .trailing))
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.full))
                    .shadow(color: cashAmber.opacity(0.35), radius: 8, x: 0, y: 4)
                }
                .disabled(processing)
            }
            .padding(.horizontal, 24).padding(.bottom, 32)
        }
        .background(Color.white)
    }
}

// MARK: - View Modifier Helper

private extension View {
    func cardStyle() -> some View {
        self
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
    }
}
