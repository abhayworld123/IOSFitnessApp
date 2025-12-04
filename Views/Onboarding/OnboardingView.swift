import SwiftUI

struct OnboardingView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var currentPage = 0
    @Binding var isPresented: Bool
    
    private let pages = OnboardingPage.pages
    private var isLastPage: Bool {
        currentPage == pages.count - 1
    }
    
    var body: some View {
        ZStack {
            // Background
            AppConstants.Colors.background(colorScheme: colorScheme)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Skip Button (top right)
                HStack {
                    Spacer()
                    if !isLastPage {
                        Button(action: {
                            completeOnboarding()
                        }) {
                            Text("Skip")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                        }
                    }
                }
                .padding(.top, 20)
                .padding(.trailing, 20)
                
                // Page Content
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)
                .onChange(of: currentPage) { newValue in
                    HapticFeedback.impact(style: .light)
                }
                
                // Page Indicators & Navigation
                VStack(spacing: 24) {
                    // Page Indicators
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Circle()
                                .fill(
                                    index == currentPage
                                    ? AppConstants.Colors.primary
                                    : AppConstants.Colors.textSecondary(colorScheme: colorScheme).opacity(0.3)
                                )
                                .frame(width: index == currentPage ? 24 : 8, height: 8)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                        }
                    }
                    .padding(.bottom, 8)
                    
                    // Navigation Button
                    Button(action: {
                        if isLastPage {
                            completeOnboarding()
                        } else {
                            withAnimation {
                                currentPage += 1
                            }
                            HapticFeedback.impact(style: .light)
                        }
                    }) {
                        HStack {
                            Text(isLastPage ? "Get Started" : "Next")
                                .font(.system(size: 18, weight: .semibold))
                            
                            if !isLastPage {
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    AppConstants.Colors.primary,
                                    AppConstants.Colors.secondary
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(AppConstants.Design.cornerRadius)
                        .shadow(color: AppConstants.Colors.primary.opacity(0.4), radius: 10, x: 0, y: 5)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            AnalyticsService.shared.trackScreenView("Onboarding", screenClass: "OnboardingView")
        }
    }
    
    private func completeOnboarding() {
        // Mark onboarding as completed
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        HapticFeedback.success()
        
        // Dismiss onboarding
        withAnimation(.easeInOut(duration: 0.5)) {
            isPresented = false
        }
    }
}

#Preview {
    OnboardingView(isPresented: .constant(true))
}

