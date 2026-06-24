import SwiftUI
import AVFoundation
import ContentsquareSDK

// MARK: - Camera Controller

class QRCameraController: NSObject, ObservableObject, AVCaptureMetadataOutputObjectsDelegate {
    @Published var isReady          : Bool    = false
    @Published var permDenied       : Bool    = false
    @Published var detectedCode     : String? = nil
    @Published var permissionState  : CameraPermState = .unknown

    enum CameraPermState { case unknown, requested, granted, denied }

    let session = AVCaptureSession()

    func requestAndStart() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionState = .granted
            configure()
        case .notDetermined:
            permissionState = .requested
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.permissionState = .granted
                        self?.configure()
                    } else {
                        self?.permissionState = .denied
                        self?.permDenied = true
                    }
                }
            }
        default:
            DispatchQueue.main.async {
                self.permissionState = .denied
                self.permDenied = true
            }
        }
    }

    func stop() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.session.stopRunning()
        }
    }

    private func configure() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input  = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else { return }

        session.beginConfiguration()
        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else {
            session.commitConfiguration(); return
        }
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.qr]
        session.commitConfiguration()

        DispatchQueue.main.async { self.isReady = true }
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.session.startRunning()
        }
    }

    // AVCaptureMetadataOutputObjectsDelegate
    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        guard detectedCode == nil,
              let obj   = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let value = obj.stringValue else { return }
        detectedCode = value
    }
}

// MARK: - Camera Preview (UIViewRepresentable)

struct QRCameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity  = .resizeAspectFill
        layer.frame         = UIScreen.main.bounds
        view.layer.addSublayer(layer)
        return view
    }

    func updateUIView(_ view: UIView, context: Context) {
        DispatchQueue.main.async {
            view.layer.sublayers?
                .compactMap { $0 as? AVCaptureVideoPreviewLayer }
                .forEach { $0.frame = view.bounds }
        }
    }
}

// MARK: - Corner Bracket Shape

struct ScannerBrackets: Shape {
    func path(in rect: CGRect) -> Path {
        let arm: CGFloat = 28
        var p = Path()
        // top-left
        p.move(to: CGPoint(x: rect.minX, y: rect.minY + arm))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX + arm, y: rect.minY))
        // top-right
        p.move(to: CGPoint(x: rect.maxX - arm, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + arm))
        // bottom-right
        p.move(to: CGPoint(x: rect.maxX, y: rect.maxY - arm))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.maxX - arm, y: rect.maxY))
        // bottom-left
        p.move(to: CGPoint(x: rect.minX + arm, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - arm))
        return p
    }
}

// MARK: - QRScannerView

struct QRScannerView: View {
    @ObservedObject var wallet    : CashWalletStore
    let onPaymentConfirmed        : (QRPaymentPayload) -> Void

    @StateObject private var cam  = QRCameraController()
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var marketConfig: MarketConfig

    @State private var scanLineY        : CGFloat = 0
    @State private var showPaymentSheet = false
    @State private var pendingPayload   : QRPaymentPayload? = nil
    @State private var demoIndex        = 0
    @State private var torchOn          = false
    @State private var scanning         = true

    // Session tracking — all events in one scan session share this ID
    @State private var scanSessionId    : String = UUID().uuidString
    @State private var sessionOpenTime  : Date   = Date()
    @State private var sheetOpenTime    : Date   = Date()

    private let viewfinderSize: CGFloat = 260

    // Common properties sent on every event for BPI funnel analysis
    private var sessionProps: [String: String] {
        [
            "scan_session_id"   : scanSessionId,
            "wallet_balance_sgd": String(format: "%.2f", wallet.balance),
            "currency"          : "SGD",
            "transaction_channel": "in_app_qr_scan",
            "payment_method"    : "qr_code"
        ]
    }

