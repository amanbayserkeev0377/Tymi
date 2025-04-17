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
            
            
            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true
            )
            
            
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            print("Failed to create ModelContainer: \(error)")
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
