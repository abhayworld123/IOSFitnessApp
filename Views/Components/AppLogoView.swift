import SwiftUI

/// Brand logo from Assets (`Logo` wordmark or `LogoMark` icon).
struct AppLogoView: View {
    enum Style {
        case wordmark
        case mark
    }

    var style: Style = .wordmark
    var maxWidth: CGFloat = 260
    var markSize: CGFloat = 72

    private var assetName: String {
        style == .wordmark ? "Logo" : "LogoMark"
    }

    var body: some View {
        Group {
            if style == .wordmark {
                Image(assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: maxWidth)
            } else {
                Image(assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: markSize, height: markSize)
            }
        }
        .accessibilityLabel("Trakkit")
    }
}

#Preview {
    VStack(spacing: 24) {
        AppLogoView(style: .wordmark)
        AppLogoView(style: .mark, markSize: 80)
    }
    .padding()
}