    var body: some View {
        ZStack {
            // Camera or dark fallback
            if cam.isReady {
                QRCameraPreview(session: cam.session)
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
                // Stylised mock camera pattern for simulator
                mockCameraBackground
            }

            // Dark vignette overlay with clear viewfinder cutout
            scannerOverlay

            // UI chrome
            VStack(spacing: 0) {
                topBar
                Spacer()
                instructionArea
            }
        }
        .onAppear {
            scanSessionId   = UUID().uuidString
            sessionOpenTime = Date()
            cam.requestAndStart()
            startScanAnimation()

            CSQ.trackScreenview("Cash - QR Scanner")
            CSQ.trackEvent("cash_qr_scanner_session_started", properties: sessionProps.merging([
                "entry_point"      : "home_quick_actions",
                "deposit_type"     : "qr_initiated",
                "supported_formats": "PayNow, SGQR, CSQCash, Barcode"
            ]) { $1 })
        }
        .onDisappear {
            cam.stop()
            let duration = Int(Date().timeIntervalSince(sessionOpenTime))
            CSQ.trackEvent("cash_qr_scanner_session_ended", properties: sessionProps.merging([
                "session_duration_seconds": String(duration),
                "scans_completed"         : String(demoIndex),
                "torch_used"              : torchOn ? "true" : "false"
            ]) { $1 })
        }
        // Camera permission state changes
        .onChange(of: cam.permissionState) { _, state in
            switch state {
            case .requested:
                CSQ.trackEvent("cash_qr_camera_permission_requested", properties: sessionProps)
            case .granted:
                CSQ.trackEvent("cash_qr_camera_permission_granted", properties: sessionProps.merging([
                    "permission_outcome": "granted",
                    "access_type"       : "camera"
                ]) { $1 })
            case .denied:
                CSQ.trackEvent("cash_qr_camera_permission_denied", properties: sessionProps.merging([
                    "permission_outcome": "denied",
                    "fallback_available" : "true",
                    "fallback_type"      : "demo_scan_button"
                ]) { $1 })
            case .unknown:
                break
            }
        }
        // Camera preview live
        .onChange(of: cam.isReady) { _, ready in
            guard ready else { return }
            CSQ.trackEvent("cash_qr_camera_preview_active", properties: sessionProps.merging([
                "camera_status"  : "live",
                "viewfinder_size": "260x260",
                "scan_mode"      : "qr_and_barcode"
            ]) { $1 })
            CSQ.trackEvent("cash_qr_scanning_initialized", properties: sessionProps.merging([
                "scan_line_animation": "active",
                "bracket_overlay"    : "visible"
            ]) { $1 })
        }
        // Real QR/barcode detected by camera
        .onChange(of: cam.detectedCode) { _, code in
            guard let raw = code, scanning else { return }
            scanning = false
            CSQ.trackEvent("cash_qr_code_detected", properties: sessionProps.merging([
                "detection_method"  : "camera_avfoundation",
                "raw_code_length"   : String(raw.count),
                "code_type"         : "qr_code",
                "time_to_detect_s"  : String(Int(Date().timeIntervalSince(sessionOpenTime)))
            ]) { $1 })
            triggerDemo()
        }
        .sheet(isPresented: $showPaymentSheet) {
            if let p = pendingPayload {
                PaymentConfirmSheet(
                    payload: p,
                    walletBalance: wallet.balance,
                    scanSessionId: scanSessionId
                ) { confirmed in
                    showPaymentSheet = false
                    if confirmed {
                        let reviewSecs = Int(Date().timeIntervalSince(sheetOpenTime))
                        CSQ.trackEvent("cash_qr_payment_success", properties: sessionProps.merging([
                            "merchant"              : p.merchant,
                            "merchant_category"     : p.category,
                            "merchant_id"           : p.merchantId,
                            "amount_sgd"            : String(format: "%.2f", p.amount),
                            "payment_reference"     : p.reference,
                            "review_duration_seconds": String(reviewSecs),
                            "transaction_type"      : "qr_payment",
                            "deposit_type"          : "qr_initiated",
                            "outcome"               : "success"
                        ]) { $1 })
                        wallet.payViaQR(p)
                        dismiss()
                        onPaymentConfirmed(p)
                    } else {
                        CSQ.trackEvent("cash_qr_payment_cancelled", properties: sessionProps.merging([
                            "merchant"          : p.merchant,
                            "merchant_category" : p.category,
                            "amount_sgd"        : String(format: "%.2f", p.amount),
                            "cancellation_stage": "payment_confirmation_sheet",
                            "outcome"           : "cancelled"
                        ]) { $1 })
                        scanning = true
                        cam.detectedCode = nil
                        CSQ.trackEvent("cash_qr_scanning_resumed", properties: sessionProps.merging([
                            "resume_reason": "user_cancelled_payment",
                            "demo_cycle"   : String(demoIndex)
                        ]) { $1 })
                    }
                }
                .environmentObject(marketConfig)
                .presentationDetents([.height(440)])
                .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Overlay

    private var scannerOverlay: some View {
        GeometryReader { geo in
            let cx = geo.size.width  / 2
            let cy = geo.size.height / 2 - 40
            let half = viewfinderSize / 2

            ZStack {
                // Dark mask
                Color.black.opacity(0.65)
                    .ignoresSafeArea()
                    .mask(
                        Rectangle()
                            .ignoresSafeArea()
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .frame(width: viewfinderSize, height: viewfinderSize)
                                    .position(x: cx, y: cy)
                                    .blendMode(.destinationOut)
                            )
                            .compositingGroup()
                    )

                // Green scan line inside viewfinder
                if scanning {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [cashGreen.opacity(0), cashGreen, cashGreen.opacity(0)],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: viewfinderSize - 20, height: 2)
                        .clipShape(RoundedRectangle(cornerRadius: 1))
                        .shadow(color: cashGreen.opacity(0.8), radius: 4)
                        .position(x: cx, y: cy - half + scanLineY)
                        .animation(
                            .easeInOut(duration: 2).repeatForever(autoreverses: true),
                            value: scanLineY
                        )
                }

                // Corner brackets
                ScannerBrackets()
                    .stroke(cashGreen, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: viewfinderSize, height: viewfinderSize)
                    .position(x: cx, y: cy)
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Circle())
            }
            Spacer()
            Text(marketConfig.strings.cashScanToPayTitle)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            Spacer()
            Button {
                torchOn.toggle()
                toggleTorch(torchOn)
                CSQ.trackEvent("cash_qr_torch_toggled", properties: sessionProps.merging([
                    "torch_state"  : torchOn ? "on" : "off",
                    "likely_reason": "low_light_environment"
                ]) { $1 })
            } label: {
                Image(systemName: torchOn ? "bolt.fill" : "bolt.slash.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(torchOn ? cashAmber : .white)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    // MARK: - Instruction Area

    private var instructionArea: some View {
        VStack(spacing: 20) {
            // Hint text
            VStack(spacing: 6) {
                Text(marketConfig.strings.cashPointCamera)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Text(marketConfig.strings.cashQRSupports)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.65))
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)

            // Demo button — always available
            Button {
                let demoList = QRPaymentPayload.demoMerchants(for: marketConfig.market)
                let merchant = demoList[demoIndex % demoList.count]
                sheetOpenTime = Date()
                CSQ.trackEvent("cash_qr_demo_scan_initiated", properties: sessionProps.merging([
                    "merchant"          : merchant.merchant,
                    "merchant_category" : merchant.category,
                    "merchant_id"       : merchant.merchantId,
                    "amount_sgd"        : String(format: "%.2f", merchant.amount),
                    "demo_step"         : String(demoIndex % QRPaymentPayload.demoMerchants.count + 1),
                    "scan_trigger"      : "demo_button",
                    "deposit_type"      : "qr_initiated",
                    "transaction_channel": "in_store_qr"
                ]) { $1 })
                triggerDemo()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "qrcode")
                        .font(.system(size: 15, weight: .semibold))
                    Text(marketConfig.strings.cashDemoScan)
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(cashDark)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(
                    LinearGradient(colors: [cashAmber, Color(hex: "#D97706")],
                                   startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.full))
                .shadow(color: cashAmber.opacity(0.5), radius: 10, x: 0, y: 5)
            }
            .padding(.horizontal, 28)

            // Permission denied hint
            if cam.permDenied {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(cashAmber)
                        .font(.system(size: 12))
                    Text(marketConfig.strings.cashCameraDenied)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.65))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 40)
            }

