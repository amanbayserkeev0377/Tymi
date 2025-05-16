import SwiftUI
import SwiftData

// Протокол для обработки действий с привычками
protocol HabitActionHandler {
    func completeHabit(_ habit: Habit, for date: Date)
    func addProgress(to habit: Habit, for date: Date)
    func editHabit(_ habit: Habit)
    func deleteHabit(_ habit: Habit)
    func showStatistics(for habit: Habit)
}

// Класс для обработки действий с привычками
@Observable @MainActor
class HabitActionService {
    private var modelContext: ModelContext
    private var habitsUpdateService: HabitsUpdateService
    private var onHabitSelected: ((Habit) -> Void)?
    private var onHabitEditSelected: ((Habit) -> Void)?
    private var onHabitStatsSelected: ((Habit) -> Void)?
    
    init(modelContext: ModelContext,
         habitsUpdateService: HabitsUpdateService,
         onHabitSelected: ((Habit) -> Void)? = nil,
         onHabitEditSelected: ((Habit) -> Void)? = nil,
         onHabitStatsSelected: ((Habit) -> Void)? = nil) {
        self.modelContext = modelContext
        self.habitsUpdateService = habitsUpdateService
        self.onHabitSelected = onHabitSelected
        self.onHabitEditSelected = onHabitEditSelected
        self.onHabitStatsSelected = onHabitStatsSelected
    }
    
    // Действия с привычками
    func completeHabit(_ habit: Habit, for date: Date) {
        let viewModel = HabitDetailViewModel(
            habit: habit,
            date: date,
            modelContext: modelContext,
            habitsUpdateService: habitsUpdateService
        )
        viewModel.completeHabit()
        viewModel.saveIfNeeded()
        habitsUpdateService.triggerUpdate()
        HapticManager.shared.play(.success)
    }
    
    func addProgress(to habit: Habit, for date: Date) {
        // Показать привычку в детальном просмотре
        if let onHabitSelected = onHabitSelected {
            onHabitSelected(habit)
        }
    }
    
    func editHabit(_ habit: Habit) {
        if let onHabitEditSelected = onHabitEditSelected {
            onHabitEditSelected(habit)
        }
    }
    
    func deleteHabit(_ habit: Habit) {
        NotificationManager.shared.cancelNotifications(for: habit)
        modelContext.delete(habit)
        habitsUpdateService.triggerUpdate()
        HapticManager.shared.play(.error)
    }
    
    func showStatistics(for habit: Habit) {
        if let onHabitStatsSelected = onHabitStatsSelected {
            onHabitStatsSelected(habit)
        }
    }
    
    func updateContext(_ context: ModelContext) {
        // Придётся сделать свойство изменяемым private var modelContext
        self.modelContext = context
    }

    func updateService(_ service: HabitsUpdateService) {
        self.habitsUpdateService = service
    }

    func setCallbacks(
        onHabitSelected: ((Habit) -> Void)? = nil,
        onHabitEditSelected: ((Habit) -> Void)? = nil,
        onHabitStatsSelected: ((Habit) -> Void)? = nil
    ) {
        self.onHabitSelected = onHabitSelected
        self.onHabitEditSelected = onHabitEditSelected
        self.onHabitStatsSelected = onHabitStatsSelected
    }
}
