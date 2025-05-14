import SwiftUI
import SwiftData

class HabitStatsViewModel: Observable {
    let habit: Habit
    
    // Основные метрики, которые мы отслеживаем
    private(set) var currentStreak: Int = 0
    private(set) var bestStreak: Int = 0
    private(set) var totalValue: Int = 0
    
    init(habit: Habit) {
        self.habit = habit
        calculateStats()
    }
    
    func calculateStats() {
        let calendar = Calendar.current
        _ = Date()
        
        // Получаем все даты завершения
        var completedDates: [Date] = []
        var completedDaysSet = Set<Date>()
        
        // Собираем данные о завершениях
        for completion in habit.completions {
            let dayStart = calendar.startOfDay(for: completion.date)
            
            // Отслеживание завершенных дней
            if completion.value >= habit.goal {
                if !completedDates.contains(where: { calendar.isDate($0, inSameDayAs: dayStart) }) {
                    completedDates.append(dayStart)
                }
                completedDaysSet.insert(dayStart)
            }
        }
        
        // totalValue теперь Int
        totalValue = completedDaysSet.count
        
        // Вычисляем серии
        currentStreak = calculateCurrentStreak(completedDates: completedDates)
        bestStreak = calculateBestStreak(completedDates: completedDates)
    }
    
    // Вычисление текущей серии
    private func calculateCurrentStreak(completedDates: [Date]) -> Int {
        let calendar = Calendar.current
        let today = Date()
        var currentStreakCount = 0
        
        // Проверяем, выполнена ли привычка сегодня
        let isCompletedToday = habit.isCompletedForDate(today)
        
        // Начинаем с сегодняшнего дня или вчерашнего, если сегодня не выполнено
        var checkDate = isCompletedToday ? today : calendar.date(byAdding: .day, value: -1, to: today)!
        
        // Идем назад по дням
        while true {
            // Проверяем только активные дни
            if habit.isActiveOnDate(checkDate) {
                // Проверяем, выполнена ли привычка
                let isCompleted = completedDates.contains { calendar.isDate($0, inSameDayAs: checkDate) }
                
                if isCompleted {
                    currentStreakCount += 1
                } else {
                    break // Серия прервана
                }
            }
            
            // Переходим к предыдущему дню
            guard let previousDate = calendar.date(byAdding: .day, value: -1, to: checkDate),
                  previousDate >= habit.startDate else { break }
            
            checkDate = previousDate
        }
        
        return currentStreakCount
    }
    
    // Вычисление лучшей серии
    private func calculateBestStreak(completedDates: [Date]) -> Int {
        let calendar = Calendar.current
        let now = Date()
        var bestStreakCount = 0
        var tempStreak = 0
        
        // Проходим все дни от начала до сегодня
        var checkDate = habit.startDate
        
        while checkDate <= now {
            // Проверяем только активные дни
            if habit.isActiveOnDate(checkDate) {
                // Проверяем, выполнена ли привычка
                let isCompleted = completedDates.contains { calendar.isDate($0, inSameDayAs: checkDate) }
                
                if isCompleted {
                    tempStreak += 1
                    bestStreakCount = max(bestStreakCount, tempStreak)
                } else {
                    tempStreak = 0
                }
            }
            
            // Переходим к следующему дню
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: checkDate) else { break }
            checkDate = nextDate
        }
        
        return bestStreakCount
    }
}
