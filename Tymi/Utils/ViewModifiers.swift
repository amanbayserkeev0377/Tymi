import SwiftUI

// MARK: - SectionCardModifier
struct SectionCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color.black.opacity(0.1) : Color.white.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(colorScheme == .dark
                                    ? Color.white.opacity(0.1)
                                    : Color.black.opacity(0.1),
                                    lineWidth: 0.5)
                    )
                    .shadow(radius: 0.5)
            )
            .padding(.horizontal)
    }
}

extension View {
    func sectionCard() -> some View {
        self.modifier(SectionCardModifier())
    }
}

// Вспомогательная структура для работы с темами приложения
struct ThemeHelper {
    // Преобразование индекса темы в ColorScheme
    static func colorSchemeFromThemeMode(_ themeMode: Int) -> ColorScheme? {
        switch themeMode {
        case 0: return nil        // System
        case 1: return .light     // Light
        case 2: return .dark      // Dark
        default: return nil
        }
    }
}
