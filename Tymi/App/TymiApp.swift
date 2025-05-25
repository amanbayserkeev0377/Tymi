import SwiftUI
import SwiftData
import UserNotifications

@main
struct TymiApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme
    
    let container: ModelContainer
    let habitsUpdateService = HabitsUpdateService()
    
    @State private var weekdayPrefs = WeekdayPreferences.shared
    
    init() {
        do {
            let schema = Schema([Habit.self, HabitCompletion.self, HabitFolder.self])
            
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .private("iCloud.com.amanbayserkeev.tymi")
            )
            container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            
            print("✅ CloudKit container initialized successfully")
        } catch {
            print("❌ CloudKit initialization error: \(error)")
            fatalError("Не удалось создать ModelContainer с CloudKit: \(error)")
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
                // Сохраняем данные при уходе в фон для лучшей синхронизации
                do {
                    try container.mainContext.save()
                    print("✅ Data saved on background")
                } catch {
                    print("❌ Failed to save on background: \(error)")
                }
                
                // Сохраняем данные из сервисов
                Task {
                    HabitTimerService.shared.persistAllCompletionsToSwiftData(modelContext: container.mainContext)
                    HabitCounterService.shared.persistAllCompletionsToSwiftData(modelContext: container.mainContext)
                }
                
            case .active:
                // При возвращении обновляем UI для получения изменений с других устройств
                habitsUpdateService.triggerUpdate()
                print("✅ App became active, triggering UI update")
                
            case .inactive:
                // Сохраняем при неактивном состоянии
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
