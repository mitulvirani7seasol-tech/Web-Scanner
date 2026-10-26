//
//  ThemeManager.swift
//  WebScanner
//

import SwiftUI
import Combine

enum AppTheme: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    
    var id: String { rawValue }
    
    var colorScheme: ColorScheme {
        switch self {
        case .dark: return .dark
        default: return .light
        }
    }
}

@MainActor
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    private let themeKey = "selected_app_theme"
    
    @Published var currentTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: themeKey)
        }
    }
    
    init() {
        if let raw = UserDefaults.standard.string(forKey: themeKey),
           let theme = AppTheme(rawValue: raw) {
            self.currentTheme = theme
        } else {
            self.currentTheme = .light
        }
    }
}
