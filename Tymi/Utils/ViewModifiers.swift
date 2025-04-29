import SwiftUI

// MARK: - SectionCardModifier for NewHabitView
struct SectionCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        content
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color.black.opacity(0.1) : Color.white.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(colorScheme == .dark
                                    ? Color.gray.opacity(0.1)
                                    : Color.gray.opacity(0.05),
                                    lineWidth: 1)
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

// MARK: - SettingsSections
struct SettingsSectionCard: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        content
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(colorScheme == .dark ? Color.black.opacity(0.15) : Color.white.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(colorScheme == .dark
                                    ? Color.gray.opacity(0.15)
                                    : Color.gray.opacity(0.1),
                                    lineWidth: 1)
                    )
                    .shadow(radius: 0.3)
            )
            .padding(.horizontal)
    }
}

extension View {
    func settingsCard() -> some View {
        self.modifier(SettingsSectionCard())
    }
}

struct SettingsIconStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 18))
            .frame(width: 24, height: 24)
            .foregroundStyle(.primary)
    }
}

extension View {
    func settingsIcon() -> some View {
        self.modifier(SettingsIconStyle())
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
