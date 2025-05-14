import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @AppStorage("themeMode") private var themeMode: Int = 0 // 0 - System, 1 - Light, 2 - Dark
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("home".localized, systemImage: "house")
            }
            .tag(0)
            
            // Statistics
            NavigationStack {
                StatisticsView()
            }
            .tabItem {
                Label("statistics".localized, systemImage: "chart.bar.xaxis")
            }
            .tag(1)
            
            // Settings
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("settings".localized, systemImage: "gearshape")
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
