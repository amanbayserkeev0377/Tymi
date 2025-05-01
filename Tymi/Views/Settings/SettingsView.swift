import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @AppStorage("themeMode") private var themeMode: Int = 0 // 0 - System, 1 - Light, 2 - Dark
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 0) {
                        // Appearance
                        AppearanceSection()
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                        
                        Divider()
                            .padding(.leading, 48)
                        
                        // Language
                        LanguageSection()
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                        
                        Divider()
                            .padding(.leading, 48)
                        
                        // Habits
                        HabitsSection()
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                        
                        Divider()
                            .padding(.leading, 48)
                        
                        // Notifications
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
            .navigationTitle("settings".localized)
            .navigationBarTitleDisplayMode(.large)
        }
        // Применяем выбранную тему
        .preferredColorScheme(getPreferredColorScheme())
        .onChange(of: notificationsEnabled) { newValue in
            if !newValue {
                NotificationManager.shared.updateAllNotifications(modelContext: modelContext)
            }
        }
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
