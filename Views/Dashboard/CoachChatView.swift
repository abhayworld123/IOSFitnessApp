import SwiftUI

struct CoachChatView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var authViewModel: AuthViewModel
    @StateObject private var viewModel = CoachChatViewModel()

    private var firstName: String {
        let raw = (authViewModel.currentUser?.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return "there" }
        return raw.split(separator: " ").first.map(String.init) ?? raw
    }

    private var activeConfig: CoachPublicConfig {
        viewModel.config ?? CoachPublicConfig.default()
    }

    private var personalizationName: String? {
        let n = firstName
        return n == "there" ? nil : n
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppConstants.TrakkitHome.background
                    .ignoresSafeArea()

                if !viewModel.isAPIConfigured {
                    configureAPIEmptyState
                } else {
                    chatContent
                }
            }
            .navigationTitle("Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(AppConstants.TrakkitHome.accentOrange)
                }
            }
        }
        .task {
            await viewModel.loadConfigIfNeeded()
        }
    }

    private var configureAPIEmptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 44))
                .foregroundStyle(AppConstants.TrakkitHome.secondaryText)
            Text("Exercise API URL is not set")
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppConstants.TrakkitHome.heading)
            Text("Add ExerciseAPIBaseURL in Info.plist to use Aura AI Coach (same domain as exercise catalog).")
                .font(.subheadline)
                .foregroundStyle(AppConstants.TrakkitHome.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Close") { dismiss() }
                .font(.body.weight(.semibold))
                .foregroundStyle(AppConstants.TrakkitHome.accentOrange)
                .padding(.top, 8)
        }
    }

    private var chatContent: some View {
        VStack(spacing: 0) {
            if let err = viewModel.errorBanner, !err.isEmpty {
                Text(err)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.08))
            }

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        auraHeaderRow
                        welcomeBlock
                        disclaimerBlock
                        greetingBubble
                        chipRow

                        ForEach(viewModel.bubbles) { bubble in
                            bubbleView(bubble)
                                .id(bubble.id)
                        }

                        if viewModel.isSending {
                            HStack {
                                thinkingBubble
                                Spacer(minLength: 50)
                            }
                            .id("thinking")
                        }

                        Color.clear.frame(height: 12)
                            .id("bottomAnchor")
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                }
                .onChange(of: viewModel.bubbles.count) { _, _ in
                    scrollToBottom(proxy: proxy)
                }
                .onChange(of: viewModel.isSending) { _, sending in
                    if sending {
                        scrollToBottom(proxy: proxy)
                    }
                }
            }

            composerBar
        }
    }

    private var auraHeaderRow: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "#8B5CF6"),
                                Color(hex: "#6366F1"),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                Text(trainerInitial)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                Image(systemName: "sparkle")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(5)
                    .background(Circle().fill(Color.black.opacity(0.2)))
                    .offset(x: 18, y: -18)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(activeConfig.trainerName)
                    .font(.headline)
                    .foregroundStyle(AppConstants.TrakkitHome.heading)
                Text(activeConfig.coachSubtitle)
                    .font(.caption)
                    .foregroundStyle(AppConstants.TrakkitHome.secondaryText)
            }
            Spacer(minLength: 0)
        }
    }

    private var trainerInitial: String {
        let t = activeConfig.trainerName.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.first.map { String($0).uppercased() } ?? "A"
    }

    private var welcomeBlock: some View {
        Text(activeConfig.welcomeTagline)
            .font(.title3.weight(.semibold))
            .multilineTextAlignment(.center)
            .foregroundStyle(AppConstants.TrakkitHome.heading)
            .frame(maxWidth: .infinity)
    }

    private var disclaimerBlock: some View {
        VStack(spacing: 6) {
            Text(activeConfig.welcomeDisclaimer)
                .font(.caption)
                .foregroundStyle(AppConstants.TrakkitHome.secondaryText)
                .multilineTextAlignment(.center)

            Button("Learn more") {
                guard let url = activeConfig.learnMoreURL else { return }
                openURL(url)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(AppConstants.TrakkitHome.accentOrange)
        }
        .frame(maxWidth: .infinity)
    }

    private var greetingBubble: some View {
        HStack {
            incomingBubble(text: "Hi \(firstName)! How can I help you today?")
            Spacer(minLength: 40)
        }
    }

    private func bubbleView(_ bubble: CoachChatBubble) -> some View {
        Group {
            switch bubble.role {
            case .assistant:
                HStack {
                    incomingBubble(text: bubble.text)
                    Spacer(minLength: 50)
                }
            case .user:
                HStack {
                    Spacer(minLength: 50)
                    outgoingBubble(text: bubble.text)
                }
            }
        }
    }

    private func incomingBubble(text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(AppConstants.TrakkitHome.heading)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white)
                    .shadow(color: AppConstants.TrakkitHome.cardShadowColor, radius: 6, x: 0, y: 2)
            )
    }

    private var thinkingBubble: some View {
        HStack(spacing: 8) {
            ProgressView()
                .scaleEffect(0.85)
            Text("Aura is thinking…")
                .font(.subheadline)
                .foregroundStyle(AppConstants.TrakkitHome.secondaryText)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white)
                .shadow(color: AppConstants.TrakkitHome.cardShadowColor, radius: 6, x: 0, y: 2)
        )
    }

    private func outgoingBubble(text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(AppConstants.TrakkitHome.accentOrange)
            )
    }

    private var chipRow: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: 10
        ) {
            ForEach(Array(activeConfig.quickChips.enumerated()), id: \.offset) { _, chip in
                Button {
                    HapticFeedback.impact()
                    Task { await viewModel.sendChipPrompt(chip, userFirstName: personalizationName) }
                } label: {
                    Text(chip)
                        .font(.footnote.weight(.medium))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(AppConstants.TrakkitHome.accentOrange)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(AppConstants.TrakkitHome.accentOrange.opacity(0.45), lineWidth: 1)
                                .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
                        )
                }
                .disabled(viewModel.isSending)
                .opacity(viewModel.isSending ? 0.5 : 1)
            }
        }
        .padding(.top, 4)
    }

    private var composerBar: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("Ask AI Coach anything…", text: $viewModel.inputText, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...5)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(Color.white)
                        .shadow(color: AppConstants.TrakkitHome.cardShadowColor, radius: 4, x: 0, y: 1)
                )

            Button {
                HapticFeedback.impact()
                Task { await viewModel.sendMessage(userFirstName: personalizationName) }
            } label: {
                Group {
                    if viewModel.isSending {
                        ProgressView()
                            .tint(AppConstants.TrakkitHome.accentOrange)
                            .scaleEffect(1.05)
                            .frame(width: 38, height: 38)
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color.white, AppConstants.TrakkitHome.accentOrange)
                            .font(.system(size: 38))
                    }
                }
            }
            .disabled(
                viewModel.isSending
                    || viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            )
            .opacity(
                viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    && !viewModel.isSending ? 0.35 : 1
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppConstants.TrakkitHome.background.opacity(0.98))
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.25)) {
            proxy.scrollTo("bottomAnchor", anchor: .bottom)
        }
    }
}

#Preview("Coach Chat") {
    CoachChatView()
        .environmentObject(AuthViewModel())
}
