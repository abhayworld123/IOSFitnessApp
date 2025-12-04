import SwiftUI

struct OnboardingPageView: View {
    let page: OnboardingPage
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Icon/Illustration
            ZStack {
                // Gradient background circle
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: page.gradientColors),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 200, height: 200)
                    .blur(radius: 40)
                    .opacity(0.3)
                
                // Icon
                Image(systemName: page.iconName)
                    .font(.system(size: 80, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: page.gradientColors),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .symbolEffect(.pulse, options: .repeating)
            }
            .frame(height: 250)
            .padding(.bottom, 40)
            
            // Title
            Text(page.title)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(AppConstants.Colors.textPrimary(colorScheme: colorScheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 16)
            
            // Description
            Text(page.description)
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 40)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    OnboardingPageView(page: OnboardingPage.pages[0])
}

