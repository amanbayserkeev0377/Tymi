import SwiftUI
import SwiftData

@main
struct TymiApp: App {
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
    }
}
