import SwiftUI
import ContentsquareSDK

// MARK: - Live Agent Feature
// "New" feature — tracks adoption via CS Product Analytics.
// Funnel: impression → tap → chat_opened → message_sent → session_ended
// Drop this overlay onto any screen's ZStack to instrument it.

// MARK: - CS Event Names (canonical)
enum LiveAgentEvent {
    static let impression     = "live_agent_button_impression"   // FAB appears on screen
    static let tapped         = "live_agent_button_tapped"       // user taps FAB
    static let chatOpened     = "live_agent_chat_opened"         // sheet is fully presented
    static let messageSent    = "live_agent_message_sent"        // user sends any message
    static let chatDismissed  = "live_agent_chat_dismissed"      // user closes sheet
    static let agentTyping    = "live_agent_agent_typing_shown"  // typing indicator displayed
    static let quickReply     = "live_agent_quick_reply_tapped"  // user taps a quick-reply chip
}

// MARK: - LiveAgentButton
// Floating action button — drop into any screen's ZStack overlay.
// Usage:  .overlay(alignment: .bottomTrailing) { LiveAgentButton(screen: "Home") }
struct LiveAgentButton: View {
    let screen: String              // CS property: which screen hosts the button

    @State private var showChat    = false
    @State private var hasTrackedImpression = false
    @State private var isPulsing   = false

    var body: some View {
        Button {
            CSQ.trackEvent(LiveAgentEvent.tapped, properties: [
                "screen":       screen,
                "feature":      "live_agent",
                "is_new_feature": true
            ])
            showChat = true
        } label: {
            ZStack(alignment: .topTrailing) {
                // Main button
                ZStack {
                    // Pulse ring
                    Circle()
                        .fill(Color(hex: "#2563EB").opacity(0.25))
                        .frame(width: isPulsing ? 70 : 56, height: isPulsing ? 70 : 56)
                        .animation(
                            .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                            value: isPulsing
                        )

                    // Button body
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#3B82F6"), Color(hex: "#1D4ED8")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                        .shadow(color: Color(hex: "#2563EB").opacity(0.45), radius: 12, x: 0, y: 6)

                    Image(systemName: "message.fill")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.white)
                }

                // "New" badge
                Text("NEW")
                    .font(.system(size: 8, weight: .black))
                    .foregroundColor(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2.5)
                    .background(Color(hex: "#DC2626"))
                    .clipShape(Capsule())
                    .offset(x: 4, y: -4)
            }
        }
        .accessibilityIdentifier("live_agent_fab_\(screen.lowercased().replacingOccurrences(of: " ", with: "_"))")
        .accessibilityLabel("Chat with a live agent")
        .padding(.trailing, 20)
        .padding(.bottom, 104)   // sits above tab bar
        .onAppear {
            isPulsing = true
            // Fire impression only once per screen appearance
            if !hasTrackedImpression {
                hasTrackedImpression = true
                CSQ.trackEvent(LiveAgentEvent.impression, properties: [
                    "screen":         screen,
                    "feature":        "live_agent",
                    "is_new_feature": true
                ])
            }
        }
        .sheet(isPresented: $showChat) {
            LiveAgentChatSheet(screen: screen)
        }
    }
}

// MARK: - LiveAgentChatSheet
struct LiveAgentChatSheet: View {
    let screen: String

    @Environment(\.dismiss) var dismiss
    @State private var inputText        = ""
    @State private var messages: [AgentMessage] = []
    @State private var isAgentTyping    = false
    @State private var sessionStartedAt = Date()
    @FocusState private var inputFocused: Bool

    // Quick-reply chip options (contextual)
    private let quickReplies = [
        "Track my order",
        "Payment issue",
        "Report a problem",
        "Promotions & deals",
        "Cancel booking",
    ]

    // Opening message shown on appear
    private let openingMessage = AgentMessage(
        id: UUID(),
        role: .agent,
        text: "Hi Jeff! I'm Jek, your CSQJek assistant. How can I help you today?",
        timestamp: Date()
    )

