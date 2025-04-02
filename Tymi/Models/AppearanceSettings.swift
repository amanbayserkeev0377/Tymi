import SwiftUI

enum ColorSchemePreference: String, CaseIterable {
    case automatic
    case light
    case dark
    
    var colorScheme: ColorScheme? {
        switch self {
        case .automatic: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
    
    var title: String {
        switch self {
        case .automatic: return "Automatic"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}

enum AppIconPreference: String, CaseIterable {
    case automatic
    case light
    case dark
    
    var iconName: String? {
        switch self {
        case .automatic: return nil
        case .light: return "Tymi_light"
        case .dark: return "Tymi_dark"
        }
    }
    
    var title: String {
        switch self {
        case .automatic: return "Automatic"
        case .light: return "Light icon"
        case .dark: return "Dark icon"
        }
    }
} 