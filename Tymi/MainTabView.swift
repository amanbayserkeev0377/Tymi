import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @AppStorage("themeMode") private var themeMode: Int = 0 // 0 - System, 1 - Light, 2 - Dark
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Вкладка "Главная"
            NavigationStack {
                TodayView()
            }
            .tabItem {
                Label("main_tab_home".localized, systemImage: "house")
            }
            .tag(0)
            
            // Вкладка "Привычки"
            NavigationStack {
                HabitsListView()
            }
            .tabItem {
                Label("main_tab_habits".localized, systemImage: "list.bullet")
            }
            .tag(1)
            
            // Вкладка "Настройки"
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("main_tab_settings".localized, systemImage: "gearshape")
            }
            .tag(2)
        }
        .preferredColorScheme(ThemeHelper.colorSchemeFromThemeMode(themeMode))
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [Habit.self, HabitCompletion.self], inMemory: true)
        .environment(HabitsUpdateService())
}
