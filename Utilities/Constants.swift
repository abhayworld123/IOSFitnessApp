import SwiftUI

struct AppConstants {
    // MARK: - Colors
    struct Colors {
        static let primary = Color(hex: "#FF6B35")
        static let secondary = Color(hex: "#004E89")
        static let error = Color.red
        static let success = Color.green
        
        // Static colors (backward compatible - defaults to dark theme)
        static let background = Color.darkBackground
        static let cardBackground = Color.darkCardBackground
        static let textPrimary = Color.darkTextPrimary
        static let textSecondary = Color.darkTextSecondary
        
        // Theme-aware color getters (use these in views with @Environment(\.colorScheme))
        static func background(colorScheme: ColorScheme) -> Color {
            Color.adaptiveBackground(colorScheme: colorScheme)
        }
        
        static func cardBackground(colorScheme: ColorScheme) -> Color {
            Color.adaptiveCardBackground(colorScheme: colorScheme)
        }
        
        static func textPrimary(colorScheme: ColorScheme) -> Color {
            Color.adaptiveTextPrimary(colorScheme: colorScheme)
        }
        
        static func textSecondary(colorScheme: ColorScheme) -> Color {
            Color.adaptiveTextSecondary(colorScheme: colorScheme)
        }
    }
    
    // MARK: - Design Tokens
    struct Design {
        static let cornerRadius: CGFloat = 16.0
        static let animationDuration: Double = 0.3
        static let cardPadding: CGFloat = 20.0
        static let spacing: CGFloat = 16.0
    }

    /// App Store / home screen display name.
    static let appDisplayName = "Trakkit"
    
    /// Trakkit home (Figma) — light mode tokens for dashboard redesign.
    struct TrakkitHome {
        static let background = Color(hex: "#F5F5F5")
        static let heading = Color(hex: "#1A1A1A")
        static let secondaryText = Color(hex: "#7A7A7A")
        static let accentOrange = Color(hex: "#F39C12")
        static let upcomingGradientStart = Color(hex: "#4A54E1")
        static let upcomingGradientEnd = Color(hex: "#7158E2")
        /// Upcoming session card: left → right (deep blue to blue-violet).
        static let upcomingCardGradientLeading = Color(hex: "#15204A")
        static let upcomingCardGradientTrailing = Color(hex: "#5B48E8")
        static let cardCornerRadius: CGFloat = 22
        static let cardShadowColor = Color.black.opacity(0.06)
        static let cardShadowRadius: CGFloat = 10
        static let cardShadowY: CGFloat = 4
        static let onFireBackground = Color(hex: "#FFE8E8")
        static let onFireText = Color(hex: "#E74C3C")
        /// Streak weekday chips (reference UI).
        static let streakDayCompletedBackground = Color(hex: "#FFE8D6")
        static let streakDayCompletedText = Color(hex: "#CC5500")
        static let streakDayInactiveBackground = Color(hex: "#EFEFEF")
        static let streakDayInactiveText = Color(hex: "#9E9E9E")
    }
    
    /// AI-driven UI (recovery tips, suggested plans, session builder, exercise “AI pick” rows).
    struct TrakkitAI {
        static let cardFill = Color(hex: "#F3F0FF")
        static let cardBorder = Color(hex: "#E4DCFF")
        static let glowTopTrailing = Color(hex: "#E9D5FF")
        static let iconBox = Color(hex: "#8B5CF6")
        static let title = Color(hex: "#7C3AED")
        static let body = Color(hex: "#3D2E2E")
        static let secondaryLabel = Color(hex: "#8E8E8E")
        static let toggleTint = Color(hex: "#8B5CF6")
        /// Slightly stronger for in-list / picker emphasis.
        static let emphasisPurple = Color(hex: "#6D28D9")
        static let rowGradientTop = Color(hex: "#F5F0FF")
        static let rowGradientBottom = Color(hex: "#EDE4FF")
        static let rowBorder = Color(hex: "#DDD0FF")
    }
    
    // MARK: - Firebase Configuration
    // Note: Add your GoogleService-Info.plist to the project
    // Firebase will be initialized in FirebaseService.swift
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

