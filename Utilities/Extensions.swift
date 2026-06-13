import SwiftUI

// MARK: - View Modifiers
struct GradientBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        AppConstants.Colors.primary,
                        AppConstants.Colors.secondary
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
}

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppConstants.Colors.cardBackground)
            .cornerRadius(AppConstants.Design.cornerRadius)
            .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

extension View {
    func gradientBackground() -> some View {
        modifier(GradientBackgroundModifier())
    }
    
    func cardStyle() -> some View {
        modifier(CardModifier())
    }
}

// MARK: - String Extensions
extension String {
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }
    
    var isValidPassword: Bool {
        let minLength = 8
        let hasUppercase = self.contains(where: { $0.isUppercase })
        let hasNumber = self.contains(where: { $0.isNumber })
        return self.count >= minLength && hasUppercase && hasNumber
    }

    var passwordValidationError: String? {
        let minLength = 8
        guard self.count >= minLength else {
            return "Password must be at least 8 characters"
        }

        let hasUppercase = self.contains(where: { $0.isUppercase })
        let hasNumber = self.contains(where: { $0.isNumber })
        guard hasUppercase && hasNumber else {
            return "Password must include at least 1 uppercase letter and 1 number"
        }

        return nil
    }
    
    var isValidName: Bool {
        return !self.trimmingCharacters(in: .whitespaces).isEmpty && self.count >= 2
    }
}

// MARK: - Haptic Feedback
struct HapticFeedback {
    static func impact(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
}

