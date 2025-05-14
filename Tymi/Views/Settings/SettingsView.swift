import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("themeMode") private var themeMode: Int = 0
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        ReorderHabitsView()
                    } label: {
                        Label("manage_habits".localized, systemImage: "arrow.up.arrow.down")
                    }
                }
                
                Section {
                    AppearanceSection()
                    WeekStartSection()
                    LanguageSection()
                }
                
                Section {
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
