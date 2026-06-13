import SwiftUI

/// Full-screen fallback for failed API calls, offline mode, or other load errors.
struct LoadFailureFallbackView: View {
    var title: String = "Oh no! Something went wrong."
    var message: String = "We couldn't load this right now. Please try again."
    var retryTitle: String = "Retry"
    var onRetry: () -> Void
    var onGoBack: (() -> Void)?

    private let screenBg = Color(hex: "#F2F2F2")
    private let orange = Color(hex: "#EE8924")

    var body: some View {
        ZStack {
            screenBg.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                heroMark
                    .padding(.bottom, 28)

                Text(title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color(hex: "#1C1C1E"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)

                Text(message)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(Color(hex: "#636366"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 12)

                Spacer(minLength: 0)

                VStack(spacing: 18) {
                    Button(action: onRetry) {
                        Text(retryTitle)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(orange)
                            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    }

                    if let onGoBack {
                        Button(action: onGoBack) {
                            Text("Go back")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(hex: "#1C1C1E"))
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }

    private var heroMark: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "#34C759").opacity(0.28))
                .frame(width: 168, height: 168)
                .blur(radius: 52)
                .offset(x: 58, y: -42)

            Circle()
                .fill(Color(hex: "#FFD60A").opacity(0.42))
                .frame(width: 200, height: 200)
                .blur(radius: 58)
                .offset(y: 12)

            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(orange)
                .frame(width: 104, height: 104)
                .shadow(color: orange.opacity(0.38), radius: 16, x: 0, y: 10)

            Image(systemName: "wifi.slash")
                .font(.system(size: 42, weight: .medium))
                .foregroundStyle(.white)
        }
        .frame(height: 148)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Connection problem")
    }
}

#Preview {
    LoadFailureFallbackView(onRetry: {}, onGoBack: {})
}

// MARK: - Loading / error gate

/// Switches between loading, standardized load failure, and success content for remote data.
struct RemoteLoadStateView<Content: View>: View {
    var isLoading: Bool
    /// When non-nil after loading completes, shows ``LoadFailureFallbackView``.
    var loadErrorMessage: String?
    var onRetry: () -> Void
    var onGoBack: (() -> Void)?
    @ViewBuilder var content: () -> Content

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if let err = loadErrorMessage, !err.isEmpty {
                LoadFailureFallbackView(message: err, onRetry: onRetry, onGoBack: onGoBack)
            } else {
                content()
            }
        }
    }
}