    var body: some View {
        VStack(spacing: 0) {
            // Sheet handle
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.csqBorder)
                .frame(width: 36, height: 4)
                .padding(.top, 10)
                .padding(.bottom, 6)

            // Header
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color(hex: "#3B82F6"), Color(hex: "#1D4ED8")],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 40, height: 40)
                    Image(systemName: "person.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("CSQJek Live Agent")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.csqTextPrimary)
                        // "New" pill
                        Text("NEW")
                            .font(.system(size: 8, weight: .black))
                            .foregroundColor(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color(hex: "#DC2626"))
                            .clipShape(Capsule())
                    }
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.csqSuccess)
                            .frame(width: 7, height: 7)
                        Text("Jek · Typically replies instantly")
                            .font(.system(size: 11))
                            .foregroundColor(.csqTextSecondary)
                    }
                }
                Spacer()
                Button {
                    let duration = Date().timeIntervalSince(sessionStartedAt)
                    CSQ.trackEvent(LiveAgentEvent.chatDismissed, properties: [
                        "screen":           screen,
                        "message_count":    messages.filter { $0.role == .user }.count,
                        "session_duration_sec": Int(duration),
                        "feature":          "live_agent"
                    ])
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.csqTextTertiary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            // Message list
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 12) {
                        // Opening agent message
                        AgentBubble(message: openingMessage)

                        // Quick replies (show only before first user message)
                        if messages.isEmpty {
                            quickReplyChips
                        }

                        // Conversation
                        ForEach(messages) { msg in
                            if msg.role == .agent {
                                AgentBubble(message: msg)
                            } else {
                                UserBubble(message: msg)
                            }
                        }

                        // Typing indicator
                        if isAgentTyping {
                            TypingIndicator()
                                .id("typing")
                                .onAppear {
                                    CSQ.trackEvent(LiveAgentEvent.agentTyping, properties: [
                                        "screen": screen, "feature": "live_agent"
                                    ])
                                }
                        }
                        Color.clear.frame(height: 4).id("bottom")
                    }
                    .padding(16)
                }
                .onChange(of: messages.count) { _, _ in
                    withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
                }
                .onChange(of: isAgentTyping) { _, _ in
                    withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
                }
            }

            Divider()

            // Input bar
            HStack(spacing: 10) {
                TextField("Type a message...", text: $inputText, axis: .vertical)
                    .font(.system(size: 14))
                    .lineLimit(4)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.csqBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .focused($inputFocused)

                Button {
                    sendMessage(inputText)
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(inputText.trimmingCharacters(in: .whitespaces).isEmpty
                                         ? Color.csqTextTertiary
                                         : Color(hex: "#2563EB"))
                }
                .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.csqSurface)
        }
        .background(Color.csqBackground)
        .onAppear {
            CSQ.trackScreenview("Live Agent - Chat")
            CSQ.trackEvent(LiveAgentEvent.chatOpened, properties: [
                "screen":   screen,
                "feature":  "live_agent",
                "is_new_feature": true
            ])
            sessionStartedAt = Date()
        }
    }

    // MARK: - Quick reply chips
    private var quickReplyChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(quickReplies, id: \.self) { reply in
                    Button {
                        CSQ.trackEvent(LiveAgentEvent.quickReply, properties: [
                            "screen":     screen,
                            "reply_text": reply,
                            "feature":    "live_agent"
                        ])
                        sendMessage(reply)
                    } label: {
                        Text(reply)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(hex: "#2563EB"))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Color(hex: "#EFF6FF"))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color(hex: "#BFDBFE"), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
            .padding(.leading, 0)
        }
    }

    // MARK: - Send + auto-reply
    private func sendMessage(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let userMsg = AgentMessage(id: UUID(), role: .user, text: trimmed, timestamp: Date())
        withAnimation { messages.append(userMsg) }
        inputText = ""

        let userMsgCount = messages.filter { $0.role == .user }.count
        CSQ.trackEvent(LiveAgentEvent.messageSent, properties: [
            "screen":            screen,
            "message_index":     userMsgCount,
            "message_length":    trimmed.count,
            "feature":           "live_agent",
            "is_quick_reply":    quickReplies.contains(trimmed)
        ])

        // Agent typing simulation
        isAgentTyping = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            isAgentTyping = false
            let reply = autoReply(for: trimmed, count: userMsgCount)
            let agentMsg = AgentMessage(id: UUID(), role: .agent, text: reply, timestamp: Date())
            withAnimation { messages.append(agentMsg) }
        }
    }

    private func autoReply(for text: String, count: Int) -> String {
        let lower = text.lowercased()
        if lower.contains("track") || lower.contains("order") {
            return "Sure! Your order is currently being prepared and is estimated to arrive in 20–25 minutes. I'll notify you when it's out for delivery."
        } else if lower.contains("payment") || lower.contains("declined") || lower.contains("card") {
            return "I can see there was a payment issue on your last transaction. Let me pull up the details — can you confirm which card you were using?"
        } else if lower.contains("cancel") {
            return "I can help you with a cancellation. Please note that cancellations made after the 5-minute window may incur a small fee. Would you like to proceed?"
        } else if lower.contains("promo") || lower.contains("deal") || lower.contains("discount") {
            return "Great news — you're eligible for the Weekend CBD Rider promo! Use code WEEKEND10 at checkout for S$10 off your next ride."
        } else if lower.contains("report") || lower.contains("problem") || lower.contains("issue") {
            return "I'm sorry to hear you're experiencing an issue. Could you describe what happened so I can escalate this to the right team?"
        } else if count == 1 {
            return "Thanks for reaching out! I'm looking into that for you now. This usually takes just a moment."
        } else {
            return "Understood. I'm checking that for you right now — is there anything else I can help you with while you wait?"
        }
    }
}

