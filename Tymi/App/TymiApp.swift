import SwiftUI
import SwiftData

@main
struct TymiApp: App {
    let container: ModelContainer
    
    init() {
        do {
            container = try ModelContainer(for: Habit.self, HabitCompletion.self)
        } catch {
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
