import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("themeMode") private var themeMode: Int = 0 // 0 - System, 1 - Light, 2 - Dark
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Секция внешнего вида
                    AppearanceSection()
                        .settingsCard()
                    
                    // Секция уведомлений
                    NotificationsSection()
                        .settingsCard()
                    
                    Spacer(minLength: 40)
                }
                .padding(.top)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    closeButton
                }
            }
        }
        // Применяем выбранную тему
        .preferredColorScheme(getPreferredColorScheme())
    }
    
    // MARK: - UI Components
    
    private var closeButton: some View {
        Button(action: {
            dismiss()
        }) {
            ZStack {
                Circle()
                    .fill(
                        colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white.opacity(0.3)
                    )
                    .frame(width: 26, height: 26)
                Image(systemName: "xmark")
                    .foregroundStyle(
                        colorScheme == .dark ? Color.white.opacity(0.4) : Color.black.opacity(0.4)
                    )
                    .font(.caption2)
                    .fontWeight(.black)
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
