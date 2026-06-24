import SwiftUI
import ContentsquareSDK

// MARK: - Splash Screen
// Shown on launch. Tap anywhere to enter the app.
// Animated indicator bar gives demo control — presenter taps when ready to proceed.

struct SplashView: View {
    @Binding var isVisible: Bool
    @EnvironmentObject var marketConfig: MarketConfig
    @State private var barProgress: CGFloat = 0
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @State private var taglineOpacity: Double = 0
    @State private var pulseOpacity: Double = 0.4

    var body: some View {
        ZStack {
            // Full coral gradient background
            LinearGradient(
                colors: [Color.csqPrimary, Color.csqPrimaryDark],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo lockup
                VStack(spacing: 24) {
                    // Brand logo — icon mark + wordmark
                    CSQJekLogoView(style: .white, iconSize: 72, showWordmark: false)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                        .accessibilityIdentifier("splash_logo_icon")
                        .accessibilityLabel("CSQJek Logo")

                    VStack(spacing: 8) {
                        Text("CSQJek")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .tracking(-1)
                            .accessibilityIdentifier("splash_wordmark")
                            .accessibilityLabel("CSQJek")

                        Text(marketConfig.strings.splashTagline)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                            .accessibilityIdentifier("splash_tagline")
                    }
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                }

                Spacer()

                // Bottom section: progress bar + tap prompt
                VStack(spacing: 20) {
                    // Pulsing tap hint
                    Text(marketConfig.strings.splashTapPrompt)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                        .opacity(pulseOpacity)

                    // Indicator bar track
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            // Track
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white.opacity(0.25))
                                .frame(height: 4)

                            // Fill
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white)
                                .frame(width: geo.size.width * barProgress, height: 4)
                        }
                    }
                    .frame(height: 4)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 52)
                }
            }
        }
        .contentShape(Rectangle()) // make entire area tappable
        .accessibilityIdentifier("splash_tap_to_proceed_overlay")
        .accessibilityLabel("Splash screen — tap anywhere to begin demo")
        .onTapGesture {
            withAnimation(.easeOut(duration: 0.35)) {
                isVisible = false
            }
        }
        .onAppear {
            CSQ.trackScreenview("Splash")
            // Logo entrance
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.1)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            // Tagline fade
            withAnimation(.easeIn(duration: 0.5).delay(0.5)) {
                taglineOpacity = 1.0
            }
            // Progress bar — fills over 8 seconds giving plenty of talk time
            withAnimation(.linear(duration: 8.0).delay(0.3)) {
                barProgress = 1.0
            }
            // Pulsing tap hint
            withAnimation(.easeIn(duration: 0.4).delay(0.8)) {
                pulseOpacity = 1.0
            }
            startPulse()
        }
    }

    private func startPulse() {
        // Gentle breathing animation on the tap hint after initial appearance
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                pulseOpacity = 0.45
            }
        }
    }
}
