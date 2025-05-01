import SwiftUI
import SwiftData

@main
struct TymiApp: App {
    @Environment(\.scenePhase) private var scenePhase
    
    let container: ModelContainer
    
    init() {
        do {
            let schema = Schema([
                Habit.self,
                HabitCompletion.self
            ])
            
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true
            )
            
            container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            
            // Инициализируем NotificationManager
            Task {
                do {
                    try await NotificationManager.shared.requestAuthorization()
                } catch {
                    print("Ошибка при запросе разрешения на уведомления: \(error)")
                }
            }
        } catch {
            print("Unresolved error loading container \(error)")
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            TodayView()
        }
        .modelContainer(container)
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .background:
                HabitTimerService.shared.handleAppDidEnterBackground()
            case .active:
                HabitTimerService.shared.handleAppWillEnterForeground()
            case .inactive:
                break
            @unknown default:
                break
            }
        }
    }
}
