import SwiftUI

struct OnboardingPage: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let iconName: String
    let gradientColors: [Color]
    
    static let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Welcome to Fitness App",
            description: "Transform your body and achieve your fitness goals with personalized workout plans designed just for you.",
            iconName: "figure.run",
            gradientColors: [AppConstants.Colors.primary, AppConstants.Colors.secondary]
        ),
        OnboardingPage(
            title: "Extensive Workout Library",
            description: "Access hundreds of professional workout videos covering all fitness levels and goals. From cardio to strength training.",
            iconName: "dumbbell.fill",
            gradientColors: [Color(hex: "#FF6B35"), Color(hex: "#F7931E")]
        ),
        OnboardingPage(
            title: "Personalized Plans",
            description: "Get custom workout plans tailored to your fitness level, schedule, and goals. Stay motivated with structured programs.",
            iconName: "calendar.badge.clock",
            gradientColors: [Color(hex: "#004E89"), Color(hex: "#0066CC")]
        ),
        OnboardingPage(
            title: "Track Your Progress",
            description: "Monitor your workouts, track your achievements, and see your fitness journey unfold with detailed analytics.",
            iconName: "chart.line.uptrend.xyaxis",
            gradientColors: [Color(hex: "#00C896"), Color(hex: "#00A878")]
        ),
        OnboardingPage(
            title: "Ready to Get Started?",
            description: "Join thousands of users who are already transforming their lives. Let's begin your fitness journey today!",
            iconName: "arrow.right.circle.fill",
            gradientColors: [AppConstants.Colors.primary, AppConstants.Colors.secondary]
        )
    ]
}