            Spacer(minLength: 44)
        }
    }

    // MARK: - Mock Camera Background

    private var mockCameraBackground: some View {
        ZStack {
            Color(hex: "#0D0D0D").ignoresSafeArea()
            // Grid lines
            GeometryReader { geo in
                Path { p in
                    stride(from: 0, to: geo.size.width, by: 40).forEach { x in
                        p.move(to: CGPoint(x: x, y: 0))
                        p.addLine(to: CGPoint(x: x, y: geo.size.height))
                    }
                    stride(from: 0, to: geo.size.height, by: 40).forEach { y in
                        p.move(to: CGPoint(x: 0, y: y))
                        p.addLine(to: CGPoint(x: geo.size.width, y: y))
                    }
                }
                .stroke(Color.white.opacity(0.04), lineWidth: 0.5)
            }
        }
    }

    // MARK: - Helpers

    private func startScanAnimation() {
        scanLineY = 0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            scanLineY = viewfinderSize - 20
        }
    }

    private func triggerDemo() {
        let payloads = QRPaymentPayload.demoMerchants(for: marketConfig.market)
        pendingPayload = payloads[demoIndex % payloads.count]
        demoIndex += 1
        scanning = false
        showPaymentSheet = true
    }

    private func toggleTorch(_ on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch else { return }
        try? device.lockForConfiguration()
        device.torchMode = on ? .on : .off
        device.unlockForConfiguration()
    }
}

