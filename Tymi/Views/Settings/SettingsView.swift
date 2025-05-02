import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @AppStorage("themeMode") private var themeMode: Int = 0 // 0 - System, 1 - Light, 2 - Dark
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true
    
    private var sectionBackground: some View {
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
    }
    
    private let sectionPadding = EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
    private var divider: some View {
        Divider().padding(.leading, 48)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Основные настройки
                    VStack(spacing: 0) {
                        // Habits
                        HabitsSection()
                            .padding(sectionPadding)
                        
                        divider
                        
                        // Language
                        LanguageSection()
                            .padding(sectionPadding)
                        
                        divider
                        
                        // Appearance
                        AppearanceSection()
                            .padding(sectionPadding)
                        
                        divider
                        
                        // Week Start
                        WeekStartSection()
                            .padding(sectionPadding)
                        
                        divider
                        
                        // Notifications
                        NotificationsSection()
                            .padding(sectionPadding)
                            
                        divider
                            
                        // Haptics
                        HapticsSection()
                            .padding(sectionPadding)
                    }
                    .background(sectionBackground)
                    .padding(.horizontal)
                    
                    // About
                    VStack(spacing: 0) {
                        AboutSection()
                            .padding(sectionPadding)
                    }
                    .background(sectionBackground)
                    .padding(.horizontal)
                    
                    Spacer(minLength: 40)
                }
                .padding(.top, 16)
            }
            .navigationTitle("settings".localized)
            .navigationBarTitleDisplayMode(.large)
        }
        // Apply selected colorscheme
        .preferredColorScheme(getPreferredColorScheme())
        .onChange(of: notificationsEnabled) { _, newValue in
            if !newValue {
                NotificationManager.shared.updateAllNotifications(modelContext: modelContext)
            }
        }
    }
        
    // MARK: - Helpers
    private func getPreferredColorScheme() -> ColorScheme? {
        return ThemeHelper.colorSchemeFromThemeMode(themeMode)
    }
}

#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
}
