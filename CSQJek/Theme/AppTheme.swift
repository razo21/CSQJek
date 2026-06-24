import SwiftUI

// MARK: - CSQJek App Theme
// Singapore super-app design — Contentsquare official brand palette (2024 guidelines)
// Source: "Contentsquare - 2024 Presentation Template.pptx" — verified from theme XML + visual slides

extension Color {
    // ── Contentsquare OFFICIAL brand palette (2024) ──────────────────────────────
    // These are the authoritative CS brand colors extracted from the official
    // 2024 presentation template. Use these for all brand-facing UI elements.

    /// PRIMARY CS brand blue — dominant hero color, key backgrounds, main accent
    static let csElectricBlue = Color(hex: "#3640E8")

    /// CS dark navy/indigo — headlines on light backgrounds, dark hero slides
    static let csDeepNavy     = Color(hex: "#1C1263")

    /// CS brand amber/gold — secondary accent, rewards, highlights
    static let csAmber        = Color(hex: "#FBAE40")

    /// CS brand coral/orange — warm CTA accent, section markers
    static let csCoral        = Color(hex: "#F26B43")

    /// CS brand cream/yellow — light slide backgrounds, card fills
    static let csCream        = Color(hex: "#FFEEB0")

    /// CS light lavender/periwinkle — soft blue tint, inactive states
    static let csLavender     = Color(hex: "#CDCFF9")

    /// CS light peach tint — soft warm backgrounds
    static let csLightPeach   = Color(hex: "#FEEDE7")

    /// App screen background — near-cream, easy on eyes in mobile context
    static let csOffWhite     = Color(hex: "#FFFDF5")

    // ── Backward-compatibility aliases (deprecated — migrate to new names above) ─
    // These existed before the 2024 brand audit. Kept to avoid breaking existing code.
    // Do not use in new code — use the official tokens above instead.
    static let csBrandRed   = Color(hex: "#F26B43")   // → use csCoral
    static let csMidNavy    = Color(hex: "#1C1263")   // → use csDeepNavy
    static let csFreshGreen = Color(hex: "#A6EF78")   // non-brand, promo-only
    static let csDarkGreen  = Color(hex: "#004C3D")   // non-brand, promo-only
    static let csLightBlue  = Color(hex: "#CDCFF9")   // → use csLavender
    static let csLightPink  = Color(hex: "#FEEDE7")   // → use csLightPeach

    // ── CSQJek app palette (service-specific, Singapore-tuned) ──
    // Primary coral/salmon brand colors
    static let csqPrimary       = Color(hex: "#FF6652")
    static let csqPrimaryLight  = Color(hex: "#FF8F80")
    static let csqPrimaryDark   = Color(hex: "#E04D3A")
    static let csqPrimaryPastel = Color(hex: "#FFF0EE")

    // Neutrals
    static let csqBackground    = Color(hex: "#F8F3EF")
    static let csqSurface       = Color(hex: "#FFFFFF")
    static let csqBorder        = Color(hex: "#E8E0DA")

    // Text
    static let csqTextPrimary   = Color(hex: "#1C1C2E")
    static let csqTextSecondary = Color(hex: "#6B7280")
    static let csqTextTertiary  = Color(hex: "#9CA3AF")

    // Semantic
    static let csqSuccess       = Color(hex: "#10B981")
    static let csqWarning       = Color(hex: "#F59E0B")
    static let csqError         = Color(hex: "#EF4444")
    static let csqInfo          = Color(hex: "#3B82F6")

    // Service category colors
    static let csqRideBlue      = Color(hex: "#4F7FFF")
    static let csqGroceryGreen  = Color(hex: "#2AC09A")   // general service-green accent — NOT the CSQMart brand

    // CSQMart brand palette — sampled from the CSQMart poster. Use ONLY inside the CSQMart experience.
    static let csqMartGreen        = Color(hex: "#2E925C")   // primary action green (matches the art background)
    static let csqMartGreenDark    = Color(hex: "#1F6E44")   // gradients / pressed
    static let csqMartGreenPastel  = Color(hex: "#E6F4EC")   // tint backgrounds
    static let csqMartForest       = Color(hex: "#14613A")   // deep green — headings / accents (matches "delivered")
    static let csqMartAmber        = Color(hex: "#F2B83C")   // warm accent — deals / highlights (matches the underline)
    static let csqFoodOrange    = Color(hex: "#FF8C42")
    static let csqExpressPurple = Color(hex: "#9B6DFF")
    static let csqTelcoTeal     = Color(hex: "#0EA5E9")   // CSQMobile — Phase 4
    static let csqNavy          = Color(hex: "#1C1C2E")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

// MARK: - Typography
struct AppFont {
    static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
    static func mono(_ size: CGFloat) -> Font {
        .system(size: size, weight: .medium, design: .monospaced)
    }
}

// MARK: - Spacing
struct AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Corner Radius
struct AppRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let full: CGFloat = 999
}

