import SwiftUI
import ContentsquareSDK

// MARK: - Rage-Tap Detection (deterministic frustration signal)
//
// The Contentsquare iOS SDK does NOT emit "rage clicks" as a client-side event —
// rage / frustration is a behavioural signal the platform derives server-side
// from the autocaptured tap stream + session replay. To make that signal
// DETERMINISTIC for a demo (rather than relying on the platform heuristic firing),
// we additionally emit an explicit custom event when a user hammers a control:
//
//   • a coupon / promo "Apply" button tapped rapidly on an invalid code, or
//   • a failing payment retried repeatedly.
//
// These complement (do not replace) the native frustration detection: the same
// rapid taps still flow into Product Analytics autocapture and Experience
// Analytics replay — this just gives you a first-class event to segment/funnel on.
//
// Usage (per view):
//   @State private var promoRage = RageTapDetector()
//   @State private var promoFailures = 0
//   ...
//   promoFailures += 1
//   if let count = promoRage.registerTap() {
//       FrustrationSignal.promoRage(service: "CSQRide", screen: "Ride - Promo Code Entry",
//                                   tapCount: count, failedAttempts: promoFailures,
//                                   codeLength: code.count, market: marketConfig.market)
//   }

/// Sliding-window rage detector. Records taps and reports when a burst of taps
/// crosses the rage threshold within `window` seconds. It is a value type — store
/// it in `@State` (mutating methods persist through the property wrapper).
struct RageTapDetector {
    /// Burst window. Taps older than this are forgotten.
    var window: TimeInterval = 3.0
    /// Number of taps within `window` that count as "rage".
    var threshold: Int = 3

    private var taps: [Date] = []

    /// Record a tap. Returns the current burst tap-count when it meets or exceeds
    /// the rage threshold (the caller should fire a CS event), otherwise `nil`.
    /// `now` is injectable for testing; defaults to the wall clock.
    mutating func registerTap(at now: Date = Date()) -> Int? {
        let cutoff = now.addingTimeInterval(-window)
        taps.removeAll { $0 < cutoff }
        taps.append(now)
        return taps.count >= threshold ? taps.count : nil
    }

    /// Clear the burst (e.g. after a successful apply).
    mutating func reset() {
        taps.removeAll()
    }
}

// MARK: - Frustration event emitters
//
// Canonical names, fired through the unified `CSQ` facade. Kept in one place so
// every coupon surface emits the SAME event (segment by `service`) and the
// payment rage-retry stays consistent with the bill-payment funnel.
enum FrustrationSignal {

    /// A coupon / promo "Apply" hammered on an invalid code. Fired across CSQRide,
    /// CSQFood and CSQMart, so a single segment / funnel spans every coupon surface.
    /// The raw code is never sent — only `code_length`.
    static func promoRage(service: String,
                          screen: String,
                          tapCount: Int,
                          failedAttempts: Int,
                          codeLength: Int,
                          market: Market) {
        CSQ.trackEvent("promo_rage_apply", properties: [
            "service":         service,            // CSQRide / CSQFood / CSQMart
            "screen":          screen,
            "tap_count":       tapCount,           // taps in the rage burst
            "failed_attempts": failedAttempts,     // total failed applies this session
            "code_length":     codeLength,         // length only — never the code itself
            "market":          market.trackingLabel
        ])
    }

    /// A failing bill payment retried repeatedly — the CSQMobile rage-retry signal.
    static func paymentRageRetry(invoiceNo: String,
                                 tapCount: Int,
                                 amount: Double,
                                 method: String,
                                 market: Market) {
        CSQ.trackEvent("telco_payment_rage_retry", properties: [
            "invoice_no": invoiceNo,
            "tap_count":  tapCount,                // number of failed retries so far
            "amount":     amount,
            "method":     method,
            "market":     market.trackingLabel
        ])
    }
}
