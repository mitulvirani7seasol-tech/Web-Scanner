//
//  AppColors.swift
//  WebScanner
//

import SwiftUI

struct AppColors {
    // MARK: - Brand / Primary
    static let primaryGreen = Color(hex: "#05974D")
    static let primaryGreenDark = Color(hex: "#007C36")
    static let primaryGreenLight = Color(hex: "#E5F5EC")
    static let gradientTopGreen = Color(hex: "#17AE60")
    static let gradientBottomGreen = Color(hex: "#007C36")
    
    static var brandGradient: LinearGradient {
        LinearGradient(
            colors: [gradientTopGreen, gradientBottomGreen],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    // MARK: - Dynamic Semantic Colors (Supports Dark & Light Mode)
    
    /// Main screen background color
    static func background(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "#0B0E14") : Color(hex: "#E8EFF7")
    }
    
    /// Card / Container surface color
    static func cardBackground(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "#161B22") : Color.white
    }
    
    /// Card border / stroke color
    static func cardStroke(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "#21262D") : Color(hex: "#E2E8F0").opacity(0.8)
    }
    
    static func card(for scheme: ColorScheme) -> Color {
        cardBackground(for: scheme)
    }
    
    static func border(for scheme: ColorScheme) -> Color {
        cardStroke(for: scheme)
    }
    
    /// Primary text color
    static func textPrimary(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white : Color(hex: "#121212")
    }
    
    /// Secondary / muted text color
    static func textSecondary(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "#747474") : Color(hex: "#919593")
    }
    
    /// Tab bar background color
    static func tabBarBackground(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "#161B22") : Color.white
    }
    
    /// Sub-tab / pill unselected background
    static func pillBackground(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "#21262D") : Color(hex: "#E5E9F0")
    }
    
    static func SaticColor(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white : Color.black
    }
    
}

// MARK: - Color Hex Initializer
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
            (a, r, g, b) = (1, 1, 1, 0)
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
