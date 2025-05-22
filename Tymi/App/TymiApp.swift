import SwiftUI
import SwiftData
import UserNotifications

@main
struct TymiApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme  // Оставляем для отслеживания изменений темы
    
    let container: ModelContainer
    let habitsUpdateService = HabitsUpdateService()
    
    @State private var weekdayPrefs = WeekdayPreferences.shared
    
    init() {
        do {
            // Инициализация базы данных
            let schema = Schema([Habit.self, HabitCompletion.self])
            let modelConfiguration = ModelConfiguration(schema: schema)
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            print("Ошибка инициализации: \(error)")
            fatalError("Не удалось создать ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(habitsUpdateService)
                .environment(weekdayPrefs)
        }
        .modelContainer(container)
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background:
                // Сохраняем данные при уходе в фон
                Task {
                    // Таймер автоматически сохранится в handleBackground,
                    // но на всякий случай сохраняем и в SwiftData
                    HabitTimerService.shared.persistAllCompletionsToSwiftData(modelContext: container.mainContext)
                    HabitCounterService.shared.persistAllCompletionsToSwiftData(modelContext: container.mainContext)
                }
                
            case .active:
                // При возвращении в активное состояние обновляем UI
                habitsUpdateService.triggerUpdate()
                
            case .inactive:
                // Сохраняем данные при неактивном состоянии
                Task {
                    HabitTimerService.shared.persistAllCompletionsToSwiftData(modelContext: container.mainContext)
                    HabitCounterService.shared.persistAllCompletionsToSwiftData(modelContext: container.mainContext)
                }
                
            @unknown default:
                break
            }
        }
    }
}
