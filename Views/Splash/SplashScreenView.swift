import SwiftUI

struct SplashScreenView: View {
    @Binding var isActive: Bool
    @Environment(\.colorScheme) var colorScheme
    @State private var size = 0.8
    @State private var opacity = 0.5
    @State private var animationCompleted = false
    @State private var startTime: Date?
    @State private var showFallback = false
    private let minimumDisplayTime: TimeInterval = 3.0 // Minimum 3 seconds
    
    var body: some View {
        ZStack {
            // Gradient Background
            LinearGradient(
                gradient: Gradient(colors: [
                    AppConstants.Colors.background(colorScheme: colorScheme),
                    AppConstants.Colors.primary.opacity(0.2),
                    AppConstants.Colors.background(colorScheme: colorScheme)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Show either Lottie Animation OR Fallback, not both
                Group {
                    if showFallback {
                        // Fallback animated icon if Lottie file not found
                        Image(systemName: "figure.run")
                            .font(.system(size: 80))
                            .foregroundColor(AppConstants.Colors.primary)
                            .symbolEffect(.pulse, options: .repeating)
                    } else {
                        // Lottie Animation (looping)
                        LottieView(
                            name: "fitness-splash",
                            loopMode: .loop,
                            animationSpeed: 1.0,
                            onAnimationComplete: {
                                // This won't be called in loop mode, but kept for compatibility
                                handleAnimationComplete()
                            },
                            onAnimationNotFound: {
                                // Animation file not found, show fallback
                                showFallback = true
                            }
                        )
                        .frame(width: 200, height: 200)
                    }
                }
                .scaleEffect(size)
                .opacity(opacity)
                
                // App Name
                Text("Fitness App")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(AppConstants.Colors.textPrimary(colorScheme: colorScheme))
                    .opacity(opacity)
                
                // Tagline (optional)
                Text("Transform Your Body")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
                    .opacity(opacity * 0.8)
            }
        }
        .onAppear {
            // Record start time
            startTime = Date()
            
            // Animate in
            withAnimation(.easeOut(duration: 1.0)) {
                size = 1.0
                opacity = 1.0
            }
            
            // Auto-complete after minimum display time if animation doesn't complete
            DispatchQueue.main.asyncAfter(deadline: .now() + minimumDisplayTime) {
                if !animationCompleted {
                    handleAnimationComplete()
                }
            }
        }
    }
    
    private func handleAnimationComplete() {
        guard !animationCompleted else { return }
        
        // Calculate elapsed time
        let elapsed = startTime.map { Date().timeIntervalSince($0) } ?? 0
        let remainingTime = max(0, minimumDisplayTime - elapsed)
        
        // Wait for minimum display time to pass
        DispatchQueue.main.asyncAfter(deadline: .now() + remainingTime) {
            guard !animationCompleted else { return }
            animationCompleted = true
            
            // Animation completed, trigger fade out
            withAnimation(.easeIn(duration: 0.5)) {
                opacity = 0
                size = 1.2
            }
            
            // Wait for fade out, then mark as complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isActive = false
            }
        }
    }
}

#Preview {
    SplashScreenView(isActive: .constant(true))
}

