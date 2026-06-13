import SwiftUI

struct NewOnboardingScreen1View: View {
    let page: NewOnboardingPage
    let onContinue: () -> Void
    
    var body: some View {
        ZStack {
            // Background Image - From Assets.xcassets or Bundle
            Group {
                if let uiImage = UIImage(named: page.backgroundImage) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    // Fallback: Try loading from Public/Images
                    Image("background_onboarding1")
                        .resizable()
                        .scaledToFill()
                }
            }
            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
            .clipped()
            .ignoresSafeArea()
            
            // Dark Overlay - stronger opacity for better text readability
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color.black.opacity(0.5), location: 0.0),
                    .init(color: Color.black.opacity(0.65), location: 0.5),
                    .init(color: Color.black.opacity(0.75), location: 1.0)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Content
            VStack(spacing: 0) {
                // Top Logo
                HStack {
                    AppLogoView(style: .mark, markSize: 46)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 50)
                
                Spacer()
                
                // Center Title - Adjusted size to match Figma
                Text(page.title)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .padding(.horizontal, 40)
                
                Spacer()
                
                // Bottom Section
                VStack(spacing: 20) {
                    Text(page.subtitle)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.95))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    // Start Tracking Button
                    Button(action: {
                        HapticFeedback.impact()
                        onContinue()
                    }) {
                        Text(page.buttonText)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                Color(hex: "#E89A3C") // Golden/Orange color from screenshot
                            )
                            .cornerRadius(27)
                    }
                    .padding(.horizontal, 30)
                }
                .padding(.bottom, 50)
            }
        }
    }
}

#Preview {
    NewOnboardingScreen1View(
        page: NewOnboardingPage.pages[0],
        onContinue: {}
    )
}
