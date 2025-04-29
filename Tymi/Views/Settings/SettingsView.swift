import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("themeMode") private var themeMode: Int = 0 // 0 - System, 1 - Light, 2 - Dark
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Секция внешнего вида
                    AppearanceSection()
                        .settingsCard()
                    
                    // Секция языка
                    LanguageSection()
                        .settingsCard()
                    
                    // Секция уведомлений
                    NotificationsSection()
                        .settingsCard()
                    
                    Spacer(minLength: 40)
                }
                .padding(.top, 16)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
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
