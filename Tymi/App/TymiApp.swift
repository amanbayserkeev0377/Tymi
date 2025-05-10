import SwiftUI
import SwiftData

@main
struct TymiApp: App {
    @Environment(\.scenePhase) private var scenePhase
    
    let container: ModelContainer
    
    init() {
        do {
            let schema = Schema([Habit.self, HabitCompletion.self])
            let modelConfiguration = ModelConfiguration(schema: schema)
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            // Запрашиваем разрешения на уведомления
            Task {
                do {
                    let granted = try await NotificationManager.shared.requestAuthorization()
                    await MainActor.run {
                        UserDefaults.standard.set(granted, forKey: "notificationsEnabled")
                    }
                } catch {
                    print("Ошибка запроса разрешений: \(error)")
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
        }
        .modelContainer(container)
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background:
                // Сохраняем состояние при уходе в фон
                NotificationCenter.default.post(
                    name: UIApplication.didEnterBackgroundNotification,
                    object: nil
                )
                
                // Сохраняем данные в SwiftData
                HabitTimerService.shared.persistAllCompletionsToSwiftData(modelContext: container.mainContext)
                HabitCounterService.shared.persistAllCompletionsToSwiftData(modelContext: container.mainContext)
                
            case .active:
                // Обновляем состояние при возвращении
                NotificationCenter.default.post(
                    name: UIApplication.willEnterForegroundNotification,
                    object: nil
                )
                
            case .inactive:
                // Сохраняем данные в SwiftData
                HabitTimerService.shared.persistAllCompletionsToSwiftData(modelContext: container.mainContext)
                HabitCounterService.shared.persistAllCompletionsToSwiftData(modelContext: container.mainContext)
                
            @unknown default:
                break
            }
        }
    }
}