// MARK: - Payment Confirmation Sheet

struct PaymentConfirmSheet: View {
    let payload       : QRPaymentPayload
    let walletBalance : Double
    let scanSessionId : String
    let onResult      : (Bool) -> Void

    @EnvironmentObject var marketConfig: MarketConfig
    @State private var isProcessing  = false
    @State private var sheetLoadTime = Date()

    private var hasSufficientFunds: Bool { walletBalance >= payload.amount }

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

    private var sheetProps: [String: String] {[
        "scan_session_id"   : scanSessionId,
        "merchant"          : payload.merchant,
        "merchant_category" : payload.category,
        "merchant_id"       : payload.merchantId,
        "amount_sgd"        : String(format: "%.2f", payload.amount),
        "currency"          : "SGD",
        "payment_reference" : payload.reference,
        "has_sufficient_funds": hasSufficientFunds ? "true" : "false",
        "transaction_channel": "in_store_qr",
        "deposit_type"      : "qr_initiated"
    ]}

    var body: some View {
        VStack(spacing: 0) {
            // Handle
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: "#E5E7EB"))
                .frame(width: 40, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 20)

            // Merchant icon
            ZStack {
                Circle()
                    .fill(payload.merchantColor.opacity(0.12))
                    .frame(width: 72, height: 72)
                Image(systemName: payload.merchantIcon)
                    .font(.system(size: 28))
                    .foregroundColor(payload.merchantColor)
            }
            .padding(.bottom, 12)

