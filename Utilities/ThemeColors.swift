import SwiftUI

// MARK: - Theme-aware Color Extension
extension Color {
    // Background colors
    static let lightBackground = Color(hex: "#FFFFFF")
    static let darkBackground = Color(hex: "#1A1A1A")
    
    // Card background colors
    static let lightCardBackground = Color(hex: "#F5F5F5")
    static let darkCardBackground = Color(hex: "#2A2A2A")
    
    // Text colors
    static let lightTextPrimary = Color(hex: "#000000")
    static let darkTextPrimary = Color(hex: "#FFFFFF")
    
    static let lightTextSecondary = Color(hex: "#666666")
    static let darkTextSecondary = Color(hex: "#999999")
    
    // Theme-aware computed properties
    static func adaptiveBackground(colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? darkBackground : lightBackground
    }
    
    static func adaptiveCardBackground(colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? darkCardBackground : lightCardBackground
    }
    
    static func adaptiveTextPrimary(colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? darkTextPrimary : lightTextPrimary
    }
    
    static func adaptiveTextSecondary(colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? darkTextSecondary : lightTextSecondary
    }
}

// MARK: - View Modifier for Theme-aware Colors
struct ThemeAwareViewModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var themeManager = ThemeManager.shared
    
    func body(content: Content) -> some View {
        content
            .preferredColorScheme(themeManager.currentTheme.colorScheme)
    }
}

extension View {
    func themeAware() -> some View {
        modifier(ThemeAwareViewModifier())
    }
}


