import SwiftUI
import SwiftData

@main
struct TymiApp: App {
    @Environment(\.scenePhase) private var scenePhase
    
    let container: ModelContainer
    let habitsUpdateService = HabitsUpdateService() // Замена HabitsUpdateService
    
    init() {
        do {
            // Инициализация базы данных
            let schema = Schema([Habit.self, HabitCompletion.self])
            let modelConfiguration = ModelConfiguration(schema: schema)
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            // Запрашиваем разрешения на уведомления - без использования async/await
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                if let error = error {
                    print("Ошибка запроса разрешений: \(error)")
                }
                
                DispatchQueue.main.async {
                    UserDefaults.standard.set(granted, forKey: "notificationsEnabled")
                }
            }
        } catch {
            print("Ошибка инициализации: \(error)")
            fatalError("Не удалось создать ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            TodayView()
                .environment(habitsUpdateService) // Внедряем наш упрощенный сервис
        }
        .modelContainer(container)
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background:
                // Сохраняем данные при уходе в фон
                HabitTimerService.shared.persistAllCompletionsToSwiftData(modelContext: container.mainContext)
                HabitCounterService.shared.persistAllCompletionsToSwiftData(modelContext: container.mainContext)
                
            case .active:
                // Запускаем таймер при возвращении, если он был активен
                break
                
            case .inactive:
                // Сохраняем данные при неактивном состоянии
                HabitTimerService.shared.persistAllCompletionsToSwiftData(modelContext: container.mainContext)
                HabitCounterService.shared.persistAllCompletionsToSwiftData(modelContext: container.mainContext)
                
            @unknown default:
                break
            }
        }
    }
}