// MARK: - Shadow
struct AppShadow {
    static let card = Shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
    static let button = Shadow(color: Color.csqPrimary.opacity(0.35), radius: 10, x: 0, y: 4)
    static let subtle = Shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
}

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Reusable Components

struct CSQButton: View {
    let title: String
    let icon: String?
    let style: ButtonStyle
    let action: () -> Void

    enum ButtonStyle { case primary, secondary, outline, ghost }

    init(_ title: String, icon: String? = nil, style: ButtonStyle = .primary, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.full))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.full)
                    .stroke(borderColor, lineWidth: style == .outline ? 2 : 0)
            )
            .shadow(color: style == .primary ? Color.csqPrimary.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .primary: return .csqPrimary
        case .secondary: return .csqPrimaryPastel
        case .outline: return .clear
        case .ghost: return .clear
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary: return .white
        case .secondary: return .csqPrimary
        case .outline: return .csqPrimary
        case .ghost: return .csqTextSecondary
        }
    }

    private var borderColor: Color {
        style == .outline ? .csqPrimary : .clear
    }
}

struct CSQCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = AppSpacing.md

    init(padding: CGFloat = AppSpacing.md, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.padding = padding
    }

    var body: some View {
        content
            .padding(padding)
            .background(Color.csqSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
            .shadow(color: Color.black.opacity(0.07), radius: 12, x: 0, y: 4)
    }
}

struct CSQSearchBar: View {
    @Binding var text: String
    let placeholder: String
    var isInteractive: Bool = true

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.csqTextTertiary)
                .font(.system(size: 16, weight: .medium))
            if isInteractive {
                TextField(placeholder, text: $text)
                    .font(AppFont.body(15))
                    .foregroundColor(.csqTextPrimary)
            } else {
                Text(placeholder)
                    .font(AppFont.body(15))
                    .foregroundColor(.csqTextTertiary)
                Spacer()
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(Color.csqBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.full))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.full)
                .stroke(Color.csqBorder, lineWidth: 1)
        )
    }
}

struct CSQChip: View {
    let label: String
    let isSelected: Bool
    var tint: Color = .csqPrimary   // selected-state colour; override per section (e.g. CSQMart green)
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? tint : Color.csqBackground)
                .foregroundColor(isSelected ? .white : .csqTextSecondary)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.full))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.full)
                        .stroke(isSelected ? Color.clear : Color.csqBorder, lineWidth: 1)
                )
        }
    }
}

// MARK: - Rating Stars
struct StarRating: View {
    let rating: Double
    var size: CGFloat = 12

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: Double(star) <= rating ? "star.fill" : "star")
                    .font(.system(size: size))
                    .foregroundColor(Double(star) <= rating ? .csqWarning : .csqBorder)
            }
        }
    }
}

// MARK: - CSQJek Logo Component
// Used on splash screen and home header.
// Recreates the brand mark: rounded-square icon with a C-smiley, plus "CSQJek" wordmark.
// Style.white  → all white (use on coral/dark backgrounds)
// Style.color  → gradient wordmark (use on white/light backgrounds)

struct CSQJekLogoView: View {
    enum LogoStyle { case white, color }
    var style: LogoStyle = .white
    var iconSize: CGFloat = 44
    var showWordmark: Bool = true

    var body: some View {
        HStack(spacing: 10) {
            // Icon mark — rounded square with C smiley
            ZStack {
                RoundedRectangle(cornerRadius: iconSize * 0.26)
                    .fill(LinearGradient(
                        colors: [Color(hex: "#FF9147"), Color(hex: "#E02800")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: iconSize, height: iconSize)

                Canvas { context, size in
                    let cx = size.width / 2
                    let cy = size.height / 2
                    let r  = size.width * 0.30
                    let lw = size.width * 0.135

                    // C arc — open on the right (from ~40° to ~315°)
                    var arc = Path()
                    arc.addArc(center: CGPoint(x: cx, y: cy),
                               radius: r,
                               startAngle: .degrees(42),
                               endAngle: .degrees(318),
                               clockwise: false)
                    context.stroke(arc, with: .color(.white),
                                   style: StrokeStyle(lineWidth: lw, lineCap: .round))

                    // Eye dot inside the C opening — gives smiley character
                    let eyeX = cx + r * 0.48
                    let eyeY = cy - r * 0.30
                    let er: CGFloat = size.width * 0.055
                    context.fill(
                        Path(ellipseIn: CGRect(x: eyeX - er, y: eyeY - er, width: er*2, height: er*2)),
                        with: .color(.white)
                    )
                }
                .frame(width: iconSize, height: iconSize)
            }

            if showWordmark {
                switch style {
                case .white:
                    Text("CSQJek")
                        .font(.system(size: iconSize * 0.66, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(-0.3)
                case .color:
                    HStack(spacing: 0) {
                        Text("CSQ")
                            .foregroundColor(Color(hex: "#E02800"))
                        Text("Jek")
                            .foregroundColor(Color(hex: "#FF8C42"))
                    }
                    .font(.system(size: iconSize * 0.66, weight: .bold, design: .rounded))
                    .tracking(-0.3)
                }
            }
        }
    }
}

