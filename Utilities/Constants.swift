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

