import SwiftUI

enum ThemeMode: Int, CaseIterable {
    case system = 0
    case light = 1
    case dark = 2
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

struct MainTabView: View {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("themeMode") private var themeMode: ThemeMode = .system
    
    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("home".localized, systemImage: "house.fill")
            }
            
            NavigationStack {
                StatisticsView()
            }
            .tabItem {
                Label("statistics".localized, systemImage: "chart.bar.fill")
            }
            
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("settings".localized, systemImage: "gearshape.fill")
            }
        }
        .preferredColorScheme(themeMode.colorScheme)
        .withAppColor()
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [Habit.self, HabitCompletion.self], inMemory: true)
        .environment(HabitsUpdateService())
}
