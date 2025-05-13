import SwiftUI
import SwiftData
import UserNotifications

@main
struct TymiApp: App {
    @Environment(\.scenePhase) private var scenePhase
    
    let container: ModelContainer
    let habitsUpdateService = HabitsUpdateService()
    
    init() {
        do {
            // Инициализация базы данных
            let schema = Schema([Habit.self, HabitCompletion.self])
            let modelConfiguration = ModelConfiguration(schema: schema)
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            // Запрашиваем разрешения на уведомления с использованием Task
            Task {
                do {
                    let options: UNAuthorizationOptions = [.alert, .sound, .badge]
                    let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: options)
                    
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
            MainTabView()
                .environment(habitsUpdateService)
                .tint(.primary)
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