// MARK: - Message Model
struct AgentMessage: Identifiable {
    let id: UUID
    enum Role { case user, agent }
    let role: Role
    let text: String
    let timestamp: Date
}

// MARK: - Bubble Views
private struct AgentBubble: View {
    let message: AgentMessage
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [Color(hex: "#3B82F6"), Color(hex: "#1D4ED8")],
                                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 28, height: 28)
                Image(systemName: "person.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(message.text)
                    .font(.system(size: 13))
                    .foregroundColor(.csqTextPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(Color.csqSurface)
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 14, bottomLeadingRadius: 4,
                            bottomTrailingRadius: 14, topTrailingRadius: 14
                        )
                    )
                    .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
                Text(timeString(message.timestamp))
                    .font(.system(size: 10))
                    .foregroundColor(.csqTextTertiary)
            }
            Spacer(minLength: 50)
        }
    }
}

private struct UserBubble: View {
    let message: AgentMessage
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            Spacer(minLength: 50)
            VStack(alignment: .trailing, spacing: 4) {
                Text(message.text)
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(
                        LinearGradient(colors: [Color(hex: "#3B82F6"), Color(hex: "#1D4ED8")],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 14, bottomLeadingRadius: 14,
                            bottomTrailingRadius: 4, topTrailingRadius: 14
                        )
                    )
                Text(timeString(message.timestamp))
                    .font(.system(size: 10))
                    .foregroundColor(.csqTextTertiary)
            }
        }
    }
}

private struct TypingIndicator: View {
    @State private var phase: Int = 0
    private let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [Color(hex: "#3B82F6"), Color(hex: "#1D4ED8")],
                                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 28, height: 28)
                Image(systemName: "person.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.white)
            }
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Color.csqTextTertiary)
                        .frame(width: 7, height: 7)
                        .scaleEffect(phase == i ? 1.4 : 1.0)
                        .animation(.easeInOut(duration: 0.35), value: phase)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.csqSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
            Spacer(minLength: 50)
        }
        .onReceive(timer) { _ in
            phase = (phase + 1) % 3
        }
    }
}

// MARK: - Helper
private func timeString(_ date: Date) -> String {
    let f = DateFormatter()
    f.dateFormat = "h:mm a"
    return f.string(from: date)
}
