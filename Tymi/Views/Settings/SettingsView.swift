import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("themeMode") private var themeMode: Int = 0
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("interface".localized)) {
                    AppearanceSection()
                    WeekStartSection()
                    LanguageSection()
                }
                
                Section(header: Text("notifications_feedback".localized)) {
                    NotificationsSection()
                    HapticsSection()
                }
                
                AboutSection()
            }
            .navigationTitle("settings".localized)
        }
        .preferredColorScheme(ThemeHelper.colorSchemeFromThemeMode(themeMode))
    }
}
