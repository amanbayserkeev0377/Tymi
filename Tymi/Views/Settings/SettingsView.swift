import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("themeMode") private var themeMode: Int = 0 // 0 - System, 1 - Light, 2 - Dark
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // ГРУППА 1: Основные настройки (в одной карточке)
                    VStack(spacing: 0) {
                        // Секция внешнего вида
                        AppearanceSection()
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                        
                        Divider()
                            .padding(.leading, 48)
                        
                        // Секция языка
                        LanguageSection()
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                        
                        Divider()
                            .padding(.leading, 48)
                        
                        // Секция привычек
                        HabitsSection()
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                        
                        Divider()
                            .padding(.leading, 48)
                        
                        // Секция уведомлений
                        NotificationsSection()
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                    }
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
                    
                    // ГРУППА 2: О приложении (отдельная карточка)
                    VStack(spacing: 0) {
                        AboutSection()
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                    }
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
                    
                    Spacer(minLength: 40)
                }
                .padding(.top, 16)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        // Применяем выбранную тему
        .preferredColorScheme(getPreferredColorScheme())
    }
        
    // MARK: - Helpers
    // Метод для определения цветовой схемы на основе выбранной темы
    private func getPreferredColorScheme() -> ColorScheme? {
        return ThemeHelper.colorSchemeFromThemeMode(themeMode)
    }
}

#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
}
