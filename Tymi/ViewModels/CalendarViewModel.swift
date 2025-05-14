import SwiftUI
import SwiftData

@Observable
class CalendarViewModel {
    let habit: Habit
    private(set) var progressMap: [String: Double] = [:]
    
    @MainActor
    init(habit: Habit, modelContext: ModelContext) {
        self.habit = habit
        updateProgressData(in: modelContext)
    }
    
    @MainActor
    func updateProgressData(in context: ModelContext) {
        progressMap.removeAll()
        
        do {
            // Исправляем предикат - сравниваем строковое представление UUID
            let habitId = habit.uuid.uuidString
            let predicate = #Predicate<HabitCompletion> { completion in
                completion.habit?.id == habitId
            }
            let descriptor = FetchDescriptor<HabitCompletion>(predicate: predicate)
            let completions = try context.fetch(descriptor)
            
            // Группируем по дате
            let calendar = Calendar.current
            var groupedByDate: [Date: [HabitCompletion]] = [:]
            
            for completion in completions {
                let startOfDay = calendar.startOfDay(for: completion.date)
                if groupedByDate[startOfDay] == nil {
                    groupedByDate[startOfDay] = []
                }
                groupedByDate[startOfDay]?.append(completion)
            }
            
            // Рассчитываем прогресс для каждой даты
            for (date, dateCompletions) in groupedByDate {
                let totalValue = dateCompletions.reduce(0) { $0 + $1.value }
                let dateKey = calendar.startOfDay(for: date).formatted(date: .numeric, time: .omitted)
                
                if habit.goal > 0 {
                    progressMap[dateKey] = min(Double(totalValue) / Double(habit.goal), 1.0)
                } else {
                    progressMap[dateKey] = totalValue > 0 ? 1.0 : 0.0
                }
            }
        } catch {
            print("Ошибка при загрузке завершений: \(error.localizedDescription)")
        }
    }
    
    func getProgress(for date: Date) -> Double {
        let calendar = Calendar.current
        let dateKey = calendar.startOfDay(for: date).formatted(date: .numeric, time: .omitted)
        return progressMap[dateKey] ?? 0.0
    }
}