            Text(payload.merchant)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color(hex: "#1C1C2E"))
            Text(payload.category)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#9CA3AF"))
                .padding(.bottom, 20)

            // Amount
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(marketConfig.strings.cashCurrencyPrefix)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(Color(hex: "#1C1C2E"))
                Text(amountDigits(payload.amount))
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "#1C1C2E"))
            }
            .padding(.bottom, 6)

            Text(payload.reference)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#9CA3AF"))
                .padding(.bottom, 20)

            // Balance check
            HStack(spacing: 6) {
                Image(systemName: walletBalance >= payload.amount
                      ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .foregroundColor(walletBalance >= payload.amount ? cashGreen : Color(hex: "#EF4444"))
                    .font(.system(size: 13))
                Text("\(marketConfig.strings.cashBalanceAfterPayment)\(marketConfig.market.formatPrice(walletBalance - payload.amount))")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "#6B7280"))
            }
            .padding(.bottom, 24)

            // CTA buttons
            HStack(spacing: 12) {
                Button {
                    let reviewSecs = Int(Date().timeIntervalSince(sheetLoadTime))
                    CSQ.trackEvent("cash_qr_payment_sheet_cancel_tapped", properties: sheetProps.merging([
                        "review_duration_seconds": String(reviewSecs),
                        "cancellation_stage"     : "payment_confirmation_sheet",
                        "outcome"                : "cancelled"
                    ]) { $1 })
                    onResult(false)
                } label: {
                    Text(marketConfig.strings.cashCancelPayment)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(hex: "#374151"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(hex: "#F3F4F6"))
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.full))
                }

                Button {
                    guard hasSufficientFunds else { return }
                    isProcessing = true
                    let reviewSecs = Int(Date().timeIntervalSince(sheetLoadTime))
                    CSQ.trackEvent("cash_qr_payment_confirm_tapped", properties: sheetProps.merging([
                        "review_duration_seconds"  : String(reviewSecs),
                        "transaction_type"         : "qr_payment",
                        "balance_before_sgd"       : String(format: "%.2f", walletBalance),
                        "balance_after_sgd"        : String(format: "%.2f", walletBalance - payload.amount),
                        "outcome"                  : "processing"
                    ]) { $1 })
                    CSQ.trackEvent("cash_qr_payment_processing_started", properties: sheetProps.merging([
                        "processing_method"   : "instant_debit",
                        "authorization_type"  : "app_authenticated",
                        "expected_duration_ms": "800"
                    ]) { $1 })
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        CSQ.trackEvent("cash_qr_payment_confirmed", properties: sheetProps.merging([
                            "transaction_type"      : "qr_payment",
                            "balance_before_sgd"    : String(format: "%.2f", walletBalance),
                            "balance_after_sgd"     : String(format: "%.2f", walletBalance - payload.amount),
                            "processing_duration_ms": "800",
                            "outcome"               : "success"
                        ]) { $1 })
                        onResult(true)
                    }
                } label: {
                    Group {
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                        } else {
                            Text(marketConfig.strings.cashPayAmount(amountDigits(payload.amount)))
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        walletBalance >= payload.amount
                            ? LinearGradient(colors: [cashGreen, Color(hex: "#059669")],
                                             startPoint: .leading, endPoint: .trailing)
                            : LinearGradient(colors: [Color.csqBorder, Color.csqBorder],
                                             startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.full))
                    .shadow(color: cashGreen.opacity(walletBalance >= payload.amount ? 0.35 : 0), radius: 8, x: 0, y: 4)
                }
                .disabled(walletBalance < payload.amount || isProcessing)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Color.white)
        .onAppear {
            sheetLoadTime = Date()
            CSQ.trackEvent("cash_qr_payment_sheet_presented", properties: sheetProps.merging([
                "sheet_type"           : "payment_confirmation",
                "balance_before_sgd"   : String(format: "%.2f", walletBalance),
                "transaction_eligible" : hasSufficientFunds ? "true" : "false"
            ]) { $1 })
            if !hasSufficientFunds {
                CSQ.trackEvent("cash_qr_insufficient_funds_detected", properties: sheetProps.merging([
                    "wallet_balance_sgd"  : String(format: "%.2f", walletBalance),
                    "required_amount_sgd" : String(format: "%.2f", payload.amount),
                    "shortfall_sgd"       : String(format: "%.2f", payload.amount - walletBalance),
                    "cta_blocked"         : "true",
                    "suggested_action"    : "top_up_wallet"
                ]) { $1 })
            }
        }
    }
}
